package Data::Validate::Type;

use warnings;
use strict;

use base 'Exporter';

use Carp;
use Data::Dump qw();
use Scalar::Util qw();

my @boolean_functions_list = qw(
	is_string
	is_arrayref
	is_hashref
	is_coderef
	is_number
	is_instance
	is_regex
);

my @assertion_functions_list = qw(
	assert_string
	assert_arrayref
	assert_hashref
	assert_coderef
	assert_number
	assert_instance
	assert_regex
);

my @filtering_functions_list = qw(
	filter_string
	filter_arrayref
	filter_hashref
	filter_coderef
	filter_number
	filter_instance
	filter_regex
);

our @EXPORT_OK =
(
	@boolean_functions_list,
	@assertion_functions_list,
	@filtering_functions_list,
);
our %EXPORT_TAGS =
(
	boolean_tests => \@boolean_functions_list,
	assertions    => \@assertion_functions_list,
	filters       => \@filtering_functions_list,
	all           =>
	[
		@boolean_functions_list,
		@assertion_functions_list,
		@filtering_functions_list,
	],
);


=head1 NAME

Data::Validate::Type - Data type validation functions.


=head1 VERSION

Version 1.6.0

=cut

our $VERSION = '1.6.0';


=head1 SYNOPSIS

	# Call with explicit package name.
	use Data::Validate::Type;
	if ( Data::Validate::Type::is_string( 'test' ) )
	{
		# ...
	}

	# Import specific functions.
	use Data::Validate::Type qw( is_string );
	if ( is_string( 'test' ) )
	{
		# ...
	}

	# Import functions for a given paradigm.
	use Data::Validate::Type qw( :boolean_tests );
	if ( is_string( 'test' ) )
	{
		# ...
	}


=head1 DESCRIPTION

L<Params::Util> is a wonderful module, but suffers from a few drawbacks:

=over 4

=item * Function names start with an underscore, which is usually used to
indicate private functions.

=item * Function names are uppercase, which is usually used to indicate file
handles or constants.

=item * Function names don't pass PerlCritic's validation, making them
problematic to import.

=item * Functions use by default the convention that collection that collections
need to not be empty to be valid (see _ARRAY0/_ARRAY for example), which is
counter-intuitive.

=item * In Pure Perl mode, the functions are created via eval, which causes
issues for L<Devel::Cover> in taint mode.

=back

Those drawbacks are purely cosmetic and don't affect the usefulness of the
functions, except for the last one. This module used to encapsulate
L<Params::Util>, but I had to refactor it out to fix the issues with
L<Devel::Cover>.

Please note that I prefer long function names that are descriptive, to arcane
short ones. This increases readability, and the bulk of the typing can be
spared with the use of a good IDE like Padre.

Also, this is work in progress - There is more functions that should be added
here, if you need one in particular feel free to contact me.


=head1 BOOLEAN TEST FUNCTIONS

Functions in this group return a boolean to indicate whether the parameters
passed match the test(s) specified by the functions or not.

All the boolean functions can be imported at once in your namespace with the
following line:

	use Data::Validate::Type qw( :boolean_tests );


=head2 is_string()

Return a boolean indicating if the variable passed is a string.

	my $is_string = Data::Validate::Type::is_string( $variable );

Note: 0 and '' (empty string) are valid strings.

Parameters:

=over 4

=item * allow_empty

Boolean, default 1. Allow the string to be empty or not.

=back

=cut

sub is_string
{
	my ( $variable, %args ) = @_;

	# Check parameters.
	my $allow_empty = delete( $args{'allow_empty'} );
	$allow_empty = 1 unless defined( $allow_empty );
	croak 'Arguments not recognized: ' . Data::Dump::dump( %args )
		unless scalar( keys %args ) == 0;

	# Check variable.
	return 0 if !defined( $variable ) || ref( $variable );

	# Check length if we don't allow empty strings.
	return 0 if !$allow_empty && length( $variable ) == 0;

	return 1;
}


=head2 is_arrayref()

