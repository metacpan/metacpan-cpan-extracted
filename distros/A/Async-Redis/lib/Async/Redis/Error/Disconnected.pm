package Async::Redis::Error::Disconnected;

use strict;
use warnings;
use 5.018;

use parent 'Async::Redis::Error';

sub queue_size { shift->{queue_size} }

1;

__END__

=head1 NAME

Async::Redis::Error::Disconnected - Disconnected exception

=head1 DESCRIPTION

Thrown when an operation cannot proceed because the client, pool, or socket is
disconnected. Examples include issuing a command without an active connection
when reconnect is disabled, pool shutdown, or a fatal reader failure.

=head1 ATTRIBUTES

=over 4

=item queue_size - Legacy field for callers that track queued work

=back

=cut
