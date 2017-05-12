use strict;
use warnings;
use Test::More 0.96;

my $mod = 'Config::MVP::Slicer';
eval "require $mod" or die $@;

my $config = {
  'Plug.attr'         => 'pa',
  'Mod::Name.opt'     => 'val',
  '=Mod::Name.opt'    => 'eq',
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

sub rewrite_prefix {
  local $_ = shift;
    s/^=//
    || s/^@/BarX::/
    || s/^/FooX::/;
  return $_;
}

# make sure the rewriter works
is rewrite_prefix('@Foo'), 'BarX::Foo', 'rewrite @';
is rewrite_prefix('=Foo'), 'Foo',       'rewrite =';
is rewrite_prefix( 'Foo'), 'FooX::Foo', 'rewrite everything else';

sub new_slicer {
  new_ok($mod, [{
    config => { opt => 'main config val', %$config },
    match_name => sub { return 0 }, # no false positives
    @_ ? (match_package => shift) : (),
  }]);
}

my $slicer = new_slicer(); # default

# default match is $_[0] eq $_[1]
ok $slicer->match_package(qw(Foo       Foo)),          'simple match';

ok !$slicer->match_package(qw(Foo      FooX::Foo)),    'no match with namespace prefix';
ok !$slicer->match_package(qw(@Bar/Foo Foo)),          'no match with when @Bundle/ prefix is specified but not found';
ok !$slicer->match_package(qw(Foo F.+)),               'not a regexp';

my $rewriter = new_slicer(sub { rewrite_prefix($_[0]) eq $_[1] });

ok $rewriter->match_package(qw( Foo     FooX::Foo)),    'match with rewritten namespace prefix';
ok $rewriter->match_package(qw(=Foo           Foo)),    'match with rewritten empty prefix';
ok $rewriter->match_package(qw(@Foo     BarX::Foo)),    'match with rewritten bundle prefix';

is_deeply
  $slicer->slice([ModName => 'Mod::Name' => {}]),
  { opt => 'val' },
  'default matches whole package name';

is_deeply
  new_slicer(sub { return 0 })->slice([ModName => 'Mod::Name' => {}]),
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

is_deeply
  $slicer->slice([Y => 'X::Moose' => {}]),
  { },
  'nothing matched';

is_deeply
  $rewriter->slice([U => 'FooX::Moose' => {}]),
  { and => ['squirrel'] },
  'matched on default rewritten package';

is_deeply
  $rewriter->slice([NO => 'BarX::Bundle' => {}]),
  { opt => 'red light' },
  'matches on rewritten package for "@"';

is_deeply
  $rewriter->slice([WORK => 'Mod::Name' => {}]),
  { opt => 'eq' },
  'matches on rewritten package for "="';

is_deeply
  $rewriter->slice([RIGHT => 'FooX::Mod::Name' => {}]),
  { opt => 'val' },
  'matches on rewritten package for ""';

is_deeply
  $rewriter->slice(['@Task/@Bundle/WhoMoose' => 'FooX::Moose' => {}]),
  { and => [qw(squirrel)] },
  'matches package regardless of @Bundle/ prefixes on name (duh)';

done_testing;
