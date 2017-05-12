#!perl 

use strict;
use warnings;
use Test::More "no_plan";
use Benchmark::Stopwatch::Pause;

#-----------------------------------------------------------------
# Benchmark::Stopwatch::Pause
#-----------------------------------------------------------------

can_ok('Benchmark::Stopwatch::Pause',qw{ 
   start
   lap
   pause
   unpause
   summary
   as_data
   as_unpaused_data
});


my $obj = Benchmark::Stopwatch::Pause->new();
isa_ok($obj, 'Benchmark::Stopwatch::Pause', 'new() does create a Benchmark::Stopwatch::Pause object');


#-----------------------------------------------------------------
# start
#-----------------------------------------------------------------

ok($obj->start,'[start]');

#-----------------------------------------------------------------
# lap
#-----------------------------------------------------------------

ok($obj->lap('test1'),'[lap]');

#-----------------------------------------------------------------
# pause
#-----------------------------------------------------------------

ok($obj->pause,'[pause]');

#-----------------------------------------------------------------
# unpause
#-----------------------------------------------------------------

ok($obj->unpause('pause1'),'[unpause]');

#-----------------------------------------------------------------
# stop
#-----------------------------------------------------------------

ok($obj->stop,'[stop]');

#-----------------------------------------------------------------
# summary
#-----------------------------------------------------------------

ok(my $summary = $obj->summary,'[summary]');
like($summary, '/_start_/', '[summary] has a start element');
like($summary, '/test1/', '[summary] has a test1 element');
like($summary, '/pause1/', '[summary] has a pause1 element');

#-----------------------------------------------------------------
# as_data
#-----------------------------------------------------------------

ok(my $data = $obj->as_data,'[as_data]');
is(ref($data), 'HASH', '[as_data] is a hash ref');
is(scalar(@{$data->{laps}}), 4, '[as_data] correct number of laps recorded');
is($data->{laps}->[0]->{name}, '_start_', '[as_data] the first element in the laps array is start');
is($data->{laps}->[1]->{name}, 'test1', '[as_data] the first element in the laps array is test1');
is($data->{laps}->[2]->{name}, 'pause', '[as_data] the first element in the laps array is pause');
ok($data->{laps}->[2]->{pause}, '[as_data] our pause is really a pause lap not just labled as such');
is($data->{laps}->[3]->{name}, 'pause1', '[as_data] the first element in the laps array is pause1');

#---------------------------------------------------------------------------
#  as_unpaused_data
#---------------------------------------------------------------------------

ok( my $d2 = $obj->as_unpaused_data, '[as_unpaused_data]' );
is( scalar( @{ $d2->{laps} } ), 3, '[as_unpaused_data] right count' );
