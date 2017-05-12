#!/usr/bin/perl
use strict;
use warnings;

use Test::More 'no_plan';

use Data::Dumper;
use File::Spec;

my $null_file = File::Spec->devnull;

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
my $class  = 'ConfigReader::Simple';
my $method = '_save';

use_ok( $class );
can_ok( $class, $method );

my $config = $class->new_string(
	Strings => [ \ 'Cat Buster' ]
	);
isa_ok( $config, $class );

is( $config->get( 'Cat' ), 'Buster' );

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Test _save without a list of directives. It should fail
{
my $rc = $config->_save( $null_file );
ok( ! $rc, "return value is false without list of directives" );
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Test _save with list of directives, but not as an array ref
{
my $rc = $config->_save( $null_file, 'Cat' );
ok( ! $rc, "return value is false without list of directives" );
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Test _save with a file name I can't open. Should fail
{
my $filename = "/a/b/c/d/e/f/1/2/3/4/5/buster";

my $rc = $config->_save( $filename, [ qw( Cat ) ] );
ok( ! $rc, "return value is false without list of directives" );
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Test _save with a file name I can open. Should work
{
my $rc = $config->_save( $null_file, [ qw(Cat) ] );
ok( $rc, "return value is true without list of directives" );
}