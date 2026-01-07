package Async::Redis::Error::Connection;

use strict;
use warnings;
use 5.018;

our $VERSION = '0.001';

use parent 'Async::Redis::Error';

sub host   { shift->{host} }
sub port   { shift->{port} }
sub path   { shift->{path} }    # for unix sockets
sub reason { shift->{reason} }

1;

__END__

=head1 NAME

Async::Redis::Error::Connection - Connection failure exception

=head1 DESCRIPTION

Thrown when connection to Redis fails or is lost.

=head1 ATTRIBUTES

=over 4

=item host - Redis host

=item port - Redis port

=item path - Unix socket path (if applicable)

=item reason - Why connection failed (timeout, refused, etc.)

=back

=cut
