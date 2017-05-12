use strict;
use warnings FATAL => 'all';

use Test::More tests => 63;
use File::Basename qw(dirname);
use File::Temp qw(tempdir);
use Data::Dumper;
use File::Slurp;
use Apache::SWIT::Test::Utils;
use Apache::SWIT::Session;

BEGIN { 
	unlink "/tmp/swit_startup_test";
	use_ok('T::Test');
	;
}

$ENV{SWIT_HAS_APACHE} = 0;

my $td = tempdir("/tmp/swit_tester_XXXXXXX", CLEANUP => 1);

my @sls = read_file("/tmp/swit_startup_test");
is(@sls, 1) or diag(join("", @sls));
like($sls[0], qr/T::SWIT .*blib.*do_swit_startups/);

T::Test->make_aliases(the_page => 'T::SWIT', res => 'T::Res');
can_ok('T::SWIT', 'can') or exit 1;
can_ok('T::Res', 'can');

@sls = read_file("/tmp/swit_startup_test");
is(@sls, 1) or diag(join("", @sls));
like($sls[0], qr/T::SWIT .*blib.*do_swit_startups/);
unlike(join("", @sls), qr/T .*Test\.pm/);
unlink("/tmp/swit_startup_test");

my $t = T::Test->new({ session_class => 'Apache::SWIT::Session' });
isa_ok($t, 'T::Test');
is($t->mech, undef);
isnt($t->session->request, undef);
is($t->session->request->pnotes('SWITSession'), $t->session);

my @res = $t->the_page_r(base_url => '/test/swit');
is_deeply(\@res, [ { hello => 'world', request => 'reqboo' } ]);

@res = $t->the_page_u(fields => { file => "$td/uuu" });
is(read_file("$td/uuu"), '');
is(read_file("$td/uuu.uri"), '/the_page/u');
is(unlink("$td/uuu"), 1);
is_deeply(\@res, [ '/test/res/r?res=hhhh' ]);

@res = $t->the_page_u(button => [ but => 'Push' ]
			, fields => { file => "$td/uuu" });
is(read_file("$td/uuu"), 'Push');
is(unlink("$td/uuu"), 1);
is_deeply(\@res, [ '/test/res/r?res=hhhh' ]);

# does nothing
is($t->ok_follow_link(text => 'This'), -1);
$t->ok_get('/test/www/hello.html');
$t->content_like(qr/HELLO, HTML/);

@res = $t->res_r;
is_deeply(\@res, [ { res => undef } ]);

@res = $t->res_r(param => { res => 'hhhh' });
is_deeply(\@res, [ { res => 'hhhh' } ])
	or diag(Dumper(\@res));

$ENV{SWIT_HAS_APACHE} = 1;
$t = T::Test->new;
isa_ok($t->mech, 'WWW::Mechanize');
@res = $t->the_page_r(base_url => '/test/swit/r');
is_deeply(\@res, [ <<ENDS ]);
<html>
<body>
<form action="u">
hello world
<input type="text" name="file" />
<input type="submit" name="but" value="Push" />
<a href="r">This</a>
reqboo
</form>
</body>
</html>
ENDS

@res = $t->the_page_u(fields => { file => "$td/uuu" });
is(read_file("$td/uuu"), '');
is(unlink("$td/uuu"), 1);
is_deeply(\@res, [ "hhhh\n" ]);

$t->the_page_r(base_url => '/test/swit/r');
@res = $t->the_page_u(button => [ but => 'Push' ]
		, fields => { file => "$td/uuu" });
is(read_file("$td/uuu"), 'Push');
is(unlink("$td/uuu"), 1);
is_deeply(\@res, [ "hhhh\n" ]);

$t->the_page_r(base_url => '/test/swit/r');
$t->the_page_u(fields => { file => "$td/CTYPE" });
is($t->mech->ct, "text/plain");
unlike(ASTU_Read_Error_Log(), qr/\[error\]/);

$t->the_page_r(base_url => '/test/swit/r');
$t->the_page_u(fields => { file => "$td/RESPOND" });
$t->content_like(qr/RESPONSE/);
is(-f "$td/RESPOND", undef);
like(ASTU_Read_Access_Log(), qr/RESPOND.*HTTP/);

my $uri = $t->mech->uri;
$t->mech->get($uri);
is($t->mech->status, 200) or ASTU_Wait;

$t->mech->post($t->mech->uri, { file => "$td/RESPOND" }
	, 'Accept-Encoding', 'gzip,deflate');
is($t->mech->status, 200) or ASTU_Wait;

my $resp = $t->mech->response->as_string;
unlike($resp, qr/RESPONSE/);
like($resp, qr/Content-Encoding: gzip/);

T::Test->make_aliases("another/page" => 'T::SWIT');
$t->root_location('/test');
@res = $t->another_page_r(make_url => 1);
is_deeply(\@res, [ <<ENDS ]);
<html>
<body>
<form action="u">
hello world
<input type="text" name="file" />
<input type="submit" name="but" value="Push" />
<a href="r">This</a>
reqboo
</form>
</body>
</html>
ENDS

# works
is($t->ok_follow_link(text => 'This'), 1);
$t->ok_get('/test/www/hello.html');
my $_hc = $t->mech->content;
my $_uri = $t->mech->uri;

$t->content_like(qr/HELLO, HTML/);
is($t->mech->response->headers->content_encoding, "gzip") or ASTU_Wait;

$t->ok_get('/test/www/hello.svg');
is($t->mech->response->headers->content_encoding, "gzip") or ASTU_Wait;

$t->ok_get('/test/www/hello.xhtml');
is($t->mech->response->headers->content_encoding, "gzip") or ASTU_Wait;

$t->ok_get('/test/www/nothing.html', 404);

$t->ok_get($_uri);
is($t->mech->content, $_hc);

# relative to root location
$t->ok_get('www/hello.html', 200);

$t->mech->max_redirect(0);
$t->ok_get("/test/swit/u?file=$td/uuu", 302);
$t->mech->max_redirect(7);

$t->ok_get("/test/ht_page/r?redir=1");
is($t->mech->content, $_hc);

$t->ok_get("/test/ht_page/r?internal=1");
is($t->mech->content, $_hc);
like($t->mech->uri, qr#/test/ht_page/r\?internal=1#);
