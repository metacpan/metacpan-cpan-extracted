use Test::More tests => 18;

BEGIN { use_ok( 'Date::Parser' ); }
require_ok( 'Date::Parser' );

my $dp = Date::Parser->new;

ok($dp->isa("Date::Parser"), "constructor is working");

my $format = "%b %d %H:%M:%S";
my $data = "Jan 23 14:12:59 example log line";
my $date = $dp->parse_data($format, $data);

ok($date->isa("Date::Parser::Date"), "parse_data is working");
cmp_ok($date->unixtime, '==', 1295784779, "unixtime is working");

$format = "%a %b %d %H:%M:%S %Y";
$data = "[Tue Jan 25 01:23:42 2011] [error] [client 66.249.72.173] Options ExecCGI is off in this directory: /var/git/git.cgi";
my $date2 = $dp->parse_data($format, $data);

ok($date->isa("Date::Parser::Date"), "parse_data is working");
cmp_ok($date2->unixtime, '==', 1295911422, "unixtime is working");

cmp_ok($date->cmp($date2), '==', -1, "cmp before is working");
cmp_ok($date2->cmp($date), '==', 1, "cmp after is working");

$format = "%a %b %d %H:%M:%S %Y";
$data = "[Tue Jan 25 01:23:42 2011] [error] [client 1.2.3.4] Options ExecCGI is off in this directory: /var/www";
my $date3 = $dp->parse_data($format, $data);

cmp_ok($date2->cmp($date3), '==', 0, "cmp equal is working");

my $delta = $date3->calc($date2);

ok($delta->isa("Date::Parser::Date"), "calc returns Date::Parser::Date");
cmp_ok($delta->unixtime, '==', 1295911422, "calc 0 is working");

$delta = $date->calc($date2);

ok($delta->isa("Date::Parser::Date"), "calc returns Date::Parser::Date");
cmp_ok($delta->cmp($date2), '==', -1, "calc -1 is working");
cmp_ok($delta->cmp($date), '==', 1, "calc -1 is working");

$delta = $date2->calc($date);

ok($delta->isa("Date::Parser::Date"), "calc returns Date::Parser::Date");
cmp_ok($delta->cmp($date), '==', 1, "calc 1 is working");
cmp_ok($delta->cmp($date2), '==', -1, "calc 1 is working");
