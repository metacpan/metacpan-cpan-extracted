package Claude::Agent::Error::JSONDecodeError;

use 5.020;
use strict;
use warnings;

use Types::Common -types;
use Marlin
    -base => 'Claude::Agent::Error',
    'line?' => Str;

=head1 NAME

Claude::Agent::Error::JSONDecodeError - JSON parsing exception

=head1 DESCRIPTION

Thrown when JSON parsing fails.

=head2 ATTRIBUTES

=over 4

=item * message - Error description

=item * line - The line that failed to parse

=back

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under The Artistic License 2.0 (GPL Compatible).

=cut

1;
