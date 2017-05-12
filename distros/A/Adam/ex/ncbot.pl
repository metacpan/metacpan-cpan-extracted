#!/usr/bin/env perl
use 5.10.0;
use lib qw(lib);
use Moses::Declare;

bot NetCat {
    server 'irc.perl.org';
    channels '#moses';

    use Regexp::Common qw(pattern);
    use aliased 'POE::Component::Server::TCP' => 'TCPServer';

    has listen => (
        isa     => 'Int',
        is      => 'ro',
        default => 12345,
    );

    has tcp_server => (
        isa        => 'Int',
        is         => 'ro',
        lazy_build => 1
    );

    method _build_tcp_server {
        TCPServer->new(
            Port            => $self->listen,
            ClientConnected => sub {
                $self->debug("client connected from $_[HEAP]{remote_ip}");
            },
            ClientInput => sub {
                $self->handle_nc_command( $_[ARG0] );
                $_[HEAP]{client}->put('ok');
                $_[KERNEL]->yield("shutdown");
                return;
            },
        );
    }

    sub START { shift->tcp_server }

    pattern
      name   => [qw(COMMAND echo -keep)],
      create => q[^(?k:[@#][^\s]+)?\s*(?k:.*)$];

    method handle_nc_command( Str $cmd) {
        my ($owner) = split /!/, $self->get_owner;

          given ($cmd) {
            when (/$RE{COMMAND}{echo}{-keep}/) {
                if ($1) {
                    my @targets = split ',', $1;                    
                    $self->privmsg( $_ => $2 ) for map { s/^@//; warn $_; $_ } @targets;
                }
                else {
                    $self->privmsg( $self->get_channels->[0] => $2 );
                }
            }

            default {
                $self->privmsg( $owner, "unknown command $cmd" );
            }
        }
    };
}
NetCat->run;
