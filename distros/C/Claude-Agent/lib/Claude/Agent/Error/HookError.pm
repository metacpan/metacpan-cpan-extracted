package Claude::Agent::Error::HookError;

use 5.020;
use strict;
use warnings;

use Types::Common -types;
use Marlin
    -base => 'Claude::Agent::Error',
    'hook_event?' => Str,
    'original_error?';

=head1 NAME

Claude::Agent::Error::HookError - Hook execution exception

=head1 DESCRIPTION

Thrown when a hook callback fails.

=head2 ATTRIBUTES

=over 4

=item * message - Error description

=item * hook_event - The event that triggered the hook

=item * original_error - The original error from the hook callback

=back

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under The Artistic License 2.0 (GPL Compatible).

=cut

1;
