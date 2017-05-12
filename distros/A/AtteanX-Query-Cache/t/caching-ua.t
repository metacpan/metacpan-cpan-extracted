use strict;
use warnings;

use Test::More;
use LWP::Protocol::PSGI;
use CHI;
use Plack::Request;

use_ok('LWP::UserAgent::SemWebCache');

my $app = sub {
	my $env = shift;
	my $req = Plack::Request->new($env);
	my $query = $req->param('query');
	my $content = "Hello $query";
	return [ 200, [ 'Cache-Control' => 'max-age=4', 'Content-Type' => 'text/plain'], [ $content] ] 
};

LWP::Protocol::PSGI->register($app);

my $cache = CHI->new( driver => 'Memory', global => 1 );
my $ua = LWP::UserAgent::SemWebCache->new(cache => $cache);

my $res1 = $ua->get("http://localhost:3000/?query=DAHUT");

ok($res1);

done_testing;
