#!perl -w

use strict;
use warnings;
use lib './lib';
use vars qw( $DEBUG );
$DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
use Test::More;
plan tests => 1;

use Data::Pretty;
local $Data::Pretty::DEBUG = $DEBUG;

print "# ";
dd getlogin;
ddx localtime;
ddx \%Exporter::;

ok(1);
