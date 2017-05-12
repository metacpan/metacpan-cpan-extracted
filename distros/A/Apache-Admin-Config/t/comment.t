use strict;
use Test;
plan test => 5;

use Apache::Admin::Config;
ok(1);

my $apache = new Apache::Admin::Config ('t/httpd.conf-dist');
ok(defined $apache);

my @list = $apache->comment;
ok(@list, 85);

my $sec = $apache->section(-which=>1);
ok(defined $sec);
my $comment = $sec->comment(-which=>0);
ok($comment->first_line, 304);
