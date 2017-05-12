#!/usr/bin/perl
use strict;
use warnings;

use Test::More 'no_plan';

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#
my $class  = 'ConfigReader::Simple';
my $method = 'parse_string';

use_ok( $class );
can_ok( $class, $method );

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#
{
my $string = <<"HERE";
cat Buster
dog \\
	Tuffy
bird Poppy
# comment = hello
kitty \\
	Mimi
HERE

my $config = $class->new();

$config->parse_string( \$string );

is( $config->get( "cat" ),    "Buster"  );
is( $config->get( "kitty" ),  "Mimi"    );
is( $config->get( "dog" ),    "Tuffy"   );
is( $config->get( "bird" ),    "Poppy"  );
is( $config->get( "comment" ), undef    );
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#
