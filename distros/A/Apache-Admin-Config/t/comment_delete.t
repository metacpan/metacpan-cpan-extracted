use strict;
use Test;
plan test => 5;

use Apache::Admin::Config;
ok(1);

my $conf = new Apache::Admin::Config;
ok(defined $conf);

$conf->add_comment('test1');
$conf->add_comment('test2');
$conf->add_comment('test3');
$conf->add_comment('test4');
$conf->add_comment('test5');
$conf->add_comment('test6');

ok($conf->comment('test3')->first_line, 3);
ok($conf->comment('test4')->first_line, 4);

$conf->comment('test3')->delete;
ok($conf->comment('test4')->first_line, 3);

