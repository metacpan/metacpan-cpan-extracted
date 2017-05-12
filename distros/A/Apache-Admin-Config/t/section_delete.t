use strict;
use Test;
plan test => 5;

use Apache::Admin::Config;
ok(1);

my $conf = new Apache::Admin::Config;
ok(defined $conf);

$conf->add_section(test=>1);
$conf->add_section(test=>2);
$conf->add_section(test=>3);
$conf->add_section(test=>4);
$conf->add_section(test=>5);
$conf->add_section(test2=>6);

ok($conf->section(test=>3)->first_line, 5);
ok($conf->section(test=>4)->first_line, 7);

$conf->section(test=>3)->delete;
ok($conf->section(test=>4)->first_line, 5);

