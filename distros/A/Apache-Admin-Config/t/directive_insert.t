use strict;
use Test;
plan test => 20;

use Apache::Admin::Config;
ok(1);

my $conf = new Apache::Admin::Config;
ok(defined $conf);

my $rv = $conf->add_directive('test', '-ontop');
ok(defined $rv);
ok($rv->name, 'test');
ok($rv->first_line, 1);

my $rv2 = $conf->add_directive('test2', '-ontop');
ok(defined $rv2);
ok($rv2->name, 'test2');
ok($rv2->first_line, 1);
ok($rv->first_line, 2);

my $rv3 = $conf->add_directive('test3', '-onbottom');
ok(defined $rv3);
ok($rv3->name, 'test3');
ok($rv3->first_line, 3);
ok($rv2->first_line, 1);
ok($rv->first_line, 2);


my $rv4 = $conf->add_directive('test4', -after=>$conf->directive('test2'));
ok(defined $rv4);
ok($rv4->name, 'test4');
ok($rv4->first_line, 2);
ok($rv3->first_line, 4);
ok($rv2->first_line, 1);
ok($rv->first_line, 3);

