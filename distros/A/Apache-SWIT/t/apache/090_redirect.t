use strict;
use warnings FATAL => 'all';

use Test::More tests => 29;
use Apache::SWIT::Test::Utils;

BEGIN { use_ok('T::Test');
	use_ok('Apache::SWIT::Session');
	use_ok('T::Redirect');
	use_ok('T::HTPage');
};

T::Test->make_aliases(redirect => 'T::Redirect');

$SIG{__DIE__} = sub { diag(Carp::longmess(@_)); };
my $t = T::Test->new;
$t->root_location('/test');
$t->redirect_r(make_url => 1);
like($t->mech->uri, qr#/test/swit/r#);
like($t->mech->content, qr/hello world/);

$t->redirect_r(make_url => 1, param => { internal => "../swit/r" });
like($t->mech->uri, qr#/test/redirect/r#);
like($t->mech->content, qr/hello world/);

$t->redirect_r(make_url => 1, param => { internal => "../cthan" });
is($t->mech->ct, "text/plain");
is($t->mech->status, 200);

T::Test->make_aliases(ht_error => 'T::HTError', another_page => 'T::HTPage');

$t->ok_ht_ht_error_r(make_url => 1, ht => { name => "buh", error => ""
		, password => "" });
$t->ht_ht_error_u(ht => { name => "foo", password => "boo" });

# we should not see password going back. Even if its incorrect.
$t->ok_ht_ht_error_r(ht => { name => "foo", password => ""
		, error => "validate" }) or ASTU_Wait;

$t->ht_ht_error_u(ht => { name => "swid", password => "hru" });
$t->ok_ht_ht_error_r(ht => { name => "swid", error => "updateho"
		, password => "" });

$t->ht_ht_error_u(ht => { name => "bad", password => "hru" });
$t->ok_ht_ht_error_r(ht => { name => "bad", error => "validie"
		, password => "" });

$t->ht_ht_error_u(ht => { name => "fail", password => "hru" });
$t->ok_ht_ht_error_r(ht => { name => "fail", error => "failure"
		, password => "" });

$ENV{SWIT_HAS_APACHE} = 0;
$t = T::Test->new({ session_class => 'Apache::SWIT::Session' });
is($t->redirect_request, undef);

$t->ht_ht_error_u(ht => { name => "bad", password => "hru" });
isnt($t->redirect_request, undef);
is($t->redirect_request->param("error"), "validie");
is($t->redirect_request->param("error_uri"), "/test/ht_error/u");

$t->ok_ht_ht_error_r(ht => { name => "bad", error => "validie"
		, password => "" });
is($t->redirect_request, undef);

$t->ht_ht_error_u(ht => { name => "FORBID", password => "hru" });
isnt($t->redirect_request, undef);

$t->ok_follow_link(text => 'doesnt matter');
is($t->redirect_request, undef);

$t->ht_ht_error_u(ht => { name => "FORBID", password => "hru" });
isnt($t->redirect_request, undef);

$t->ok_get('www/hello.html', 200);
is($t->redirect_request, undef);

$t->ht_ht_error_u(ht => { name => "bad", password => "hru" });
$t->ok_ht_ht_error_r(make_url => 1, ht => { name => "buh", error => ""
		, password => "" });

$t->redirect_u(fields => { v1 => 'space' });
$t->ok_ht_another_page_r(ht => { v1 => '' });
