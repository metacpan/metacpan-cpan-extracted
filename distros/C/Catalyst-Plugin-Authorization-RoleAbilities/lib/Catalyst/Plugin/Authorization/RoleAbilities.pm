package Catalyst::Plugin::Authorization::RoleAbilities;

# ABSTRACT: Ability based authorization for Catalyst (using only Roles)

use Moose;
extends 'Catalyst::Plugin::Authorization::Roles';

use Set::Object         ();
use Scalar::Util        ();
use Catalyst::Exception ();

sub check_user_ability {
    my ($c, @roles) = @_;
    local $@;
    eval { $c->assert_user_ability(@roles) };
    return $@ ? 0 : 1;
}

sub assert_user_ability {
    my ($c, @actions) = @_;

    my $user;

    if (Scalar::Util::blessed($actions[0]) && $actions[0]->isa("Catalyst::Authentication::User")) {

        # A user was supplied in the arguments
        $user = shift @actions;
    }

    $user ||= $c->user;

    Catalyst::Exception->throw("No logged in user, and none supplied as argument") unless $user;

    my $have = Set::Object->new(map { $_->name } $user->user_roles->search_related('role')->search_related('role_actions')->search_related('action'));
    my $need = Set::Object->new(@actions);

    if ($have->superset($need)) {
        $c->log->debug("Action granted: @actions") if $c->debug;
        return 1;
    } else {
        $c->log->debug("Action denied: @actions") if $c->debug;
        my @missing = $need->difference($have)->members;
        Catalyst::Exception->throw("Missing actions: @missing");
    }
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=head1 NAME

Catalyst::Plugin::Authorization::RoleAbilities - Ability based authorization for Catalyst (using only Roles)

=head1 VERSION

version 0.003

=head1 SYNOPSIS

    use Catalyst qw/
    	Authentication
    	Authorization::RoleAbilities
    /;

    sub delete : Local {
    	my ( $self, $c ) = @_;

    	$c->assert_user_ability( qw/delete_user/ ); # only users with roles that can perform this action can delete

    	$c->model("User")->delete_it();
    }

=head1 DESCRIPTION

Ability based authorization allows more flexibility than role based authorization.  Users can have roles, which then
have many actions associated.  An action can be associated with several roles.  With this you don't check whether a user
has specific roles, but instead whether the roles can perform specific actions.

L<Catalyst::Plugin::Authorization::RoleAbilities> extends L<Catalyst::Plugin::Authorization::Roles> so every method of
L<Catalyst::Plugin::Authorization::Roles> still can be used.

See L<SEE ALSO> for other authorization modules.

=head1 METHODS

=head2 assert_user_ability [ $user ], @actions

Checks that the roles of the user (as supplied by the first argument, or, if omitted,
C<< $c->user >>) has the ability to perform specified actions.

If for any reason (C<< $c->user >> is not defined, the user's roles are missing the
appropriate action, etc.) the check fails, an error is thrown.

You can either catch these errors with an eval, or clean them up in your C<end>
action.

=head2 check_user_ability [ $user ], @actions

Takes the same args as C<assert_user_ability>, and performs the same check, but
instead of throwing errors returns a boolean value.

=head1 REQUIRED TABLES

=head2 Actions

Table name: C<actions>

Columns:

=over 4

=item *

C<id>, as C<integer>, Primary Key

=item *

C<name>, as C<character varying> or C<text>

=back

=head2 Roles to Actions

Table name: C<role_actions>

Columns:

=over 4

=item *

C<id>, as C<integer>, Primary Key

=item *

C<role_id>, as C<integer>, Foreign Key to C<roles.id>

=item *

C<action_id>, as C<integer>, Foreign Key to C<actions.id>

=back

=head1 SEE ALSO

=over 4

=item *

L<Catalyst::Plugin::Authorization::Roles>

=item *

L<Catalyst::Plugin::Authorization::Abilities> - A more complex ability based authorization module

=back

=head1 AUTHOR

Matthias Dietrich <perl@rainboxx.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Matthias Dietrich.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
