#############################################################################
#
# Data::BitMask - bitmask manipulation
#
# Author: Toby Ovod-Everett
#############################################################################
# Copyright 2003, 2004 Toby Ovod-Everett.  All rights reserved
#
# This program is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# For comments, questions, bugs or general interest, feel free to
# contact Toby Ovod-Everett at toby@ovod-everett.org
#############################################################################

=head1 NAME

Data::BitMask - bitmask manipulation

=head1 SYNOPSIS

  use Data::BitMask;

  my $FileMask = Data::BitMask->new(
      READ =>    1,
      WRITE =>   2,
      EXECUTE => 4,
      RX =>      5,
      RWX =>     7,
      FULL =>    7,
    );

  my $mask = $FileMask->build_mask('READ|WRITE');
  print Data::Dumper->Dump([
      $FileMask->explain_mask($mask),
      $FileMask->break_mask($mask)
    ]);
  
  my $mask2 = $FileMask->build_mask({FULL => 1, WRITE => 0});

=head1 DESCRIPTION

This module allows one to create bitmask manipulator objects that can be used to 
create bitmask values based on a list of constants, as well as to break apart 
masks using those constants.  The advantages are that you don't have to pollute 
namespaces to use constants, you can ensure that only appropriate constants are 
used for specific masks, you can easily break apart and explain masks, and in 
general it is much easier for the user to interact with masks.

The module only interacts with masks that fit in Perl integers.  In some places, 
it presumes that you are using 32 bit integers (i.e. canonicalizing negative 
values).

The module expends a modest amount of overhead in creating the C<Data::BitMask> 
object so as to speed up future mask manipulations.

=head2 Installation instructions

This module requires C<Module::Build 0.24> to use the automated installation 
procedures.  With C<Module::Build> installed:

  Build.PL
  perl build test
  perl build install

It can also be installed manually by copying C<lib/Data/Bitmask.pm> to 
C<perl/site/lib/Data/Bitmask.pm>.

=head1 Suggest Module Implementation

Here is one suggested approach to using bitmask manipulators in a module.

  {
  my $cache;
  sub SECURITY_INFORMATION {
    $cache ||= Data::BitMask->new(
        OWNER_SECURITY_INFORMATION => 0x1,
        GROUP_SECURITY_INFORMATION => 0x2,
        DACL_SECURITY_INFORMATION  => 0x4,
        SACL_SECURITY_INFORMATION  => 0x8,
      );
  }
  }

The bitmask manipulator can then be accessed as:

  &SECURITY_INFORMATION->build_mask('DACL_SECURITY_INFORMATION');

Or, if you are outside of the module, as:

  &Win32::Security::SECURITY_INFORMATION->build_mask('DACL_SECURITY_INFORMATION');

This has several advantages:

=over 4

=item *

Demand creation of the C<Data::Bitmask> object.  Creating objects with huge 
numbers of constants (i.e. hundreds or thousands) can be a bit time consuming, 
so this delays creation until the object actually gets used.  At the same time, 
the created object is cached.

=item *

Easy access from within in the module, reasonably easy access from outside the 
module.

=item *

If the user wants even easier access from outside the module, you can support 
Exporter and let the sub be exported.

=back

=head1 Method Reference

=cut

use strict;

package Data::BitMask;

use vars qw($VERSION $masks);

$VERSION = '0.91';

$masks = {};

=head2 new

Creates a new bitmask manipulator.  Pass a list of constant and value pairs. The 
constants do not have to be disjoint, but order does matter.  When executing 
C<explain_mask> or C<explain_const>, constants that are earlier in the list take 
precendence over those later in the list.  Constant names are not allowed to 
have space or pipes in them, and constant values have to be integers. Constant 
names are case insensitive but preserving.

If the passed value for the constant name is an anonymous array, then it is 
presumed that the name is the first value and that the remainder consists of 
name-value pairs of parameters.  The only currently supported parameter is 
C<full_match>, which implies that the constant should only be returned from 
C<break_mask> or C<explain_mask> if it perfectly matches the mask being 
explained.  For example:

      [qw(FILES_ONLY_NO_INHERIT full_match 1)] =>    1,

=cut

sub new {
	my $class = shift;
	my(@constants) = @_;

	scalar(@constants) % 2 and &croak("You have to pass an even number of parameters in \@constants.");
	
	my $self = {
		constants => \@constants,
	};

	bless $self, $class;

	$self->_check_constants;

	return $self;
}


=head2 add_constants

Adds constants to an existing bitmask manipulator.  Pass a list of constant and
value pairs as for C<new>.  Constants will be added to the end of the list (see
C<new> for an explanation of ordering concerns).

The main use for C<add_constants> is adding aggregate constants created by using 
C<build_mask>.

=cut

sub add_constants {
	my $self = shift;
	my(@constants) = @_;

	scalar(@constants) % 2 and &croak("You have to pass an even number of parameters in \@constants.");
	push(@{$self->{constants}}, @constants);
	$self->_check_constants;
}

