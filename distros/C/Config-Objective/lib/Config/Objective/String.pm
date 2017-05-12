
###
###  Copyright 2002-2003 University of Illinois Board of Trustees
###  Copyright 2002-2003 Mark D. Roth
###  All rights reserved. 
###
###  Config::Objective::String - string data type for Config::Objective
###
###  Mark D. Roth <roth@uiuc.edu>
###  Campus Information Technologies and Educational Services
###  University of Illinois at Urbana-Champaign
###


package Config::Objective::String;

use strict;

use Config::Objective::DataType;

our @ISA = qw(Config::Objective::DataType);


###############################################################################
###  equals() method (for conditional expressions)
###############################################################################

sub equals
{
	my ($self, $value) = @_;

#	print "==> equals(" . ref($self) . "='$self->{value}', '$value')\n";

	return ($self->{value} eq $value);
}


###############################################################################
###  match() method (for conditional expressions)
###############################################################################

sub match
{
	my ($self, $regex) = @_;

	return ($self->{value} =~ m/$regex/i);
}


###############################################################################
###  set() method
###############################################################################

sub set
{
	my ($self, $value) = @_;

#	print "==> String::set($value)\n";

	if (defined($value))
	{
		die "non-scalar value specified for string variable\n"
			if (ref($value));

		die "value must be absolute path\n"
			if ($self->{value_abspath}
			    && $value !~ m|^/|);
	}
	else
	{
		die "value required\n"
			if (! $self->{value_optional});
		$value = '';
	}

	return $self->SUPER::set($value);
}


###############################################################################
###  append() method - append new string to existing value
###############################################################################

sub append
{
	my ($self, $value) = @_;

	die "non-scalar value specified for string variable\n"
		if (defined($value) && ref($value));

	$self->{value} .= $value;

	return 1;
}


###############################################################################
###  prepend() method - prepend new string to existing value
###############################################################################

sub prepend
{
	my ($self, $value) = @_;

	die "non-scalar value specified for string variable\n"
		if (defined($value) && ref($value));

	$self->{value} = $value . $self->{value};

	return 1;
}


###############################################################################
###  gsub() method - substring replacement
###############################################################################

sub gsub
{
	my ($self, $old, $new) = @_;

#	print "==> gsub(): value='$self->{value}' old='$old' new='$new'\n";

	$self->{value} =~ s/$old/$new/g;

	return 1;
}


###############################################################################
###  cleanup and documentation
###############################################################################

1;

__END__

=head1 NAME

Config::Objective::String - string data type class for Config::Objective

=head1 SYNOPSIS

  use Config::Objective;
  use Config::Objective::String;

  my $conf = Config::Objective->new('filename', {
			'stringobj'	=> Config::Objective::String->new()
		});

=head1 DESCRIPTION

The B<Config::Objective::String> module provides a class that
represents a string value in an object so that it can be used with
B<Config::Objective>.  Its methods can be used to manipulate the
encapsulated string value from the config file.

The B<Config::Objective::String> class is derived from the
B<Config::Objective::DataType> class, but it defines/overrides the
following methods:

=over 4

=item set()

Sets the object's value to its argument.  The value must be a scalar.

If the object was created with the I<value_abspath> attribute enabled,
the value must be an absolute path string.

If the object was created with the I<value_optional> attribute enabled,
the argument is optional; if missing, an empty string will be used
instead.

=item append()

Appends its argument to the object's value using string concatenation.

=item prepend()

Prepends its argument to the object's value using string concatenation.

=item gsub()

For each substring matching the first argument in the object's value,
substitutes the second argument.

=item equals()

Returns true if the argument equals the object's value.  The comparison
is done using the perl "eq" operator.

=item match()

Returns true if the object's value matches the argument.  The comparison
is done using the argument as a case-insensitive regular expression.

=back

=head1 AUTHOR

Mark D. Roth E<lt>roth@uiuc.eduE<gt>

=head1 SEE ALSO

L<perl>

L<Config::Objective>

L<Config::Objective::DataType>

=cut

