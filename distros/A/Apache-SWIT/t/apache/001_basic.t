use strict;
use warnings FATAL => 'all';

use Test::More tests => 24;
use File::Temp qw(tempdir);
use File::Basename qw(dirname);
use File::Slurp;
use Apache::SWIT::Test::Utils;

BEGIN { use_ok('T::Test'); }

is(HTV(), 'HTML::Tested::Value');
is(HT(), 'HTML::Tested');
is(HTJ(), 'HTML::Tested::JavaScript');
is($ENV{SWIT_HAS_APACHE}, 1);
ok(-f "$INC[0]/../conf/seal.key");

# our blib should be first
like($INC[0], qr/blib/);

my $s_up = "$INC[0]/../conf/startup.pl";
ok(-f $s_up);
like(read_file($s_up), qr/Seal/);

my $t = T::Test->new;
$t->root_location('/test');

like($0, qr/001_basic/);
ok($t->mech);
$t->mech_get_base("/test/basic_handler");
like($t->mech->content, qr/hhhh/) or ASTU_Wait();
like($t->mech->content, qr/blib/);

$t->mech_get_base('basic_handler');
like($t->mech->content, qr/hhhh/) or ASTU_Wait();

$t->mech_get_base("/test/swit/r");
like($t->mech->content, qr/hello world/);
like($t->mech->content, qr/reqboo/);

my $td = tempdir("/tmp/swit_basic_XXXXXXX", CLEANUP => 1);
$t->mech->submit_form(fields => { file => "$td/fff" });

# Redirected to res handler
is($t->mech->content, "hhhh\n") or ASTU_Wait();
ok(-f "$td/fff");

$t->mech_get_base("/test/cthan");
is($t->mech->ct, "text/plain");
is($t->mech->status, 200);

like(ASTU_Read_Error_Log(), qr/normal operations/);
like(ASTU_Read_Access_Log(), qr/GET/);

my $env = $ENV{APACHE_SWIT_SERVER_URL};
{
	local $ENV{APACHE_SWIT_SERVER_URL} = "$env/test";
	$t->mech_get_base("/swit/r");
	like($t->mech->content, qr/hello world/);
};
# ok_get works with other protocols
$t->ok_get('https://mail.google.com');
