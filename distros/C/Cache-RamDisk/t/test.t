#!/usr/bin/perl -w


use Cache::RamDisk;
use Cache::RamDisk::Functions;


warn "\n\tTests may may take some seconds on slow boxes - never mind!\t";

print "1..6 \n";

my $c = cache_install ( { 'Base'   => '/tmp/cachetest/rd',
                          'SIndex' => { 'fie' => 32,
                                        'foe' => 32,
                                        'fum' => 32
                                      },
                          'INodes' => 2048,
                          'Keys'   => { 'fie' => 200,
                                        'foe' => 200,
                                        'fum' => 200 }
                                                    } );
unless ($c) {
   print "not ok \n";
   exit 0
}
print "ok 1 \n";

my $tref = { };
$tref->{bar} = 'w' x 2048;

$c = Cache::RamDisk->new ('/tmp/cachetest/rd', CACHE_LRU);
for (my $i = 0; $i < 660; $i++) {
   if ($i % 2) {
      last unless $c->put({'fie' => { $i => $tref }});
   }
   elsif ($i % 3) {
      last unless $c->put({'foe' => { $i => $tref }});
   }
   else {
      last unless $c->put({'fum' => { $i => $tref }});
   }
}
if ($c->errstr) {
   warn $c->errstr;
   print "not ok \n";
   exit 0;
}
print "ok 2 \n";

$c->invalidate({'fie' => 1});
if ($c->errstr) {
   warn $c->errstr;
   print "not ok \n";
   exit 0;
}
print "ok 3 \n";

$c = cache_status('/tmp/cachetest/rd');
unless ($c || $c->key_stat('fie') != 199) {
   print "not ok \n";
   exit 0;
}
print "ok 4 \n";


$c = Cache::RamDisk->new ('/tmp/cachetest/rd', CACHE_LRU);
for (my $i = 0; $i < 660; $i++) {
   if ($i % 2) {
      last unless $c->get({'fie' => $i });
   }
   elsif ($i % 3) {
      last unless $c->get({'foe' => $i });
   }
   else {
      last unless $c->get({'fum' => $i });
   }
}
if ($c->errstr) {
   warn $c->errstr;
   print "not ok \n";
   exit 0;
}
print "ok 4 \n";


unless (cache_remove('/tmp/cachetest/rd')) {
   print "not ok \n";
   exit 0
}
print "ok 6 \n";
