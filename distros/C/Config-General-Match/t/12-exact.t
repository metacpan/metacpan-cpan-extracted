
use strict;
use warnings;

use Test::More 'no_plan';

use Config::General::Match;

my $conf_text = <<EOF;

    <SectA bbb>
        testval_a         = 4
        testval_b         = 4
        testval_c         = 4
        testval_bbb       = 4
    </SectA bbb>

    <SectC bbb>
        testval_c         = 5
        testval_Cbbb      = 5
    </SectC bbb>

    <SectB    aaabbbccc>
        testval_a         = 3
        testval_b         = 3
        testval_c         = 3
        testval_aaabbbccc = 3
    </SectB>

    <SectB    aaa>
        testval_a   = 1
        testval_b   = 1
        testval_c   = 1
        testval_aaa = 1
    </SectB>

    <SectB    aaabbb>
        testval_a      = 2
        testval_b      = 2
        testval_c      = 2
        testval_aaabbb = 2
    </SectB>

EOF

my $conf = Config::General::Match->new(
    -String => $conf_text,
    -MatchSections => [
        {
            -Name      => 'SectA',
            -MatchType => 'exact',
        },
        {
            -Name      => 'SectB',
            -MatchType => 'exact',
        },
        {
            -Name          => 'SectC',
            -MatchType     => 'exact',
            -MergePriority => 10,
        },
    ],
);

my %config;

%config = $conf->getall_matching('wubba');

ok (!keys %config, 'wubba: no match');

%config = $conf->getall_matching('aaa');
# aaa(1)
is($config{'testval_a'},   1,        '[aaa] testval_a:    1');
is($config{'testval_b'},   1,        '[aaa] testval_b:    1');
is($config{'testval_c'},   1,        '[aaa] testval_c:    1');
is($config{'testval_aaa'}, 1,        '[aaa] testval_aaa:  1');
ok(! exists $config{'testval_bbb'},  '[aaa] testval_bbb:  not exists');
ok(! exists $config{'testval_Cbbb'}, '[aaa] testval_Cbbb: not exists');

%config = $conf->getall_matching('aaabbbccc');
# aaabbbccc(3)
is($config{'testval_a'},         3,       '[aaabbbccc] testval_a:         3');
is($config{'testval_b'},         3,       '[aaabbbccc] testval_b:         3');
is($config{'testval_c'},         3,       '[aaabbbccc] testval_c:         3');
is($config{'testval_aaabbbccc'}, 3,       '[aaabbbccc] testval_aaabbbccc: 3');
ok(! exists $config{'testval_aaa'},       '[aaabbbccc] testval_aaa:       not exists');
ok(! exists $config{'testval_bbb'},       '[aaabbbccc] testval_bbb:       not exists');
ok(! exists $config{'testval_Cbbb'},      '[aaabbbccc] testval_Cbbb:      not exists');
ok(! exists $config{'testval_aaabbb'},    '[aaabbbccc] testval_aaabbb:    not exists');

%config = $conf->getall_matching('xxxaaabbbcccxxx');
# no match
ok(! exists $config{'testval_a'},         '[xxxaaabbbcccxxx] testval_a:         not exists');
ok(! exists $config{'testval_b'},         '[xxxaaabbbcccxxx] testval_b:         not exists');
ok(! exists $config{'testval_c'},         '[xxxaaabbbcccxxx] testval_c:         not exists');
ok(! exists $config{'testval_aaa'},       '[xxxaaabbbcccxxx] testval_aaa:       not exists');
ok(! exists $config{'testval_bbb'},       '[xxxaaabbbcccxxx] testval_bbb:       not exists');
ok(! exists $config{'testval_Cbbb'},      '[xxxaaabbbcccxxx] testval_Cbbb:      not exists');
ok(! exists $config{'testval_aaabbb'},    '[xxxaaabbbcccxxx] testval_aaabbb:    not exists');
ok(! exists $config{'testval_aaabbbccc'}, '[xxxaaabbbcccxxx] testval_aaabbbccc: not exists');

%config = $conf->getall_matching('bbbccc');
# no match
ok(! exists $config{'testval_a'},         '[bbbccc] testval_a:         not exists');
ok(! exists $config{'testval_b'},         '[bbbccc] testval_b:         not exists');
ok(! exists $config{'testval_c'},         '[bbbccc] testval_c:         not exists');
ok(! exists $config{'testval_aaa'},       '[bbbccc] testval_aaa:       not exists');
ok(! exists $config{'testval_bbb'},       '[bbbccc] testval_bbb:       not exists');
ok(! exists $config{'testval_Cbbb'},      '[bbbccc] testval_Cbbb:      not exists');
ok(! exists $config{'testval_aaabbb'},    '[bbbccc] testval_aaabbb:    not exists');
ok(! exists $config{'testval_aaabbbccc'}, '[bbbccc] testval_aaabbbccc: not exists');




