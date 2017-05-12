package Audit::DBI::Utils;

use strict;
use warnings;

use Carp;
use Class::Load;
use Data::Dumper;
use Data::Validate::Type;


=head1 NAME

Audit::DBI::Utils - Utilities for the Audit::DBI distribution.


=head1 VERSION

Version 1.9.0

=cut

our $VERSION = '1.9.0';


=head1 SYNOPSIS

	use Audit::DBI::Utils;

	my $ip_address = Audit::DBI::Utils::integer_to_ipv4( $integer );

	my $integer = Audit::DBI::Utils::ipv4_to_integer( $ip_address );

	my $differences = Audit::DBI::Utils::diff_structures(
		$data_structure_1,
		$data_structure_2,
		comparison_function => sub { my ( $a, $b ) = @_; $a eq $b; }, #optional
	);

	my $diff_string_bytes = Audit::DBI::Utils::get_diff_string_bytes(
		$differences
	);


=head1 FUNCTIONS

=head2 stringify_data_structure()

	my $string = Audit::DBI::Utils::stringify_data_structure(
		data_structure             => $data_structure,
		object_stringification_map =>
		{
			'Math::Currency' => 'as_float',
		},
	);

=cut

sub stringify_data_structure
{
	my ( %args ) = @_;
	my $data_structure = delete( $args{'data_structure'} );
	my $object_stringification_map = delete( $args{'object_stringification_map'} );
	croak 'The following arguments are not valid: ' . join( ', ', keys %args )
		if scalar( keys %args ) != 0;

	return _stringify_data_structure( $data_structure, $object_stringification_map );
}

sub _stringify_data_structure
{
	my ( $data_structure, $object_stringification_map ) = @_;

	if ( Data::Validate::Type::is_arrayref( $data_structure ) )
	{
		# If we have an array, try to stringify each of the elements.
		return
		[
			map { _stringify_data_structure( $_, $object_stringification_map ) } @$data_structure
		];
	}
	elsif ( Data::Validate::Type::is_hashref( $data_structure ) )
	{
		# First, we try to stringify this object.
		foreach my $class ( keys %$object_stringification_map )
		{
			next if !Data::Validate::Type::is_instance( $data_structure, class => $class );
			my $stringification_method = $object_stringification_map->{ $class };
			next if !$data_structure->can( $stringification_method );
			return $data_structure->$stringification_method();
		}

		# If we haven't found it in our list of stringifiable objects,
		# then we need to investigate the individual keys.
		return
		{
			map
				{ $_ => _stringify_data_structure( $data_structure->{ $_ }, $object_stringification_map ) }
				keys %$data_structure
		};
	}
	else
	{
		return $data_structure;
	}
}


=head2 integer_to_ipv4()

Convert a 32-bits integer representing an IP address into its IPv4 form.

	my $ip_address = Audit::DBI::Utils::integer_to_ipv4( $integer );

=cut

sub integer_to_ipv4
{
	my ( $integer ) = @_;

	return undef
		if !defined( $integer ) || $integer !~ m/^\d+$/;

	return join( '.', map { ( $integer >> 8 * ( 3 - $_ ) ) % 256 } 0..3 );
}


=head2 ipv4_to_integer()

Convert an IPv4 address to a 32-bit integer.

	my $integer = Audit::DBI::Utils::ipv4_to_integer( $ip_address );

=cut

sub ipv4_to_integer
{
	my ( $ip_address ) = @_;

	return undef
		if !defined( $ip_address );

	if ( my ( @bytes ) = $ip_address =~ m/^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$/x )
	{
		if ( ! grep { $_ > 255 } @bytes )
		{
			@bytes = reverse( @bytes );
			my $integer = 0;
			foreach my $exponent ( 0..3 )
			{
				$integer += $bytes[ $exponent ] * 256**$exponent;
			}
			return $integer;
		}
	}

	# Invalid input.
	return undef;
}


