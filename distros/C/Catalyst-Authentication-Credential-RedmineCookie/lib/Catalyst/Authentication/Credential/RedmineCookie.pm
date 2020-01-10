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
        $pid ||= open2($out, $in, ref($cmd) ? @$cmd : $cmd) or die "open2 error. \$?:$? \$!:$!";
        if ( waitpid($pid, WNOHANG) ) {
            die "child process has gone. pid:$pid";
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
                    my $authinfo = { id => $id, _redmine_cookie => $data };
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

=encoding utf8

=head1 NAME

Catalyst::Authentication::Credential::RedmineCookie - Decode the redmine cookie _redmine_session

=head1 SYNOPSIS

    package TestApp;
    use base qw(Catalyst);
    __PACKAGE__->config(
        'Plugin::Authentication' => {
            default_realm => 'redmine_cookie',
            realms => {
                redmine_cookie => {
                    credential => {
                        class => 'RedmineCookie',
                        # examples
                        cmd   => [qw(ssh redmine.server /root/rails4_cookie_to_json.rb)],
                        cmd   => [qw(sudo jexec redmine /root/rails4_cookie_to_json.rb)],
                    },
                    # It does not specify a store, it works with NullStore.
                    store => {
                        class => 'DBIx::Class',
                        user_model => 'DBIC::Users',
                    }
                },
            },
        },
        # Not required for NullStore.
        'Model::DBIC' => {
            schema_class => "Catalyst::Authentication::RedmineCookie::Schema",
            connect_info => [
                "DBI:mysql:database=redmine", 'user', 'pass',
                {
                    RaiseError        => 1,
                    PrintError        => 0,
                    AutoCommit        => 1,
                    pg_enable_utf8    => 1, # for pg
                    mysql_enable_utf8 => 1, # for mysql
                }
            ],
        },
    );
    __PACKAGE__->setup(
        'Authentication',
    );

    package TestApp::Controller::Root;
    use base qw(Catalyst::Controller);
    sub index :Path('/') {
        my ($self, $c) = @_;

        $c->authenticate;

        # If the store is DBIx::Class
        if ($c->user) {
            ref $c->user;             # Catalyst::Authentication::Store::DBIx::Class::User
            ref $c->user->get_object; # TestApp::Model::DBIC::Users
        }

        # If the store is Null
        if ($c->user) {
            ref $c->user;             # Catalyst::Authentication::User::Hash
            ref YAML::Syck::Dump($c->user);
            # --- !!perl/hash:Catalyst::Authentication::User::Hash
            # _redmine_cookie:
            #   _csrf_token: 7fwDk6DF6aCWepctbBGvawotX2tQBDSXZJ7CXcUtD7o=
            #   session_id: 422c2d4f6ad5ee804d54c73946d35802
            #   sudo_timestamp: '1578451011'
            #   tk: addd76728a211c7124e4f4bf90455ecfa6b039e6
            #   user_id: 1
            # auth_realm: redmine_cookie
            # id: 1
        }
    }

    1;

=head1 AUTHOR

Tomohiro Hosaka, E<lt>bokutin@bokut.inE<gt>

=head1 COPYRIGHT AND LICENSE

The Catalyst::Authentication::Credential::RedmineCookie module is

Copyright (C) 2020 by Tomohiro Hosaka

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
