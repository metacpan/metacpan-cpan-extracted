package Class::Light;
# Copyright (c) 2009 Christopher Davaz. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# Documentation at the __END__

use strict;
use warnings;
use vars qw($VERSION);
use Carp;

$VERSION = "0.01003";

sub new {
	my $class = shift;

	croak "Attempted instantiation of abstract class " + __PACKAGE__
		if $class eq __PACKAGE__;

	my $super = $class;
	my @super;

	# Find all super classes and add them to @super in hierarchical order.
	no strict 'refs';
	while ($super ne __PACKAGE__) {
		unshift @super, $super;
		$super = ${$super . "::ISA"}[0];
	}

	my $self = {};
	bless $self, $class;

	for (@super) {
		my $init = $_ . "::_init";
		&$init($self, @_) if exists &$init;
	}
	use strict 'refs';

	return $self;
}

# Subclasses should implement their own _init method.
sub init;

our $AUTOLOAD;
sub AUTOLOAD {
	my ($pkg, $method) = ($AUTOLOAD =~ /(.+)::(.+)/);
	my ($type, $attr)  = ($method   =~ /^(get|set)_?(.*)/);

	# We only handle methods that match the pattern /^(get|set)_?(.*)/
	croak "Unknown method: $AUTOLOAD" unless $type && $attr;

	my $origAttr = $attr;
	$attr = lcfirst $attr;

	# Don't allow calls such as "getattr", see documentation for details.
	if ($method eq $type . $attr && $origAttr eq $attr) {
		croak "Unknown method: $AUTOLOAD";
	}

	# Disallow access to private members
	unless ($type && $attr !~ /^_/ && exists $_[0]->{$attr}) {
		croak "Unknown method: $AUTOLOAD";
	}

	# We want to check if an alternative form of invocation is available
	# and if it is make an alias for that method instead of calling the
	# automatically generated one.
	my (@form) = (
		$pkg . "::" . $type . ucfirst $origAttr,
		$pkg . "::" . $type . "_" . $origAttr,
		$pkg . "::" . $type . "_" . $attr
	);

	no strict 'refs';
	for (@form) {
		if (exists &$_) {
			*{$AUTOLOAD} = \&$_;
			goto &{$AUTOLOAD};
		}
	}

	if ($type =~ /^get/) {
		*{$AUTOLOAD} = sub { return $_[0]->{$attr} };
	}
	elsif ($type =~ /^set/) {
		*{$AUTOLOAD} = sub {
			my $old = $_[0]->{$attr};
			$_[0]->{$attr} = $_[1];
			return $old;
		}
	}

	goto &{$AUTOLOAD};
}

sub DESTROY {}

1;
__END__

=head1 NAME

Class::Light - Provides cascading object initialization and autovivified accessors and mutators

=head1 SYNOPSIS

		package SubClass;
		use base qw(Class::Light);

		sub _init {
			my $self = shift;
			my $data = shift;
			$self->{'data'} = $data;
		}

		package main;
		
		my $obj = SubClass->new("epiphany");

		# Will print the string epiphany on stdout
		if ($obj->getData eq $obj->get_data) {
			print $obj->get_Data;
		}

		$obj->setData("42");
		print $obj->getData;

=head1 DESCRIPTION

Subclasses are not to define a class method named "new", instead
they should define the private instance method named "_init" which
does object initialization. C<new> will invoke C<_init> from each
superclass in the object's class hierarchy including of course the
object's class itself. C<_init> should not bless or return $self as
this is handled by C<new>.

Installs default accessor and mutator methods for public instance
members. Public members are those hash keys that don't start with
an underscore.

Accessor and mutator methods can be invoked as:

C<< $obj->getAttribute >> or C<< $obj->get_attribute >> or C<< $obj->get_Attribute >>

All forms of invocation will search for the member named "attribute"
in the object and, if found, AUTOLOAD will install a method of the
corresponding name in the package that C<$obj>'s class belongs to. Note
that this imposes the restriction on inheriting classes that if they
want automatically defined accessor and mutator methods for their
public members, those members' identifiers must start with a lowercase
letter. Also note that access to private members will not be given to
AUTOLOAD, so for example a method invocation such as C<< $obj->get__attribute >>
will not install and execute an accessor for the private member "_attribute".
If a method already exists for one of the three forms shown above then that
method is executed. For example, if a user invokes a non-existant
C<< $obj->get_foo >> but C<< $obj->getFoo >> does exist, then
C<< $obj->getFoo >> is invoked.

=head1 METHODS

There are no public methods except for C<new> and those autovivified.
All sorts of bells and whistles could have been added such as logging,
error storage, etc. However the goal of Class::Light is to provide
simple (and useful) object initialization and method autovivification.
If you want to add logging or other features simply create a sublcass
of Class::Light and add your features.

=head1 AUTHOR

Christopher Davaz         www.chrisdavaz.com          cdavaz@gmail.com

=head1 VERSION

Version 0.01003 (Apr 25 2009)

=head1 SEE ALSO

L<perlobj> L<perltoot>

=head1 COPYRIGHT

Copyright (c) 2008 Christopher Davaz. All rights reserved.
This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
