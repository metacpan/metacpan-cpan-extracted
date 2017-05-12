use strict;

# vim: ft=perl ts=3 sts=3 sw=3 et ai :

use Test::More;
use Test::Exception;
use Data::Dumper;
use Path::Tiny;
use Storable qw< nstore retrieve >;

use Data::Tubes qw< pipeline summon >;

summon('Plumbing::cache');
ok __PACKAGE__->can('cache'), "summoned cache";

my $me = path(__FILE__);
my $base = $me->sibling($me->basename() . '.tmp');
$base->remove() if $base->is_file();
$base->remove_tree() if $base->is_dir();

my $wrapped = sub { $_[0]->{OUTPUT} = $_[0]->{INPUT} + 1; return $_[0]; };

{
   my $cache = $base->child('01');
   ok !$cache->is_dir(), 'directory does not exist initially';

   my $tube  = cache(
      cache  => ['^Data::Tubes::Util::Cache', repository => $cache],
      tube   => $wrapped,
      key    => 'INPUT',
      output => 'OUTPUT',
   );
   isa_ok $tube, 'CODE', 'the tube seems a tube';
   my $inrec = {INPUT => 10};
   my $outrec = $tube->($inrec);
   is_deeply $outrec, $inrec, 'tube wrapping worked fine';
   is $outrec->{OUTPUT}, 11, 'tube wrapping computation was fine';

   ok $cache->is_dir(), 'directory was created';
   my @files = $cache->children();
   is scalar(@files), 1, 'one file was created';
   is $files[0], $cache->child('10'), 'filename is same as key';

   # now change the cache behind the scenes, verify that cached stuff
   nstore [15], $cache->child('10');
   $outrec = $tube->($inrec);
   is $outrec->{OUTPUT}, 15, 'cached value was used, for sure';

   # now add something else
   $inrec = {INPUT => 123};
   $outrec = $tube->($inrec);
   is_deeply $outrec, {%$inrec, OUTPUT => 124}, 'new computation';

   my @files = $cache->children();
   is scalar(@files), 2, 'one additionl file was created';
}

$base->remove_tree();
done_testing();