sub _iterate_constants {
	my $self = shift;
	my($sub) = @_;

	foreach my $i (0..@{$self->{constants}}/2-1) {
		my $name = $self->{constants}->[$i*2];
		my $params;
		if (ref($name) eq 'ARRAY') {
			my(@temp) = @$name;
			$name = shift @temp;
			$params = {@temp};
		}
		$sub->($self, $name, $self->{constants}->[$i*2+1], $params);
	}
}

sub _check_constants {
	my $self = shift;

	$self->_iterate_constants( sub {
		local $^W = 0;
		$_[1] =~ /(\s|\|)/ and &croak("Constant names cannot have spaces or pipes: '$_[1]'.");
		int($_[1]) eq $_[1] and &croak("Constant names cannot be integers: '$_[1]'.");
		int($_[2]) eq $_[2] or &croak("Constant values have to be integers: '$_[1]' '$_[2]'.");
		int($_[2]) < 0 and &croak("Constant values have to be positive integers: '$_[1]' '$_[2]'.");
		$_[2] = int($_[2]);
	});

	$self->_build_forward_cache;
	$self->_build_reverse_cache;
	$self->_build_occlusion_cache;

}

sub _build_forward_cache {
	my $self = shift;

	$self->{forward_cache} = {};

	$self->_iterate_constants( sub {
		my($self, $name, $value, $params) = @_;
		$name = uc($name);
		if (exists $self->{forward_cache}->{$name}) {
			$self->{forward_cache}->{$name} != $value and &croak("Multiple values for constant '$name'.");
		}
		$self->{forward_cache}->{$name} = $value;
	});
}

sub _build_reverse_cache {
	my $self = shift;

	$self->{reverse_cache} = {};
	$self->{full_match} = {};

	$self->_iterate_constants( sub {
		my($self, $name, $value, $params) = @_;
		push(@{$self->{reverse_cache}->{$value}}, $name);
		$self->{full_match}->{$name} = undef if $params->{full_match};
	});
}

sub _build_occlusion_cache {
	my $self = shift;

	$self->{occlusion_cache} = {};

	my(@temp) = map {int($_)} keys %{$self->{reverse_cache}};

	foreach my $valuer (@temp) {
		my $namer = $self->{reverse_cache}->{$valuer}->[0];
		$self->{occlusion_cache}->{$namer} = [];
		foreach my $valued (@temp) {
			foreach my $named (@{$self->{reverse_cache}->{$valued}}) {
				$namer eq $named and next;
				if ( $valued == ($valued & $valuer) ) {
					push(@{$self->{occlusion_cache}->{$namer}}, $named);
				}
			}
		}
	}
}


=head2 build_mask

This takes one of three things as a parameter:

=over 4

=item *

scalar - string is split on 'C<|>' and/or whitespace to generate a list of 
constants

=item *

ARRAY ref - elements are the list of constants

=item *

HASH ref - keys with true values are the list of constants; keys with false 
values are subtracted from the resultant mask

=back

In all situations, integers are legal in place of constant names and are treated 
as the value, after adding 2**32 to any negative integers.

=cut

sub build_mask {
	my $self = shift;
	my($struct) = @_;

	my(@add, @sub);

	local $^W = 0;

	if (ref($struct) eq 'ARRAY') {
		@add = map {uc($_)} @{$struct};
	} elsif (ref($struct) eq 'HASH') {
		@add = map {uc($_)} grep {$struct->{$_}} keys %$struct;
		@sub = map {uc($_)} grep {!$struct->{$_}} keys %$struct;
	} elsif (int($struct) eq $struct) {
		return int($struct) < 0 ? int($struct) + 2**31 + 2**31 : int($struct);
	} else {
		@add = map {uc($_)} split(/\s*\|\s*|\s+/, $struct);
	}

	my $mask = 0;
	foreach my $i (@add) {
		if (int($i) eq $i) {
			$mask |= (int($i) < 0 ? int($i) + 2**31 + 2**31 : int($i));
		} else {
			exists $self->{forward_cache}->{$i} or &croak("Unable to find constant '$i'");
			$mask |= $self->{forward_cache}->{$i};
		}
	}

	foreach my $i (@sub) {
		if (int($i) eq $i) {
			$mask &= ~(int($i) < 0 ? int($i) + 2**31 + 2**31 : int($i));
		} else {
			exists $self->{forward_cache}->{$i} or &croak("Unable to find constant '$i'");
			$mask &= ~$self->{forward_cache}->{$i};
		}
	}

	return $mask;
}

=head2 break_mask

Breaks a mask apart.  Pass a mask value as an integer.  Returns a hash of all
constants whose values are subsets of the passed mask.  Values are set to 1 so
the result can safely be passed to C<build_mask>.

