package Abilities;

# ABSTRACT: Simple, hierarchical user authorization for web applications, with optional support for plan-based (paid) services.

use Carp;
use Hash::Merge qw/merge/;
use Moo::Role;
use namespace::autoclean;

our $VERSION = "0.5";
$VERSION = eval $VERSION;

=head1 NAME

Abilities - Simple, hierarchical user authorization for web applications, with optional support for plan-based (paid) services.

=head1 VERSION

version 0.5

=head1 SYNOPSIS

	package User;
	
	use Moose; # or Moo
	with 'Abilities';
	
	# ... define required methods ...
	
	# somewhere else in your code:

	# get a user object that consumed the Abilities role
	my $user = MyApp->get_user('username'); # $user is a User object

	# check if the user is able to do something
	if ($user->can_perform('something')) {
		do_something();
	} else {
		die "Hey you can't do that, you can only do " . join(', ', keys %{$user->abilities});
	}

=head1 DESCRIPTION

Abilities is a simple yet powerful mechanism for authorizing users of web
applications (or any applications) to perform certain actions in the application. This is an
extension of the familiar role-based access control that is common in
various systems and frameworks like L<Catalyst> (See L<Catalyst::Plugin::Authorization::Roles>
for the role-based implementation and L<Catalyst::Plugin::Authorization::Abilities>
for the ability-based implementation that inspired this module).