Return a boolean indicating if the variable passed is an arrayref that can be
dereferenced into an array.

	my $is_arrayref = Data::Validate::Type::is_arrayref( $variable );

	my $is_arrayref = Data::Validate::Type::is_arrayref(
		$variable,
		allow_empty => 1,
		no_blessing => 0,
	);

	# Check if the variable is an arrayref of hashrefs.
	my $is_arrayref = Data::Validate::Type::is_arrayref(
		$variable,
		allow_empty           => 1,
		no_blessing           => 0,
		element_validate_type =>
			sub
			{
				return Data::Validate::Type::is_hashref( $_[0] );
			},
	);

Parameters:

=over 4

=item * allow_empty

Boolean, default 1. Allow the array to be empty or not.

=item * no_blessing

Boolean, default 0. Require that the variable is not blessed.

=item * element_validate_type

None by default. Set it to a coderef to validate the elements in the array.
The coderef will be passed the element to validate as first parameter, and it
must return a boolean indicating whether the element was valid or not.

=back

=cut

sub is_arrayref
{
	my ( $variable, %args ) = @_;

	# Check parameters.
	my $allow_empty = delete( $args{'allow_empty'} );
	$allow_empty = 1 unless defined( $allow_empty );
	my $no_blessing = delete( $args{'no_blessing'} ) || 0;
	my $element_validate_type = delete( $args{'element_validate_type'} );
	croak '"element_validate_type" must be a coderef'
		if defined( $element_validate_type ) && !is_coderef( $element_validate_type );
	croak 'Arguments not recognized: ' . Data::Dump::dump( %args )
		unless scalar( keys %args ) == 0;

	# Check variable.
	return 0 if !defined( $variable ) || !ref( $variable );

	if ( $no_blessing )
	{
		# The variable must be a standard arrayref.
		return 0 if ref( $variable ) ne 'ARRAY';
	}
	else
	{
		# Check that the variable is either an array or allows
		# dereferencing as one.
		return 0 if !
			(
				( Scalar::Util::reftype( $variable ) eq 'ARRAY' )
				|| overload::Method( $variable, '@{}' )
			);
	}

	# Check size of the array if we require a non-empty array.
	return 0 if !$allow_empty && scalar( @$variable ) == 0;

	# If we have an element validator specified, now that we know that we have
	# an array, it's a good time to test the individual elements.
	if ( defined( $element_validate_type ) )
	{
		foreach my $element ( @$variable )
		{
			return 0 if !$element_validate_type->( $element );
		}
	}

	return 1;
}


=head2 is_hashref()

Return a boolean indicating if the variable passed is a hashref that can be
dereferenced into a hash.

	my $is_hashref = Data::Validate::Type::is_hashref( $variable );

	my $is_hashref = Data::Validate::Type::is_hashref(
		$variable,
		allow_empty => 1,
		no_blessing => 0,
	);

Parameters:

=over 4

=item * allow_empty

Boolean, default 1. Allow the array to be empty or not.

=item * no_blessing

Boolean, default 0. Require that the variable is not blessed.

=back

=cut

sub is_hashref
{
	my ( $variable, %args ) = @_;

	# Check parameters.
	my $allow_empty = delete( $args{'allow_empty'} );
	$allow_empty = 1 unless defined( $allow_empty );
	my $no_blessing = delete( $args{'no_blessing'} ) || 0;
	croak 'Arguments not recognized: ' . Data::Dump::dump( %args )
		unless scalar( keys %args ) == 0;

	# Check variable.
	return 0 if !defined( $variable ) || !ref( $variable );

	if ( $no_blessing )
	{
		# The variable must be a standard hashref.
		return 0 if ref( $variable ) ne 'HASH';
	}
	else
	{
		# Check that the variable is either a hashref or allows dereferencing
		# as one.
		return 0 if !
			(
				( Scalar::Util::reftype( $variable ) eq 'HASH' )
				|| overload::Method( $variable, '%{}' )
			);
	}

	# If we don't allow empty hashes, check keys.
	return 0 if !$allow_empty && scalar( keys %$variable ) == 0;

	return 1;
}


=head2 is_coderef()

Return a boolean indicating if the variable passed is an coderef that can be
dereferenced into a block of code.

	my $is_coderef = Data::Validate::Type::is_coderef( $variable );

=cut

