use strict;

# vim: ft=perl ts=3 sts=3 sw=3 et ai :

use Test::More;
use Test::Exception;
use Data::Dumper;

use Data::Tubes qw< pipeline summon >;

summon('Plumbing::cache');
ok __PACKAGE__->can('cache'), "summoned cache";

my $wrapped = sub { $_[0]->{OUTPUT} = $_[0]->{INPUT} + 1; return $_[0]; };

{
   my $cache = {};
   my $tube  = cache(
      cache  => $cache,
      tube   => $wrapped,
      key    => 'INPUT',
      output => 'OUTPUT',
   );
   isa_ok $tube, 'CODE', 'the tube seems a tube';
   my $inrec = {INPUT => 10};
   my $outrec = $tube->($inrec);
   is_deeply $outrec, $inrec, 'tube wrapping worked fine';
   is $outrec->{OUTPUT}, 11, 'tube wrapping computation was fine';
   is scalar(keys %$cache), 1, 'cache is populated now';
   is_deeply $cache, {10 => [11]}, 'cache populated as expected';

   # now change the cache behind the scenes, verify that cached stuff
   # is taken indeed
   $cache->{10} = [15];
   $outrec = $tube->($inrec);
   is $outrec->{OUTPUT}, 15, 'cached value was used, for sure';

   # now add something else
   $inrec = {INPUT => 123};
   $outrec = $tube->($inrec);
   is_deeply $outrec, {%$inrec, OUTPUT => 124}, 'new computation';

   # verify there's a new item
   is scalar(keys %$cache), 2, 'cache has additional element';
}

{
   my $cache = {};
   my $tube  = cache(
      cache => [
         '^Data::Tubes::Util::Cache',
         repository => $cache,
         max_items  => 1,
      ],
      cleaner => 'purge',
      tube    => $wrapped,
      key     => 'INPUT',
      output  => 'OUTPUT',
   );
   isa_ok $tube, 'CODE', 'the tube seems a tube';
   my $inrec = {INPUT => 10};
   my $outrec = $tube->($inrec);
   is_deeply $outrec, $inrec, 'tube wrapping worked fine';
   is scalar(keys %$cache), 1, 'cache is populated now';
   is_deeply $cache, {10 => [11]}, 'cache populated as expected';

   # now add something else
   $inrec = {INPUT => 123};
   $outrec = $tube->($inrec);
   is_deeply $outrec, {%$inrec, OUTPUT => 124}, 'new computation';

   # no change in size of cache is expected
   is scalar(keys %$cache), 1, 'purge worked';
}

{
   my $cache = {};
   my $tube  = cache(
      cache => [
         '^Data::Tubes::Util::Cache',
         repository => $cache,
         max_items  => 1,
      ],
      cleaner => 'purge',
      tube    => $wrapped,
      key     => 'INPUT',
      output  => 'OUTPUT',
      merger  => sub {
         my ($record, $output, $data) = @_;
         return {%$record, $output => $data, foo => 'bar'};
      },
   );
   isa_ok $tube, 'CODE', 'the tube seems a tube';
   my $inrec = {INPUT => 10};
   my $outrec = $tube->($inrec);
   is_deeply $inrec, {INPUT => 10, OUTPUT => 11},
     'input record left untouched';
   is_deeply $outrec, {%$inrec, foo => 'bar'},
     'tube wrapping worked fine, merger too';
   is scalar(keys %$cache), 1, 'cache is populated now';
   is_deeply $cache, {10 => [11]}, 'cache populated as expected';

   # now add something else
   $inrec = {INPUT => 123};
   $outrec = $tube->($inrec);
   is_deeply $outrec, {%$inrec, foo => 'bar'}, 'new computation';

   # no change in size of cache is expected
   is scalar(keys %$cache), 1, 'purge worked';
}

