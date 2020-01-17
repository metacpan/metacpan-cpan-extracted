package Catalyst::Authentication::Credential::RedmineCookie;

use Moose;

use IPC::Open2;
use JSON::MaybeXS qw(:legacy);
use POSIX ":sys_wait_h";

has cmd => ( is => 'ro', isa => 'Str|ArrayRef', required => 1 );

# /jails/logserver/usr/local/lib/ruby/gems/2.6/gems/rack-1.6.11/lib/rack/session/cookie.rb
# https://qiita.com/labocho/items/32efc5b7c73aba3500ff
 
my $pid;
my $in;
my $out;

sub BUILDARGS { $_[1] }

sub authenticate {
    my ($self, $c, $realm, $info) = @_;

    if (my $cookie = $c->req->cookies->{_redmine_session}) {
        my $str = $cookie->value;
        my $cmd = $self->cmd;
        my $retry;
        OPEN: $pid ||= open2($out, $in, ref($cmd) ? @$cmd : $cmd) or die "open2 error. \$?:$? \$!:$!";
        if ( waitpid($pid, WNOHANG) ) {
            $c->log->warn("child process has gone. retry pid:$pid");
            if ($retry) {
                die "failed to start child process. pid:$pid";
            }
            else {
                $pid = undef;
                $retry++;
                goto OPEN;
            }
        }
        $in->print($str."\n");
        $in->flush;
        my $line = <$out>;
        if ( $line =~ /^{/ ) {
            my $data = eval { decode_json($line) };
            if ($@) {
                $c->log->error("@{[ __PACKAGE__ ]} $@ line:$line");
            }
            else {
                if (my $id = $data->{user_id}) {
                    my $authinfo = { id => $id, status => 1, _redmine_cookie => $data };
                    return $realm->find_user($authinfo, $c);
                }
                else {
                    $c->log->debug("@{[ __PACKAGE__ ]} header _redmine_session has not user_id");
                }
            }
        }
        else {
            $c->log->error("@{[ __PACKAGE__ ]} invalid input. line:$line");
        }
    }
    else {
        $c->log->debug("@{[ __PACKAGE__ ]} header _redmine_session missing");
    }
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;
