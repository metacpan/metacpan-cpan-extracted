
use strict;
use warnings;

use Test::More 'no_plan';

use Config::General::Match;

my $conf_text = <<EOF;

    <Path /foo/ >
        foo = 1
    </Path>

    <Location /bar >
        bar = 1
    </Location>

    <Location2 /bar >
        bar = 1
    </Location2>

EOF

my $conf = Config::General::Match->new(
    -String => $conf_text,
    -MatchSections => [
        {
            -Name          => 'Path',
            -MatchType     => 'substring',
            -SectionType   => 'path',
        },
        {
            -Name             => 'Location',
            -MatchType        => 'substring',
            -SectionType      => 'location',
            -TrimSectionNames => 0,
        },
        {
            -Name             => 'Location2',
            -MatchType        => 'substring',
            -SectionType      => 'location2',
            -TrimSectionNames => undef,
        },
    ],
);

my %config;

%config = $conf->getall_matching(path => '/foo/');
is($config{'foo'}, 1,      '[path => /foo/] foo: 1');
ok(!exists $config{'bar'}, '[path => /foo/] bar: not present');

%config = $conf->getall_matching(location => '/bar');
ok(!exists $config{'foo'}, '[location => /bar] foo: not present');
ok(!exists $config{'bar'}, '[location => /bar] bar: not present');

%config = $conf->getall_matching(location => '/bar ');
ok(!exists $config{'foo'}, '[location => /bar ] foo: not present');
is($config{'bar'}, 1,      '[location => /bar ] bar: 1');


%config = $conf->getall_matching(location2 => '/bar');
ok(!exists $config{'foo'}, '[location2 => /bar] foo: not present');
ok(!exists $config{'bar'}, '[location2 => /bar] bar: not present');

%config = $conf->getall_matching(location2 => '/bar ');
ok(!exists $config{'foo'}, '[location2 => /bar ] foo: not present');
is($config{'bar'}, 1,      '[location2 => /bar ] bar: 1');

