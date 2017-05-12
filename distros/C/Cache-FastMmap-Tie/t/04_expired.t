use strict;
use Data::Dumper;
use Test::More tests => 16;
#use Test::More qw(no_plan); 

my $DEBUG = 1;

BEGIN { use_ok 'Cache::FastMmap::Tie' }

ok(my $fc = tie my %h, 'Cache::FastMmap::Tie', 
	(
        'cache_size' => '10m',
        'expire_time' => '1m'
	)
);

ok(not(exists $h{AAA}) , 'not(exists $h{AAA})' . __LINE__);
ok(not(keys %h), 'not(keys %h)' . __LINE__);

is(do { $h{BBB}=undef; exists $h{BBB}}, 1 , '$h{BBB}=undef; exists $h{BBB}');
is(not($h{BBB}) , 1 , 'not($h{BBB}) ' . __LINE__);
ok((exists $h{BBB}) , '(exists $h{BBB})' . __LINE__);
is_deeply(["BBB"] ,[keys %h], '["BBB"] is_deeply [keys %h]' . __LINE__);
sleep_print(50);
ok((exists $h{BBB}) , '(exists $h{BBB})' . __LINE__);
is_deeply(["BBB"] ,[keys %h], '["BBB"] is_deeply [keys %h]' . __LINE__);
sleep_print(7);
ok( (exists $h{BBB}) , 'not(exists $h{BBB})' . __LINE__);
is_deeply(["BBB"] ,[keys %h], '["BBB"] is_deeply [keys %h]' . __LINE__);


sleep_print(5);
ok(not(exists $h{BBB}) , 'not(exists $h{BBB})' . __LINE__);
isnt(Dumper(["BBB"]) ,Dumper([keys %h]), '["BBB"] isnt [keys %h]' . __LINE__);
sleep_print(1);
ok(not(exists $h{BBB}) , 'not(exists $h{BBB})' . __LINE__);
isnt(Dumper(["BBB"]) ,Dumper([keys %h]), '["BBB"] isnt [keys %h]' . __LINE__);

### 

sub sleep_print {
	my $s = shift;
	my $c = 0;
	$DEBUG and printf "Please wait a little.. (%ds); ", $s;
	for ( 1 .. $s ) {
		$c++;
		sleep 1;
		$c =~ /\d$/;
		$DEBUG and print $& == 0 ? ',' : '.';
	}
	$DEBUG and print "\n";
}


