#!/usr/bin/perl
use strict;
use warnings;

use Test::More 'no_plan';

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
my $class  = 'ConfigReader::Simple';
my $method = 'new_string';

use_ok( $class );
can_ok( $class, $method );

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Test that it works with both Strings and Keys
# Has all valid keys
{
my $key = 'Cat';
my $cat = 'Buster';

my $config = $class->$method(
	Strings => [ \ "$key = $cat" ],
	Keys    => [ $key     ],
	);

isa_ok( $config, $class );

is( $config->get( $key ), $cat );
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Test that it works with only Strings
{
my $key = 'Cat';
my $cat = 'Mimi';

my $config = $class->$method(
	Strings => [ \ "$key = $cat" ],
	);

isa_ok( $config, $class );

is( $config->get( $key ), $cat );
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Test that it croaks with no arguments
{
eval { $class->$method() };
my $at = $@;
ok( defined $at, "$method fails with no arguments" );
like( $at, qr/must be an array reference/ );
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Test that it croaks with Strings containing a non-scalar ref
{
eval { $class->$method( Strings => [ 'Foo = Bar' ] ) };
my $at = $@;
ok( defined $at, "$method fails when string contains a non-reference" );
like( $at, qr/not a scalar reference/ );
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Test that it croaks when Strings value is not an array ref
{
eval { $class->$method( Strings => '', Keys => [] ) };
my $at = $@;
ok( defined $at, "$method fails when Keys value is the empty string" );
like( $at, qr/must be an array reference/ );
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Test that it croaks when Keys value is not an array ref
{
eval { $class->$method( Strings => [ ], Keys => '' ) };
my $at = $@;
ok( defined $at, "$method fails when Keys value is the empty string" );
like( $at, qr/must be an array reference/ );
}

