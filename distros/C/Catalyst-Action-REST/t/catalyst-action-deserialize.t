use strict;
use warnings;
use Test::More;
use Test::Requires qw(YAML::Syck);
use YAML::Syck;
use FindBin;

use lib ("$FindBin::Bin/lib", "$FindBin::Bin/../lib", "$FindBin::Bin/broken");
use Test::Rest;

my $t = Test::Rest->new('content_type' => 'text/x-yaml');

use_ok 'Catalyst::Test', 'Test::Catalyst::Action::REST';
my $url = '/deserialize/test';

my $req = $t->put( url => $url, data => Dump({ kitty => "LouLou" }));
my $res = request($req);
ok( $res->is_success, 'PUT Deserialize request succeeded' );
is( $res->content, "LouLou", "Request returned deserialized data");

$req->method('GET');
isnt( request($req)->content, 'LouLou', 'GET request with body does not work by default' );

$req->url('/deserialize/test_action_args');
is( request($req)->content, 'LouLou', 'GET request via action_args');

my $nt = Test::Rest->new('content_type' => 'text/broken');
my $bres = request($nt->put( url => $url, data => Dump({ kitty => "LouLou" })));
is( $bres->code, 415, 'PUT on un-useable Deserialize class returns 415');

my $ut = Test::Rest->new('content_type' => 'text/not-happening');
my $ures = request($ut->put( url => $url, data => Dump({ kitty => "LouLou" })));
is ($bres->code, 415, 'GET on unknown Content-Type returns 415');

1;

done_testing;