=head2 diff_structures()

Return the differences between the two data structures passed as parameter.

By default, if leaf nodes are compared with '==' if they are both numeric, and
with 'eq' otherwise.

An optional I<comparison_function> parameter can be used to specify a different
comparison function.

	my $differences = Audit::DBI::Utils::diff_structures(
		$data_structure_1,
		$data_structure_2,
	);

	# Alternative built-in comparison function.
	# Leaf nodes are compared using 'eq'.
	my $diff = Audit::DBI::Utils::diff_structures(
		$data_structure_1,
		$data_structure_2,
		comparison_function => 'eq',
	);

	# Alternative custom comparison function.
	my $diff = Audit::DBI::Utils::diff_structures(
		$data_structure_1,
		$data_structure_2,
		comparison_function => sub
		{
			my ( $variable_1, $variable2 ) = @_;
			# [...]
			return $is_equal;
		}
	);

=cut

sub diff_structures
{
	my ( @args ) = @_;
	return _diff_structures(
		{},
		@args
	);
}

sub _diff_structures_comparison_eq
{
	my ( $variable_1, $variable_2 ) = @_;

	return $variable_1 eq $variable_2;
}

sub _diff_structures_comparison_default
{
	my ( $variable_1, $variable_2 ) = @_;

	# For numbers, return numerical comparison.
	return $variable_1 == $variable_2
		if Scalar::Util::looks_like_number( $variable_1 ) && Scalar::Util::looks_like_number( $variable_2 );

	# Otherwise, use exact string match.
	return $variable_1 eq $variable_2;
}

sub _diff_structures
{
	my ( $cache, $structure1, $structure2, %args ) = @_;
	my $comparison_function = $args{'comparison_function'};

	# make sure the provided equality function is really a coderef
	if ( !Data::Validate::Type::is_coderef( $comparison_function ) )
	{
		if ( defined( $comparison_function ) && ( $comparison_function eq 'eq' ) )
		{
			$comparison_function = \&_diff_structures_comparison_eq;
		}
		else
		{
			$comparison_function = \&_diff_structures_comparison_default;
		}
	}

	# If one of the structure is undef, return
	if ( !defined( $structure1 ) || !defined( $structure2 ) )
	{
		if ( !defined( $structure1 ) && !defined( $structure2 ) )
		{
			return undef;
		}
		else
		{
			return
			{
				old => $structure1,
				new => $structure2
			};
		}
	}

	# Cache memory addresses to make sure we don't get into an infinite loop.
	# The idea comes from Test::Deep's code.
	return undef
		if exists( $cache->{ "$structure1" }->{ "$structure2" } );
	$cache->{ "$structure1" }->{ "$structure2" } = undef;

	# Hashes (including hashes blessed as objects)
	if ( Data::Validate::Type::is_hashref( $structure1 ) && Data::Validate::Type::is_hashref( $structure2 ) )
	{
		my %union_keys = map { $_ => undef } ( keys %$structure1, keys %$structure2 );

		my %tmp = ();
		foreach ( keys %union_keys )
		{
			my $diff = _diff_structures(
				$cache,
				$structure1->{$_},
				$structure2->{$_},
				%args,
			);
			$tmp{$_} = $diff
				if defined( $diff );
		}

		return ( scalar( keys %tmp ) != 0 ? \%tmp : undef );
	}

	# If the structures have different references, since we've ruled out blessed
	# hashes (objects) above (that could have a different blessing with the same
	# actual content), return the elements
	if ( ref( $structure1 ) ne ref( $structure2 ) )
	{
		return
		{
			old => $structure1,
			new => $structure2
		};
	}

	# Simple scalars, compare and return
	if ( ref( $structure1 ) eq '' )
	{
		return $comparison_function->( $structure1, $structure2 )
			? undef
			: {
				old => $structure1,
				new => $structure2
			};
	}

	# Arrays
	if ( Data::Validate::Type::is_arrayref( $structure1 ) )
	{
		my @tmp = ();
		my $max_length = ( sort { $a <=> $b } ( scalar( @$structure1 ), scalar( @$structure2 ) ) )[1];
		for my $i ( 0..$max_length-1 )
		{
			my $diff = _diff_structures(
				$cache,
				$structure1->[$i],
				$structure2->[$i],
				%args,
			);
			next unless defined( $diff );

			$diff->{'index'} = $i;
			push(
				@tmp,
				$diff
			);
		}

		return ( scalar( @tmp ) != 0 ? \@tmp : undef );
	}

	# We don't track other types for audit purposes
	return undef;
}


