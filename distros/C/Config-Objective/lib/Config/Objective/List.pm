
###
###  Copyright 2002-2003 University of Illinois Board of Trustees
###  Copyright 2002-2003 Mark D. Roth
###  All rights reserved. 
###
###  Config::Objective::List - list data type for Config::Objective
###
###  Mark D. Roth <roth@uiuc.edu>
###  Campus Information Technologies and Educational Services
###  University of Illinois at Urbana-Champaign
###


package Config::Objective::List;

use strict;

use Config::Objective::DataType;

our @ISA = qw(Config::Objective::DataType);


###############################################################################
###  default is add() method
###############################################################################

sub default
{
	my ($self, $value) = @_;

	$self->add($value);
}


###############################################################################
###  unset method
###############################################################################

sub unset
{
	my ($self) = @_;

	$self->{'value'} = [];
	return 1;
}


###############################################################################
###  set method
###############################################################################

sub set
{
	my ($self, $value) = @_;

#	print "==> List::set($value)\n";

	$self->unset();
	return $self->add($value);
}


###############################################################################
###  add method
###############################################################################

sub add
{
	my ($self, $value) = @_;

	$value = $self->_scalar_or_list($value);
	$self->{'value'} = []
		if (!defined($self->{'value'}));
	push(@{$self->{'value'}}, @$value);

	return 1;
}


###############################################################################
###  add_top method
###############################################################################

sub add_top
{
	my ($self, $value) = @_;

	$value = $self->_scalar_or_list($value);
	$self->{'value'} = []
		if (!defined($self->{'value'}));
	unshift(@{$self->{'value'}}, @$value);

	return 1;
}


###############################################################################
###  delete method
###############################################################################

sub delete
{
	my ($self, $value) = @_;
	my ($val);

	$value = $self->_scalar_or_list($value);
	$self->{'value'} = []
		if (!defined($self->{'value'}));
	foreach $val (@$value)
	{
		$self->{'value'} = [ grep !/$val/, @{$self->{'value'}} ];
	}

	return 1;
}


###############################################################################
###  cleanup and documentation
###############################################################################

1;

__END__

=head1 NAME

Config::Objective::List - list data type class for Config::Objective

=head1 SYNOPSIS

  use Config::Objective;
  use Config::Objective::List;

  my $conf = Config::Objective->new('filename', {
			'listobj'	=> Config::Objective::List->new()
		});

=head1 DESCRIPTION

The B<Config::Objective::List> module provides a class that
represents a list in an object so that it can be used with
B<Config::Objective>.  Its methods can be used to manipulate the
encapsulated list from the config file.

The B<Config::Objective::List> class is derived from the
B<Config::Objective::DataType> class, but it defines/overrides the
following methods:

=over 4

=item add()

Adds the supplied value to the end of the object's list.  The value can
be a scalar or a reference to a list, in which case the values in the
referenced list are added to the object's list.

=item unset()

Sets the object's value to an empty list.

=item set()

The same as add(), except that the existing list is emptied by calling
the unset() method before adding the new data.

=item default()

Calls the add() method.

=item add_top()

Same as add, but adds to the front of the list instead of the end.

=item delete()

Deletes elements from the list that match its argument.  Matching is
performed by using the argument as a regular expression.  The argument
can be a scalar or a reference to a list, in which case each item of the
referenced list is used to check the values in the object's list.

=back

=head1 AUTHOR

Mark D. Roth E<lt>roth@uiuc.eduE<gt>

=head1 SEE ALSO

L<perl>

L<Config::Objective>

L<Config::Objective::DataType>

=cut

