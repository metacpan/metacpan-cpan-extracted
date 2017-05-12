#!/usr/bin/perl
use strict;
use warnings;

use Test::More 'no_plan';

use File::Spec::Functions qw(catfile);

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
my $class  = 'ConfigReader::Simple';
my $method = 'add_config_file';

use_ok( $class );
can_ok( $class, $method );

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Test with a file that does not exist
{
my $filename = 'a/b/c';
ok( ! -e $filename, "Missing file is actually missing" );

my $mock = bless {}, $class;

is( $mock->$method( $filename ), undef, "$method with missing file fails" );
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Test with a file that isn't parseable
{
no warnings 'redefine';
no strict 'refs';
local *{ "${class}::parse" } = sub { 0 };

my $filename = catfile( qw(t example.config) );
ok( -e $filename, "$filename exists" );

my $mock = bless {}, $class;

is( $mock->$method( $filename ), undef, "$method with empty file fails" );
}