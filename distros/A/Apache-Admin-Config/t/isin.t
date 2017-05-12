use strict;
use Test;
plan test => 9;

use Apache::Admin::Config;

my $conf = new Apache::Admin::Config;

my $sec1 = $conf->add_section(test=>1);
ok(defined $sec1);
my $sec2 = $sec1->add_section(test=>2);
ok(defined $sec2);
my $sec3 = $sec2->add_section(test=>2);
ok(defined $sec3);

ok($sec1->isin($conf));
ok(!$sec2->isin($conf));
ok(!$sec3->isin($conf));
ok($sec1->isin($conf, '-recursif'));
ok($sec2->isin($conf, '-recursif'));
ok($sec3->isin($conf, '-recursif'));
