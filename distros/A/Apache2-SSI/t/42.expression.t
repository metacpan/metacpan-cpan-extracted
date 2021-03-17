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
        expect => qr/^[[:blank:]\h\v]*Regular expression matched\!/,
        name => 'regex',
        uri => "${BASE_URI}/10.01.expr.html",
        code => 200,
        headers => {
            Cookie => q{sitePrefs=%7B%22lang%22%3A%22en-GB%22%7D}
        },
    },
    {
        expect => qr/^[[:blank:]\h\v]*It worked, no content language found\./,
        name => 'Negative length variable',
        uri => "${BASE_URI}/10.02.expr.html",
        code => 200,
    },
    {
        expect => qr/^[[:blank:]\h\v]*Ok,[[:blank:]]+found[[:blank:]]+request[[:blank:]]+method\b/,
        name => 'String comparison',
        uri => "${BASE_URI}/10.03.expr.html",
        code => 200,
        headers =>
        {
        'User-Agent' => q{Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:86.0) Gecko/20100101 Firefox/86.0},
        }
    },
    {
        expect => qr/^[[:blank:]\h\v]*Ok, found DNT\./,
        name => 'Integer comparison',
        uri => "${BASE_URI}/10.04.expr.html",
        code => 200,
        headers =>
        {
        DNT => 1,
        },
    },
    {
        expect => qr/^[[:blank:]\h\v]*Yes, this string is empty\./,
        name => 'Empty string check',
        uri => "${BASE_URI}/10.05.expr.html",
        code => 200,
    },
    {
        expect => qr/^[[:blank:]\h\v]*Found the ip in the list\./,
        name => 'String in list (using function)',
        uri => "${BASE_URI}/10.06.expr.html",
        code => 200,
    },
];

run_tests( $tests,
{
    debug => $DEBUG,
    type => 'expression',
    total_tests => 2,
});

