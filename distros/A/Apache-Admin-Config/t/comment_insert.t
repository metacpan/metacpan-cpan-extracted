use strict;
use Test;
plan test => 20;

use Apache::Admin::Config;
ok(1);

my $conf = new Apache::Admin::Config;
ok(defined $conf);

my $rv = $conf->add_comment('test', '-ontop');
ok(defined $rv);
ok($rv->value, 'test');
ok($rv->first_line, 1);

my $rv2 = $conf->add_comment('test2', '-ontop');
ok(defined $rv2);
ok($rv2->value, 'test2');
ok($rv2->first_line, 1);
ok($rv->first_line, 2);

my $rv3 = $conf->add_comment('test3', '-onbottom');
ok(defined $rv3);
ok($rv3->value, 'test3');
ok($rv3->first_line, 3);
ok($rv2->first_line, 1);
ok($rv->first_line, 2);


my $rv4 = $conf->add_comment('test4', -after=>$conf->comment('test2'));
ok(defined $rv4);
ok($rv4->value, 'test4');
ok($rv4->first_line, 2);
ok($rv3->first_line, 4);
ok($rv2->first_line, 1);
ok($rv->first_line, 3);

