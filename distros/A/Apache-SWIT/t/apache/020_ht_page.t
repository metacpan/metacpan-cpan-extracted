use strict;
use warnings FATAL => 'all';

use Test::More tests => 32;
use File::Temp qw(tempdir);
use File::Slurp;
use Apache::SWIT::Session;
use Apache::SWIT::Test::Utils;

BEGIN { use_ok('T::Test');
	use_ok('Apache::SWIT::HTPage'); 
	use_ok('T::HTPage');
}

$ENV{SWIT_HAS_APACHE} = 0;

my $_hp = "http://" .  Apache::TestRequest::hostport() . "/";

my $td = tempdir("/tmp/swit_ht_page_XXXXXXX", CLEANUP => 1);

T::Test->make_aliases(another_page => 'T::HTPage',
		, inhe_page => 'T::HTInherit', "and/another" => 'T::HTPage');

my $t = T::Test->new({ session_class => 'Apache::SWIT::Session' });
$t->ok_ht_another_page_r(base_url => '/test/ht_page', ht => { 
		hello => 'world', HT_SEALED_hid => 'secret'
		, v1 => undef, }) or ASTU_Wait;

my $res = $t->ok_ht_another_page_r(base_url => '/test/ht_page', 
	param => { v1 => 'hi', },
	ht => { hello => 'world', v1 => 'hi', hostport => $_hp
		, req_uri => '/test/ht_page' });
is($res, 1);

$t->ok_ht_another_page_r(ht => { req_uri => '/another_page/r',
		hello => 'world', HT_SEALED_hid => 'secret', v1 => undef, });

$t->ok_ht_another_page_r(base_url => '/test/ht_page', 
	param => { HT_SEALED_hid => 'momo', },
	ht => { HT_SEALED_hid => 'momo' });

write_file("$td/up.txt", "Hello\nworld\n");

my @x = $t->ht_another_page_u(ht => { file => "$td/uuu"
					, up => "$td/up.txt" });
my $ur = read_file("$td/uuu");
is(unlink("$td/uuu"), 1);
is_deeply(\@x, [ '/test/basic_handler' ]);
is($ur, "$td/up.txt\nHello\nworld\n");

# for direct only we can pass stuff also through param.
# Hiddens stay untouched this way.
$t->ht_another_page_u(param => { file => "$td/fff" }
	, ht => { up => "$td/up.txt" });
isnt(-f "$td/fff", undef);

$ENV{SWIT_HAS_APACHE} = 1;
$t = T::Test->new({ session_class => 'Apache::SWIT::Session' });

# $SIG{__DIE__} = sub { diag(Carp::longmess(@_)); };
$t->ok_ht_inhe_page_r(param => { inhe => 'FFF' }
		, base_url => '/test/inhe_page/r', ht => { 
		hello => 'world', HT_SEALED_hid => 'secret'
		, inhe_val => 'FFF'
		, hostport => $_hp });

$t->ok_ht_another_page_r(base_url => '/test/ht_page/r', ht => { 
		hello => 'world', HT_SEALED_hid => 'secret'
		, hostport => $_hp });
like($t->mech->content, qr/got more/);
like($t->mech->content, qr#:templates/htpage\.tt:#);

$t->ok_ht_another_page_r(base_url => '/test/ht_page/r'
	, param => { HT_SEALED_hid => 'gaga' }, ht => { 
		hello => 'world', HT_SEALED_hid => 'gaga' });

$t->ok_ht_another_page_r(param => { HT_SEALED_hid => 'gaga' }, ht => { 
		hello => 'world', HT_SEALED_hid => 'gaga' });

@x = $t->ht_another_page_r(base_url => '/test/ht_page/r'
		, ht => { hello => 'life' });
isnt($x[0], undef);

is(read_file("$td/up.txt"), "Hello\nworld\n");
is(unlink("$td/uuu"), 0);

# give param to show it doesn't affect anything in apache
@x = $t->ht_another_page_u(param => { file => "$td/hru" }
		, ht => { file => "$td/uuu", up => "$td/up.txt" });
is(-f "$td/hru", undef);

$ur = read_file("$td/uuu");
is(unlink("$td/uuu"), 1);
is(@x, 1);
like($x[0], qr/hhhh/);
is($ur, "$td/up.txt\nHello\nworld\n");

my @al1 = ASTU_Read_Access_Log();
$t->mech->reload;
my @al2 = ASTU_Read_Access_Log();
is(@al2, @al1 + 1);

like($t->mech->content, qr/hhhh/);
is(unlink("$td/uuu"), 0);

$t->ok_ht_and_another_r(base_url => '/test/ht_page/r', ht => { 
		hello => 'world' });

eval {
	$t->ht_another_page_u(form_name => 'aa'
			, ht => { inv_up => "$td/up.txt" });
};
like($@, qr/multipart/);

eval {
	local *STDERR;
	open STDERR, '>/dev/null';
	$t->ht_another_page_u(form_name => 'bwbbw'
			, ht => { inv_up => "$td/up.txt" });
};
like($@, qr/No form_name/);
