package Claude::Agent::Permission::Result;

use 5.020;
use strict;
use warnings;

use Types::Common -types;
use Marlin
    'behavior==' => Str;  # rw attribute, no init_arg (set by subclasses)

=head1 NAME

Claude::Agent::Permission::Result - Base class for permission results

=head1 DESCRIPTION

Base class for permission results in the Claude Agent SDK.

=head2 ATTRIBUTES

=over 4

=item * behavior - The permission behavior ('allow' or 'deny')

=back

=head2 METHODS

=head3 to_hash

    my $hash = $result->to_hash();

Convert the result to a hash for JSON serialization.

=cut

sub to_hash {
    my ($self) = @_;
    return { behavior => $self->behavior };
}

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under The Artistic License 2.0 (GPL Compatible).

=cut

1;
