

# This test just
# copies 04-path, with the following changes:
#  * replace Module with Path
#  * replace App with Location
#  * replace txt with pm
#  * specify a PathSeparator of '::'

use strict;
use warnings;

use Test::More 'no_plan';


use Config::General::Match;

my $conf_text = <<EOF;

    <Module Foo>
        val  = 1
        sect = foo
        foo  = 1
    </Module>

    <App Foo::Bar>
        val    = 2
        sect   = foobar
        foobar = 1
    </App>

    <Module Foo::Bar::Baz>
        val       = 3
        sect      = foobarbaz
        foobarbaz = 1
    </Module>

EOF

my $conf = Config::General::Match->new(
    -String => $conf_text,
    -MatchSections => [
        {
            -Name          => 'App',
            -MatchType     => 'hierarchy',
            -PathSeparator => '::',
            -MergePriority => 1,
        },
        {
            -Name          => 'Module',
            -MatchType     => 'path',
            -PathSeparator => '::',
            -MergePriority => 2,
        },
    ],
);

my %config;

%config = $conf->getall_matching('Foo');
# Foo (1)
is($config{'sect'},       'foo',  '[Foo] sect:      foo');
is($config{'val'},        1,      '[Foo] val:       1');
is($config{'foo'},        1,      '[Foo] foo:       1');
ok(!exists $config{'foobar'},     '[Foo] foobar:    not present');
ok(!exists $config{'foobarbaz'},  '[Foo] foobarbaz: not present');

%config = $conf->getall_matching('Foo::');
# Foo (1)
is($config{'sect'},       'foo',  '[Foo::] sect:      foo');
is($config{'val'},        1,      '[Foo::] val:       1');
is($config{'foo'},        1,      '[Foo::] foo:       1');
ok(!exists $config{'foobar'},     '[Foo::] foobar:    not present');
ok(!exists $config{'foobarbaz'},  '[Foo::] foobarbaz: not present');

%config = $conf->getall_matching('Foo::Bar');
# Foo::Bar (2), Foo (1)
is($config{'sect'},       'foo',  '[Foo::Bar] sect:      foo');
is($config{'val'},        1,      '[Foo::Bar] val:       1');
is($config{'foo'},        1,      '[Foo::Bar] foo:       1');
is($config{'foobar'},     1,      '[Foo::Bar] foobar:    1');
ok(!exists $config{'foobarbaz'},  '[Foo::Bar] foobarbaz: not present');

%config = $conf->getall_matching('Foo::Bar.txt');
# Foo (1)
is($config{'sect'},       'foo',  '[Foo::Bar.txt] sect:      foo');
is($config{'val'},        1,      '[Foo::Bar.txt] val:       1');
is($config{'foo'},        1,      '[Foo::Bar.txt] foo:       1');
ok(!exists $config{'foobar'},     '[Foo::Bar.txt] foobar:    not present');
ok(!exists $config{'foobarbaz'},  '[Foo::Bar.txt] foobarbaz: not present');

%config = $conf->getall_matching('Foo::Bar::Baz::Boom.pm');
# Foo::bar     (2)
# Foo         (1)
# Foo::bar/baz (3)
is($config{'sect'},       'foobarbaz',  '[Foo::Bar::Baz::Boom.pm] sect:      foobarbaz');
is($config{'val'},        3,            '[Foo::Bar::Baz::Boom.pm] val:       3');
is($config{'foo'},        1,            '[Foo::Bar::Baz::Boom.pm] foo:       1');
is($config{'foobar'},     1,            '[Foo::Bar::Baz::Boom.pm] foobar:    1');
is($config{'foobarbaz'},  1,            '[Foo::Bar::Baz::Boom.pm] foobarbaz: 1');


# No matches
%config = $conf->getall_matching('Foo.pm');
ok (!keys %config, 'Foo.pm: no match');

%config = $conf->getall_matching('foo');
ok (!keys %config, 'foo: no match');

%config = $conf->getall_matching('foo.pm');
ok (!keys %config, 'foo.pm: no match');

%config = $conf->getall_matching('Food');
ok (!keys %config, 'Food: no match');

%config = $conf->getall_matching('Food::Bar.pm');
ok (!keys %config, 'Food::Bar.pm: no match');


