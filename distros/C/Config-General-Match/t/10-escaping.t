

use strict;
use warnings;

use Test::More 'no_plan';


use Config::General::Match;

my $conf_text = <<'EOF';
    Module = 0
    <Match \.pm$>
        Module = 1
    </Match>

EOF

my $conf = Config::General::Match->new(
    -MatchSections => [
        {
            -Name        => 'Match',
            -MatchType   => 'regex',
            -SectionType => 'match',
        },
    ],
    -String          => $conf_text,

);

my %config;
%config = $conf->getall_matching(
    match   => 'Simple.pm',
);

is($config{'Module'},      1, '[match: Simple.pm] Perl_Module:       1');

%config = $conf->getall_matching(
    match   => 'Simplexpm',
);
is($config{'Module'},      0, '[match: Simplexpm] Perl_Module:       1');

