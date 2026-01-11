package Claude::Agent::Content::Text;

use 5.020;
use strict;
use warnings;

use Types::Common -types;
use Marlin
    'type'  => sub { 'text' },
    'text!' => Str;

=head1 NAME

Claude::Agent::Content::Text - Text content block

=head1 DESCRIPTION

A text content block containing Claude's response text.

=head2 ATTRIBUTES

=over 4

=item * type - Always 'text'

=item * text - The text content

=back

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under The Artistic License 2.0 (GPL Compatible).

=cut

1;
