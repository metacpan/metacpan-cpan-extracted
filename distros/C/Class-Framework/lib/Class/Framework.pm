package Class::Framework;
use warnings;
use strict;

use Class::Accessor ();
use Class::MethodVars ();

our $VERSION = '1.'.qw $Rev: 228 $[1];

sub insert_base($$) {
	my ($package,$base) = @_;
	eval "unshift(\@${package}::ISA,q($base))" unless $package->isa($base);
}

sub add_base($@) {
	my ($package,@base) = @_;
	eval "package $package; use base qw( @base ); 1" or die $@;
}

sub import {
	shift; # I don't care about what package this is. You should never be @ISA = "Class::Framework".
	my $package = caller;
	for (my $i = 0; $i < @_; $i++) {
		next unless $_[$i] eq '-base';
		if (ref($_[$i+1]) and ref($_[$i+1]) eq 'ARRAY' and not grep { not /\A\w+(?:::\w+)*\z/ } @{$_[$i+1]}) {
			add_base($package,@{$_[$i+1]});
			splice(@_,$i,2);
			last;
		} elsif ( (not ref($_[$i+1])) and $_[$i+1]=~/\A\w+(?:::\w+)*\z/ ) {
			add_base($package,$_[$i+1]);
			splice(@_,$i,2);
			last;
		}
	}
	insert_base $package,"Class::Accessor";
	insert_base $package,"Class::Framework::New";
	eval "package $package; Class::MethodVars->import(\@_); 1" or die $@; # And this is where the rest of @_ is used...
	my @fields = @{$Class::MethodVars::Configs{$package}->{fields}};
	my @rwfields = @{$Class::MethodVars::Configs{$package}->{rwfields}};
	my @rofields = @{$Class::MethodVars::Configs{$package}->{rofields}};
	my @wofields = @{$Class::MethodVars::Configs{$package}->{wofields}};
	# There are also "hiddenfields" which don't get accessors...
	eval "package $package; use fields \@fields; 1" or die $@;
	$package->mk_accessors(@rwfields) if @rwfields;
	$package->mk_accessors(@rofields) if @rofields;
	$package->mk_accessors(@wofields) if @wofields;
	
}

package Class::Framework::New;
use warnings;
use strict;

use Class::MethodVars; # Defaults - I only need __CLASS__ anyway.

sub new :ClassMethod {
	my $fields;
	if (@_ == 1 and ref($_[0]) and $_[0]->isa("HASH")) {
		$fields = shift;
	} elsif ((@_ % 2) == 0) {
		$fields = {@_};
	}
	my $me = fields::new(__CLASS__); # Note that __CLASS__ could be different to __PACKAGE__!
	%$me = %$fields if $fields;
	if ($me->can("_INIT")) {
		$me->_INIT(@_);
	}
	return $me;
}

1;
__END__

=head1 NAME

Class::Framework - Interface which combines L<Class::Accessor>, L<fields>, and L<Class::MethodVars> to ease creating a Class.

=head1 SYNOPSIS

  package Pixel;
  use warnings; # You always do this don't you...
  use strict; # This module is strict-safe (unless you use -varargs, but see Class::MethodVars for that).

  use Class::Framework -fields=>qw( x y colour );

  sub _INIT :Method {
	unless (grep { this->colour eq $_ } qw( red green blue yellow white black )) {
		require Carp;
		Carp::croak "${^_colour} is not a recognised colour!";
	}
  }

  sub print_To_Array($) :Method(. arrayref) {
    ${^_arrayref}->[this->y]->[this->x] = this->colour;
  }

  1;
  __END__

=head1 DESCRIPTION

This package is intended to allow you to rapidly create a class using L<fields> with L<Class::Accessor> generated accessors along with L<Class::MethodVars> methods.

Inheriting from other classes built using L<Class::Framework> or L<Class::MethodVars> will automatically inherit their fields.
You can inherit from any other class with the -base=> option to save an extra "use base" line.

=head1 CATCHES

The following items are things that you may find unusual when using L<Class::Framework> to make your class. Most of the time they should not be a problem for you.

=over 4

=item "@ISA"

You may notice "Class::Framework::New" and/or "Class::MethodVars::_ATTRS" in your @ISA. The former provides the default new() function (see below), the latter provides the :Method and :ClassMethod attributes.

=item "new()"

A default "new()" method is provided which will accept a HASH or HASHREF as parameters to define initial values. It will also call ->_INIT(@_) on the
resulting object allowing you to create a :Method which will initialise an object. This is all intended to neatly glue together fields::new and Class::Accessors with the minimum of fuss from a user's point of view. (Don't forget to call this->NEXT::_INIT(@_) for the parent class init if appropriate!).
Because this is inherited from Class::Framework::New you can create your own new() to do your own thing.

=back

=head1 SEE ALSO

See L<Class::MethodVars> for the parameters on the use line. All options except -base are passed through to that module.
See L<Class::Accessor> used by this module.

=head1 AUTHOR

Copyright 2006 Timothy Hinchcliffe <cpan@spidererrol.co.uk>

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself. That means either (a) the GNU General Public License or (b) the Artistic License.

=cut