sub is_coderef
{
	my ( $variable, %args ) = @_;

	# Check parameters.
	croak 'Arguments not recognized: ' . Data::Dump::dump( %args )
		unless scalar( keys %args ) == 0;

	# Check variable.
	return 0 if !defined( $variable ) || !ref( $variable );
	return 0 if ref( $variable ) ne 'CODE';

	return 1;
}


=head2 is_number()

Return a boolean indicating if the variable passed is a number.

	my $is_number = Data::Validate::Type::is_number( $variable );
	my $is_number = Data::Validate::Type::is_number(
		$variable,
		positive => 1,
	);
	my $is_number = Data::Validate::Type::is_number(
		$variable,
		strictly_positive => 1,
	);

Parameters:

=over 4

=item * strictly_positive

Boolean, default 0. Set to 1 to check for a strictly positive number.

=item * positive

Boolean, default 0. Set to 1 to check for a positive number.

=back

=cut

sub is_number
{
	my ( $variable, %args ) = @_;

	# Check parameters.
	my $positive = delete( $args{'positive'} ) || 0;
	my $strictly_positive = delete( $args{'strictly_positive'} ) || 0;
	croak 'Arguments not recognized: ' . Data::Dump::dump( %args )
		unless scalar( keys %args ) == 0;

	# Check variable.
	return 0 if !defined( $variable ) || ref( $variable );

	# Requires Scalar::Util v1.18 or higher.
	return 0 if !Scalar::Util::looks_like_number( $variable );

	# Check extra restrictions.
	return 0 if $positive && $variable < 0;
	return 0 if $strictly_positive && $variable <= 0;

	return 1;
}


=head2 is_instance()

Return a boolean indicating if the variable is an instance of the given class.

Note that this handles inheritance properly, so it will return true if the
variable is an instance of a subclass of the class given.

	my $is_instance = Data::Validate::Type::is_instance(
		$variable,
		class => $class,
	);

Parameters:

=over 4

=item * class

Required, the name of the class to check the variable against.

=back

=cut

sub is_instance
{
	my ( $variable, %args ) = @_;

	# Check parameters.
	my $class = delete( $args{'class'} );
	croak 'A class argument is required'
		if !defined( $class ) || $class eq '';
	croak 'Arguments not recognized: ' . Data::Dump::dump( %args )
		unless scalar( keys %args ) == 0;

	# Check variable.
	return 0 if !defined( $variable ) || !Scalar::Util::blessed( $variable );

	# Test that the object is a member if the class.
	return 0 if !$variable->isa( $class );

	return 1;
}


=head2 is_regex()

Return a boolean indicating if the variable is a regular expression.

	my $is_regex = Data::Validate::Type::is_regex( $variable );

=cut

sub is_regex
{
	my ( $variable ) = @_;

	# Check variable.
	return defined( $variable ) && ( ref( $variable ) eq 'Regexp' )
		? 1
		: 0;
}


=head1 ASSERTION-BASED FUNCTIONS

Functions in this group do not return anything, but will die when the parameters
passed don't match the test(s) specified by the functions.

All the assertion test functions can be imported at once in your namespace with
the following line:

	use Data::Validate::Type qw( :assertions );


=head2 assert_string()

Die unless the variable passed is a string.

	Data::Validate::Type::assert_string( $variable );

Note: 0 and '' (empty string) are valid strings.

Parameters:

=over 4

=item * allow_empty

Boolean, default 1. Allow the string to be empty or not.

=back

=cut

sub assert_string
{
	my ( $variable, %args ) = @_;

	croak 'Not a string'
		unless is_string( $variable, %args );

	return;
}


=head2 assert_arrayref()

Die unless the variable passed is an arrayref that can be dereferenced into an
array.

	Data::Validate::Type::assert_arrayref( $variable );

	Data::Validate::Type::assert_arrayref(
		$variable,
		allow_empty => 1,
		no_blessing => 0,
	);

	# Require the variable to be an arrayref of hashrefs.
	Data::Validate::Type::assert_arrayref(
		$variable,
		allow_empty           => 1,
		no_blessing           => 0,
		element_validate_type =>
			sub
			{
				return Data::Validate::Type::is_hashref( $_[0] );
			},
	);

