use strict;
use Test::More 0.98 tests => 24;

use Date::Cutoff::JP;
my $dco = Date::Cutoff::JP->new({ cutoff => 10, late => 0, payday => 0 });

my %calc = $dco->calc_date('2019-01-15');
is $calc{cutoff}, '2019-02-12', "cutoff for Jan.";
is $calc{payday}, '2019-02-28', "payday for Jan.";

%calc = $dco->calc_date('2019-02-15');
is $calc{cutoff}, '2019-03-11', "cutoff for Feb.";
is $calc{payday}, '2019-04-01', "payday for Feb.";

%calc = $dco->calc_date('2019-03-15');
is $calc{cutoff}, '2019-04-10', "cutoff for Mar.";
is $calc{payday}, '2019-05-07', "payday for Mar."; # 特別連休のため

%calc = $dco->calc_date('2019-04-15');
is $calc{cutoff}, '2019-05-10', "cutoff for Apr.";
is $calc{payday}, '2019-05-31', "payday for Apr.";

%calc = $dco->calc_date('2019-05-15');
is $calc{cutoff}, '2019-06-10', "cutoff for May.";
is $calc{payday}, '2019-07-01', "payday for May.";

%calc = $dco->calc_date('2019-06-15');
is $calc{cutoff}, '2019-07-10', "cutoff for Jun.";
is $calc{payday}, '2019-07-31', "payday for Jun.";

%calc = $dco->calc_date('2019-07-15');
is $calc{cutoff}, '2019-08-13', "cutoff for Jul.";
is $calc{payday}, '2019-09-02', "payday for jul.";

%calc = $dco->calc_date('2019-08-15');
is $calc{cutoff}, '2019-09-10', "cutoff for Aug.";
is $calc{payday}, '2019-09-30', "payday for Aug.";

%calc = $dco->calc_date('2019-09-15');
is $calc{cutoff}, '2019-10-10', "cutoff for Sep.";
is $calc{payday}, '2019-10-31', "payday for Sep.";

%calc = $dco->calc_date('2019-10-15');
is $calc{cutoff}, '2019-11-11', "cutoff for Oct.";
is $calc{payday}, '2019-12-02', "payday for Oct.";

%calc = $dco->calc_date('2019-11-15');
is $calc{cutoff}, '2019-12-10', "cutoff for Nov.";
is $calc{payday}, '2019-12-31', "payday for Nov.";

%calc = $dco->calc_date('2019-12-15');
is $calc{cutoff}, '2020-01-10', "cutoff for Dec.";
is $calc{payday}, '2020-01-31', "payday for Dec.";

done_testing;
