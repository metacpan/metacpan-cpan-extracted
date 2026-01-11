package Claude::Agent::Permission::Result::Allow;

use 5.020;
use strict;
use warnings;

use Types::Common -types;
use Claude::Agent::Permission::Result;
use Marlin
    -base => 'Claude::Agent::Permission::Result',
    'updated_input?',
    'updated_permissions?';

=head1 NAME

Claude::Agent::Permission::Result::Allow - Permission allow result

=head1 DESCRIPTION

Permission result that allows the tool to execute.

=head2 ATTRIBUTES

=over 4

=item * behavior - Always 'allow'

=item * updated_input - The input to pass to the tool (can be modified)

=item * updated_permissions - Optional permissions update

=back

=cut

sub BUILD {
    my ($self) = @_;
    # Force behavior to 'allow'
    $self->behavior('allow');
    return;
}

=head2 METHODS

=head3 to_hash

    my $hash = $result->to_hash();

Convert the result to a hash for JSON serialization.

=cut

sub to_hash {
    my ($self) = @_;
    my $hash = { behavior => 'allow' };
    $hash->{updatedInput} = $self->updated_input if $self->has_updated_input;
    $hash->{updatedPermissions} = $self->updated_permissions if $self->has_updated_permissions;
    return $hash;
}

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under The Artistic License 2.0 (GPL Compatible).

=cut

1;
