package Async::Redis::Error::Timeout;

use strict;
use warnings;
use 5.018;

our $VERSION = '0.001';

use parent 'Async::Redis::Error';

sub command        { shift->{command} }
sub timeout        { shift->{timeout} }
sub maybe_executed { shift->{maybe_executed} }

1;

__END__

=head1 NAME

Async::Redis::Error::Timeout - Timeout exception

=head1 DESCRIPTION

Thrown when a Redis operation times out.

=head1 ATTRIBUTES

=over 4

=item command - The command that timed out (arrayref)

=item timeout - The timeout value in seconds

=item maybe_executed - Boolean; true if command may have been executed
on server before timeout. This happens when we timeout after writing
the command but before receiving response.

=back

=cut
