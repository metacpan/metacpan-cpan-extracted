#!/usr/local/bin/perl
BEGIN
{
    use strict;
    use warnings;
    use lib './lib';
    use open ':std' => ':utf8';
    use vars qw( $DEBUG );
    use Test2::V0;
    # 2021-11-1T167:12:10+0900
    use Test::Time time => 1635754330;
    use ok( 'Apache2::API::DateTime' );
    use ok( 'DateTime' ) || bail_out( "No DateTime module installed" );
    our $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
    require( "./t/env.pl" ) if( -e( "t/env.pl" ) );
};

use strict;
use warnings;

my $fmt = Apache2::API::DateTime->new;
isa_ok( $fmt, 'Apache2::API::DateTime' );

# To generate this list:
# perl -lnE '/^sub (?!init|[A-Z]|_)/ and say "can_ok( \$fmt, \''", [split(/\s+/, $_)]->[1], "\'' );"' ./lib/Apache2/API/DateTime.pm
can_ok( $fmt, 'format_datetime' );
can_ok( $fmt, 'parse_date' );
can_ok( $fmt, 'parse_datetime' );
can_ok( $fmt, 'str2datetime' );
can_ok( $fmt, 'str2time' );
can_ok( $fmt, 'time2datetime' );
can_ok( $fmt, 'time2str' );

my $dt = DateTime->now;
$dt->set_formatter( $fmt );
is( $dt->stringify, 'Mon, 01 Nov 2021 08:12:10 GMT', 'format_datetime' );
my @tests = (
    ['Mon, 01 Nov 2021 08:12:10 GMT','2021-11-01T08:12:10','rfc822/rfc1123 format'],
    ['Monday, 01-Nov-21 08:12:10 GMT','2021-11-01T08:12:10','rfc1036'],
    ['Mon Nov  1 08:12:10 2021','2021-11-01T08:12:10','ANSI C asctime'],
    ['01 Nov 2021 08:12:10 GMT','2021-11-01T08:12:10','rfc7231'],
    ['2021-11-01T08:12:10','2021-11-01T08:12:10','iso8601'],
    ['2021-11-01 08:12:10','2021-11-01T08:12:10','iso8601'],
);

foreach my $t ( @tests )
{
    my $dt = $fmt->parse_datetime( $t->[0] );
    if( !defined( $dt ) )
    {
        fail( $t->[2] . ': ' . $t->[0] . ' -> ' . $t->[1] . ': ' . $fmt->error );
        next;
    }
    is( $t->[1] => $dt->iso8601, $t->[2] );
}

done_testing();

__END__

