

use strict;
use warnings;

use Test::More 'no_plan';

use Config::General::Match;

my $conf_text = <<EOF;

    <SeCTION    aaa>
        testval foo
    </SEction>
    <SECTION    aaabbb>
        testval bar
    </section>
    <secTION    aaabbbccc>
        testval baz
    </sECTION>

EOF

my ($conf, %config);

# Without -LowerCaseNames
$conf = Config::General::Match->new(
    -String => $conf_text,
    -MatchSections => [
        {
            -Name      => 'SectION',
            -MatchType => 'substring',
        },
    ],
);

%config = $conf->getall_matching('wubba');

%config = $conf->getall_matching('aaa');
ok(!exists $config{'testval'}, 'case sensitive [aaa] testval:   not exists');

%config = $conf->getall_matching('aaabbbccc');
ok(!exists $config{'testval'}, 'case sensitive [aaabbbccc] testval:   not exists');


# With -LowerCaseNames
$conf = Config::General::Match->new(
    -String         => $conf_text,
    -LowerCaseNames => 1,
    -MatchSections  => [
        {
            -Name      => 'SectION',
            -MatchType => 'substring',
        },
    ],
);


%config = $conf->getall_matching('aaa');
is($config{'testval'},   'foo', 'case insensitive [aaa] testval:   foo');

%config = $conf->getall_matching('aaabbbccc');
is($config{'testval'},   'baz', 'case insensitive [aaabbbccc] testval:   baz');

