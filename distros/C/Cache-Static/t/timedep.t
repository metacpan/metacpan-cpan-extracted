#!/usr/bin/perl -w

#for when we are invoked from "make test"
use lib "t";

use strict;
use TEST;

print "1..10\n";
my $key = Cache::Static::make_key("timedep test key".int rand 99999);

### testing time|1s type deps
Cache::Static::set($key, "value", [ "time|1s" ]);
ok ( "1 second test, no time elapsed", 
	Cache::Static::get_if_same($key, [ "time|1s" ]) );

sleep(2);
ok ( "1 second test, time has elapsed", 
	!Cache::Static::get_if_same($key, [ "time|1s" ]) );

### testing a more complicated dep: time|0w0d0h0m1s
### this verifies the timespec parsing code
Cache::Static::set($key, "value", [ "time|0w0d0h0m1s" ]);
ok ( "complicated 1 second test, no time elapsed", 
	Cache::Static::get_if_same($key, [ "time|0w0d0h0m1s" ]) );

sleep(2);
ok ( "complicated 1 second test, time has elapsed", 
	!Cache::Static::get_if_same($key, [ "time|1s" ]) );

### testing time|M:15s type deps
my $sec = (localtime())[0];
my $offset = 1;
my $deadline = ($sec + $offset) % 60;

Cache::Static::set($key, "value", [ "time|M:${deadline}s" ]);
ok ( "Minute+offset test, no time elapsed",
	Cache::Static::get_if_same($key, [ "time|M:${deadline}s" ]) );

sleep($offset+1);
ok ( "Minute+offset test, time elapsed",
	!Cache::Static::get_if_same($key, [ "time|M:${deadline}s" ]) );

### testing a more complicated offset spec: dep: time|1M:0w0d0h0m1s
$sec = (localtime())[0];
$offset = 1;
$deadline = ($sec + $offset) % 60;

Cache::Static::set($key, "value", [ "time|M:0w0d0h0m${deadline}s" ]);
ok ( "complicated Minute+offset test, no time elapsed",
	Cache::Static::get_if_same($key, [ "time|M:0w0d0h0m${deadline}s" ]) );

sleep($offset+1);
ok ( "complicated Minute+offset test, time elapsed",
	!Cache::Static::get_if_same($key, [ "time|M:0w0d0h0m${deadline}s" ]) );

### testing a more complicated offset spec, relative to now:
my @lt = localtime;
$offset = 1;
$lt[0] += $offset;
while($lt[0] > 60) { $lt[0] -= 60; $lt[1] += 1; }
while($lt[1] > 60) { $lt[1] -= 60; $lt[2] += 1; }
while($lt[2] > 24) { $lt[2] -= 24; $lt[6] = ($lt[6] + 1) % 7; }
my $target = $lt[6].'d'.$lt[2].'h'.$lt[1].'m'.$lt[0].'s';

Cache::Static::set($key, "value", [ "time|W:$target" ]);
ok ( "Week+offset test, no time elapsed",
	Cache::Static::get_if_same($key, [ "time|W:$target" ]) );

sleep($offset+1);
ok ( "Week+offset test, time elapsed",
	!Cache::Static::get_if_same($key, [ "time|W:$target" ]) );

exit 0;
