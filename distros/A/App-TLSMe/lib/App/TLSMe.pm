package App::TLSMe;

use strict;
use warnings;

our $VERSION = '0.11';

use constant DEBUG => $ENV{APP_TLSME_DEBUG};

use File::Spec;
require Carp;

use AnyEvent;
use AnyEvent::TLS;
use AnyEvent::Socket;
use POSIX 'setsid', ':sys_wait_h';
use Proc::Pidfile;

use App::TLSMe::Pool;
use App::TLSMe::Logger;

use constant CERT => <<'EOF';
-----BEGIN CERTIFICATE-----
MIICsDCCAhmgAwIBAgIJAPZgxGgzkLMkMA0GCSqGSIb3DQEBBQUAMEUxCzAJBgNV
BAYTAkFVMRMwEQYDVQQIEwpTb21lLVN0YXRlMSEwHwYDVQQKExhJbnRlcm5ldCBX
aWRnaXRzIFB0eSBMdGQwHhcNMTEwMzE1MDgxMzExWhcNMzEwMzEwMDgxMzExWjBF
MQswCQYDVQQGEwJBVTETMBEGA1UECBMKU29tZS1TdGF0ZTEhMB8GA1UEChMYSW50
ZXJuZXQgV2lkZ2l0cyBQdHkgTHRkMIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKB
gQClL0W4K2Ux4ntepXG4Z4sHPn/KR7efIwy6ciEnOBFa8JPnnP2ZI8b4ifS8ayC0
VqwzZgYEb+roCM2BZ8oJIxGkwS0iwb/16KDgw4ODrIT5c9gRnpbezLpbolbChQMb
rhhH9qPswVPGXFdWIudgZ9bWV1NDGPdvt7tmxryWQO2PEQIDAQABo4GnMIGkMB0G
A1UdDgQWBBTlwxPDs2JacAUoc8KSDPNDKTEZ3TB1BgNVHSMEbjBsgBTlwxPDs2Ja
cAUoc8KSDPNDKTEZ3aFJpEcwRTELMAkGA1UEBhMCQVUxEzARBgNVBAgTClNvbWUt
U3RhdGUxITAfBgNVBAoTGEludGVybmV0IFdpZGdpdHMgUHR5IEx0ZIIJAPZgxGgz
kLMkMAwGA1UdEwQFMAMBAf8wDQYJKoZIhvcNAQEFBQADgYEAGtfsSndB3GftZKEa
74bgp8UZNJJT9W2bQgHFoL/4Tjl9CpoAtNR0wuTO7TvV+jzhON85YkMR83OQ4ol4
J+ew017cvKvsk5lKNZhgX8d+CBgWHh5FBZA19TYmH4RgV0ZKGJnDky2CR3fdcHnk
ChexCtgZ2nIYm3W/Z7wRA+xjHok=
-----END CERTIFICATE-----
EOF

use constant KEY => << 'EOF';
-----BEGIN RSA PRIVATE KEY-----
MIICXwIBAAKBgQClL0W4K2Ux4ntepXG4Z4sHPn/KR7efIwy6ciEnOBFa8JPnnP2Z
I8b4ifS8ayC0VqwzZgYEb+roCM2BZ8oJIxGkwS0iwb/16KDgw4ODrIT5c9gRnpbe
zLpbolbChQMbrhhH9qPswVPGXFdWIudgZ9bWV1NDGPdvt7tmxryWQO2PEQIDAQAB
AoGBAJkpduzol+EkTh4ZK5O/tmKWKemGjBTra97o+iKiUz1OOuYUY/R9/vzu9dVL
Q7zTbMIPxF6S424Y02w8r1G/iZgLt3HjbYEbkBZWFIIH4CTttnd5IjtRsJvVkFU3
YR6bWG4qvoqVxdlb2cE8BJofdM3f/zYkoP1UEBcwdUXLAvGdAkEA1jidDz7CgbN2
2TS33/p6lHb4C9f+DedlWOJYzzBkfExOE1J1UdxzUtB4K6iZeE5idELCiOtXsxeV
5Efahob4NwJBAMVma+lD8KVCZR/lOyAK3F9SHTgP1Wi3/Dawrq8Cc3emNusSLzsO
kFSoW8p0jZUKx2PVO0Z1D3ls/UXPHBc/fvcCQQCAJJ929iDd+x+V8J4pYikfVEcu
toanhIqwb72WOqlxXSe7ETFSxZ9Ko5+u5gzf1Wu5hhHeW4E7hVlJk93ZaTVjAkEA
mjj04iAEaPjAjPTJBrW1inta/KvSLahg0lGjiHO/xqEDkxB3+gnc1Wdbn4cD/oeX
U/YKA3f9iP6PufSfm8It7QJBAMZmOUrkGJyScCVP7ugzLliGExtYQeuXtl+79sOz
M+T4ZKNBUAz3HOOy3HTMs1bpudLd/Jgpi9ftbW+0+fZ07II=
-----END RSA PRIVATE KEY-----
EOF

