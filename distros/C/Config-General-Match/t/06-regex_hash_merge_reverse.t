
# This is adapted from regex.t but with Hash::Merge options set to
# RIGHT_PRECEDENT, and the results reversed to adapt to this change

use strict;
use warnings;

use Test::More 'no_plan';

use Config::General::Match;

my $conf_text = <<EOF;

    <FooMatch  a.*>
        sect  = a
        val1  = 1
        secta = 1
    </FooMatch>
    <BarMatch  b.*>
        sect  = b
        val1  = 2
        sectb = 1
    </BarMatch>
    <FooMatch  c.*>
        sect  = c
        val1  = 3
        sectc = 1
    </FooMatch>
    <BarMatch  d.*>
        sect  = d
        val1  = 4
        sectd = 1
    </BarMatch>
    <FooMatch  e.*>
        sect  = e
        val1  = 5
        secte = 1
    </FooMatch>

EOF

my $conf = Config::General::Match->new(
    -String => $conf_text,
    -MatchSections => [
        {
            -Name          => 'FooMatch',
            -MatchType     => 'regex',
            -MergePriority => 1,
        },
        {
            -Name          => 'BarMatch',
            -MatchType     => 'regex',
            -MergePriority => 2,
        },
    ],
);

Hash::Merge::set_behavior('RIGHT_PRECEDENT');

my %config;

%config = $conf->getall_matching('abcd');
# [Section] match (chars): value
# [Foo] c(2): 3 * reversed, so this one wins
# [Foo] a(4): 1
# [Bar] d(1): 4
# [Bar] b(3): 2

is($config{'sect'},    'c',         '[abcd] sect:    c');
is($config{'val1'},    3,           '[abcd] val1:    3');
is($config{'secta'},   1,           '[abcd] secta:   1');
is($config{'sectb'},   1,           '[abcd] sectb:   1');
is($config{'sectc'},   1,           '[abcd] sectc:   1');
is($config{'sectd'},   1,           '[abcd] sectd:   1');
ok(!exists $config{'secte'},        '[abcd] secte:   not present');

%config = $conf->getall_matching('a');
# [Section] match (chars): value
# [Foo] a(1): 1
#
is($config{'sect'},    'a',         '[a] sect:    a');
is($config{'val1'},    1,           '[a] val1:    1');
is($config{'secta'},   1,           '[a] secta:   1');
ok(!exists $config{'sectb'},        '[a] sectb:   not present');
ok(!exists $config{'sectc'},        '[a] sectc:   not present');
ok(!exists $config{'sectd'},        '[a] sectd:   not present');
ok(!exists $config{'secte'},        '[a] secte:   not present');

%config = $conf->getall_matching('cad');
# [Section] match (chars): value
# [Foo] a(2): 1 * reversed, so this one wins
# [Foo] c(3): 3
# [Bar] d(1): 4
is($config{'sect'},    'a',         '[cad] sect:    a');
is($config{'val1'},    1,           '[cad] val1:    1');
is($config{'secta'},   1,           '[cad] secta:   1');
ok(!exists $config{'sectb'},        '[cad] sectb:   not present');
is($config{'sectc'},   1,           '[cad] sectc:   1');
is($config{'sectd'},   1,           '[cad] sectd:   1');
ok(!exists $config{'secte'},        '[cad] secte:   not present');

