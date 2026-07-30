use strict; use warnings; use Test::More; use File::Temp 'tempdir';
use Data::PerfectHash::Shared;
my $dir=tempdir(CLEANUP=>1);
{ my $p="$dir/empty.phs"; Data::PerfectHash::Shared->build_int($p,[]);
  my $s=Data::PerfectHash::Shared->load($p); is $s->count,0,'empty count'; ok !$s->has(1),'empty has'; }
{ my $p="$dir/one.phs"; Data::PerfectHash::Shared->build_int($p,[42]);
  my $s=Data::PerfectHash::Shared->load($p); is $s->count,1; ok $s->has(42); ok !$s->has(43); }
{ my $p="$dir/dup.phs"; Data::PerfectHash::Shared->build_int($p,[5,5,5,7,7]);
  my $s=Data::PerfectHash::Shared->load($p); is $s->count,2,'dedup'; ok $s->has(5)&&$s->has(7); }
{ my $p="$dir/sempty.phs"; Data::PerfectHash::Shared->build_str($p,[]);
  my $s=Data::PerfectHash::Shared->load($p); is $s->count,0,'str empty count'; ok !$s->has("x"),'str empty has'; }
{ my $p="$dir/sone.phs"; Data::PerfectHash::Shared->build_str($p,["hello"]);
  my $s=Data::PerfectHash::Shared->load($p); is $s->count,1,'str single count'; ok $s->has("hello"),'str single hit'; ok !$s->has("world"),'str single miss'; }
{ my $p="$dir/sdup.phs"; Data::PerfectHash::Shared->build_str($p,["a","a","b"]);
  my $s=Data::PerfectHash::Shared->load($p); is $s->count,2,'str dedup'; ok $s->has("a")&&$s->has("b"),'str dedup hits'; }
done_testing;
