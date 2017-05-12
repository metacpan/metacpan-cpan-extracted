use strict;
use warnings;
use Test::More 0.88;
use Test::Output;
use Test::Exception;
use t::AppLogStatsTest qw/test_stats/;

use App::LogStats;

t::AppLogStatsTest::set_interactive();

{
    my $stats = App::LogStats->new;
    isa_ok($stats, 'App::LogStats');

    stdout_is { $stats->run; } '', 'just run';
}

{
    my $stats = App::LogStats->new;
    throws_ok {
        $stats->run('_no_exists_file_');
    } qr/^_no_exists_file_: No such file/, 'no_exists_file';
}

test_stats('');

test_stats(<<'_TXT_', 'share/log1');

 --------- ------ 
               1  
 --------- ------ 
  count       10  
  sum         55  
 --------- ------ 
  average   5.50  
 --------- ------ 
  max         10  
  min          1  
  range        9  
 --------- ------ 
_TXT_

test_stats(<<"_TXT_", '--tsv', 'share/log1');

\t1
count\t10
sum\t55
average\t5.50
max\t10
min\t1
range\t9
_TXT_

test_stats(<<"_TXT_", '--csv', 'share/log1');

,"1"
"count","10"
"sum","55"
"average","5.50"
"max","10"
"min","1"
"range","9"
_TXT_

test_stats(<<'_TXT_', '--strict', 'share/log1');

 --------- ------ 
               1  
 --------- ------ 
  count       10  
  sum         55  
 --------- ------ 
  average   5.50  
 --------- ------ 
  max         10  
  min          1  
  range        9  
 --------- ------ 
_TXT_

test_stats(<<'_TXT_', '--through', 'share/log1');
1
2
3
4
5
6
7
8
9
10

 --------- ------ 
               1  
 --------- ------ 
  count       10  
  sum         55  
 --------- ------ 
  average   5.50  
 --------- ------ 
  max         10  
  min          1  
  range        9  
 --------- ------ 
_TXT_

test_stats(<<'_TXT_', '--digit', 3, 'share/log1');

 --------- ------- 
                1  
 --------- ------- 
  count        10  
  sum          55  
 --------- ------- 
  average   5.500  
 --------- ------- 
  max          10  
  min           1  
  range         9  
 --------- ------- 
_TXT_

test_stats(<<'_TXT_', '--through', 'share/log1');
1
2
3
4
5
6
7
8
9
10

 --------- ------ 
               1  
 --------- ------ 
  count       10  
  sum         55  
 --------- ------ 
  average   5.50  
 --------- ------ 
  max         10  
  min          1  
  range        9  
 --------- ------ 
_TXT_

{
    my $expect = <<'_TXT_';

 --------- ---- 
             1  
 --------- ---- 
  count      5  
  sum       15  
 --------- ---- 
  average    3  
 --------- ---- 
  max        5  
  min        1  
  range      4  
 --------- ---- 
_TXT_

    test_stats($expect, 'share/log2');
    test_stats($expect, '-f1', 'share/log2');
}

test_stats(<<'_TXT_', '--more', 'share/log1');

 ---------- ------ 
                1  
 ---------- ------ 
  count        10  
  sum          55  
 ---------- ------ 
  average    5.50  
  median     5.50  
  mode       5.50  
 ---------- ------ 
  max          10  
  min           1  
  range         9  
  variance   9.17  
  stddev     3.03  
 ---------- ------ 
_TXT_

test_stats(<<'_TXT_', '-f1,2', 'share/log2');

 --------- ---- ---- 
             1    2  
 --------- ---- ---- 
  count      5    5  
  sum       15   40  
 --------- ---- ---- 
  average    3    8  
 --------- ---- ---- 
  max        5   10  
  min        1    6  
  range      4    4  
 --------- ---- ---- 
_TXT_

test_stats(<<"_TXT_", '-f1,2', '--tsv', 'share/log2');

\t1\t2
count\t5\t5
sum\t15\t40
average\t3\t8
max\t5\t10
min\t1\t6
range\t4\t4
_TXT_

test_stats(<<"_TXT_", '-f1,2', '--csv', 'share/log2');

,"1","2"
"count","5","5"
"sum","15","40"
"average","3","8"
"max","5","10"
"min","1","6"
"range","4","4"
_TXT_

test_stats(<<'_TXT_', '-f1,2,3', 'share/log2');

 --------- ---- ---- --- 
             1    2   3  
 --------- ---- ---- --- 
  count      5    5   -  
  sum       15   40   -  
 --------- ---- ---- --- 
  average    3    8   -  
 --------- ---- ---- --- 
  max        5   10   -  
  min        1    6   -  
  range      4    4   -  
 --------- ---- ---- --- 
_TXT_

test_stats(<<'_TXT_', '-f2,1,3', 'share/log2');

 --------- ---- ---- --- 
             1    2   3  
 --------- ---- ---- --- 
  count      5    5   -  
  sum       15   40   -  
 --------- ---- ---- --- 
  average    3    8   -  
 --------- ---- ---- --- 
  max        5   10   -  
  min        1    6   -  
  range      4    4   -  
 --------- ---- ---- --- 
_TXT_

test_stats(<<'_TXT_', '-f1,2', '-d,', 'share/log3');

 --------- ---------- ------- 
                   1       2  
 --------- ---------- ------- 
  count            3       3  
  sum          6,800   3,900  
 --------- ---------- ------- 
  average   2,266.67   1,300  
 --------- ---------- ------- 
  max          3,400   1,400  
  min          1,100   1,200  
  range        2,300     200  
 --------- ---------- ------- 
_TXT_

test_stats(<<'_TXT_', '-f1,2', '-d,', '--no-comma', 'share/log3');

 --------- --------- ------ 
                  1      2  
 --------- --------- ------ 
  count           3      3  
  sum          6800   3900  
 --------- --------- ------ 
  average   2266.67   1300  
 --------- --------- ------ 
  max          3400   1400  
  min          1100   1200  
  range        2300    200  
 --------- --------- ------ 
_TXT_

test_stats(<<'_TXT_', '-f1,2', '-d,', '--no-comma', '--more', 'share/log3');

 ---------- ------------ ------- 
                      1       2  
 ---------- ------------ ------- 
  count               3       3  
  sum              6800    3900  
 ---------- ------------ ------- 
  average       2266.67    1300  
  median           2300    1300  
  mode          2266.67    1300  
 ---------- ------------ ------- 
  max              3400    1400  
  min              1100    1200  
  range            2300     200  
  variance   1323333.33   10000  
  stddev        1150.36     100  
 ---------- ------------ ------- 
_TXT_

test_stats(<<'_TXT_', '--rc', 'share/.statsrc');

 ---------- ------ 
                1  
 ---------- ------ 
  count        10  
  sum          55  
 ---------- ------ 
  average    5.50  
  median     5.50  
  mode       5.50  
 ---------- ------ 
  max          10  
  min           1  
  range         9  
  variance   9.17  
  stddev     3.03  
 ---------- ------ 
_TXT_

done_testing;