=head2 get_diff_string_bytes()

Return the size in bytes of the string differences. The argument must be a diff
structure returned by C<Audit::DBI::Utils::diff_structures()>.

This function has two modes:

=over 4

=item * Relative comparison (default):

In this case, a string change from 'TestABC' to 'TestCDE' is a 0 bytes
change (since there is the same number of characters).

	my $diff_string_bytes = Audit::DBI::Utils::get_diff_string_bytes(
		$diff_structure
	);

=item * Absolute comparison:

In this case, a string change from 'TestABC' to 'TestCDE' is a 6 bytes
change (3 characters removed, and 3 added).

	my $diff_string_bytes = Audit::DBI::Utils::get_diff_string_bytes(
		$diff_structure,
		absolute => 1,
	);

Note that absolute comparison requires L<String::Diff> to be installed.

=back

=cut

sub get_diff_string_bytes
{
	my ( $diff_structure, %args ) = @_;

	croak 'Cannot perform string comparison without String::Diff installed, please install first and then retry'
		if $args{'absolute'} && !Class::Load::try_load_class( 'String::Diff' );

	return _get_diff_string_bytes(
		{},
		$diff_structure,
		%args,
	);
}

sub _get_diff_string_bytes
{
	my ( $cache, $diff_structure, %args ) = @_;

	return 0
		if !defined( $diff_structure );

	# Cache memory addresses to make sure we don't get into an infinite loop.
	# The idea comes from Test::Deep's code.
	return undef
		if exists( $cache->{ "$diff_structure" } );
	$cache->{ "$diff_structure" } = undef;

	# A hash can mean that a hash had different keys, or this is a leaf node
	# indicating old/new data.
	if ( Data::Validate::Type::is_hashref( $diff_structure ) )
	{
		# If we have an 'old' and 'new' key, then it's a leaf node.
		if ( exists( $diff_structure->{'new'} ) && exists( $diff_structure->{'old'} ) )
		{
			# If we're performing an absolute comparison, we need to add the data removed
			# to the data added.
			if ( $args{'absolute'} )
			{
				# If both structures are not strings, it means we can't inspect
				# inside to do a finer grained comparison and we can only add their
				# respective sizes.
				return get_string_bytes( $diff_structure->{'new'} ) + get_string_bytes( $diff_structure->{'old'} )
					if !Data::Validate::Type::is_string( $diff_structure->{'new'} )
						|| !Data::Validate::Type::is_string( $diff_structure->{'old'} );

				# If both structures are strings however, then we can diff the
				# strings to find out exactly how much has changed.
				my $diff = String::Diff::diff_fully(
					$diff_structure->{'old'},
					$diff_structure->{'new'},
				);

				my $diff_string_bytes = 0;
				foreach my $line ( @{ $diff->[0] }, @{ $diff->[1] } )
				{
					if ( $line->[0] eq '+' )
					{
						$diff_string_bytes += get_string_bytes( $line->[1] );
					}
					elsif ( $line->[0] eq '-' )
					{
						$diff_string_bytes += get_string_bytes( $line->[1] );
					}
				}
				return $diff_string_bytes;
			}
			# If we're performing a relative comparison, we substract the data removed
			# from the data added.
			else
			{
				return get_string_bytes( $diff_structure->{'new'} ) - get_string_bytes( $diff_structure->{'old'} );
			}
		}
		# Otherwise, we need to explore inside the values.
		else
		{
			my $diff_string_bytes = 0;
			foreach my $value ( values %$diff_structure )
			{
				$diff_string_bytes += _get_diff_string_bytes( $cache, $value, %args );
			}
			return $diff_string_bytes;
		}
	}

	# If we have an array, loop through it.
	if ( Data::Validate::Type::is_arrayref( $diff_structure ) )
	{
		my $diff_string_bytes = 0;
		foreach my $element ( @$diff_structure )
		{
			$diff_string_bytes += _get_diff_string_bytes( $cache, $element, %args );
		}
		return $diff_string_bytes;
	}

	# The above parses entirely a diff structure, if anything didn't match
	# then the diff structure is not valid.
	local $Data::Dumper::Terse = 1;
	croak 'Invalid diff structure: ' . Dumper( $diff_structure );
}