Parameters:

=over 4

=item * allow_empty

Boolean, default 1. Allow the array to be empty or not.

=item * no_blessing

Boolean, default 0. Require that the variable is not blessed.

=item * element_validate_type

None by default. Set it to a coderef to validate the elements in the array.
The coderef will be passed the element to validate as first parameter, and it
must return a boolean indicating whether the element was valid or not.

=back

=cut

sub assert_arrayref
{
	my ( $variable, %args ) = @_;

	croak 'Not an arrayref'
		unless is_arrayref( $variable, %args );

	return;
}


=head2 assert_hashref()

Die unless the variable passed is a hashref that can be dereferenced into a hash.

	Data::Validate::Type::assert_hashref( $variable );

	Data::Validate::Type::assert_hashref(
		$variable,
		allow_empty => 1,
		no_blessing => 0,
	);

Parameters:

=over 4

=item * allow_empty

Boolean, default 1. Allow the array to be empty or not.

=item * no_blessing

Boolean, default 0. Require that the variable is not blessed.

=back

=cut

sub assert_hashref
{
	my ( $variable, %args ) = @_;

	croak 'Not a hashref'
		unless is_hashref( $variable, %args );

	return;
}


=head2 assert_coderef()

Die unless the variable passed is an coderef that can be dereferenced into a
block of code.

	Data::Validate::Type::assert_coderef( $variable );

=cut

sub assert_coderef
{
	my ( $variable, %args ) = @_;

	croak 'Not a coderef'
		unless is_coderef( $variable, %args );

	return;
}


=head2 assert_number()

Die unless the variable passed is a number.

	Data::Validate::Type::assert_number( $variable );
	Data::Validate::Type::assert_number(
		$variable,
		positive => 1,
	);
	Data::Validate::Type::assert_number(
		$variable,
		strictly_positive => 1,
	);

Parameters:

=over 4

=item * strictly_positive

Boolean, default 0. Set to 1 to check for a strictly positive number.

=item * positive

Boolean, default 0. Set to 1 to check for a positive number.

=back

=cut

sub assert_number
{
	my ( $variable, %args ) = @_;

	croak 'Not a number'
		unless is_number( $variable, %args );

	return;
}


=head2 assert_instance()

Die unless the variable is an instance of the given class.

Note that this handles inheritance properly, so it will not die if the
variable is an instance of a subclass of the class given.

	Data::Validate::Type::assert_instance(
		$variable,
		class => $class,
	);

Parameters:

=over 4

=item * class

Required, the name of the class to check the variable against.

=back

=cut

sub assert_instance
{
	my ( $variable, %args ) = @_;

	croak 'Not an instance of the class'
		unless is_instance( $variable, %args );

	return;
}


=head2 assert_regex()

Die unless the variable is a regular expression.

	Data::Validate::Type::assert_regex( $variable );

=cut

sub assert_regex
{
	my ( $variable ) = @_;

	croak 'Not a regular expression'
		unless is_regex( $variable );

	return;
}


=head1 FILTERING FUNCTIONS

Functions in this group return the variable tested against when it matches the
test(s) specified by the functions.

All the filtering functions can be imported at once in your namespace with the
following line:

	use Data::Validate::Type qw( :filters );


=head2 filter_string()

Return the variable passed if it is a string, otherwise return undef.

	Data::Validate::Type::filter_string( $variable );

Note: 0 and '' (empty string) are valid strings.

Parameters:

=over 4

=item * allow_empty

Boolean, default 1. Allow the string to be empty or not.

=back

=cut

sub filter_string
{
	my ( $variable, %args ) = @_;

	return is_string( $variable, %args )
		? $variable
		: undef;
}


=head2 filter_arrayref()

Return the variable passed if it is an arrayref that can be dereferenced into an
array, otherwise undef.

	Data::Validate::Type::filter_arrayref( $variable );

	Data::Validate::Type::filter_arrayref(
		$variable,
		allow_empty => 1,
		no_blessing => 0,
	);

	# Only return the variable if it is an arrayref of hashrefs.
	Data::Validate::Type::filter_arrayref(
		$variable,
		allow_empty           => 1,
		no_blessing           => 0,
		element_validate_type =>
			sub
			{
				return Data::Validate::Type::is_hashref( $_[0] );
			},
	);

