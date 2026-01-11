package Claude::Agent::Error::ProcessError;

use 5.020;
use strict;
use warnings;

use Types::Common -types;
use Marlin
    -base => 'Claude::Agent::Error',
    'exit_code?' => Int,
    'stderr?'    => Str;

=head1 NAME

Claude::Agent::Error::ProcessError - Process execution exception

=head1 DESCRIPTION

Thrown when the Claude CLI process fails.

=head2 ATTRIBUTES

=over 4

=item * message - Error description

=item * exit_code - Process exit code

=item * stderr - Standard error output

=back

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under The Artistic License 2.0 (GPL Compatible).

=cut

1;
