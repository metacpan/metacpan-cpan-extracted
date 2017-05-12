#!/usr/bin/perl
use strict;
use warnings;

use Test::More 'no_plan';

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
my $class  = 'ConfigReader::Simple';
my $method = '_validate_keys';

use_ok( $class );
can_ok( $class, $method );

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Test that it works if validkeys is not set
{
my $config = bless {}, $class; # a mock, nothing set

ok( $config->$method(), "$method returns true without validkeys set" );
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Test that it works if validkeys is set, but not an array reference
{
my $config = bless { validkeys => 4 }, $class; # a mock, nothing set

eval { $config->$method() };
my $at = $@;
ok( length $at, 'eval fails when validkeys is not an aray ref' );
like( $at, qr/not an array reference/, "Passing non array ref fails" );
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Test that it works if validkeys is set, but missing in config
{
my $config = bless { validkeys => [ qw(Buster) ] }, $class; # a mock, nothing set

eval { $config->$method() };
my $at = $@;
ok( length $at, 'eval fails when Buster directive is missing' );
like( $at, qr/do not occur/, "Missing key fails" );
}