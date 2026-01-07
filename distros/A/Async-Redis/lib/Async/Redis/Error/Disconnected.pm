package Async::Redis::Error::Disconnected;

use strict;
use warnings;
use 5.018;

our $VERSION = '0.001';

use parent 'Async::Redis::Error';

sub queue_size { shift->{queue_size} }

1;

__END__

=head1 NAME

Async::Redis::Error::Disconnected - Disconnected exception

=head1 DESCRIPTION

Thrown when a command is issued while disconnected and the
command queue is full (cannot queue for later execution).

=head1 ATTRIBUTES

=over 4

=item queue_size - Current size of command queue

=back

=cut
