use strict;
use Test;
plan test => 20;

use Apache::Admin::Config;
ok(1);

my $conf = new Apache::Admin::Config;
ok(defined $conf);

my $rv = $conf->add_section(test=>1, '-ontop');
ok(defined $rv);
ok($rv->name, 'test');
ok($rv->first_line, 1);

my $rv2 = $conf->add_section(test2=>2, '-ontop');
ok(defined $rv2);
ok($rv2->name, 'test2');
ok($rv2->first_line, 1);
ok($rv->first_line, 3);

my $rv3 = $conf->add_section(test3=>3, '-onbottom');
ok(defined $rv3);
ok($rv3->name, 'test3');
ok($rv3->first_line, 5);
ok($rv2->first_line, 1);
ok($rv->first_line, 3);


my $rv4 = $conf->add_section(test4=>4, -after=>$conf->section(test2=>2));
ok(defined $rv4);
ok($rv4->name, 'test4');
ok($rv4->first_line, 3);
ok($rv3->first_line, 7);
ok($rv2->first_line, 1);
ok($rv->first_line, 5);
