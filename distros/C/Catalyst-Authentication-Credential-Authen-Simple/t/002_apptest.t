use strict;
use warnings;

use Test::More;

plan tests => 35;

use lib 't/lib';

use Catalyst::Test qw/AuthTestApp2/;

cmp_ok(get("/authed_ok?username=bob&password=uniquepass"), 'eq', 'authed Bob Smith', "bob authed through onlyone");
cmp_ok(get("/authed_ok?username=john&password=uniquepass"), 'eq', 'authed John Smith', "john authed through onlyone");

cmp_ok(get("/authed_ko?username=bob&password=bob")       , 'eq', 'not authed', "bob not authed through stub");
cmp_ok(get("/authed_ko?username=john&password=john")       , 'eq', 'not authed', "john not authed through stub");
cmp_ok(get("/authed_ko?username=bob&password=xxx")       , 'eq', 'not authed', "bob not authed");
cmp_ok(get("/authed_ko?username=john&password=xxx")       , 'eq', 'not authed', "john not authed");
cmp_ok(get("/authed_ko?username=notuser&password=uniquepass"), 'eq', 'not authed', "unexistant user not authed");
