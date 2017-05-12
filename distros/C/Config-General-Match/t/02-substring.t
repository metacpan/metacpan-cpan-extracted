
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
            -MatchType => 'substring',
        },
        {
            -Name      => 'SectB',
            -MatchType => 'substring',
        },
        {
            -Name          => 'SectC',
            -MatchType     => 'substring',
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
# aaa(1), bbb(4), aaabbb(2), aaabbbccc(3), bbb(5)
is($config{'testval_a'},         3, '[aaabbbccc] testval_a:         3');
is($config{'testval_b'},         3, '[aaabbbccc] testval_b:         3');
is($config{'testval_c'},         5, '[aaabbbccc] testval_c:         5');
is($config{'testval_aaa'},       1, '[aaabbbccc] testval_aaa:       1');
is($config{'testval_bbb'},       4, '[aaabbbccc] testval_bbb:       4');
is($config{'testval_Cbbb'},      5, '[aaabbbccc] testval_Cbbb:      5');
is($config{'testval_aaabbb'},    2, '[aaabbbccc] testval_aaabbb:    2');
is($config{'testval_aaabbbccc'}, 3, '[aaabbbccc] testval_aaabbbccc: 3');


%config = $conf->getall_matching('xxxaaabbbcccxxx');
# aaa(1), bbb(4), aaabbb(2), aaabbbccc(3), bbb(5)
is($config{'testval_a'},         3, '[xxxaaabbbcccxxx] testval_a:         3');
is($config{'testval_b'},         3, '[xxxaaabbbcccxxx] testval_b:         3');
is($config{'testval_c'},         5, '[xxxaaabbbcccxxx] testval_b:         5');
is($config{'testval_aaa'},       1, '[xxxaaabbbcccxxx] testval_aaa:       1');
is($config{'testval_bbb'},       4, '[aaabbbccc] testval_bbb:             4');
is($config{'testval_Cbbb'},      5, '[aaabbbccc] testval_Cbbb:            5');
is($config{'testval_aaabbb'},    2, '[xxxaaabbbcccxxx] testval_aaabbb:    2');
is($config{'testval_aaabbbccc'}, 3, '[xxxaaabbbcccxxx] testval_aaabbbccc: 3');

%config = $conf->getall_matching('bbbccc');
# bbb(4), bbb(5)
is($config{'testval_a'},         4, '[bbbccc] testval_a:         4');
is($config{'testval_b'},         4, '[bbbccc] testval_b:         4');
is($config{'testval_c'},         5, '[bbbccc] testval_c:         5');
is($config{'testval_bbb'},       4, '[bbbccc] testval_c:         4');
is($config{'testval_Cbbb'},      5, '[bbbccc] testval_c:         5');


%config = $conf->getall_matching('cccxxxaaaxxxaaabbbxxx');
# aaa(1), bbb(4), aaabbb(2), bbb(5)
is($config{'testval_a'},         2,       '[cccxxxaaaxxxaaabbbxxx] testval_a:         2');
is($config{'testval_b'},         2,       '[cccxxxaaaxxxaaabbbxxx] testval_b:         2');
is($config{'testval_c'},         5,       '[cccxxxaaaxxxaaabbbxxx] testval_b:         5');
is($config{'testval_aaa'},       1,       '[cccxxxaaaxxxaaabbbxxx] testval_aaa:       1');
is($config{'testval_bbb'},       4,       '[cccxxxaaaxxxaaabbbxxx] testval_bbb:       4');
is($config{'testval_Cbbb'},      5,       '[cccxxxaaaxxxaaabbbxxx] testval_Cbbb:      5');
is($config{'testval_aaabbb'},    2,       '[cccxxxaaaxxxaaabbbxxx] testval_aaabbb:    2');
ok(! exists $config{'testval_aaabbbccc'}, '[cccxxxaaaxxxaaabbbxxx] testval_aaabbbccc: not exists');


