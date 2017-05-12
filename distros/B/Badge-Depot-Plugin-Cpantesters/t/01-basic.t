use strict;
use warnings;
use Test::More;
use if $ENV{'AUTHOR_TESTING'}, 'Test::Warnings';

use Badge::Depot::Plugin::Cpantesters;

my $badge = Badge::Depot::Plugin::Cpantesters->new(_meta => { dist => 'Badge-Depot-Plugin-CpanTesters', version => '0.0100' });

is $badge->to_html,
   '<a href="http://matrix.cpantesters.org/?dist=Badge-Depot-Plugin-CpanTesters%200.0100"><img src="http://badgedepot.code301.com/badge/cpantesters/Badge-Depot-Plugin-CpanTesters/0.0100" alt="CPAN Testers result" /></a>',
   'Correct html';


done_testing;
