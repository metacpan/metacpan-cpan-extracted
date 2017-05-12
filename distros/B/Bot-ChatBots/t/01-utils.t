use strict;
use Test::More tests => 2;

use Bot::ChatBots::Utils qw< load_module pipeline resolve_module >;

can_ok __PACKAGE__, qw< load_module pipeline resolve_module >;

subtest 'resolve_module' => sub {
   for my $spec (
      ['Bot::ChatBots::Foo', 'Foo'],
      ['Bot::ChatBots::Foo', '::Foo'],
      [Foo => '+Foo'],
      [Foo => '^Foo'],
      ['Bot::ChatBots::Foo::Bar', 'Foo::Bar'],
      ['Bot::ChatBots::Foo::Bar', '::Foo::Bar'],
      ['Foo::Bar' => '+Foo::Bar'],
      ['Foo::Bar' => '^Foo::Bar'],

      ['Baz::Foo', 'Foo',   'Baz'],
      ['Baz::Foo', '::Foo', 'Baz'],
      [Foo => '+Foo', 'Baz'],
      [Foo => '^Foo', 'Baz'],
      ['Baz::Foo::Bar', 'Foo::Bar',   'Baz'],
      ['Baz::Foo::Bar', '::Foo::Bar', 'Baz'],
      ['Foo::Bar' => '+Foo::Bar', 'Baz'],
      ['Foo::Bar' => '^Foo::Bar', 'Baz'],

      ['Bot::Baz::Foo', 'Foo',   'Bot::Baz'],
      ['Bot::Baz::Foo', '::Foo', 'Bot::Baz'],
      [Foo => '+Foo', 'Bot::Baz'],
      [Foo => '^Foo', 'Bot::Baz'],
      ['Bot::Baz::Foo::Bar', 'Foo::Bar',   'Bot::Baz'],
      ['Bot::Baz::Foo::Bar', '::Foo::Bar', 'Bot::Baz'],
      ['Foo::Bar' => '+Foo::Bar', 'Bot::Baz'],
      ['Foo::Bar' => '^Foo::Bar', 'Bot::Baz'],
     )
   {
      my ($expected, @params) = @$spec;
      my $got = resolve_module(@params);
      is $got, $expected, "(@params) -> $expected";
   } ## end for my $spec (['Bot::ChatBots::Foo'...])
};

done_testing();