sub new {
    my $class = shift;
    my (%args) = @_;

    my ($host, $port) = $class->_parse_listen_address($args{listen});
    my ($backend_host, $backend_port) =
      $class->_parse_backend_address($args{backend});

    my $tls_ctx = $class->_build_tls_ctx(%args);
    $tls_ctx->init;

    my $self = {
        host         => $host,
        port         => $port,
        backend_host => $backend_host,
        backend_port => $backend_port,
        tls_ctx      => $tls_ctx,
        %args
    };
    bless $self, $class;

    $self->{protocol} ||= 'http';
    die "Unknown protocol '$self->{protocol}'"
      unless $self->{protocol} =~ m/^http|raw$/;

    $self->{pool}   ||= App::TLSMe::Pool->new;
    $self->{logger} ||= $self->_build_logger($args{log_file});

    if ($self->{pid_file}) {
        $self->{pid_file} = File::Spec->rel2abs($self->{pid_file});
    }

    $self->_register_signals;

    if ($self->{daemonize}) {
        die "Log file is required when daemonizing\n"
          unless $self->{log_file};

        $self->_daemonize;
    }

    $self->_create_pidfile if $self->{pid_file};

    $self->_listen;

    return $self;
}

sub run {
    my $self = shift;

    $self->{cv}->wait;

    return $self;
}

sub stop {
    my $self = shift;

    $self->{cv}->send;

    $self->_log('Shutting down');

    return $self;
}

sub _daemonize {
    my $self = shift;

    chdir '/' or die "Can't chdir to /: $!";

    open STDIN, '/dev/null' or die "Can't read /dev/null: $!";
    open STDOUT, '>', '/dev/null' or die "Can't write to /dev/null: $!";
    open STDERR, '>', '/dev/null' or die "Can't write to /dev/null: $!";

    defined(my $pid = fork) or die "Can't fork: $!";
    exit if $pid;

    die "Can't start a new session: $!" if setsid == -1;

    return $self;
}

sub _create_pidfile {
    my $self = shift;

    $self->{pid} = Proc::Pidfile->new(pidfile => $self->{pid_file});

    $self->_log('Created pid file: ' . $self->{pid}->pidfile);

    return $self;
}

sub _parse_listen_address {
    my $self = shift;
    my ($address) = @_;

    my ($host, $port) = split ':', $address, -1;
    $host ||= '0.0.0.0';
    $port ||= 443;

    return ($host, $port);
}

sub _parse_backend_address {
    my $self = shift;
    my ($address) = @_;

    my ($backend_host, $backend_port);

    if ($address =~ m/:\d+$/) {
        ($backend_host, $backend_port) = split ':', $address, -1;
        $backend_host ||= '127.0.0.1';
        $backend_port ||= 8080;
    }
    else {
        $backend_host = 'unix/';
        $backend_port = File::Spec->rel2abs($address);
    }

    return ($backend_host, $backend_port);
}

sub _build_tls_ctx {
    my $self = shift;
    my (%args) = @_;

    my $tls_ctx = {method => delete $args{method}};

    if (my $cipher_list = delete $args{cipher_list}) {
        $tls_ctx->{cipher_list} = $cipher_list;
    }

    if (defined(my $cert_file = delete $args{cert_file})) {
        Carp::croak("Certificate file '$cert_file' does not exist")
          unless -f $cert_file;

        $tls_ctx->{cert_file} = $cert_file;

        if (defined(my $password = delete $args{cert_password})) {
            if ($password eq '') {
                print 'Enter certificate password: ';
                system('stty', '-echo');
                $password = <STDIN>;
                system('stty', 'echo');
                chomp $password;
                print "\n";
            }

            $tls_ctx->{cert_password} = $password;
        }

        if (my $key_file = delete $args{key_file}) {
            Carp::croak("Private key file '$key_file' does not exist")
              unless -f $key_file;

            $tls_ctx->{key_file} = $key_file;
        }

    }
    else {
        DEBUG && warn "Using default certificate and private key values\n";

        $tls_ctx = {%$tls_ctx, cert => CERT, key => KEY};
    }

    return AnyEvent::TLS->new(%$tls_ctx);
}

