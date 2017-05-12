package LocalTest;

use strict;
use warnings;

use Carp;
use Data::Dump;
use Data::Validate::Type;
use Test::Exception;
use Test::More;


=head1 NAME

LocalTest - Test data and functions for L<Data::Validate::Type>.


=head1 VERSION

Version 1.6.0

=cut

our $VERSION = '1.6.0';


=head1 SYNOPSIS

	my $tests = LocalTest::get_tests();


=head1 DESCRIPTION

=cut

my $test_data =
[
	{
		key         => 'undef',
		data        => undef,
	},
	{
		key         => 'empty_hashref',
		data        => {},
	},
	{
		key         => 'non_empty_hashref',
		data        => { foo => 1 },
	},
	{
		key         => 'unnamed_subroutine',
		data        => sub () { 1 },
	},
	{
		key         => 'empty_arrayref',
		data        => [],
	},
	{
		key         => 'non_empty_arrayref',
		data        => [ 1, 2, 3 ],
	},
	{
		key         => 'empty_string_ref',
		data        => \"",
	},
	{
		key         => 'string_ref',
		data        => \"foo",
	},
	{
		key         => 'empty_string',
		data        => '',
	},
	{
		key         => 'zero',
		data        => 0,
	},
	{
		key         => 'one',
		data        => 1,
	},
	{
		key         => 'string',
		data        => 'a test string',
	},
	{
		key         => 'blessed_arrayref',
		data        => bless(
			[ 1, 2, 3 ],
			'TestArrayBless',
		),
	},
	{
		key         => 'blessed_hashref',
		data        => bless(
			{
				'key' => 'value'
			},
			'TestHashBless',
		),
	},
	{
		key         => 'strictly_positive_integer',
		data        => 10,
	},
	{
		key         => 'strictly_negative_integer',
		data        => -10,
	},
	{
		key         => 'strictly_positive_float',
		data        => 10.12345678,
	},
	{
		key         => 'strictly_negative_float',
		data        => -10.12345678,
	},
	{
		key         => 'arrayref_of_hashrefs',
		data        =>
		[
			{},
			{
				test => 1,
			},
			bless(
				{
					'key' => 'value',
				},
				'TestHashBless',
			),
		],
	},
	{
		key         => 'arrayref_of_mixed_data',
		data        =>
		[
			{},
			{
				test => 1,
			},
			[],
		],
	},
	{
		key         => 'regex',
		data        => qr/test/,
	},
	{
		key         => 'empty_regex',
		data        => qr/test/,
	},
];


=head1 FUNCTIONS

=head2 get_tests()

Return the test cases available.

	my $tests = LocalTest::get_tests();

=cut

sub get_tests
{
	return $test_data;
}


=head2 ok_run_tests()

Run the tests for a given function and type.

	LocalTest::ok_run_tests(
		function_name => 'is_string',
		type          => 'boolean',
		function_args =>
		{
			allow_empty => 1,
		},
		pass_tests    =>
		[
			qw(
				empty_string
				zero
				one
				string
				strictly_positive_integer
				strictly_negative_integer
				strictly_positive_float
				strictly_negative_float
			)
		],
	);

Parameters:

=over 4

=item * function_name

The name of the function to test. Must be a valid function of C<Data::Validate::Type>.

=item * type

The type of the function. Accepted values are 'boolean', 'assert', and 'filter'.
It is important to set this properly, otherwise the test function won't know
how to evaluate the output of the function tested.

=item * function_args

A hashref of arguments to pass to the function to test when executing the calls
to it.

=item * pass_tests

The arrayref of test cases that the function to test is expected to pass. See
C<LocalTest::get_tests()> for a list of all the test cases available. By
extension, all the test cases not listed in this list are expected to fail.

=back

=cut

sub ok_run_tests
{
	my ( %args ) = @_;
	my $function_name = delete( $args{'function_name'} );
	my $function_args = delete( $args{'function_args'} ) || {};
	my $type = delete( $args{'type'} );
	my $pass_tests = delete( $args{'pass_tests'} );

	# Verify parameters.
	croak "The argument 'function_name' must be defined"
		if !defined( $function_name ) || $function_name eq '';
	croak "The argument 'type' must be defined"
		if !defined( $type ) || $type eq '';
	croak "The argument 'type' is not valid"
		if $type !~ /^(?:boolean|assert|filter)$/;
	croak "The argument 'pass_tests' must be defined"
		if !defined( $pass_tests );

	my $function = $Data::Validate::Type::{$function_name};

	my $tests = LocalTest::get_tests();
	unless ( Test::More->builder()->has_plan() )
	{
		plan(
			defined( $tests ) && scalar( @$tests ) != 0
				? ( tests => scalar( @$tests ) )
				: ( skip_all => 'No test cases found, cannot run tests.' )
		);
	}

	foreach my $test ( @$tests )
	{
		my $data = $test->{'data'};
		my $key = $test->{'key'};
		my $expected_success = scalar( grep { $_ eq $key } @$pass_tests ) != 0 ? 1 : 0;

		if ( $type eq 'boolean' )
		{
			is(
				$function->( $data, %$function_args ),
				$expected_success,
				"$function_name( " . Data::Dump::dump( $data ) . ' ) returns ' . ( $expected_success ? 'true' : 'false' ) . '.',
			) || diag( "Failed test '$key'." );
		}
		elsif ( $type eq 'assert' )
		{
			if ( $expected_success )
			{
				lives_ok(
					sub
					{
						$function->( $data, %$function_args );
					},
					"$function_name( " . Data::Dump::dump( $data ) . ' )',
				) || diag( "Failed test '$key'." );
			}
			else
			{
				dies_ok(
					sub
					{
						$function->( $data, %$function_args );
					},
					"$function_name( " . Data::Dump::dump( $data ) . ' )',
				) || diag( "Failed test '$key'." );
			}
		}
		elsif ( $type eq 'filter' )
		{
			is_deeply(
				$function->( $data, %$function_args ),
				$expected_success ? $data : undef,
				"$function_name( " . Data::Dump::dump( $data ) . ' )',
			) || diag( "Failed test '$key'." );
		}
	}

	return;
}


=head1 AUTHOR

Guillaume Aubert, C<< <aubertg at cpan.org> >>.


=head1 BUGS

Please report any bugs or feature requests through the web interface at
L<https://github.com/guillaumeaubert/Data-Validate-Type/issues>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

	perldoc LocalTest


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


=head1 COPYRIGHT & LICENSE

Copyright 2012-2017 Guillaume Aubert.

This code is free software; you can redistribute it and/or modify it under the
same terms as Perl 5 itself.

This program is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE. See the LICENSE file for more details.

=cut

1;