Parameters:

=over 4

=item * allow_empty

Boolean, default 1. Allow the array to be empty or not.

=item * no_blessing

Boolean, default 0. Require that the variable is not blessed.

=item * element_validate_type

None by default. Set it to a coderef to validate the elements in the array.
The coderef will be passed the element to validate as first parameter, and it
must return a boolean indicating whether the element was valid or not.

=back

=cut

sub filter_arrayref
{
	my ( $variable, %args ) = @_;

	return is_arrayref( $variable, %args )
		? $variable
		: undef;
}


=head2 filter_hashref()

Return the variable passed if it is a hashref that can be dereferenced into a
hash, otherwise return undef.

	Data::Validate::Type::filter_hashref( $variable );

	Data::Validate::Type::filter_hashref(
		$variable,
		allow_empty => 1,
		no_blessing => 0,
	);

Parameters:

=over 4

=item * allow_empty

Boolean, default 1. Allow the array to be empty or not.

=item * no_blessing

Boolean, default 0. Require that the variable is not blessed.

=back

=cut

sub filter_hashref
{
	my ( $variable, %args ) = @_;

	return is_hashref( $variable, %args )
		? $variable
		: undef;
}


=head2 filter_coderef()

Return the variable passed if it is a coderef that can be dereferenced into a
block of code, otherwise return undef.

	Data::Validate::Type::filter_coderef( $variable );

=cut

sub filter_coderef
{
	my ( $variable, %args ) = @_;

	return is_coderef( $variable, %args )
		? $variable
		: undef;
}


=head2 filter_number()

Return the variable passed if it is a number, otherwise return undef.

	Data::Validate::Type::filter_number( $variable );
	Data::Validate::Type::filter_number(
		$variable,
		positive => 1,
	);
	Data::Validate::Type::filter_number(
		$variable,
		strictly_positive => 1,
	);

Parameters:

=over 4

=item * strictly_positive

Boolean, default 0. Set to 1 to check for a strictly positive number.

=item * positive

Boolean, default 0. Set to 1 to check for a positive number.

=back

=cut

sub filter_number
{
	my ( $variable, %args ) = @_;

	return is_number( $variable, %args )
		? $variable
		: undef;
}


=head2 filter_instance()

Return the variable passed if it is an instance of the given class.

Note that this handles inheritance properly, so it will return the variable if
it is an instance of a subclass of the class given.

	Data::Validate::Type::filter_instance(
		$variable,
		class => $class,
	);

Parameters:

=over 4

=item * class

Required, the name of the class to check the variable against.

=back

=cut

sub filter_instance
{
	my ( $variable, %args ) = @_;

	return is_instance( $variable, %args )
		? $variable
		: undef;
}


=head2 filter_regex()

Return the variable passed if it is a regular expression.

	Data::Validate::Type::filter_regex( $variable );

=cut

sub filter_regex
{
	my ( $variable ) = @_;

	return is_regex( $variable )
		? $variable
		: undef;
}


=head1 BUGS

Please report any bugs or feature requests through the web interface at
L<https://github.com/guillaumeaubert/Data-Validate-Type/issues>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

	perldoc Data::Validate::Type


You can also look for information at:

=over 4

=item * GitHub (report bugs there)

L<https://github.com/guillaumeaubert/Data-Validate-Type/issues>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Data-Validate-Type>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Data-Validate-Type>

=item * MetaCPAN

L<https://metacpan.org/release/Data-Validate-Type>

=back


=head1 AUTHOR

L<Guillaume Aubert|https://metacpan.org/author/AUBERTG>,
C<< <aubertg at cpan.org> >>.


=head1 ACKNOWLEDGEMENTS

Thanks to Adam Kennedy for writing L<Params::Util>. This module started as an
encapsulation for Params::Util and I learnt quite a bit from it.


=head1 COPYRIGHT & LICENSE

Copyright 2012-2017 Guillaume Aubert.

This code is free software; you can redistribute it and/or modify it under the
same terms as Perl 5 itself.

This program is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE. See the LICENSE file for more details.

=cut

1;
