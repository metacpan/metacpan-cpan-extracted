use strict;
use warnings;
use Test::More;
use if $ENV{'AUTHOR_TESTING'}, 'Test::Warnings';

use Badge::Depot::Plugin::Kwalitee;

my $badge = Badge::Depot::Plugin::Kwalitee->new(_meta => { dist => 'Badge-Depot-Plugin-Kwalitee', version => '0.0100' }, author => 'CSSON');

is $badge->to_html,
   '<a href="http://cpants.cpanauthors.org/release/CSSON/Badge-Depot-Plugin-Kwalitee-0.0100"><img src="http://badgedepot.code301.com/badge/kwalitee/CSSON/Badge-Depot-Plugin-Kwalitee/0.0100" alt="Distribution kwalitee" /></a>',
   'Correct html';

done_testing;
