use strict;
use Test;
plan test => 5;

use Apache::Admin::Config;
ok(1);

my $conf = new Apache::Admin::Config;
ok(defined $conf);

$conf->add_directive(test=>1);
$conf->add_directive(test=>2);
$conf->add_directive(test=>3);
$conf->add_directive(test=>4);
$conf->add_directive(test=>5);
$conf->add_directive(test2=>6);

ok($conf->directive(test=>3)->first_line, 3);
ok($conf->directive(test=>4)->first_line, 4);

$conf->directive(test=>3)->delete;
ok($conf->directive(test=>4)->first_line, 3);

