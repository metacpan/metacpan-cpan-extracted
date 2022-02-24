=head1 NAME

Data::DPath::Flatten - Convert complex data structure into key/value pairs

=head1 SYNOPSIS

  use Data::DPath::Flatten qw/flatten/;
  
  # Data can be arrays or hashes.
  my $hash = flatten( \@record );
  my $hash = flatten( \%record );
  
  # Aliases add more human readable field names.
  my $hash = flatten( \@record );
  my $hash = flatten( \%record );

=head1 DESCRIPTION

B<Data::DPath::Flatten> transforms an arbitrary data structure into a hash of
key/value pairs. 

Why? To store raw data in an SQL database. L<ETL::Pipeline::Input> returns 
arbitrary data structures. For example, Excel files return an array but XML 
files a hash. B<Data::DPath::Flatten> gives me a unique key for each field in
the file, regardless of the Perl data structure.

Use B<Data::DPath::Flatten> where you need key/value pairs from arbitrary data.
The module traverses nested data structures of any depth and converts into a 
single dimension.

=cut

package Data::DPath::Flatten;

use 5.14.0;
use Carp;
use Exporter qw/import/;


our @EXPORT = (qw/flatten/);
our $VERSION = '1.00';


=head1 FUNCTIONS

=head3 flatten( $data )

B<flatten> takes an arbitrary data structure and converts into a one level array
reference. Essentially, it flattens out nested data structures.

B<flatten> returns a hash reference. The keys are L<Data::DPath> paths into the 
original record. The value is the raw data value from the file.

The parameter C<$data> is required. It is a reference to the input data 
structure.

  # Recursively traverse arrays and hashes. 
  my $hash = flatten( \@fields );
  my $hash = flatten( \%record );
  
  # Scalars work, but it's kind of pointless. These come out the same.
  my $hash = flatten( $single );
  my $hash = flatten( \$single );

When B<flatten> encounters a HASH or ARRAY reference, it recursively traverses
the nested structure. Circular references are traversed only once, to avoid 
infinite loops.

SCALAR references are dereferenced and the value stored.

All other references and objects are stored as references.

=cut

sub flatten {
	my $data = shift;
	
	# Flatten the original data into a one level hash. Make sure I get a new
	# reference for every call.
	my $new  = {};
	_step( $data, $new, '', {} );

	# Return the flattened hash reference.	
	return $new;
}


#-------------------------------------------------------------------------------
# Internal subroutines.

# Recursively traverse the data structure, building the path string as it goes.
# The initial path is an empty string. This code adds the leading "/".
# 
# The $seen parameter stops circular references from causing infinite loops. We
# traverse any reference only once.
# 
# I looked into using existing data traversal modules such as Data::Rmap, 
# Data::Traverse, Data::Visitor, or Data::Walk. Simple recurrsion was so much
# easier. I would have to use all kinds of gloabl variables and conditionals
# just to build the correct paths. This works and handles circular references.
sub _step {
	my ($from, $to, $path, $seen) = @_;

	# Process this node of the structure.
	if (!defined( $from )) { 
		# No op!
	} elsif (ref( $from ) eq '') { 
		if ($path eq '') { $to->{'/'  } = $from; }
		else             { $to->{$path} = $from; }
	} elsif (ref( $from) eq 'SCALAR') { 
		if ($path eq '') { $to->{'/'  } = $$from; }
		else             { $to->{$path} = $$from; }
	} elsif (ref( $from) eq 'HASH') {
		unless (exists $seen->{$from}) {
			$seen->{$from}++;
			while (my ($key, $value) = each %$from) {
				$key = "\"$key\"" if m/\.\.|\*|::ancestor(-or-self)?|\/\/|\[|\]/;
				_step( $value, $to, "$path/$key", $seen );
			}
		}
	} elsif (ref( $from ) eq 'ARRAY') {
		unless (exists $seen->{$from}) {
			$seen->{$from}++;
			while (my ($index, $value) = each @$from) {
				_step( $value, $to, "$path/*[$index]", $seen );
			}
		}
	} else {
		if ($path eq '') { $to->{'/'  } = $from; }
		else             { $to->{$path} = $from; }
	}

	return;
}


=head1 SEE ALSO

L<Data::DPath>

=head1 REPOSITORY

L<https://github.com/rbwohlfarth/Data-DPath-Flatten>

=head1 AUTHOR

Robert Wohlfarth <rbwohlfarth@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2022  Robert Wohlfarth

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl 5.10.0. For details, see the full text of the 
license in the file LICENSE.

This program is distributed in the hope that it will be useful, but
without any warranty; without even the implied

=cut

# Required by Perl to load the module.
1;
