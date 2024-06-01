use strict;
use Test::More 0.98 tests => 24;

use Date::Cutoff::JP;
my $dco = Date::Cutoff::JP->new({ cutoff => 0, late => 1, payday => 0 });

my %calc = $dco->calc_date('2019-01-01');
is $calc{cutoff}, '2019-01-31', "cutoff for Jan.";
is $calc{payday}, '2019-02-28', "payday for Jan.";

%calc = $dco->calc_date('2019-02-01');
is $calc{cutoff}, '2019-02-28', "cutoff for Feb.";
is $calc{payday}, '2019-04-01', "payday for Feb.";

%calc = $dco->calc_date('2019-03-01');
is $calc{cutoff}, '2019-04-01', "cutoff for Mar.";
is $calc{payday}, '2019-05-07', "payday for Mar."; # 特別連休のため

%calc = $dco->calc_date('2019-04-01');
is $calc{cutoff}, '2019-05-07', "cutoff for Apr."; # 特別連休のため
is $calc{payday}, '2019-05-31', "payday for Apr.";

%calc = $dco->calc_date('2019-05-01');
is $calc{cutoff}, '2019-05-31', "cutoff for May.";
is $calc{payday}, '2019-07-01', "payday for May.";

%calc = $dco->calc_date('2019-06-01');
is $calc{cutoff}, '2019-07-01', "cutoff for Jun.";
is $calc{payday}, '2019-07-31', "payday for Jun.";

%calc = $dco->calc_date('2019-07-01');
is $calc{cutoff}, '2019-07-31', "cutoff for Jul.";
is $calc{payday}, '2019-09-02', "payday for jul.";

%calc = $dco->calc_date('2019-08-01');
is $calc{cutoff}, '2019-09-02', "cutoff for Aug.";
is $calc{payday}, '2019-09-30', "payday for Aug.";

%calc = $dco->calc_date('2019-09-01');
is $calc{cutoff}, '2019-09-30', "cutoff for Sep.";
is $calc{payday}, '2019-10-31', "payday for Sep.";

%calc = $dco->calc_date('2019-10-01');
is $calc{cutoff}, '2019-10-31', "cutoff for Oct.";
is $calc{payday}, '2019-12-02', "payday for Oct.";

%calc = $dco->calc_date('2019-11-01');
is $calc{cutoff}, '2019-12-02', "cutoff for Nov.";
is $calc{payday}, '2019-12-31', "payday for Nov.";

%calc = $dco->calc_date('2019-12-01');
is $calc{cutoff}, '2019-12-31', "cutoff for Dec.";
is $calc{payday}, '2020-01-31', "payday for Dec.";

done_testing;
