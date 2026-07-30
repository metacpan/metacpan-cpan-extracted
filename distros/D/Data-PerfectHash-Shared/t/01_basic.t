use strict; use warnings; use Test::More;
use Data::PerfectHash::Shared;
use File::Temp 'tempdir';
my $b = Data::PerfectHash::Shared->new_builder(type => 'int');
isa_ok $b, 'Data::PerfectHash::Shared::Builder';
$b->add(10); $b->add(20); $b->add_many([30,40,50]);
is $b->count, 5, 'count after adds';
{ my $bd = Data::PerfectHash::Shared->new_builder(type => 'int');
  $bd->add(5); $bd->add(5); is $bd->count, 2, 'builder count is pre-dedup'; }
my $s = Data::PerfectHash::Shared->new_builder(type => 'str');
$s->add('alpha'); $s->add_many(['beta','gamma']);
is $s->count, 3, 'str count';

my $dir = tempdir(CLEANUP => 1);
my $path = "$dir/set.phs";
my @ids = map { $_ * 7 + 3 } 0 .. 999;   # 1000 distinct ints
Data::PerfectHash::Shared->build_int($path, \@ids);
is((stat $path)[2] & 0777, 0600, 'default mode 0600');
$b->build("$dir/mode640.phs", mode => 0640);
is((stat "$dir/mode640.phs")[2] & 0777, 0640, 'explicit mode 0640');
my $set = Data::PerfectHash::Shared->load($path);
isa_ok $set, 'Data::PerfectHash::Shared';
my $ok = 0; $ok += $set->has($_) for @ids;
is $ok, scalar(@ids), 'every member present';

my %seen; $set->each_key(sub { $seen{$_[0]}++ });
is scalar(keys %seen), scalar(@ids), 'each_key visits every key';
ok -e $set->path, 'path exists';
is $set->path, $path, 'path round-trips';
$set->unlink; ok !-e $path, 'unlink removes the file';

done_testing;
