use strict;
use warnings;

use Test::More import => ['!pass'];
#use Plack::Test;
use  Test::WWW::Mechanize::PSGI;
use HTTP::Request::Common;
use Crypt::JWT qw(encode_jwt decode_jwt);
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
like $exception, '/^JWT: invalid token format/', "Exception includes a message";
done_testing();
