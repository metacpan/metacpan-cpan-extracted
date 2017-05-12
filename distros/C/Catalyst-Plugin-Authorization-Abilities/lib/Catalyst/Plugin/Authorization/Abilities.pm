package Catalyst::Plugin::Authorization::Abilities;

# ABSTRACT: Ability based authorization for Catalyst/DBIx::Class apps, based on Catalyst::Plugin::Authorization::Roles

use strict;
use warnings;

use Scalar::Util        ();
use Catalyst::Exception ();

use version 0.77; our $VERSION = version->declare("v0.31.0");

=head1 NAME

Catalyst::Plugin::Authorization::Abilities - Ability based authorization for Catalyst/DBIx::Class apps, based on Catalyst::Plugin::Authorization::Roles

=head1 VERSION

version v0.31.0

=head1 SYNOPSIS

	# In MyApp.pm (notice we do not use Authorization::Roles):

	use Catalyst qw/
		Authentication
		Authorization::Abilities
	/;

	__PACKAGE__->config->{abilities}->{super_user_id} = 1; # this is the default

	# Anywhere in your code
	sub delete : Local {
		my ( $self, $c ) = @_;

		# check if the user can perform a certain action,
		# such as delete_foo, throw error if not.
		$c->assert_user_ability('delete_foo');
		$c->model("Foo")->delete_all();
	}

	# Checking roles is also provided
	sub display_user : Local {
		my ( $self, $c ) = @_;
	
		if ($c->check_user_roles(qw/admin editor/)) {
			print "User belongs to the admin and editor roles.";
		} else {
			print "User doesn't belong to both the admin and editor roles.";
		}
	}

	# Checkout required database schemas under REQUIRED SCHEMA

=head1 DESCRIPTION

Ability based access control is an extension of the role based access control
available through L<Catalyst::Plugin::Authorization::Roles>. In this plugin, however,
every user has a list of actions he is allowed to perform, and every restricted
part of the application makes an assertion about the necessary abilities.

Abilities to perform certain actions can be given to a user specifically, or
via roles the user can assume. For example, if user 'user01' is member of role
'admin', and this user wishes to perform some action, for example 'delete_foo',
than they will only be able to do so if the 'delete_foo' ability was given to
either the user itself or the 'admin' role itself.

Roles can inherit actions from other roles. For example, role 'mega_mods' can
inherit from roles 'mods' and 'editors'. Thus, users of the 'mega_mods' role will assume
all actions owned by the 'mods' and 'editors' roles, plus those specifically
given to 'mega_mods'. Inheritance is recursive, so if 'mods', for example, inherits
from 'plain_users', then 'mega_mods' will also have anything the 'plain_users'
role has (NOTE: recursive inheritance is new in v0.30.0).

With C<check_user_ability()> and C<assert_user_ability()>, these conditionals are checked
to grant or deny the user access to the required actions.

This method of authorization allows for much more flexibility with regards to
access control, such that roles and abilities can be added/edited/deleted using
the application itself (via your own controllers!). This is useful for applications
such as message boards, where the administrator might wish to create roles with
certain actions and associate users with those roles. For example, the admin can
create an 'editor' role, giving users of this role the ability to edit and delete
posts, but not any other administrative action. So in essence, this plugin takes
the control of who's able to do what from the developer and hands it to the end-user.

Note that this plugin is not to be used in conjunction with L<Catalyst::Plugin::Authorization::Roles>,
and that it requires several tables to be present in the database/schema (see L</"REQUIRED SCHEMA">).

=head2 REQUIRED SCHEMA

=head3 MyApp::Schema::Result::Action

	package MyApp::Schema::Result::Action;

	...

	__PACKAGE__->table("actions");
	__PACKAGE__->add_columns(
		"id",
		{ data_type => "INTEGER", is_nullable => 0, size => undef },
		"name",
		{ data_type => "VARCHAR", is_nullable => 0, size => 128 },
		"description",
		{ data_type => "TEXT", is_nullable => 1, size => undef },
	);
	__PACKAGE__->set_primary_key("id");

=head3 MyApp::Schema::Result::Role (changed in v0.30.0)

	package MyApp::Schema::Result::Role;

	...

	__PACKAGE__->table("roles");
	__PACKAGE__->add_columns(
		"id",
		{ data_type => "INTEGER", is_nullable => 0, size => undef },
		"name",
		{ data_type => "VARCHAR", is_nullable => 0, size => 128 },
	);
	__PACKAGE__->set_primary_key("id");
	__PACKAGE__->has_many(map_role_actions => 'MyApp::Schema::Result::RoleAction', 'role_id');
	__PACKAGE__->many_to_many(actions => 'map_role_actions', 'action');
	__PACKAGE__->has_many(map_role_roles => 'MyApp::Schema::Result::RoleRole', 'role_id');
	__PACKAGE__->many_to_many(roles => 'map_role_roles', 'role');

