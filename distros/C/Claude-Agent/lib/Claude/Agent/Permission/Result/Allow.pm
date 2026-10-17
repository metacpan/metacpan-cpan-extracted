package Claude::Agent::Permission::Result::Allow;

use 5.020;
use strict;
use warnings;

use Object::Proto ();
use Claude::Agent::Permission::Result;

BEGIN {
    Object::Proto::define('Claude::Agent::Permission::Result::Allow',
        extends => 'Claude::Agent::Permission::Result',
        'updated_input:predicate',
        'updated_permissions:predicate',
    );
}

sub BUILD {
    my ($self) = @_;
    $self->behavior('allow');
    return;
}

sub to_hash {
    my ($self) = @_;
    my $hash = { behavior => 'allow' };
    $hash->{updatedInput} = $self->updated_input if $self->has_updated_input;
    $hash->{updatedPermissions} = $self->updated_permissions if $self->has_updated_permissions;
    return $hash;
}

1;

__END__

=head1 NAME

Claude::Agent::Permission::Result::Allow - Permission result that allows a tool

=head1 DESCRIPTION

Permission result that lets the tool run, optionally with changed input
or a permission rule update.

=head1 ATTRIBUTES

=head2 behavior

Always C<allow>.

=head2 updated_input

The input the tool should run with. When not given, the CLI is sent the
input it asked about.

=head2 updated_permissions

ArrayRef of permission updates for the CLI to apply, in the CLI's own
C<PermissionUpdate> shape.

=head1 METHODS

=head2 new

Takes a flat list of name/value pairs. Unknown names are ignored.

=head2 to_hash

    my $hash = $result->to_hash;

C<{ behavior =E<gt> 'allow', updatedInput =E<gt> ..., updatedPermissions =E<gt> ... }>
with only the attributes that were given.

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under The Artistic License 2.0 (GPL Compatible).

=cut
