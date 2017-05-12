use strict;
use warnings;
use Test::More 0.96;

my $mod = 'Config::MVP::Slicer';
eval "require $mod" or die $@;

my $config = {
  'Plug.attr'         => 'pa',
  'Mod::Name.opt'     => 'val',
  'Moose.and[]'       => 'squirrel',
  '@Bundle/Moose.and[]' => 'camel',
  '@Bundle.opt'       => 'red light',
  'Hunting.season[0]' => 'duck',
  'Hunting.season[1]' => 'wabbit',
  'Hunting.season[9]' => 'fudd',
  # keys are sorted very simply (alphabetically)
  'Hunting2.season[1.09]' => 'bunny',
  'Hunting2.season[1.10]' => 'bird',
  'Hunting2.season[1.08]' => 'wabbit',
  'Hunting2.season[1.11]' => 'duck',
  'Hunting2.season[z]' => 'zombie',
};

sub new_slicer {
  new_ok($mod, [{
    config => { opt => 'main config val', %$config },
    match_package => sub { return 0 }, # no false positives
    @_ ? (match_name => shift) : (),
  }]);
}

my $slicer = new_slicer(); # default

ok $slicer->match_name(qw(Foo      Foo)),           'simple match';
ok $slicer->match_name(qw(Foo      @Bar/Foo)),      'match with @Bundle/ prefix';
ok!$slicer->match_name(qw(Foo      Bar)),           'no match';

ok $slicer->match_name(qw(Foo      @Baz/@Bar/Foo)), 'match with multiple @Bundle/ prefixes';

ok!$slicer->match_name(qw(@Bar/Foo Foo)),           'no match when @Bundle/ prefix is specified but not found';
ok $slicer->match_name(qw(@Bar/Foo @Bar/Foo)),      'match with single @Bundle/ prefix on each';
ok $slicer->match_name(qw(@Bar/Foo @Baz/@Bar/Foo)), 'match with multiple @Bundle/ prefixes on each';
ok!$slicer->match_name(qw(@Bar/Foo @Baz/Foo)),      'no match with different @Bundle/ prefixes';

ok!$slicer->match_name(qw(Foo F.+)),                'not a regexp';

is_deeply
  $slicer->slice([Plug => 'X::Plug' => {}]),
  { attr => 'pa' },
  'default matches name';

is_deeply
  new_slicer(sub { return 0 })->slice([Plug => 'X::Plug' => {}]),
  { },
  '"always false" returns empty hash';

is_deeply
  new_slicer(sub { return 1 })->slice([Plug => 'X::Plug' => {}]),
  {
    'attr' => 'pa',
    'opt'  => 'val',
    'and'  => [qw(camel squirrel)],
    # keys are sorted alphabetically, so Hunting comes before Hunting2
    season => [qw(duck wabbit fudd wabbit bunny bird duck zombie)],
  },
  '"always true" matches all items that match regexp';

# XXX: is it correct/desired that both 'Moose' match?

is_deeply
  $slicer->slice(['Moose' => 'X::Moose' => {}]),
  { and => [qw(squirrel)] },
  'matches without @Bundle/ prefix';

is_deeply
  $slicer->slice(['@Bundle/Moose' => 'X::Moose' => {}]),
  { and => [qw(camel squirrel)] },
  'matches with @Bundle/ prefix';

is_deeply
  $slicer->slice(['@Task/@Bundle/Moose' => 'X::Moose' => {}]),
  { and => [qw(camel squirrel)] },
  'matches with mutliple @Bundle/ prefixes';

is_deeply
  $slicer->slice(['@Bundle' => 'X::Bundle' => {}]),
  { 'opt' => 'red light' },
  'matches bundle by itself';

is_deeply
  new_slicer(sub { $_[0] =~ /hunting/i })->slice(['@Bundle' => 'X::Bundle' => {}]),
  { season => [qw(duck wabbit fudd wabbit bunny bird duck zombie)] },
  'grab everythin matching aribtrary pattern';

done_testing;
