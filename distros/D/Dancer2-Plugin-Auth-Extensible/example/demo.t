use strict;
use warnings;

use Test::More;
use Test::WWW::Mechanize;
plan tests => 2;

my $url = "http://127.0.0.1:3000";

subtest visitor => sub {
	plan tests => 20;

	my $visitor = Test::WWW::Mechanize->new;
	$visitor->get_ok($url);
	$visitor->content_like(qr{Non-secret home page!});

	foreach my $page (qw(sake vodka beer secret)) {
		my $res = $visitor->get("$url/$page");
		is $visitor->status, 401, 'status 401';
		is $visitor->uri, "$url/login?return_url=%2F$page";
		#diag $visitor->content;
		$visitor->content_like(qr{You need to log in to continue.});
	}

	$visitor->get("$url/login");
	is $visitor->status, 401, 'status 401';
	is $visitor->uri, "$url/login";
	$visitor->content_like(qr{You need to log in to continue.});

	# Maybe there should be some indication that the authentication failed
	# and maybe it should not return 401. I am not sure. See
	# https://github.com/PerlDancer/Dancer2-Plugin-Auth-Extensible/issues/14
	$visitor->submit_form(
		form_number => 1,
		fields => {
			username => 'foo',
			password => 'bar',
		},
	);
	is $visitor->status, 401, 'status 401';
	$visitor->content_like(qr{You need to log in to continue.});
	#diag $visitor->content;
	is $visitor->uri, "$url/login";

	# TODO logout
};

subtest beerdrinker => sub {
	plan tests => 7;

	my $beerdrinker = Test::WWW::Mechanize->new;
	$beerdrinker->get_ok($url);
	$beerdrinker->follow_link( text => 'log in' );
	is $beerdrinker->status, 401, 'status 401';  # shouldn't this be 200 ??
	$beerdrinker->submit_form_ok({
		form_number => 1,
		fields => {
			username => 'beerdrinker',
			password => 'password',
		},
	});

	$beerdrinker->get_ok("$url/beer");
	is $beerdrinker->content, 'Any drinker can get beer.';

	$beerdrinker->get_ok("$url/secret");
	is $beerdrinker->content, 'Only logged-in users can see this. You are logged in as user Beer drinker';

	# TODO: currently gives 404 https://github.com/PerlDancer/Dancer2-Plugin-Auth-Extensible/issues/15
	# $beerdrinker->get_ok("$url/vodka");
};