=head3 MyApp::Schema::Result::UserRole

	package MyApp::Schema::Result::UserRole;

	...

	__PACKAGE__->table("user_roles");
	__PACKAGE__->add_columns(
		"user_id",
		{ data_type => "INTEGER", is_nullable => 0, size => undef },
		"role_id",
		{ data_type => "INTEGER", is_nullable => 0, size => undef },
	);
	__PACKAGE__->set_primary_key("user_id", "role_id");
	__PACKAGE__->belongs_to('role' => 'MyApp::Schema::Result::Role', 'role_id');

=head3 MyApp::Schema::Result::RoleRole (new since v0.2, changed in v0.30.0)

	package MyApp::Schema::Result::RoleRole;

	...

	__PACKAGE__->table("role_roles");
	__PACKAGE__->add_columns(
		"role_id",
		{ data_type => "INTEGER", is_nullable => 0, size => undef },
		"inherits_from_id",
		{ data_type => "INTEGER", is_nullable => 0, size => undef },
	);
	__PACKAGE__->set_primary_key("role_id", "parent_id");
	__PACKAGE__->belongs_to('parent' => 'MyApp::Schema::Result::Role', 'role_id');
	__PACKAGE__->belongs_to('role' => 'MyApp::Schema::Result::Role', 'inherits_from_id');

=head3 MyApp::Schema::Result::RoleAction

	package MyApp::Schema::Result::RoleAction;

	...

	__PACKAGE__->table("role_actions");
	__PACKAGE__->add_columns(
		"role_id",
		{ data_type => "INTEGER", is_nullable => 0, size => undef },
		"action_id",
		{ data_type => "INTEGER", is_nullable => 0, size => undef },
	);
	__PACKAGE__->set_primary_key("role_id", "action_id");
	__PACKAGE__->belongs_to('role' => 'MyApp::Schema::Result::Role', 'role_id');
	__PACKAGE__->belongs_to('action' => 'MyApp::Schema::Result::Action', 'action_id');

=head3 MyApp::Schema::Result::UserAction

	package MyApp::Schema::Result::UserAction;

	...

	__PACKAGE__->table("user_actions");
	__PACKAGE__->add_columns(
		"user_id",
		{ data_type => "INTEGER", is_nullable => 0, size => undef },
		"action_id",
		{ data_type => "INTEGER", is_nullable => 0, size => undef },
	);
	__PACKAGE__->set_primary_key("user_id", "action_id");
	__PACKAGE__->belongs_to('action' => 'MyApp::Schema::Result::Action', 'action_id');

=head3 MyApp::Schema::Result::User

	package MyApp::Schema::Result::User;

	...

	__PACKAGE__->table("users");
	__PACKAGE__->add_columns(
		"id",
		{ data_type => "INTEGER", is_nullable => 0, size => undef },
		...
	);
	__PACKAGE__->set_primary_key("id");
	__PACKAGE__->has_many(map_user_role => 'MyApp::Schema::Result::UserRole', 'user_id');
	__PACKAGE__->many_to_many(user_roles => 'map_user_role', 'role');
	__PACKAGE__->has_many(map_user_action => 'MyApp::Schema::Result::UserAction', 'user_id');
	__PACKAGE__->many_to_many(actions => 'map_user_action', 'action');

=head1 METHODS

=head2 assert_user_ability( [ $user ], @actions )

Checks that the user (as supplied by the first argument, or, if omitted,
C<< $c->user >>) has the ability to perform all specified actions. It's enough
for one action not to be granted for this method to deny ability.

If the user has all actions, this method will return a true value. Users either
get actions directory (UserAction in the schema), or via roles (UserRole), which
can inherit other roles (RoleRole). Role inheritance is recursive (see L<"/DESCRIPTION">
for more info).

If for any reason the check fails (C<< $c->user >> is not defined, the user is missing an
appropriate action, etc.), an error is thrown.

You can either catch these errors with an eval, or clean them up in your C<end>
action. See L<check_user_ability()> for an alternative that simply returns false
instead.

This method automatically grants ability, no matter which actions were passed,
to the super-user. This is probably the user who installed MyApp and is setting
it up, so that they can create roles and assign actions (otherwise the installing
user might have never been able to do anything). The super-user is identified
by supplying a user ID to MyApp's config (see SYNOPSIS). This setting defaults
to user ID 1.

=cut