As opposed to role-based access control - where users are allowed access
to a certain feature (here called 'action') only through their association
to a certain role that is hard-coded into the program - in ability-based
acccess control, a list of actions is assigned to every user, and they are
only allowed to perform these actions. Actions are not assigned by the
developer during development, but rather by the end-user during deployment.
This allows for much more flexibility, and also speeds up development,
as you (the developer) do not need to think about who should be allowed
to perform a certain action, and can easily grant access later-on after
deployment (assuming you're also the end-user).

Abilities to perform certain actions can be given to a user specifically, or
via roles the user can assume (as in role-based access control). For example,
if user 'user01' is a member of role 'admin', and this user wishes to perform
some action, for example 'delete_foo', then they will only be able to do
so if the 'delete_foo' ability was given to either the user itself or the
'admin' role itself. Furthermore, roles can recursively inherit other roles;
for example, the role 'mega_mods' can inherit the roles 'mods' and 'editors'.
Users of the 'mega_mods' role will assume all actions owned by the 'mods'
and 'editors' roles.

A commonly known use-case for this type of access control is message boards,
where the administrator might wish to create roles with certain actions
and associate users with the roles (more commonly called 'user groups');
for example, the admin can create an 'editor' role, giving users of this
role the ability to edit and delete posts, but not any other administrative
action. So in essence, this type of access control relieves the developer
of deciding who gets to do what and passes these decisions to the
end-user, which might actually be necessary in certain situations.

The C<Abilities> module is implemented as a L<Moo role|Moo::Role> (which makes
it compatible with L<Moose> code). In order to be able to use this mechanism,
applications must implement a user management system that will consume this role.
More specifically, a user class and a role class must be implemented, consuming this role. L<Entities> is a reference implementation that can be used by applications, or
just taken as an example of an ability-based authorization system. L<Entities::User>
and L<Entities::Role> are the user and role classes that consume the Abilities
role in the Entities distribution.

=head2 CONSTRAINTS

Generally, an ability is a yes/no option. Either the user can or can't perform
a specific action. At times, this might not be flexible enough, and the user's
ability to perform a certain action should be constrained. For example, a user
might be granted the ability to edit posts in a blog, but this ability should
be constrained to the user's posts only. The user is not to be allowed to edit
posts created by other users. C<Abilities> supports constraints by allowing to
set a name-based constraint when granting a user/role a certain ability. Then,
checking the user's ability to perform an action can include the constraint,
for example:

	if ($post->{user_id} eq $user->id && $user->can_perform('edit_posts', 'only_his')) {
		# allow
	} else {
		# do not allow
	}

Here, the C<Abilities> module allows you to check if the user's ability is constrained,
but the responsibility for making sure the constraint is actually relevant
to the case is left to you. In the above example, it is the application that
checks if the post the user is trying to edit was created by them, not the C<Abilities>
module.

=head2 (PAID) SUBSCRIPTION-BASED WEB SERVICES

Apart from the scenario described above, this module also provides optional
support for subscription-based web services, such as those where customers
subscribe to a certain paid (or free, doesn't matter) plan from a list
of available plans (GitHub is an example of such a service). This functionality
is also implemented as a Moo(se) role, in the L<Abilities::Features> module provided
with this distribution. Read its documentation for detailed information.

=head1 REQUIRED METHODS

Classes that consume this role are required to implement the following
methods:

=head2 roles()

Returns a list of all role names that a user object belongs to, or a role object
inherits from.

Example return structure:

	( 'moderator', 'supporter' )

NOTE: In previous versions, this method was required to return
an array of role objects, not a list of role names. This has been changed
in version 0.3.

=cut

requires 'roles';

=head2 actions()

Returns a list of all action names that a user object has been explicitely granted,
or that a role object has been granted. If a certain action is constrained, then
it should be added to the list as an array reference with two items, the first being
the name of the action, the second being the name of the constraint.

Example return structure:

	( 'create_posts', ['edit_posts', 'only_his'], 'comment_on_posts' )

NOTE: In previous versions, this method was required to return
an array of action objects, not a list of action names. This has been changed
in version 0.3.

=cut

requires 'actions';

=head2 is_super()

This is a boolean attribute that both user and role objects should have.
If a user/role object has a true value for this attribute, then they
will be able to perform any action, even if it wasn't granted to them.

=cut

requires 'is_super';

=head2 get_role( $name )

This is a method that returns the object of the role named C<$name>.

=cut

requires 'get_role';

=head1 PROVIDED METHODS

Classes that consume this role will have the following methods available
to them:

=head2 can_perform( $action, [ $constraint ] )

Receives the name of an action, and possibly a constraint, and returns a true
value if the user/role can perform the provided action.

=cut

sub can_perform {
	my ($self, $action, $constraint) = @_;

	# a super-user/super-role can do whatever they want
	return 1 if $self->is_super;

	# return false if user/role doesn't have that ability
	return unless $self->abilities->{$action};

	# user/role has ability, but is there a constraint?
	if ($constraint && $constraint ne '_all_') {
		# return true if user/role's ability is not constrained
		return 1 if !ref $self->abilities->{$action};
		
		# it is constrained (or at least it should be, let's make
		# sure we have an array-ref of constraints)
		if (ref $self->abilities->{$action} eq 'ARRAY') {
			return 1 if $constraint eq '_any_';	# caller wants to know if
								# user/role has any constraint,
								# which we now know is true
			foreach (@{$self->abilities->{$action}}) {
				return 1 if $_ eq $constraint;
			}
			return; # constraint not met
		} else {
			carp "Expected an array-ref of constraints for action $action, received ".ref($self->abilities->{$action}).", returning false.";
			return;
		}
	} else {
		# no constraint, make sure user/role's ability is indeed
		# not constrained
		return if ref $self->abilities->{$action}; # implied: ref == 'ARRAY', thus constrained
		return 1; # not constrained
	}
}

=head2 assigned_role( $role_name )

This method receives a role name and returns a true value if the user/role
is a direct member of the provided role. Only direct membership is checked,
so the user/role must be specifically assigned to the provided role, and
not to a role that inherits from that role (see L</"does_role( $role )">
instead).

=cut

sub assigned_role {
	my ($self, $role) = @_;

	return unless $role;

	foreach ($self->roles) {
		return 1 if $_ eq $role;
	}

	return;
}

=head2 does_role( $role_name )

Receives the name of a role, and returns a true value if the user/role
inherits the abilities of the provided role. This method takes inheritance
into account, so if a user was directly assigned to the 'admins' role,
and the 'admins' role inherits from the 'devs' role, then C<does_role('devs')>
will return true for that user (while C<assigned_role('devs')> returns false).

=cut

sub does_role {
	my ($self, $role) = @_;

	return unless $role;

	foreach (map([$_, $self->get_role($_)], $self->roles)) {
		return 1 if $_->[0] eq $role || $_->[1]->does_role($role);
	}

	return;
}

=head2 abilities()

Returns a hash reference of all the abilities a user/role object can
perform, after consolidating abilities inherited from roles (including
recursively) and directly granted. Keys in the hash-ref will be names
of actions, values will be 1 (for yes/no actions) or a single-item array-ref
with the name of a constraint (for constrained actions).

=cut

sub abilities {
	my $self = shift;

	my $abilities = {};

	# load direct actions granted to this user/role
	foreach ($self->actions) {
		# is this action constrained/scoped?
		unless (ref $_) {
			$abilities->{$_} = 1;
		} elsif (ref $_ eq 'ARRAY' && scalar @$_ == 2) {
			$abilities->{$_->[0]} = [$_->[1]];
		} else {
			carp "Can't handle action of reference ".ref($_);
		}
	}

	# load actions from roles this user/role consumes
	my @hashes = map { $self->get_role($_)->abilities } $self->roles;

	# merge all abilities
	while (scalar @hashes) {
		$abilities = merge($abilities, shift @hashes);
	}

	return $abilities;
}

=head1 UPGRADING FROM v0.2

Up to version 0.2, C<Abilities> required the C<roles> and C<actions>
attributes to return objects. While this made it easier to calculate
abilities, it made this system a bit less flexible.

In version 0.3, C<Abilities> changed the requirement such that both these
attributes need to return strings (the names of the roles/actions). If your implementation
has granted roles and actions stored in a database by names, this made life a bit easier
for you. On other implementations, however, this has the potential of
requiring you to write a bit more code. If that is the case, I apologize,
but keep in mind that you can still store granted roles and actions
any way you want in a database (either by names or by references), just
as long as you correctly provide C<roles> and C<actions>.

Unfortunately, in both versions 0.3 and 0.4, I made a bit of a mess
that rendered both versions unusable. While I documented the C<roles>
attribute as requiring role names instead of role objects, the actual
implementation still required role objects. This has now been fixed,
but it also meant I had to add a new requirement: consuming classes
now have to provide a method called C<get_role()> that takes the name
of a role and returns its object. This will probably means loading the
role from a database and blessing it into your role class that also consumes
this module.

I apologize for any inconvenience this might have caused.

=head1 AUTHOR

Ido Perlmuter, C<< <ido at ido50 dot net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-abilities at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Abilities>. I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

	perldoc Abilities

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Abilities>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Abilities>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Abilities>

=item * Search CPAN

L<http://search.cpan.org/dist/Abilities/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2010-2013 Ido Perlmuter.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
