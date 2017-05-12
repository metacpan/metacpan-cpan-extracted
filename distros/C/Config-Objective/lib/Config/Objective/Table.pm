
###
###  Copyright 2002-2003 University of Illinois Board of Trustees
###  Copyright 2002-2003 Mark D. Roth
###  All rights reserved. 
###
###  Config::Objective::Table - table data type for Config::Objective
###
###  Mark D. Roth <roth@uiuc.edu>
###  Campus Information Technologies and Educational Services
###  University of Illinois at Urbana-Champaign
###


package Config::Objective::Table;

use strict;

use Config::Objective::List;

our @ISA = qw(Config::Objective::List);


###############################################################################
###  utility function
###############################################################################

sub _find_row
{
	my ($self, $query) = @_;
	my ($ct, $lref, $key);

	ROWS: for ($ct = 0; $ct < @{$self->{value}}; $ct++)
	{
		$lref = $self->{value}->[$ct];
		foreach $key (keys %$query)
		{
			next ROWS
				if ($lref->[$key] !~ m/$query->{$key}/);
		}

		return $ct;
	}

	return undef;
}


###############################################################################
###  insert_row method
###############################################################################

sub insert_row
{
	my ($self, $query, $newrow) = @_;
	my ($row);

	die "insert_row: row specifier must be a hash\n"
		if (ref($query) ne 'HASH');

	die "insert_row: new row must be list type\n"
		if (ref($newrow) ne 'ARRAY');

	$row = $self->_find_row($query);
	splice(@{$self->{value}}, $row, 0, $newrow)
		if (defined($row));
}


###############################################################################
###  find_row method
###############################################################################

sub find_row
{
	my ($self, $query) = @_;
	my ($row);

	die "find_row: row specifier must be a hash\n"
		if (ref($query) ne 'HASH');

	$row = $self->_find_row($query);
	return $self->{value}->[$row]
		if (defined($row));

	return undef;
}


###############################################################################
###  replace_row_cells method
###############################################################################

sub replace_row_cells
{
	my ($self, $query, $replspec) = @_;
	my ($row, $col);

	die "replace_row_cells: row specifier must be a hash\n"
		if (ref($query) ne 'HASH');

	die "replace_row_cells: replacement specifier must be a hash\n"
		if (ref($replspec) ne 'HASH');

	$row = $self->_find_row($query);
	return
		if (!defined($row));

	foreach $col (keys %$replspec)
	{
		$self->{value}->[$row]->[$col] = $replspec->{$col};
	}
}


###############################################################################
###  append_to_row_cells method
###############################################################################

sub append_to_row_cells
{
	my ($self, $query, $addspec) = @_;
	my ($row, $col);

	die "append_to_row_cells: row specifier must be a hash\n"
		if (ref($query) ne 'HASH');

	die "append_to_row_cells: addition specifier must be a hash\n"
		if (ref($addspec) ne 'HASH');

	$row = $self->_find_row($query);
	return
		if (!defined($row));

	foreach $col (keys %$addspec)
	{
		$self->{value}->[$row]->[$col] .= ' '
			if ($self->{value}->[$row]->[$col] ne '');
		$self->{value}->[$row]->[$col] .= $addspec->{$col};
	}
}


###############################################################################
###  old methods - to be used for backward compatibility only!
###############################################################################

sub add_before
{
	my ($self, $value) = @_;

	die "add_before: method requires list argument\n"
		if (ref($value) ne 'ARRAY');

	die "add_before: invalid argument(s)\n"
		if (@{$value} != 3
		    || ref($value->[2]) ne 'ARRAY');

	return $self->insert_row({ $value->[0] => $value->[1] }, $value->[2]);
}


sub find
{
	my ($self, $value) = @_;

	die "find: method requires list argument\n"
		if (ref($value) ne 'ARRAY');

	die "find: invalid argument(s)\n"
		if (@{$value} != 2);

	return $self->find_row({ $value->[0] => "\b$value->[1]\b" });
}


sub replace
{
	my ($self, $value) = @_;

	die "replace: method requires list argument\n"
		if (ref($value) ne 'ARRAY');

	die "replace: invalid argument(s)\n"
		if (@{$value} != 4);

	$self->replace_row_cells({ $value->[0] => $value->[1] },
				 { $value->[2] => $value->[3] });
}


sub modify
{
	my ($self, $value) = @_;

	die "modify: method requires list argument\n"
		if (ref($value) ne 'ARRAY');

	die "modify: invalid argument(s)\n"
		if (@{$value} != 4);

	$self->append_to_row_cells({ $value->[0] => $value->[1] },
				   { $value->[2] => $value->[3] });
}


###############################################################################
###  cleanup and documentation
###############################################################################

1;

__END__

=head1 NAME

Config::Objective::Table - table data type class for Config::Objective

=head1 SYNOPSIS

  use Config::Objective;
  use Config::Objective::Table;

  my $conf = Config::Objective->new('filename', {
			'tableobj'	=> Config::Objective::Table->new()
		});

=head1 DESCRIPTION

The B<Config::Objective::Table> module provides a class that represents a
table value in an object so that it can be used with B<Config::Objective>.
Its methods can be used to manipulate the encapsulated table value from
the config file.

The table data is represented as a list of lists.  Both rows
and columns are indexed starting at 0.  It is derived from the
B<Config::Objective::List> class, but it supports the following additional
methods:

=over 4

=item insert_row()

Inserts a new row into the table before a specified row.

The first argument is used to determine the existing row before which
the new row should be inserted.  It must be a reference to a hash that
maps column numbers to a regular expression that the column's value must
match.  If the hash is empty, the new row will be inserted before the
first existing row.

The second argument is a reference to an array.  It contains the row to
be inserted.

=item find_row()

Finds a row in the table.  The argument must be a reference to a hash
that maps column numbers to a regular expression that the column's value
must match.  If the hash is empty, the first row will be returned.

This function is not very useful for calling from a config file, but
it's sometimes useful to call it from perl once the config file has been
read.

=item replace_row_cells()

Replaces one or more cells in a given row.

The first argument is used to determine the row to be modified.  It must
be a reference to a hash that maps column numbers to a regular expression
that the column's value must match.  If the hash is empty, the first row
is used.

The second argument represents the new values for the matching row.  It
must be a reference to a hash that maps column numbers to the new value
for that column.

=item append_to_row_cells()

Similar to replace_row_cells(), but appends to the existing value instead
of replacing it.  A space character is appended before the new value.

=back

In addition, the following deprecated methods are available for backward
compatibility:

=over 4

=item add_before()

Inserts a new row into the table before a specified row.  The argument
must be a reference to a list containing three elements: a number
indicating what column to search on, a string which is used as a regular
expression match to find a matching row in the table, and a reference
to the new list to be inserted before the matching row.

=item find()

Finds a row with a specified word in a specified column.  The column
number is the first argument, and the word to match on is the second.
It returns a reference to the matching row, or I<undef> if no matches
were found.

=item replace()

Finds a row in the same manner as find(), and then replaces that row's
value in a specified column with a new value.  The arguments are the
column number to search on, the word to search for, the column number to
replace, and the text to replace it with.

=item modify()

Similar to replace(), but appends to the existing value instead of
replacing it.  A space character is appended before the new value.

=back

Note that these deprecated methods should not be used by new applications.
They will be removed altogether in a future release.

=head1 AUTHOR

Mark D. Roth E<lt>roth@uiuc.eduE<gt>

=head1 SEE ALSO

L<perl>

L<Config::Objective>

L<Config::Objective::List>

=cut

