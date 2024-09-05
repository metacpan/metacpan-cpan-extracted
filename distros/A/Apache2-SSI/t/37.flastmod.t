#!/usr/local/bin/perl
BEGIN
{
    use strict;
    use warnings;
    use Test::More qw( no_plan );
    use lib './lib';
    use vars qw( $BASE_URI $DEBUG );
    require( "./t/functions.pl" ) || BAIL_OUT( "Unable to find library \"functions.pl\"." );
    our $BASE_URI;
    use DateTime;
    use DateTime::Format::Strptime;
    our $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
};

use strict;
use warnings;

my( $inc_ts, $me_ts, $year );
local $@;
# try-catch
eval
{
    my $dt = DateTime->now( time_zone => 'local' );
    $year = $dt->year;
    my $inc = "./t/htdocs${BASE_URI}/include.01.txt";
    ## diag( "File $inc last modified time is ", $inc->stat->mtime, " (", scalar( localtime( $inc->stat->mtime ) ), ")." );
    $inc_ts = DateTime->from_epoch( epoch => (CORE::stat( $inc ))[9], time_zone => 'local' );
    my $params =
    {
        pattern => '%A %B %d, %Y',
        time_zone => 'local',
    };
    $params->{locale} = $ENV{lang} if( length( $ENV{lang} ) );
    my $fmt = DateTime::Format::Strptime->new( %$params );
    $inc_ts->set_formatter( $fmt );
    my $me = "./t/htdocs${BASE_URI}/07.03.flastmod.html";
    $me_ts = DateTime->from_epoch( epoch => (CORE::stat( $me ))[9], time_zone => 'local' );
    my $fmt2 = DateTime::Format::Strptime->new(
        pattern => '%D',
        time_zone => 'local',
        locale => 'en_US',
    );
    $me_ts->set_formatter( $fmt2 );
    diag( __FILE__, " last modification date time is '$me_ts'." ) if( $DEBUG );
};
if( $@ )
{
    BAIL_OUT( $@ );
}

my $tests =
[
    {
        expect => qr/^[[:blank:]\h\v]*This file last modified ${inc_ts}/,
        name => 'with time format preset',
        uri => "${BASE_URI}/07.01.flastmod.html",
        code => 200,
    },
    {
        expect => qr/^[[:blank:]\h\v]*Year\: ${year}/,
        name => 'using DATE_LOCAL',
        uri => "${BASE_URI}/07.02.flastmod.html",
        code => 200,
    },
    {
        expect => qr/^[[:blank:]\h\v]*This file last modified ${me_ts}/,
        name => 'using LAST_MODIFIED',
        uri => "${BASE_URI}/07.03.flastmod.html",
        code => 200,
    },
];

run_tests( $tests,
{
    debug => 0,
    type => 'flastmod',
});

