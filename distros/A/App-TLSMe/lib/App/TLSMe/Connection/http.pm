package App::TLSMe::Connection::http;

use strict;
use warnings;

use base 'App::TLSMe::Connection';

sub _on_send_handler {
    my $self = shift;

    my $x_forwarded_for   = "X-Forwarded-For: $self->{peer_host}\x0d\x0a";
    my $x_forwarded_proto = "X-Forwarded-Proto: https\x0d\x0a";

    my $headers;
    return sub {
        my $handle = shift;

        if ($headers) {
            $self->{backend_handle}->push_write($handle->rbuf);
            $handle->{rbuf} = '';
        }
        elsif ($handle->rbuf
            =~ s/ (?<=\x0a)\x0d?\x0a /$x_forwarded_for$x_forwarded_proto\x0d\x0a/xms
          )
        {
            $self->{backend_handle}->push_write($handle->rbuf);
            $handle->{rbuf} = '';

            $headers = 1;
        }
      }
}

1;
__END__

=head1 NAME

App::TLSMe::Connection::http - HTTP connection class

=head1 DESCRIPTION

Connection for http protocol.

=cut