{
   my $cache_obj = Data::Tubes::Util::Cache->new(max_items => 1);
   my $tube = cache(
      cache   => $cache_obj,
      cleaner => 'purge',
      tube    => $wrapped,
      key     => 'INPUT',
      output  => 'OUTPUT',
   );
   isa_ok $tube, 'CODE', 'the tube seems a tube';
   my $inrec = {INPUT => 10};
   my $outrec = $tube->($inrec);
   is_deeply $outrec, $inrec, 'tube wrapping worked fine';

   my $cache = $cache_obj->repository();
   is scalar(keys %$cache), 1, 'cache is populated now';
   is_deeply $cache, {10 => [11]}, 'cache populated as expected';

   # now add something else
   $inrec = {INPUT => 123};
   $outrec = $tube->($inrec);
   is_deeply $outrec, {%$inrec, OUTPUT => 124}, 'new computation';

   # no change in size of cache is expected
   is scalar(keys %$cache), 1, 'purge worked';
}

$wrapped = sub {
   my $record = shift;
   my @out    = map {
      { %$record, OUTPUT => ($record->{INPUT} + $_) }
   } 1 .. 3;
   return (records => \@out);
};
{
   my $cache = {};
   my $tube  = cache(
      cache  => $cache,
      tube   => $wrapped,
      key    => 'INPUT',
      output => 'OUTPUT',
   );
   isa_ok $tube, 'CODE', 'the tube seems a tube';
   my $inrec = {INPUT => 10};
   my ($type, $outrec) = $tube->($inrec);
   is $type, 'records', 'records returned back';
   is_deeply $outrec,
     [
      {INPUT => 10, OUTPUT => 11},
      {INPUT => 10, OUTPUT => 12},
      {INPUT => 10, OUTPUT => 13},
     ],
     'tube wrapping worked fine';
   is scalar(keys %$cache), 1, 'cache is populated now';
   is_deeply $cache, {10 => [records => [11, 12, 13]]},
     'cache populated as expected';

   # now change the cache behind the scenes, verify that cached stuff
   # is taken indeed
   $cache->{10} = [15];
   $outrec = $tube->($inrec);
   is $outrec->{OUTPUT}, 15, 'cached value was used, for sure';
}

$wrapped = sub {
   my $record = shift;
   my @out    = map {
      { %$record, OUTPUT => ($record->{INPUT} + $_) }
   } 1 .. 3;
   return (iterator => sub { return unless @out; return shift @out; });
};
{
   my $cache = {};
   my $tube  = cache(
      cache    => $cache,
      tube     => $wrapped,
      selector => sub { return $_[0]{'INPUT'} },
      output   => 'OUTPUT',
   );
   isa_ok $tube, 'CODE', 'the tube seems a tube';
   my $inrec = {INPUT => 10};
   my ($type, $outrec) = $tube->($inrec);
   is $type, 'records', 'records returned back, from iterator';
   is_deeply $outrec,
     [
      {INPUT => 10, OUTPUT => 11},
      {INPUT => 10, OUTPUT => 12},
      {INPUT => 10, OUTPUT => 13},
     ],
     'tube wrapping worked fine';
   is scalar(keys %$cache), 1, 'cache is populated now';
   is_deeply $cache, {10 => [records => [11, 12, 13]]},
     'cache populated as expected';

   # now change the cache behind the scenes, verify that cached stuff
   # is taken indeed
   $cache->{10} = [15];
   $outrec = $tube->($inrec);
   is $outrec->{OUTPUT}, 15, 'cached value was used, for sure';
}

$wrapped = sub { return };
{
   my $cache = {};
   my $tube  = cache(
      cache    => $cache,
      tube     => $wrapped,
      selector => sub { return $_[0]{'INPUT'} },
      output   => 'OUTPUT',
   );
   isa_ok $tube, 'CODE', 'the tube seems a tube';
   my $inrec = {INPUT => 10};
   my @outcome = $tube->($inrec);
   is scalar(@outcome), 0, 'nothing returned by tube';
   is scalar(keys %$cache), 1, 'cache is populated now';
   is_deeply $cache, {10 => []}, 'cache populated as expected';

   # now change the cache behind the scenes, verify that cached stuff
   # is taken indeed
   $cache->{10} = [15];
   my $outrec = $tube->($inrec);
   is $outrec->{OUTPUT}, 15, 'cached value was used, for sure';
}

throws_ok { cache() } qr{no tube to cache},
  'missing tube complains loudly';

done_testing();
