use strict;
#use Test::More tests => 10;
use Test::More qw(no_plan); 

BEGIN { use_ok 'Cache::FastMmap::Tie' }

ok(my $fc = tie my %h, 'Cache::FastMmap::Tie', );

ok(not(exists $h{AAA}) , 'not(exists $h{AAA})');
ok(not(keys %h), 'not(keys %h)');

is(do { $h{BBB}=undef; exists $h{BBB}}, 1 , '$h{BBB}=undef; exists $h{BBB}');

ok( not($h{BBB}) , 'not($h{BBB})');

is_deeply(["BBB"] ,[keys %h], '["BBB"] is_deeply [keys %h]');

