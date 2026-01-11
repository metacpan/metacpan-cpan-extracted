package Claude::Agent::Content::Thinking;

use 5.020;
use strict;
use warnings;

use Types::Common -types;
use Marlin
    'type'       => sub { 'thinking' },
    'thinking!'  => Str,       # The thinking content
    'signature?' => Str;       # Optional signature for verification

=head1 NAME

Claude::Agent::Content::Thinking - Thinking content block

=head1 DESCRIPTION

A thinking content block containing Claude's reasoning process.
Only present when extended thinking is enabled.

=head2 ATTRIBUTES

=over 4

=item * type - Always 'thinking'

=item * thinking - The thinking/reasoning content

=item * signature - Optional cryptographic signature

=back

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under The Artistic License 2.0 (GPL Compatible).

=cut

1;
