
use strict;
use warnings;

use Test::More 'no_plan';

use Config::General::Match;

my $conf_text = <<EOF;

    <Path /foo>
        val  = 1
        sect = foo
        foo  = 1
    </Path>

    <Location /foo/bar>
        val    = 2
        sect   = foobar
        foobar = 1
    </Location>

    <Path /foo/bar/baz>
        val       = 3
        sect      = foobarbaz
        foobarbaz = 1
    </Path>

EOF

my $conf = Config::General::Match->new(
    -String => $conf_text,
    -MatchSections => [
        {
            -Name          => 'Location',
            -MatchType     => 'path',
            -MergePriority => 1,
        },
        {
            -Name          => 'Path',
            -MatchType     => 'path',
            -MergePriority => 2,
        },
    ],
);

my %config;

%config = $conf->getall_matching('/foo');
# /foo (1)
is($config{'sect'},       'foo',  '[/foo] sect:      foo');
is($config{'val'},        1,      '[/foo] val:       1');
is($config{'foo'},        1,      '[/foo] foo:       1');
ok(!exists $config{'foobar'},     '[/foo] foobar:    not present');
ok(!exists $config{'foobarbaz'},  '[/foo] foobarbaz: not present');

%config = $conf->getall_matching('/foo/');
# /foo (1)
is($config{'sect'},       'foo',  '[/foo/] sect:      foo');
is($config{'val'},        1,      '[/foo/] val:       1');
is($config{'foo'},        1,      '[/foo/] foo:       1');
ok(!exists $config{'foobar'},     '[/foo/] foobar:    not present');
ok(!exists $config{'foobarbaz'},  '[/foo/] foobarbaz: not present');

%config = $conf->getall_matching('/foo/bar');
# /foo/bar (2), /foo (1)
is($config{'sect'},       'foo',  '[/foo/bar] sect:      foo');
is($config{'val'},        1,      '[/foo/bar] val:       1');
is($config{'foo'},        1,      '[/foo/bar] foo:       1');
is($config{'foobar'},     1,      '[/foo/bar] foobar:    1');
ok(!exists $config{'foobarbaz'},  '[/foo/bar] foobarbaz: not present');

%config = $conf->getall_matching('/foo/bar.txt');
# /foo (1)
is($config{'sect'},       'foo',  '[/foo/bar.txt] sect:      foo');
is($config{'val'},        1,      '[/foo/bar.txt] val:       1');
is($config{'foo'},        1,      '[/foo/bar.txt] foo:       1');
ok(!exists $config{'foobar'},     '[/foo/bar.txt] foobar:    not present');
ok(!exists $config{'foobarbaz'},  '[/foo/bar.txt] foobarbaz: not present');

%config = $conf->getall_matching('/foo/bar/baz/boom.txt');
# /foo/bar     (2)
# /foo         (1)
# /foo/bar/baz (3)
is($config{'sect'},       'foobarbaz',  '[/foo/bar/baz/boom.txt] sect:      foobarbaz');
is($config{'val'},        3,            '[/foo/bar/baz/boom.txt] val:       3');
is($config{'foo'},        1,            '[/foo/bar/baz/boom.txt] foo:       1');
is($config{'foobar'},     1,            '[/foo/bar/baz/boom.txt] foobar:    1');
is($config{'foobarbaz'},  1,            '[/foo/bar/baz/boom.txt] foobarbaz: 1');


# No matches
%config = $conf->getall_matching('/foo.txt');
ok (!keys %config, '/foo.txt: no match');

%config = $conf->getall_matching('foo');
ok (!keys %config, 'foo: no match');

%config = $conf->getall_matching('foo/bar');
ok (!keys %config, 'foo: no match');

%config = $conf->getall_matching('foo.txt');
ok (!keys %config, 'foo.txt: no match');

%config = $conf->getall_matching('/food');
ok (!keys %config, '/food: no match');

%config = $conf->getall_matching('/food/bar.txt');
ok (!keys %config, '/food/bar.txt: no match');


