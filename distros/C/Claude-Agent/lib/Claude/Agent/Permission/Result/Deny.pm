package Claude::Agent::Permission::Result::Deny;

use 5.020;
use strict;
use warnings;

use Types::Common -types;
use Claude::Agent::Permission::Result;
use Marlin
    -base => 'Claude::Agent::Permission::Result',
    'message?' => Str,
    'interrupt?' => Bool;

=head1 NAME

Claude::Agent::Permission::Result::Deny - Permission deny result

=head1 DESCRIPTION

Permission result that denies the tool execution.

=head2 ATTRIBUTES

=over 4

=item * behavior - Always 'deny'

=item * message - Reason for denial (shown to Claude)

=item * interrupt - If true, interrupts the entire query

=back

=cut

sub BUILD {
    my ($self) = @_;
    # Force behavior to 'deny'
    $self->behavior('deny');
    return;
}

=head2 METHODS

=head3 to_hash

    my $hash = $result->to_hash();

Convert the result to a hash for JSON serialization.

=cut

sub to_hash {
    my ($self) = @_;
    my $hash = {
        behavior  => 'deny',
        interrupt => $self->interrupt ? \1 : \0,
    };
    $hash->{message} = $self->message if $self->has_message;
    return $hash;
}

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under The Artistic License 2.0 (GPL Compatible).

=cut

1;
