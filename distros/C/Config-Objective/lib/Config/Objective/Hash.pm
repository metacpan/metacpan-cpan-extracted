
###
###  Copyright 2002-2003 University of Illinois Board of Trustees
###  Copyright 2002-2003 Mark D. Roth
###  All rights reserved. 
###
###  Config::Objective::Hash - hash data type for Config::Objective
###
###  Mark D. Roth <roth@uiuc.edu>
###  Campus Information Technologies and Educational Services
###  University of Illinois at Urbana-Champaign
###


package Config::Objective::Hash;

use strict;

use Config::Objective::DataType;

our @ISA = qw(Config::Objective::DataType);


###############################################################################
###  default method is insert()
###############################################################################

sub default
{
	my ($self, $value) = @_;

	$self->insert($value);
}


###############################################################################
###  unset method
###############################################################################

sub unset
{
	my ($self) = @_;

	$self->{'value'} = {};
	return 1;
}


###############################################################################
###  set method
###############################################################################

sub set
{
	my ($self, $value) = @_;

#	print "==> Hash::set($value)\n";

	$self->unset();
	return $self->insert($value);
}


###############################################################################
###  insert method
###############################################################################

sub insert
{
	my ($self, $value) = @_;
	my ($key1, $key2);

#	print "==> Hash::insert($value)\n";

	die "insert: method requires hash argument\n"
		if (ref($value) ne 'HASH');

	$self->{'value'} = {}
		if (!defined($self->{'value'}));

	foreach $key1 (keys %$value)
	{
		print "\t'$key1' => '$value->{$key1}'\n"
			if ($self->{'debug'});

		die "key must be an absolute path\n"
			if ($self->{'key_abspath'}
			    && $key1 !~ m|^/|);

		if (!defined($value->{$key1}))
		{
			die "hash value missing\n"
				if (!$self->{'value_optional'});
		}
		else
		{
			die "hash value is not a $self->{'value_type'}\n"
				if (defined($self->{'value_type'})
				    && $self->{'value_type'} ne ref($value->{$key1}));

			die "value must be an absolute path\n"
				if ($self->{'value_abspath'}
				    && $value->{$key1} !~ m|^/|);
		}

		if (exists($self->{'value'}->{$key1}))
		{
#			print "key1='$key1'\n";
			if (ref($self->{'value'}->{$key1}) eq 'HASH')
			{
#				print "key1={" . join(',', sort keys %{$self->{'value'}->{$key1}}) . "}\n";
				foreach $key2 (keys %{$value->{$key1}})
				{
#					print "\tkey2='$key2'\n";
					$self->{'value'}->{$key1}->{$key2} = $value->{$key1}->{$key2};
				}

#				print "'$key1' => { " . join(', ', sort keys %{$self->{'value'}->{$key1}}) . " }\n";
				next;
			}
			elsif (ref($self->{'value'}->{$key1}) eq 'ARRAY')
			{
				push(@{$self->{'value'}->{$key1}}, @{$value->{$key1}});
				next;
			}
		}

		### overwrite the existing entry
		### or create a new one
		print "OVERRIDE: $value->{$key1}\n"
			if ($self->{'debug'});
		$self->{'value'}->{$key1} = $value->{$key1};
	}

	return 1;
}


###############################################################################
###  exists method
###############################################################################
 
sub exists
{
	my ($self, $value) = @_;
 
	return (exists($self->{'value'}->{$value}) ? 1 : 0);
}

 
###############################################################################
###  find method
###############################################################################
 
sub find
{
	my ($self, $value) = @_;
 
	return (exists($self->{value}->{$value})
		? $self->{value}->{$value}
		: undef);
}

 
###############################################################################
###  delete method
###############################################################################

sub delete
{
	my ($self, $value) = @_;
	my ($val);

	$value = $self->_scalar_or_list($value);
	foreach $val (@$value)
	{
		delete $self->{'value'}->{$val};
	}

	return 1;
}


###############################################################################
###  cleanup and documentation
###############################################################################

1;

__END__

=head1 NAME

Config::Objective::Hash - hash data type class for Config::Objective

=head1 SYNOPSIS

  use Config::Objective;
  use Config::Objective::Hash;

  my $conf = Config::Objective->new('filename', {
			'hashobj'	=> Config::Objective::Hash->new(
							'value_abspath' => 1,
							...
						)
		});

=head1 DESCRIPTION

The B<Config::Objective::Hash> module provides a class that
represents a hash in an object so that it can be used with
B<Config::Objective>.  Its methods can be used to manipulate the
encapsulated hash from the config file.

The B<Config::Objective::Hash> class is derived from the
B<Config::Objective::DataType> class, but it defines/overrides the
following methods:

=over 4

=item insert()

Inserts the specified values into the object's hash.  The argument must
be a reference to a hash, whose keys and values are copied into the
object's hash.

If the values are lists, inserting a key that already exists will append
the new list to the existing list.  If the values are hashes, inserting
a key that already exists will insert the new key/value pairs into the
existing value hash.

If the object was created with the I<value_optional> attribute enabled,
keys may be inserted with no defined values.

If the object was created with the I<value_type> attribute set to
either "ARRAY" or "HASH", then the hash values must be references to
the corresponding structure type.

If the object was created with the I<value_abspath> attribute enabled,
the hash values must be absolute path strings.

If the object was created with the I<key_abspath> attribute enabled, the
hash keys must be absolute path strings.

=item set()

The same as insert(), except that the existing hash is emptied by calling
the unset() method before inserting the new data.

=item default()

Calls the insert() method.

=item unset()

Sets the object's value to an empty hash.

=item delete()

Deletes a specific hash key.  The argument can be a scalar or a
reference to a list, in which case all of the keys in the list are
deleted.

=item exists()

Returns true if the argument is found in the hash, false otherwise.

=item find()

If the argument is found in the hash, returns its value.  Otherwise,
returns false.

=back

=head1 BUGS

The I<value_abspath> and I<key_abspath> attributes should be replaced by
a generic mechanism that allows the caller to supply a reference to a
subroutine that will be called to validate the key and value data.

=head1 AUTHOR

Mark D. Roth E<lt>roth@uiuc.eduE<gt>

=head1 SEE ALSO

L<perl>

L<Config::Objective>

L<Config::Objective::DataType>

=cut

