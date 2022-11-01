#!/usr/local/bin/perl
BEGIN
{
    use strict;
    use warnings;
    # use Test::More qw( no_plan );
    use Test::More;
    use lib './lib';
    use vars qw( $BASE_URI $DEBUG );
    require( "./t/functions.pl" ) || BAIL_OUT( "Unable to find library \"functions.pl\"." );
    our $BASE_URI;
    use_ok( 'Apache2::SSI::File' ) || BAIL_OUT( "Unable to load Apache2::SSI" );
    use_ok( 'Module::Generic' ) || BAIL_OUT( "Unable to load Module::Generic" );
    use_ok( 'Module::Generic::Number' ) || BAIL_OUT( "Unable to load Module::Generic::Number" );
    our $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
};

use strict;
use warnings;

diag( "Test include file is ./t/htdocs${BASE_URI}/include.01.txt" ) if( $DEBUG );
my $inc = Apache2::SSI::File->new( "./t/htdocs${BASE_URI}/include.01.txt", debug => $DEBUG );
my $inc_size = Module::Generic::Number->new( $inc->finfo->size );
my $size_formatted = $inc_size < 1024 ? $inc_size : $inc_size->format_bytes;

my $tests =
[
    {
        expect => qr/^[[:blank:]\h\v]*This file size is ${size_formatted}/,
        name => 'abbrev',
        uri => "${BASE_URI}/08.01.fsize.html",
        code => 200,
    },
    {
        expect => qr/^[[:blank:]\h\v]*This file size is ${inc_size}/,
        name => 'bytes',
        uri => "${BASE_URI}/08.02.fsize.html",
        code => 200,
    },
];

run_tests( $tests,
{
    debug => $DEBUG,
    type => 'fsize',
    total_tests => 3,
});