sub assert_user_ability {
	my ($c, @actions) = @_;

	my $user;

	if (Scalar::Util::blessed($actions[0]) && $actions[0]->isa("Catalyst::Authentication::User")) {
		# A user was supplied in the arguments
		$user = shift @actions;
	}

	$user ||= $c->user;

	Catalyst::Exception->throw("No logged in user, and none supplied as argument") unless $user;

	my $super_user_id = $c->config->{abilities} && ref $c->config->{abilities} eq 'HASH' && $c->config->{abilities}->{super_user_id} ? $c->config->{abilities}->{super_user_id} : 1;
	if ($user->id == $super_user_id) {
		# The super-user can do anything he wants
		$c->log->debug("Ability granted: @actions") if $c->debug;
		return 1;
	}

	my $flag = 1;	# Flag indicating whether user can perform all actions,
			# set to true first and possibly falsified later
	ACTION: foreach (@actions) {
		# check whether user has been specifically granted this action
		next ACTION if $c->_user_has_action($user, $_);

		# if not, check whether user gets the action from a role (including
		# inherited roles)
		foreach my $role ($user->user_roles) {
			next ACTION if $c->_role_has_action($role, $_);
		}

		# Action not granted, undef $flag and exit loop
		undef $flag;
		last ACTION;
	}

	if ($flag) {
		$c->log->debug('Ability granted: '.join(', ', @actions)) if $c->debug;
		return 1;
	} else {
		$c->log->debug('Ability denied: '.join(', ', @actions)) if $c->debug;
		Catalyst::Exception->throw('Missing abilities');
	}
}

=head2 check_user_ability( [ $user ], @actions )

Same as C<assert_user_ability>, but instead of throwing errors returns a boolean value.

=cut

sub check_user_ability {
	my ($c, @actions) = @_;

	local $@;
	eval { $c->assert_user_ability(@actions) };
}

=head2 check_user_roles( [ $user ], @roles )

Checks that the user (as supplied by the first argument, or, if omitted,
C<< $c->user >>) belongs to the specified roles. Returns a true value
only if user belongs to all roles specified, and false otherwise.

Note that inherited roles are taken into account. For example, if user directly
belongs to role 'x', which inherits from role 'y', which inherits from role 'z', then
this method will return true for role 'z'.

=cut

sub check_user_roles {
	my ($c, @roles) = @_;

	my $user;

	if ( Scalar::Util::blessed( $roles[0] ) && $roles[0]->isa("Catalyst::Authentication::User") ) {
		$user = shift @roles;
	}

	$user ||= $c->user;

	return unless $user;

	my $flag = 1;	# Flag indicating whether user has the roles, initial set
			# to true and possibly falsified later
	foreach (@roles) {
		next if $c->_user_takes_role($user, $_);
		
		# failed
		undef $flag;
		last;
	}

	if ($flag) {
		$c->log->debug('User has roles: '.join(', ', @roles)) if $c->debug;
		return 1;
	} else {
		$c->log->debug('User doesn\'t have roles: '.join(', ', @roles)) if $c->debug;
		return;
	}
}

=head1 _INTERNAL_METHODS

The following methods are only to be used internally.

=head2 _user_has_action( $user, $action )

=cut

sub _user_has_action {
	my ($c, $user, $action) = @_;

	foreach ($user->actions) {
		return 1 if $_->name eq $action;
	}

	# sorry, no
	return;
}

=head2 _role_has_action( $role, $action )

=cut

sub _role_has_action {
	my ($c, $role, $action) = @_;

	# check direct actions
	foreach ($role->actions) {
		return 1 if $_->name eq $action;
	}

	# check inherited roles
	foreach ($role->roles) {
		return 1 if $c->_role_has_action($_, $action);
	}

	# sorry, no
	return;
}

=head2 _user_takes_role( $user, $role )

=cut

sub _user_takes_role {
	my ($c, $user, $role) = @_;

	foreach ($user->user_roles) {
		return 1 if $_->name eq $role;

		# maybe this role inherits the role we're looking for
		return 1 if $c->_role_takes_role($_, $role);
	}

	# sorry, no
	return;
}

=head2 _role_takes_role( $role, $role_taken )

=cut

sub _role_takes_role {
	my ($c, $role, $taken) = @_;

	foreach ($role->roles) {
		return 1 if $_->name eq $taken;

		# maybe this role inherits the role we're looking for
		return 1 if $c->_role_takes_role($_, $taken);
	}

	# sorry, no
	return;
}

=head1 SEE ALSO

L<Catalyst::Plugin::Authentication>, L<Catalyst::Plugin::Authorization::Roles>

=head1 AUTHOR

Ido Perlmuter, C<< <ido at ido50.net> >>

=head1 ACKNOWLEDGEMENTS

Based on L<Catalyst::Plugin::Authorization::Roles> by Yuval Kogman.

Thanks to Dabg for writing a test suite.

=head1 BUGS

Please report any bugs or feature requests to C<bug-catalyst-plugin-authorization-abilities at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Catalyst-Plugin-Authorization-Abilities>. I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

	perldoc Catalyst::Plugin::Authorization::Abilities

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Catalyst-Plugin-Authorization-Abilities>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Catalyst-Plugin-Authorization-Abilities>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Catalyst-Plugin-Authorization-Abilities>

=item * Search CPAN

L<http://search.cpan.org/dist/Catalyst-Plugin-Authorization-Abilities/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2009-2011 Ido Perlmuter.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
