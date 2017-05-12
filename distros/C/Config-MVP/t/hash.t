use strict;
use warnings;

use Test::More;

use lib 't/lib';

{
  package CMRFBA;
  use Moose;
  extends 'Config::MVP::Assembler';
  with 'Config::MVP::Assembler::WithBundles';
}

{
  package CMRFB;
  use Moose;
  extends 'Config::MVP::Reader::Hash';

  sub build_assembler { CMRFBA->new; }
}

{
  my $config = CMRFB->new->read_config({
    'Foo::Bar' => {
      x => 1,
      y => [ 2, 4 ],
      z => 3,
    },
    'bz' => {
      __package => 'Foo::Baz',
      single => 1,
      multi  => [ 2, 3 ],
    },
    'Foo::Metaboondle' => { },
    'Foo::Quux' => {
      a => 1,
      b => 2,
      c => 3,
    }
  });

  my @sections = $config->sections;

  is(@sections, 7, "there are seven sections");

  @sections = sort { lc $a->name cmp lc $b->name } @sections;
  my ($b_1, $b_2, $b_3, $b_b, $baz, $bar, $quux) = @sections;

  is($bar->name,     'Foo::Bar',  '1st is Foo::Bar (name)');
  is($bar->package,  'Foo::Bar',  '1st is Foo::Bar (pkg)');

  is($baz->name,     'bz',        '2nd is bz (name)');
  is($baz->package,  'Foo::Baz',  '2nd is Foo::Baz (pkg)');

  is($b_1->name,     'boondle_1', '2nd is boondle_1 (name)');
  is($b_1->package,  'Foo::Boo1', '2nd is Foo::Boo1 (pkg)');

  is($b_2->name,     'boondle_2', '2nd is boondle_2 (name)');
  is($b_2->package,  'Foo::Boo2', '2nd is Foo::Boo2 (pkg)');

  is($b_b->name,     'boondle_B', '3rd is boondle_B (name)');
  is($b_b->package,  'Foo::Bar',  '3rd is Foo::Bar (pkg)');

  is($b_3->name,     'boondle_3', '4th is boondle_3 (name)');
  is($b_3->package,  'Foo::Boo2', '4th is Foo::Boo2 (pkg)');

  is($quux->name,    'Foo::Quux', '5th is Foo::Quux (name)');
  is($quux->package, 'Foo::Quux', '5th is Foo::Quux (pkg)');
}

{
  my $config = CMRFB->new->read_config({
    'Foo::BoondleHref' => { },
  });

  my @sections = $config->sections;
  is(@sections, 3, "we get 2 sections");
  is_deeply(
    $sections[2]->payload,
    { y => [ 1, 2, 3 ] },
    "boondle_B has expected contents",
  );
}

{
  my $config = CMRFB->new->read_config({
    'Foo::BoondleHref' => { },
  });

  my @sections = $config->sections;
  is(@sections, 3, "we get 2 sections");
  is_deeply(
    $sections[2]->payload,
    { y => [ 1, 2, 3 ] },
    "boondle_B has expected contents",
  );
}

done_testing;
