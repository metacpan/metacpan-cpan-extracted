use Test::More;
BEGIN {
my @needs = grep { ! eval "require $_; 1" } qw(HTTP::Daemon Net::EmptyPort);

if( @needs ) {
	plan 'skip_all' => "Local::localversion needs " . join ' and ', @needs;
	}
}

use File::Spec::Functions qw(catfile);
use HTTP::Response;
use Net::EmptyPort;

sub start_server {
	my( $port ) = @_;

	my $child_pid = fork;

	return $child_pid unless $child_pid == 0;

	require HTTP::Daemon;
	require HTTP::Date;
	require HTTP::Status;

	my $d = HTTP::Daemon->new( LocalPort => $port ) or exit;
	CONNECTION: while (my $c = $d->accept) {
		REQUEST: while (my $r = $c->get_request) {
			my $file = (split m|/|, $r->uri->path)[-1] // 'index.html';
			my $path = catfile 't', 'html', $file;

			if ($r->method eq 'GET') {
				if( -e $path ) {
					$c->send_file_response( catfile 't', 'html', $file);
					}
				elsif( $path eq 'shutdown' ) {
					$c->close; undef $c;
					last CONNECTION;
					}
				else {
					$c->send_error(HTTP::Status::RC_NOT_FOUND())
					}
				}
			elsif ($r->method eq 'HEAD') { # update_mirror does this
				if( -e $path ) {
					my $res = HTTP::Response->new;
					$res->code(200);
					$res->content('');
					$res->header('Last-Modified'  => HTTP::Date::time2str( (stat $path)[9] )),
					$res->header('Content-Length' => (-s $path));
					$c->send_response($res);
					}
				else {
					$c->send_error(HTTP::Status::RC_NOT_FOUND())
					}
				}
			else {
				$c->send_error(HTTP::Status::RC_FORBIDDEN())
				}
			}
		$c->close;
		undef($c);
		}

	exit;
	}

sub can_fetch { require LWP::UserAgent; LWP::UserAgent->new->get( shift )->is_success }

1;
