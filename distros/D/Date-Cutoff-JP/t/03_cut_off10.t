use strict;
use Test::More 0.98 tests => 24;

use lib './lib';

use Date::Cutoff::JP;
my $dco = Date::Cutoff::JP->new({ cutoff => 10, late => 1, payday => 0 });

my %calc = $dco->calc_date('2019-01-01');
is $calc{cutoff}, '2019-01-10', "cutoff is ok for Jan.";
is $calc{payday}, '2019-02-28', "payday is ok for Jan.";

%calc = $dco->calc_date('2019-02-01');
is $calc{cutoff}, '2019-02-12', "cutoff is ok for Feb.";
is $calc{payday}, '2019-04-01', "payday is ok for Feb.";

%calc = $dco->calc_date('2019-03-01');
is $calc{cutoff}, '2019-03-11', "cutoff is ok for Mar.";
is $calc{payday}, '2019-04-30', "payday is ok for Mar."; # 特別連休のため本当は5月7日

%calc = $dco->calc_date('2019-04-01');
is $calc{cutoff}, '2019-04-10', "cutoff is ok for Apr.";
is $calc{payday}, '2019-05-31', "payday is ok for Apr.";

%calc = $dco->calc_date('2019-05-01');
is $calc{cutoff}, '2019-05-10', "cutoff is ok for May.";
is $calc{payday}, '2019-07-01', "payday is ok for May.";

%calc = $dco->calc_date('2019-06-01');
is $calc{cutoff}, '2019-06-10', "cutoff is ok for Jun.";
is $calc{payday}, '2019-07-31', "payday is ok for Jun.";

%calc = $dco->calc_date('2019-07-01');
is $calc{cutoff}, '2019-07-10', "cutoff is ok for Jul.";
is $calc{payday}, '2019-09-02', "payday is ok for jul.";

%calc = $dco->calc_date('2019-08-01');
is $calc{cutoff}, '2019-08-12', "cutoff is ok for Aug."; # 山の日の振替休日があるので本当は13日
is $calc{payday}, '2019-09-30', "payday is ok for Aug.";

%calc = $dco->calc_date('2019-09-01');
is $calc{cutoff}, '2019-09-10', "cutoff is ok for Sep.";
is $calc{payday}, '2019-10-31', "payday is ok for Sep.";

%calc = $dco->calc_date('2019-10-01');
is $calc{cutoff}, '2019-10-10', "cutoff is ok for Oct.";
is $calc{payday}, '2019-12-02', "payday is ok for Oct.";

%calc = $dco->calc_date('2019-11-01');
is $calc{cutoff}, '2019-11-11', "cutoff is ok for Nov.";
is $calc{payday}, '2019-12-31', "payday is ok for Nov.";

%calc = $dco->calc_date('2019-12-01');
is $calc{cutoff}, '2019-12-10', "cutoff is ok for Dec.";
is $calc{payday}, '2020-01-31', "payday is ok for Dec.";

done_testing;
