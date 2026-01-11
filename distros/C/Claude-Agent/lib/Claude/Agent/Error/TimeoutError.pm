package Claude::Agent::Error::TimeoutError;

use 5.020;
use strict;
use warnings;

use Types::Common -types;
use Marlin
    -base => 'Claude::Agent::Error',
    'timeout_ms?' => Num;

=head1 NAME

Claude::Agent::Error::TimeoutError - Timeout exception

=head1 DESCRIPTION

Thrown when an operation times out.

=head2 ATTRIBUTES

=over 4

=item * message - Error description

=item * timeout_ms - Timeout value in milliseconds

=back

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under The Artistic License 2.0 (GPL Compatible).

=cut

1;
