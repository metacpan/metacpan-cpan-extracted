package Abilities::Features;

# ABSTRACT: Extends Abilities with plan management for subscription-based web services.

use Carp;
use Hash::Merge qw/merge/;
use Moo::Role;
use namespace::autoclean;

our $VERSION = "0.5";
$VERSION = eval $VERSION;

=head1 NAME

Abilities::Features - Extends Abilities with plan management for subscription-based web services.

=head1 VERSION

version 0.5

=head1 SYNOPSIS

	package Customer;
	
	use Moose; # or Moo
	with 'Abilities::Features';
	
	# ... define required methods ...
	
	# somewhere else in your code:

	# get a customer object that consumed the Abilities::Features role
	my $customer = MyApp->get_customer('some_company');
		
	# check if the customer has a certain feature
	if ($customer->has_feature('ssl_encryption')) {
		&initiate_https_connection();
	} else {
		&initiate_http_connection();
	}

=head1 DESCRIPTION

This L<Moo role|Moo::Role> extends the ability-based authorization
system defined by the L<Abilities> module with customer and plan management
for subscription-based web services. This includes paid services, where
customers subscribe to a plan from a list of available plans, each plan
with a different set of features. Examples of such a service are GitHub
(a Git revision control hosting service, where customers purchase a plan
that provides them with different amounts of storage, SSH support, etc.)
and MailChimp (email marketing service where customers purchase plans
that provide them with different amounts of monthly emails to send and
other features).

The L<Abilities> role defined three entities: users, roles and actions.
This role defines three more entities: customers, plans and features.
Customers are organizations, companies or individuals that subscribe to
your web service. They can subscribe to any number of plans, and thus be
provided with the features of these plans. The users from the Abilities
module will now be children of the customers. They still go on being members
of roles and performing actions they are granted with, but now possibly
only within the scope of their parent customer, and to the limits defined
in the customer's plan. Plans can inherit features from other plans, allowing
for defining plans faster and easier.

Customer and plan objects are meant to consume the Abilities::Features
role. L<Entities> is a reference implementation of both the L<Abilities> and
L<Abilities::Features> roles. It is meant to be used as-is by web applications,
or just as an example of how a user management and authorization system
that consumes these roles might look like. L<Entities::Customer> and
L<Entities::Plan> are customer and plan classes that consume this role.

Just like in L<Abilities>, features can be constrained. For more info,
see L<Abilities/"CONSTRAINTS">.

More information about how these roles work can be found in the L<Entities>
documentation.

=head1 REQUIRED METHODS

Customer and plan classes that consume this role are required to provide
the following methods:

=head2 plans()

This method returns a list of all plan names that a customer has subscribed to,
or that a plan inherits from.

Example return structure:

	( 'starter', 'diamond' )

NOTE: In previous versions, this method was required to return
an array of plan objects, not a list of plan names. This has been changed
in version 0.3.

=cut

requires 'plans';

=head2 features()

This method returns a list of all feature names that a customer has explicitely
been given, or that a plan has. If a certain feature is constrained, then
it should be added to the list as an array reference with two items, the first being
the name of the feature, the second being the name of the constraint.

Example return structure:

	( 'ssh_access', [ 'multiple_users', 5 ] )

NOTE: In previous versions, this method was required to return
an array of feature objects, not a list of feature names. This has been changed
in version 0.3.

=cut

requires 'features';

=head2 get_plan( $name )

Returns the object of the plan named C<$plan>.

=cut

requires 'get_plan';

=head1 METHODS

Classes that consume this role will have the following methods provided
to them:

=head2 has_feature( $feature_name, [ $constraint ] )

Receives the name of a feature, and possibly a constraint, and returns a
true value if the customer/plan has that feature, false value otherwise.

=cut

