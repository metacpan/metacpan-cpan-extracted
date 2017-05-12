use strict;
use warnings;

use lib 't/lib';

use Test::More;
use Config::MVP::Reader::INI;

my $seq = Config::MVP::Reader::INI->read_config('eg/mvp.ini');

my @section_names = $seq->section_names;

is_deeply(
  \@section_names,
  [ qw(_ Foo::Bar baz), 'Bap Bop Boop', 'Bap Bop Blort' ],
  "loaded the right names from sample config",
);

is($seq->section_named('_')->package, undef, 'root package');

is_deeply(
  $seq->section_named('_')->payload,
  { foo => 10, bar => 11 },
  "_ payload as expected",
);

is($seq->section_named('Foo::Bar')->package, 'Foo::Bar', 'Foo::Bar package');

is_deeply(
  $seq->section_named('Foo::Bar')->payload,
  { x => 10, y => [ 20, 30 ], z => -123 },
  'Foo::Bar payload',
);

is($seq->section_named('baz')->package, 'Foo::Bar', 'baz package');

is_deeply(
  $seq->section_named('baz')->payload,
  { x => 1 },
  'baz payload',
);

is($seq->section_named('Bap Bop Boop')->package, 'Foo::Bar', 'Bap Bop Boop package');

is_deeply(
  $seq->section_named('Bap Bop Boop')->payload,
  { yarp => 1 },
  'Bap Bop Boop payload',
);

done_testing;
