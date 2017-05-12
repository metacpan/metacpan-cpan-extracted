use strict;
use warnings;

use Test::More import => ['!pass'];
#use Plack::Test;
use  Test::WWW::Mechanize::PSGI;
use HTTP::Request::Common;
use JSON::WebToken;
use Data::Dumper;

#plan tests => 5;

{
	use Dancer2;
	BEGIN {
		set plugins => { JWT => { secret => 'secret'}};
	}
	use Dancer2::Plugin::JWT;

	set log => 'debug';

	hook 'jwt_exception' => sub { 
		halt(Dumper($_[0]));
	};

	get '/' => sub {
		"OK";
	};

}

my $app = __PACKAGE__->to_app;
is (ref $app, 'CODE', 'Got the test app');

my $mech =  Test::WWW::Mechanize::PSGI -> new ( app => $app );

my $authorization = 'FDAHFKDAHFKDFKAGFKAHKJAHFKgdhfdhfajkdgdsad';
$mech->add_header("Authorization" => $authorization);
$mech->get_ok("/");
my $exception = $mech->content();
$exception = eval "my $exception";
is ref($exception), "JSON::WebToken::Exception", "Exception with correct type";
ok exists($exception->{message}), "Exception includes a message";
ok exists($exception->{code}), "Exception includes a code";

done_testing();
