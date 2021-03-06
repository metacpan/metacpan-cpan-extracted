#!/usr/local/bin/perl
BEGIN
{
    ## use Test::More qw( no_plan );
    use Test::More;
    use lib './lib';
    require( "./t/functions.pl" ) || BAIL_OUT( "Unable to find library \"functions.pl\"." );
    our $BASE_URI;
    use_ok( 'Apache2::SSI::File' ) || BAIL_OUT( "Unable to load Apache2::SSI" );
    use_ok( 'Module::Generic' ) || BAIL_OUT( "Unable to load Module::Generic" );
    our $DEBUG = 0;
};

diag( "Test include file is ./t/htdocs${BASE_URI}/include.01.txt" ) if( $DEBUG );
my $inc = Apache2::SSI::File->new( "./t/htdocs${BASE_URI}/include.01.txt" );
my $inc_size = Module::Generic::Number->new( $inc->finfo->size );
my $size_formatted = $inc_size < 1024 ? $inc_size : $inc_size->format_bytes;

my $tests =
[
    {
        expect => <<EOT,

This file size is ${size_formatted}
EOT
        name => 'abbrev',
        uri => "${BASE_URI}/08.01.fsize.html",
        code => 200,
    },
    {
        expect => <<EOT,

This file size is ${inc_size}
EOT
        name => 'bytes',
        uri => "${BASE_URI}/08.02.fsize.html",
        code => 200,
    },
];

run_tests( $tests,
{
    debug => $DEBUG,
    type => 'fsize',
    total_tests => 2,
});

