

use strict;
use warnings;

use Test::More 'no_plan';


use Config::General::Match;

my $conf_text = <<EOF;

    <Module Foo>
        val                   = 1
        sect                  = [Module]Foo
        [Module]Foo           = 1
    </Module>

    <App Foo::Bar::>
        val                   = 2
        sect                  = [App]Foo::Bar::
        [App]Foo::Bar::       = 1
    </App>

    <Module Foo::Bar::Baz>
        val                   = 3
        sect                  = [Module]Foo::Bar::Baz
        [Module]Foo::Bar::Baz = 1
    </Module>

    <Path /foo>
        val                   = 4
        sect                  = [Path]/foo
        [Path]/foo            = 1
    </Path>

    <Location /foo/bar>
        val                   = 5
        sect                  = [Location]/foo/bar
        [Location]/foo/bar    = 1
    </Location>

    <LocationMatch zap>
        val                   = 6
        sect                  = [LocationMatch]zap
        [LocationMatch]zap    = 1
    </LocationMatch>

    <FooMatch  a+>
        val                   = 7
        sect                  = [FooMatch]a+
        [FooMatch]a+          = 1
    </FooMatch>

EOF

my $conf;
$conf = Config::General::Match->new(
    -String => $conf_text,
    -MatchSections => [
        {
            -Name          => 'App',
            -MatchType     => 'hierarchy',
            -PathSeparator => '::',
            -SectionType   => 'module',
        },
        {
            -Name          => 'Module',
            -MatchType     => 'path',
            -PathSeparator => '::',
            -SectionType   => 'module',
        },
        {
            -Name          => 'Path',
            -MatchType     => 'path',
            -SectionType   => 'path',
        },
        {
            -Name          => 'Location',
            -MatchType     => 'path',
            -SectionType   => 'path',
        },
        {
            -Name          => 'LocationMatch',
            -MatchType     => 'substring',
            -SectionType   => 'path',
        },
        {
            -Name          => 'FooMatch',
            -MatchType     => 'regex',
            -SectionType   => 'foo',
        },
    ],
);

my %config;

%config = $conf->getall_matching(
    module => 'Foo',
    path   => '/foo',
    foo    => 'xxx',
);
# <section> (chars): val
# <Module Foo> (3): 1
# <Path /foo>  (4): 4

is($config{'val'},         4,             '[module=Foo,path=/foo,foo=xxx] val:         4');
is($config{'sect'},        '[Path]/foo',  '[module=Foo,path=/foo,foo=xxx] sect:        [Path]/foo');
is($config{'[Path]/foo'},  1,             '[module=Foo,path=/foo,foo=xxx] [Path]/foo:  1');
is($config{'[Module]Foo'}, 1,             '[module=Foo,path=/foo,foo=xxx] [Module]Foo: 1');

%config = $conf->getall_matching(
    module => 'Foo::Bar::Baz',
    path   => '/foo/bar/baz',
    foo    => 'apple',
);
# <section> (chars): val
# <FooMatch a+>          (1): 7
# <Module Foo>           (3): 1
# <Path /foo>            (4): 4
# <Location /foo/bar>    (8): 5
# <App Foo::Bar::>       (10): 2
# <Module Foo::Bar::Baz> (13): 3

is($config{'val'},                    3,                       '[module=Foo::Bar::Baz,path=/foo/bar/baz,foo=apple] val:                 3');
is($config{'sect'},                   '[Module]Foo::Bar::Baz', '[module=Foo::Bar::Baz,path=/foo/bar/baz,foo=apple] sect:                [Module]Foo::Bar::Baz');
is($config{'[FooMatch]a+'},           1,                       '[module=Foo::Bar::Baz,path=/foo/bar/baz,foo=apple] [FooMatch]a+:        1');
is($config{'[Module]Foo'},            1,                       '[module=Foo::Bar::Baz,path=/foo/bar/baz,foo=apple] [Module]Foo:         1');
is($config{'[Path]/foo'},             1,                       '[module=Foo::Bar::Baz,path=/foo/bar/baz,foo=apple] [Path]/foo:          1');
is($config{'[Location]/foo/bar'},     1,                       '[module=Foo::Bar::Baz,path=/foo/bar/baz,foo=apple] [Location]/foo/bar:  1');
is($config{'[App]Foo::Bar::'},        1,                       '[module=Foo::Bar::Baz,path=/foo/bar/baz,foo=apple] [App]Foo::Bar::      1');
is($config{'[Module]Foo::Bar::Baz'},  1,                       '[module=Foo::Bar::Baz,path=/foo/bar/baz,foo=apple] [App]Foo::Bar::Baz   1');

