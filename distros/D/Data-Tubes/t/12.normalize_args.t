use strict;
use Test::More;
use Data::Dumper;

use Data::Tubes::Util qw< normalize_args >;
ok __PACKAGE__->can('normalize_args'), 'imported normalize_args';

for my $tspec (
   [[{name => 'foo'}], {name => 'foo'}, 'only defaults',],
   [
      [{name => 'bar'}, {name => 'foo'}],
      {name => 'bar'},
      'overriding default',
   ],
   [
      [{surname => 'bar'}, {name => 'foo'}],
      {surname => 'bar', name => 'foo'},
      'adding to defaults',
   ],
   [
      [name => 'bar', {name => 'foo'}],
      {name => 'bar'},
      'overriding default, list version',
   ],
   [
      [surname => 'bar', {name => 'foo'}],
      {surname => 'bar', name  => 'foo'},
      'adding to defaults, list version',
   ],
   [
      ['bar', [{name => 'foo'}, 'surname']],
      {surname => 'bar', name => 'foo'},
      'adding to defaults, list version, using default key',
   ],
   [
      [surname => 'bar', [{name => 'foo'}, 'middle']],
      {surname => 'bar', name => 'foo'},
      'adding to defaults, list version, ignoring default key',
   ],
  )
{
   my ($params, $expected, $name) = @$tspec;
   my $got = normalize_args(@$params);
   is_deeply $got, $expected, $name;
} ## end for my $tspec ([[{name ...}]])

done_testing();