Commonly used for operations like:

	if ($MaskManipulator->break_mask($my_mask_value)->{CONSTANT}) {

Note that C<break_mask> accepts 

To eliminate a constant from explain_mask or break_mask unless it perfectly 
matches, use C<full_match> constants.

=cut

sub break_mask {
	my $self = shift;
	my($mask) = @_;

	local $^W = 0;

	if (int($mask) eq $mask) {
		$mask = int($mask) < 0 ? int($mask) + 2**31 + 2**31 : int($mask);
	} else {
		$mask = $self->build_mask($mask);
	}

	my($struct) = {};
	my $testmask = 0;
	$mask = int($mask + ($mask < 0 ? (2**31 + 2**31) : 0));

	while (my($value, $names) = each(%{$self->{reverse_cache}})) {
		if ( int($value) == ($mask & int($value)) ) {
			my(@names) = grep {!exists $self->{full_match}->{$_}} @$names;
			scalar(@names) or next;
			@{$struct}{@names} = (1) x scalar(@names);
			$testmask |= int($value);
		}
	}

	$testmask == $mask or &croak("Unable to break down mask $mask completely.  Found $testmask.");

	return $struct;
}

=head2 explain_mask

Explains a mask in terms of a relatively minimal set of constants.  Pass either 
a mask value as an integer or any valid parameter for C<build_mask>.  Returns a 
hash of constants that will recreate the mask. Many times, this will be the 
minimum number of constants necessary to describe the mask.  Note that creating 
the true minimum set of constants is somewhat painful (see Knapsack problem).  

The algorithm used by C<explain_mask> is to first test for a constant that 
perfectly matches the mask.  If one is found, this is the obvious answer.  In 
the absence of a perfect match, C<break_mask> is used to generate a maximal 
solution.  All simply occluded constants are then eliminated (that is to say, 
all constants in the list whose values are subsets of another single constant). 
This means, for instance, that if you had only three constants, AB => 3, BC => 
6, and AC => 5, C<explain_mask> would return all three when passed the value 7 
because no one constant is a subset of any single one of the others.

To eliminate a constant from explain_mask or break_mask unless it perfectly 
matches, use C<full_match> constants.

=cut

sub explain_mask {
	my $self = shift;
	my($mask) = @_;

	local $^W = 0;

	if (int($mask) eq $mask) {
		$mask = int($mask) < 0 ? int($mask) + 2**31 + 2**31 : int($mask);
	} else {
		$mask = $self->build_mask($mask);
	}

	return {$self->{reverse_cache}->{$mask}->[0] => 1} if exists $self->{reverse_cache}->{$mask};

	my $struct = $self->break_mask($mask);
	my(@temp) = keys(%$struct);

	foreach my $namer (@temp) {
		exists $struct->{$namer} or next;
		foreach my $named (@{$self->{occlusion_cache}->{$namer}}) {
			delete $struct->{$named} if exists $struct->{$named};
		}
	}

	return $struct;
}


=head2 build_const

This takes one of two things as a parameter:

=over 4

=item *

scalar integer - if a scalar integer is passed, then the value is simply 
returned, after adding 2**32 to any negative integers

=item *

scalar - string is looked up in the list of constants

=back

=cut

sub build_const {
	my $self = shift;
	my($const) = @_;

	local $^W = 0;

	if (int($const) eq $const) {
		return int($const) < 0 ? int($const) + 2**31 + 2**31 : int($const);
	} else {
		exists $self->{forward_cache}->{$const} or &croak("Unable to find constant '$const'");
		return $self->{forward_cache}->{$const};
	}
}

=head2 explain_const

Looks for a perfect match for the passed mask value.  Pass either a mask value 
as an integer or any valid parameter for C<build_mask>.  If one is not found, it 
croaks.

=cut

sub explain_const {
	my $self = shift;
	my($const) = @_;

	local $^W = 0;

	if (int($const) eq $const) {
		$const = int($const) < 0 ? int($const) + 2**31 + 2**31 : int($const);
	} else {
		exists $self->{forward_cache}->{$const} or &croak("Unable to find constant '$const'");
		$const = $self->{forward_cache}->{$const};
	}

	return $self->{reverse_cache}->{$const}->[0] if exists $self->{reverse_cache}->{$const};
	&croak("Unable to lookup $const.");
}


=head2 get_constants

Returns all constants passed either to C<new> or C<add_constants>.

=cut

sub get_constants {
	my $self = shift;

	return @{$self->{constants}};
}


### croak autoload is courtesy of Mark Jason-Dominus,
### http://perl.plover.com/yak/tricks/samples/slide122.html

sub croak {
	require Carp;

	local $^W = 0;
	*croak = \&Carp::croak;
	goto &croak;
}


=head1 AUTHOR

Toby Ovod-Everett, toby@ovod-everett.org

=head1 LICENSE

Copyright 2003, 2004 Toby Ovod-Everett.  All rights reserved.
This program is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=cut

1;