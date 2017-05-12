
###
###  Copyright 2002-2003 University of Illinois Board of Trustees
###  Copyright 2002-2003 Mark D. Roth
###  All rights reserved. 
###
###  Config::Objective::DataType - base class for Config::Objective data types
###
###  Mark D. Roth <roth@uiuc.edu>
###  Campus Information Technologies and Educational Services
###  University of Illinois at Urbana-Champaign
###


package Config::Objective::DataType;

use strict;


###############################################################################
###  constructor
###############################################################################

sub new
{
	my ($class, %opts) = @_;
	my ($self);

	$self = \%opts;
	bless($self, $class);

	$self->unset()
		if (!exists($self->{'value'}));

	return $self;
}


###############################################################################
###  get method
###############################################################################

sub get
{
	my ($self) = @_;

#	print "==> get(" . ref($self) . ")\n";

	return $self->{'value'};
}


###############################################################################
###  set method
###############################################################################

sub set
{
	my ($self, $value) = @_;

#	print "==> set(\"$value\")\n";

	$self->{'value'} = $value;
	return 1;
}


###############################################################################
###  default method
###############################################################################

sub default
{
	my ($self, $value) = @_;

	$self->set($value);
}


###############################################################################
###  unset method
###############################################################################

sub unset
{
	my ($self) = @_;

	$self->{'value'} = undef;
	return 1;
}


###############################################################################
###  utility function for parsing arguments
###############################################################################

sub _scalar_or_list
{
	my ($self, $value) = @_;

	$value = [ $value ]
		if (! ref($value));

	die "method requires scalar or list argument\n"
		if (ref($value) ne 'ARRAY');

	return $value;
}


###############################################################################
###  cleanup and documentation
###############################################################################

1;

__END__

=head1 NAME

Config::Objective::DataType - base class for Config::Objective data types

=head1 SYNOPSIS

  use Config::Objective;
  use Config::Objective::DataType;

  my $conf = Config::Objective->new('filename', {
		'objname'	=> Config::Objective::DataType->new(
					'attr1' => 0,
					'attr2' => "string",
					...
				)
	});

=head1 DESCRIPTION

The B<Config::Objective::DataType> module provides a class that
encapsulates a value in an object so that it can be used with
B<Config::Objective>.  Its methods can be used to manipulate the
encapsulated value from the config file.

The B<Config::Objective::DataType> class is not intended to be used
to directly instantiate configuration objects, but it does
support the following methods for use in subclasses:

=over 4

=item new()

The constructor.  It can be passed a hash to set the object's
attributes.  The object will be created as a reference to this hash.

The value encapsulated by the object is stored in the "value" attribute.
Setting this attribute in the constructor call will set the initial
value for the object.  If no initial value is supplied, the constructor
will call the undef() method.

The B<Config::Objective::DataType> class does not use any other
attributes.  However, they can be useful in subclasses.

=item set()

Sets the object's value to the supplied value.

=item get()

Returns the object's value.

=item unset()

Sets the object's value to I<undef>.

=item default()

Calls the set() method.

=back

=head1 AUTHOR

Mark D. Roth E<lt>roth@uiuc.eduE<gt>

=head1 SEE ALSO

L<perl>

L<Config::Objective>

=cut

