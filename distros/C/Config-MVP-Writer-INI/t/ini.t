use strict;
use warnings;
use Test::More 0.96;
use lib 't/lib';
use Test::Routine;
use Test::Routine::Util;
with 'IniTests';

run_me(basic => {
  args => {
    rewrite_package => sub {
      $_[0] =~ /Mod::(.+)/ ? $1 :
      $_[0] =~ /ModX::(.+)/ ? "-$1" :
      $_[0]
    },
  },
  sections => [
    # name, package, payload
    [Name => 'Mod::Package' => {}],
    [Ducky => Rubber => {
      feathers => 'yellow',
      orange => ['feet', 'beak'],
    }],
    [Pizza => 'Mod::Pizza' => ],
    ['@Multi/@Bundle/Donkey' => 'Mod::Donuts' => ],
    ['@Multi/@Bundle/Donuts' => 'ModX::Donuts' => ],
    [CokeBear => 'Mod::CokeBear' => {':version' => '1.002023'}],
    [MASH => MASH => {':rum' => 'cookies', section => 8, discharge => undef, mess => ''}],
    [SomethingElse => {with => 'a config'}],
    [AllTheSame => ],
    'EvenMore::TheSame' =>
    'Mod::NoArray' =>
    '@Bundle',
    [EndWithConfig => EWC => {foo => [qw( bar baz )]}],
  ],
  expected_ini => <<INI,
[Package / Name]

[Rubber / Ducky]
feathers = yellow
orange   = feet
orange   = beak

[Pizza]
[Donuts / Donkey]
[-Donuts]

[CokeBear]
:version = 1.002023

[MASH]
:rum      = cookies
discharge =
mess      =
section   = 8

[SomethingElse]
with = a config

[AllTheSame]
[EvenMore::TheSame]
[NoArray / Mod::NoArray]
[\@Bundle]

[EWC / EndWithConfig]
foo = bar
foo = baz
INI
});

run_me('no payloads; ends with single newline' => {
  sections => [qw(Foo Bar)],
  expected_ini => "[Foo]\n[Bar]\n",
});

run_me('one section with payload' => {
  sections => [ [Dark => Blue => {rescued => 1}] ],
  expected_ini => "[Blue / Dark]\nrescued = 1\n",
});

done_testing;