sub _register_signals {
    my $self = shift;

    $SIG{__WARN__} = sub {
        $self->_log(@_);
    };

    $SIG{__DIE__} = sub {
        $self->_log(@_) if $self;
        exit(1);
    };

    $SIG{TERM} = $SIG{INT} = sub {
        $self->_log('Shutting down');
        exit(0);
    };
}

sub _listen {
    my $self = shift;

    $self->_log('Starting up');

    $self->{cv} = AnyEvent->condvar;

    tcp_server $self->{host}, $self->{port}, $self->_accept_handler,
      $self->_bind_handler;
}

sub _accept_handler {
    my $self = shift;

    return sub {
        my ($fh, $peer_host, $peer_port) = @_;

        $self->_log("Accepted connection from $peer_host:$peer_port");

        $self->{pool}->add_connection(
            protocol     => $self->{protocol},
            fh           => $fh,
            backend_host => $self->{backend_host},
            backend_port => $self->{backend_port},
            peer_host    => $peer_host,
            peer_port    => $peer_port,
            tls_ctx      => $self->{tls_ctx},
            on_eof       => sub {
                my ($conn) = @_;

                $self->_log("Closing connection from $peer_host:$peer_port");

                $self->{pool}->remove_connection($fh);
            },
            on_error => sub {
                my ($conn, $error) = @_;

                if ($error =~ m/ssl23_get_client_hello: http request/) {
                    my $response = $self->_build_http_response(
                        '501 Not Implemented',
                        '<h1>501 Not Implemented</h1>'
                          . '<p>Try <code>https://</code> instead of <code>http://</code>?</p>'
                    );

                    syswrite $fh, $response;
                }

                $self->_log(
                    "Closing connection from $peer_host:$peer_port: $error");

                $self->{pool}->remove_connection($fh);
            },
            on_backend_connected => sub {
                $self->_log("Connected to backend");
            },
            on_backend_eof => sub {
                $self->_log("Disconnected from backend");
            },
            on_backend_error => sub {
                my ($conn, $message) = @_;

                $self->_log("Disconnected from backend: $message");

                my $response = $self->_build_http_response('502 Bad Gateway',
                    '<h1>502 Bad Gateway</h1>');

                $conn->write($response);
            }
        );
    };
}

sub _bind_handler {
    my $self = shift;

    return sub {
        my ($fh, $host, $port) = @_;

        $self->_log("Listening on $host:$port");

        $self->_drop_privileges;

        return $self->{backlog} || 128;
    };
}

sub _drop_privileges {
    my $self = shift;

    if ($self->{user}) {
        $self->_log('Dropping privileges');

        eval { require Privileges::Drop; 1 }
          or do { die "Privileges::Drop is required\n" };

        if ($self->{group}) {
            Privileges::Drop::drop_uidgid($self->{user}, $self->{group});
        }
        else {
            Privileges::Drop::drop_privileges($self->{user});
        }
    }
}

sub _build_http_response {
    my $self = shift;
    my ($status_message, $body) = @_;

    my $length = length($body);

    return join "\015\012", "HTTP/1.1 $status_message",
      "Content-Length: $length", "", $body;
}

sub _log {
    my $self = shift;

    return unless $self->{logger};

    $self->{logger}->log(@_);
}

sub _build_logger {
    my $self = shift;
    my ($log) = @_;

    my $fh;
    if ($log) {
        open $fh, '>>', $log or die "Can't open log file '$log': $!";
    }

    return App::TLSMe::Logger->new(fh => $fh);
}

1;
__END__

=head1 NAME

App::TLSMe - TLS/SSL tunnel

=head1 SYNOPSIS

    App::TLSMe->new(
        listen    => ':443',
        backend   => '127.0.0.1:8080',
        cert_file => 'cert.pem',
        key_file  => 'key.pem'
    )->run;

Run C<tlsme -h> for more options.

=head1 DESCRIPTION

This module is used by a command line application C<tlsme>. You might want to
look at its documentation instead.

=head1 METHODS

=head2 C<new>

    my $app = App::TLSMe->new;

=head2 C<run>

    $app->run;

Start the secure tunnel.

=head2 C<stop>

    $app->stop;

Stop the secure tunnel (used for testing).

=head1 DEVELOPMENT

=head2 Repository

    http://github.com/vti/app-tlsme

=head1 CREDITS

Andrey Sidorov

James D Bearden

=head1 AUTHOR

Viacheslav Tykhanovskyi, C<vti@cpan.org>.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011-2013, Viacheslav Tykhanovskyi

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=cut