=head2 get_string_bytes()

Return the size in bytes of all the strings contained in the data structure
passed as argument.

	my $string_bytes = Audit::DBI::Utils::get_string_bytes( 'Test' );

	my $string_bytes = Audit::DBI::Utils::get_string_bytes(
		[ 'Test1', 'Test2' ]
	);

	my $string_bytes = Audit::DBI::Utils::get_string_bytes(
		{ 'Test' => 1 }
	);

Note: this function is recursive, and will explore both arrayrefs and hashrefs.

=cut

sub get_string_bytes
{
	my ( $structure ) = @_;

	return _get_string_bytes(
		{},
		$structure,
	);
}


sub _get_string_bytes
{
	my ( $cache, $structure ) = @_;

	return 0
		if !defined( $structure );

	# Use bytes pragma to calculate the byte size of the strings correctly.
	use bytes;

	# Strings allow ending the recursion.
	if ( Data::Validate::Type::is_string( $structure ) )
	{
		return bytes::length( $structure );
	}

	# Cache memory addresses to make sure we don't get into an infinite loop.
	# If a loop is detected in the structure, we've counted the size of one
	# cycle at this point and we'll ignore the others.
	return 0 if defined( $cache->{ "$structure" } );
	$cache->{ "$structure" } = 1;

	# For hashrefs, we calculate the size of the keys and the values.
	if ( Data::Validate::Type::is_hashref( $structure ) )
	{
		my $size = 0;
		foreach my $data ( keys %$structure, values %$structure )
		{
			$size += _get_string_bytes( $cache, $data );
		}
		return $size;
	}

	# For arrayrefs, we calculate the size of each element.
	if ( Data::Validate::Type::is_arrayref( $structure ) )
	{
		my $size = 0;
		foreach my $data ( @$structure )
		{
			$size += _get_string_bytes( $cache, $data );
		}
		return $size;
	}

	# If it's not a string, an array, or a hash, we can't retrieve strings
	# from the data structure so we'll ignore it.
	return 0;
}


=head1 BUGS

Please report any bugs or feature requests through the web interface at
L<https://github.com/guillaumeaubert/Audit-DBI/issues/new>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Audit::DBI::Utils


You can also look for information at:

=over 4

=item * GitHub's request tracker

L<https://github.com/guillaumeaubert/Audit-DBI/issues>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Audit-DBI>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Audit-DBI>

=item * MetaCPAN

L<https://metacpan.org/release/Audit-DBI>

=back


=head1 AUTHOR

L<Guillaume Aubert|https://metacpan.org/author/AUBERTG>,
C<< <aubertg at cpan.org> >>.


=head1 COPYRIGHT & LICENSE

Copyright 2010-2017 Guillaume Aubert.

This code is free software; you can redistribute it and/or modify it under the
same terms as Perl 5 itself.

This program is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE. See the LICENSE file for more details.

=cut

1;
