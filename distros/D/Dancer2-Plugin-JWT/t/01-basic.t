use strict;
use warnings;

use Test::More import => ['!pass'];
#use Plack::Test;
use  Test::WWW::Mechanize::PSGI;
use HTTP::Request::Common;
use Crypt::JWT qw(encode_jwt decode_jwt);


#plan tests => 5;

{
	use Dancer2;
	BEGIN {
		set plugins => { JWT => { secret => 'secret'}};
	}
	use Dancer2::Plugin::JWT;

	set log => 'debug';

	get '/defined/jwt' => sub {
		defined(jwt) ? "DEFINED" : "UNDEFINED";
	};

	get '/define/jwt' => sub {
		jwt { my => 'data' };
		"OK";
	};

	get '/redirect/jwt' => sub {
		jwt { my => 'redirect' };
		redirect "/";
	};

	get '/' => sub {
		"OK";
	};
}

my $app = __PACKAGE__->to_app;
is (ref $app, 'CODE', 'Got the test app');

my $mech =  Test::WWW::Mechanize::PSGI -> new ( app => $app );

$mech->get_ok('/defined/jwt');
$mech->content_is("UNDEFINED", "by default it is undef");

$mech->get_ok('/define/jwt');
$mech->content_is("OK", "No exceptions on defining jwt");

my $response = $mech->res();
my $authorization = $response->authorization;
ok($authorization, "We have something");
ok($mech->header_exists_ok('Authorization'), 'Has Authorization header');
ok($mech->header_exists_ok('Set-Cookie'), 'Has Set-Cookie header');
ok($mech->lacks_header_ok('Location'), 'No Location header');
my $x = decode_jwt(token => $authorization, key => "secret");
is_deeply($x, {my => 'data'}, "Got correct data back");

$mech->add_header("Authorization" => $authorization);
$mech->get_ok("/defined/jwt");
$mech->content_is("DEFINED", "We got something");

# Auth header with Bearer schema
$mech->add_header("Authorization" => 'Bearer ' . $authorization);
$mech->get_ok("/defined/jwt");
$mech->content_is("DEFINED", "We got something");

# Wrong number of spaces in Auth header
$mech->add_header("Authorization" => 'Bearer  ' . $authorization);
$mech->get_ok("/redirect/jwt");
$mech->content_is("OK", "we redirected");

# Auth header with a wrong schema
$mech->add_header("Authorization" => 'Basic ' . $authorization);
$mech->get_ok("/redirect/jwt");
$mech->content_is("OK", "we redirected");

$mech->delete_header("Authorization");
$mech->get_ok("/redirect/jwt");
$mech->content_is("OK", "we redirected");

$response = $mech->res();
$authorization = $response->authorization;
ok($authorization, "Redirect keeped jwt");
$x = eval { decode_jwt(token => $authorization, key => "secret") };
is_deeply($x, {my => 'redirect'}, "Got correct data back even with redirect");

done_testing();
__END__
test_psgi $app, sub {
	my $cb = shift;

	is $cb->(GET '/defined/jwt')->content, "UNDEFINED", "by default it is undef";

	#--
	{
		my $ans = $cb->(GET '/define/jwt');
	
		is $ans->content, "OK", "No exceptions on defining jwt";
		my $authorization = $ans->header("Authorization");
		ok($authorization, "We have something");
		my $x = decode_jwt(token => $authorization, key => "secret");
		is_deeply($x, {my => 'data'}, "Got correct data back");

		is $cb->(HTTP::Request->new(GET => '/defined/jwt',
			HTTP::Headers->new(Authorization => $authorization)))->content,
			"DEFINED", "we got something";
	}


	#--
};
