
###
###  Copyright 2002-2003 University of Illinois Board of Trustees
###  Copyright 2002-2003 Mark D. Roth
###  All rights reserved. 
###
###  Config::Objective::Integer - integer data type for Config::Objective
###
###  Mark D. Roth <roth@uiuc.edu>
###  Campus Information Technologies and Educational Services
###  University of Illinois at Urbana-Champaign
###


package Config::Objective::Integer;

use strict;
use integer;

#use overload
#	'""'		=> 'get',
##	'0+'		=> 'get',
#	'+'		=> 'numeric_add',
#	'='		=> 'set',
#	'eq'		=> 'equals',
##	'fallback'	=> 1
#	;

use Config::Objective::DataType;

our @ISA = qw(Config::Objective::DataType);


###############################################################################
###  equals method (for conditional expressions)
###############################################################################

sub equals
{
	my ($self, $value) = @_;

	return $self->eq($value);
}


sub eq
{
	my ($self, $value) = @_;

#	print "==> equals(" . ref($self) . "='$self->{'value'}', '$value')\n";

	return ($self->{'value'} == $value);
}


###############################################################################
###  not-equals method (for conditional expressions)
###############################################################################

sub ne
{
	my ($self, $value) = @_;

	return ($self->{'value'} != $value);
}


###############################################################################
###  greater-than method (for conditional expressions)
###############################################################################

sub gt
{
	my ($self, $value) = @_;

	return ($self->{'value'} > $value);
}


###############################################################################
###  less-than method (for conditional expressions)
###############################################################################

sub lt
{
	my ($self, $value) = @_;

	return ($self->{'value'} < $value);
}


###############################################################################
###  less-than-or-equal-to method (for conditional expressions)
###############################################################################

sub le
{
	my ($self, $value) = @_;

	return ($self->{'value'} <= $value);
}


###############################################################################
###  greater-than-or-equal-to method (for conditional expressions)
###############################################################################

sub ge
{
	my ($self, $value) = @_;

	return ($self->{'value'} >= $value);
}


###############################################################################
###  set method
###############################################################################

sub set
{
	my ($self, $value) = @_;

#	print "==> Integer::set($value)\n";

	die "value required\n"
		if (!defined($value));

	die "non-scalar value specified for integer variable\n"
		if (ref($value));

	die "non-numeric value specified for integer variable\n"
		if ($value !~ m/^-?\d+$/);

	$self->{'value'} = $value;
}


###############################################################################
###  add method
###############################################################################

sub add
{
	my ($self, $value) = @_;

	$self->{'value'} += $value;
}


###############################################################################
###  subtract method
###############################################################################

sub sub
{
	my ($self, $value) = @_;

	$self->{'value'} -= $value;
}


###############################################################################
###  divide method
###############################################################################

sub div
{
	my ($self, $value) = @_;

	$self->{'value'} = int($self->{'value'} / $value);
}


###############################################################################
###  multiply method
###############################################################################

sub mult
{
	my ($self, $value) = @_;

	$self->{'value'} *= $value;
}


###############################################################################
###  increment method
###############################################################################

sub incr
{
	my ($self) = @_;

	$self->{'value'}++;
}


###############################################################################
###  decrement method
###############################################################################

sub decr
{
	my ($self) = @_;

	$self->{'value'}--;
}


###############################################################################
###  cleanup and documentation
###############################################################################

1;

__END__

=head1 NAME

Config::Objective::Integer - integer data type class for Config::Objective

=head1 SYNOPSIS

  use Config::Objective;
  use Config::Objective::Integer;

  my $conf = Config::Objective->new('filename', {
			'intobj'	=> Config::Objective::Integer->new()
		});

=head1 DESCRIPTION

The B<Config::Objective::Integer> module provides a class that
represents an integer value in an object so that it can be used with
B<Config::Objective>.  Its methods can be used to manipulate the
encapsulated integer value from the config file.

The B<Config::Objective::Integer> class is derived from the
B<Config::Objective::DataType> class, but it defines/overrides the
following methods:

=over 4

=item set()

Sets the object's value to the supplied value.  The value must consist of
only digit characters, with an optional leading "-" character to denote
a negative value.

=item add()

Adds the supplied value to the object's value.

=item sub()

Subtracts the supplied value from the object's value.

=item div()

Divides the object's value by the supplied value.

=item mult()

Multiplies the object's value by the supplied value.

=item incr()

Increments the object's value by one.

=item decr()

Decrements the object's value by one.

=item equals()

Same as the eq() method.

=item eq()

Returns true if the object's value is equal to the supplied value.

=item ne()

Returns true if the object's value is not equal to the supplied value.

=item gt()

Returns true if the object's value is greater than the supplied value.

=item lt()

Returns true if the object's value is less than the supplied value.

=item ge()

Returns true if the object's value is greater than or equal to the
supplied value.

=item le()

Returns true if the object's value is less than or equal to the
supplied value.

=back

=head1 AUTHOR

Mark D. Roth E<lt>roth@uiuc.eduE<gt>

=head1 SEE ALSO

L<perl>

L<Config::Objective>

L<Config::Objective::DataType>

=cut

