#!perl

use strict;
use warnings;
$|=1;

use Test::More;
use File::Spec;
use lib 't';
use CTWS_Testing;

if(CTWS_Testing::has_environment()) { plan tests    => 17; }
else                                { plan skip_all => "Environment not configured"; }

ok(  my $obj = CTWS_Testing::getObj(), "got object" );
isa_ok( $obj, 'CPAN::Testers::WWW::Statistics', "Parent object type" );

ok(  my $page = CTWS_Testing::getPages(), "got object" );
isa_ok( $page, 'CPAN::Testers::WWW::Statistics::Pages', "Pages object type" );

ok(  my $graph = CTWS_Testing::getGraphs(), "got object" );
isa_ok( $graph, 'CPAN::Testers::WWW::Statistics::Graphs', "Graphs object type" );

my $db = 't/_DBDIR/test.db';
isa_ok( $obj->{CPANSTATS},                      'CPAN::Testers::Common::DBUtils', 'CPANSTATS' );
is(     $obj->{CPANSTATS}->{driver},   'mysql', 'CPANSTATS.database' );

ok(    $obj->directory, 'directory' );
is(    $obj->directory, File::Spec->catfile('t', '_TMPDIR'), 'directory' );
ok( -d $obj->directory, 'directory exists' );


my @now = localtime(time);
my $date1 = sprintf "%04d%02d", $now[5]+1900, $now[4]; $date1++;
my $date2 = sprintf "%04d%02d", $now[5]+1900, $now[4];
my $date3 = sprintf "%04d%02d", $now[5]+1900, $now[4]; $date3--;

$date2 -= 88    if($date2 % 100 > 12 || $date2 % 100 < 1);
$date3 -= 88    if($date3 % 100 > 12 || $date3 % 100 < 1);

eval { $page->set_dates() };
is($page->{dates}{THISMONTH}, $date1, '..this month');
is($page->{dates}{LASTMONTH}, $date2, '..last month');
is($page->{dates}{THATMONTH}, $date3, '..previous month');

my @full_range = ( '00000000-99999999' );
my @test_range = ( '199901-200412', '200301-200712', '200601-201012', '200901-201312', "201201-$page->{dates}{LASTMONTH}" );

is($obj->ranges(), undef, '.. no range');
is_deeply($obj->ranges('NONE'), \@full_range, '.. single full range');
is_deeply($obj->ranges('TEST_RANGES'), \@test_range, '.. list of ranges');
