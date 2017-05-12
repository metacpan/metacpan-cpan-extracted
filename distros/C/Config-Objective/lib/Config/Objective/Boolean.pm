
###
###  Copyright 2002-2003 University of Illinois Board of Trustees
###  Copyright 2002-2003 Mark D. Roth
###  All rights reserved. 
###
###  Config::Objective::Boolean - boolean data type for Config::Objective
###
###  Mark D. Roth <roth@uiuc.edu>
###  Campus Information Technologies and Educational Services
###  University of Illinois at Urbana-Champaign
###


package Config::Objective::Boolean;

use strict;

#use overload
#	'bool'	=> \&get
#	;

use Config::Objective::DataType;

our @ISA = qw(Config::Objective::DataType);


###############################################################################
###  utility function to interpret boolean values
###############################################################################

sub _boolean
{
	my ($self, $value) = @_;

	if (!defined($value)
	    || $value =~ m/^(yes|on|true|1)$/i)
	{
		return 1;
	}
	elsif ($value =~ m/^(no|off|false|0)$/i)
	{
		return 0;
	}

	die "non-boolean value '$value' specified for boolean variable\n";
}


###############################################################################
###  set method
###############################################################################

sub set
{
	my ($self, $value) = @_;

#	print "==> Boolean::set($value)\n";

	$self->{'value'} = $self->_boolean($value);
}


###############################################################################
###  equals method
###############################################################################

sub equals
{
	my ($self, $value) = @_;

	return ($self->{'value'} == $self->_boolean($value));
}


###############################################################################
###  cleanup and documentation
###############################################################################

1;

__END__

=head1 NAME

Config::Objective::Boolean - boolean data type class for Config::Objective

=head1 SYNOPSIS

  use Config::Objective;
  use Config::Objective::Boolean;

  my $conf = Config::Objective->new('filename', {
			'boolobj'	=> Config::Objective::Boolean->new()
		});

=head1 DESCRIPTION

The B<Config::Objective::Boolean> module provides a class that
represents a boolean value in an object so that it can be used with
B<Config::Objective>.  Its methods can be used to manipulate the
encapsulated boolean value from the config file.

The B<Config::Objective::Boolean> class is derived from the
B<Config::Objective::DataType> class, but it defines/overrides the
following methods:

=over 4

=item set()

Sets the object's value to the supplied value.  The value must be one
of the following: "yes", "no", "on", "off", "true", "false", 1, or 0.

=item equals()

Returns true if the argument equals the object's value.  If the argument
is not defined, it is treated as if it were true.

=back

=head1 AUTHOR

Mark D. Roth E<lt>roth@uiuc.eduE<gt>

=head1 SEE ALSO

L<perl>

L<Config::Objective>

L<Config::Objective::DataType>

=cut