sub has_feature {
	my ($self, $feature, $constraint) = @_;

	# return false if customer/plan does not have that feature
	return unless $self->available_features->{$feature};

	# customer/plan has feature, but is there a constraint?
	if ($constraint) {
		# return true if customer/plan's feature is not constrained
		return 1 if !ref $self->available_features->{$feature};
		
		# it is constrained (or at least it should be, let's make
		# sure we have an array-ref of constraints)
		if (ref $self->available_features->{$feature} eq 'ARRAY') {
			foreach (@{$self->available_features->{$feature}}) {
				return 1 if $_ eq $constraint;
			}
			return; # constraint not met
		} else {
			carp "Expected an array-ref of constraints for feature $feature, received ".ref($self->available_features->{$feature}).", returning false.";
			return;
		}
	} else {
		# no constraint, make sure customer/plan's feature is indeed
		# not constrained
		return if ref $self->available_features->{$feature}; # implied: ref == 'ARRAY', thus constrained
		return 1; # not constrained
	}
}

=head2 in_plan( $plan_name )

Receives the name of plan and returns a true value if the user/customer
is a direct member of the provided plan(s). Only direct association is
checked, so the user/customer must be specifically assigned to that plan,
and not to a plan that inherits from that plan (see L</"inherits_plan( $plan_name )">
instead).

=cut

sub in_plan {
	my ($self, $plan) = @_;

	return unless $plan;

	foreach ($self->plans) {
		return 1 if $_ eq $plan;
	}

	return;
}

=head2 inherits_plan( $plan_name )

Returns a true value if the customer/plan inherits the features of
the provided plan(s). If a customer belongs to the 'premium' plan, and
the 'premium' plan inherits from the 'basic' plan, then C<inherits_plan('basic')>
will be true for that customer, while C<in_plan('basic')> will be false.

=cut

sub inherits_plan {
	my ($self, $plan) = @_;

	return unless $plan;

	foreach (map([$_, $self->get_plan($_)], $self->plans)) {
		return 1 if $_->[0] eq $plan || $_->[1]->inherits_plan($plan);
	}

	return;
}

=head2 available_features

Returns a hash-ref of all features available to a customer/plan object, after
consolidating features from inherited plans (recursively) and directly granted.
Keys of this hash-ref will be the names of the features, values will either be
1 (for yes/no features), or a single-item array-ref with a name of a constraint
(for constrained features).

=cut

sub available_features {
	my $self = shift;

	my $features = {};

	# load direct features granted to this customer/plan
	foreach ($self->features) {
		# is this features constrained?
		unless (ref $_) {
			$features->{$_} = 1;
		} elsif (ref $_ eq 'ARRAY' && scalar @$_ == 2) {
			$features->{$_->[0]} = [$_->[1]];
		} else {
			carp "Can't handle feature of reference ".ref($_);
		}
	}

	# load features from plans this customer/plan has
	my @hashes = map { $self->get_plan($_)->available_features } $self->plans;

	# merge all features
	while (scalar @hashes) {
		$features = merge($features, shift @hashes);
	}

	return $features;
}

=head1 UPGRADING FROM v0.2

Up to version 0.2, C<Abilities::Features> required the C<plans> and C<features>
attributes to return objects. While this made it easier to calculate
available features, it made this system a bit less flexible.

In version 0.3, C<Abilities::Features> changed the requirement such that both these
attributes need to return strings (the names of the plans/features). If your implementation
has granted plans and features stored in a database by names, this made life a bit easier
for you. On other implementations, however, this has the potential of
requiring you to write a bit more code. If that is the case, I apologize,
but keep in mind that you can still store granted plans and features
any way you want in a database (either by names or by references), just
as long as you correctly provide C<plans> and C<features>.

Unfortunately, in both versions 0.3 and 0.4, I made a bit of a mess
that rendered both versions unusable. While I documented the C<plans>
attribute as requiring plan names instead of plan objects, the actual
implementation still required plan objects. This has now been fixed,
but it also meant I had to add a new requirement: consuming classes
now have to provide a method called C<get_plan()> that takes the name
of a plan and returns its object. This will probably means loading the
plan from a database and blessing it into your plan class that also consumes
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

	perldoc Abilities::Features

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
