use strict;
use warnings;

use Test::More 0.88;
use Test::Requires qw(YAML::Syck);
use FindBin;

use lib ("$FindBin::Bin/lib", "$FindBin::Bin/../lib", "$FindBin::Bin/broken");
use Test::Rest;

my $t = Test::Rest->new('content_type' => 'text/x-yaml');

use_ok 'Catalyst::Test', 'Test::Catalyst::Action::REST';

my $res = request($t->get(url => '/serialize/test'));
ok( $res->is_success, 'GET the serialized request succeeded' );
is( $res->content, "--- \nlou: is my cat\n", "Request returned proper data");

my $nt = Test::Rest->new('content_type' => 'text/broken');
my $bres = request($nt->get(url => '/serialize/test'));
is( $bres->code, 415, 'GET on un-useable Serialize class returns 415');

my $ut = Test::Rest->new('content_type' => 'text/not-happening');
my $ures = request($ut->get(url => '/serialize/test'));
is ($bres->code, 415, 'GET on unknown Content-Type returns 415');

# This check is to make sure we can still serialize after the first
# request.
my $res2 = request($t->get(url => '/serialize/test_second'));
ok( $res2->is_success, '2nd request succeeded' );
is( $res2->content, "--- \nlou: is my cat\n", "request returned proper data");

Test::Catalyst::Action::REST->controller('Serialize')->{serialize} = { };
$res2 = request($t->get(url => '/serialize/test_second'));
ok( $res2->is_success, 'request succeeded (deprecated config)' );
is( $res2->content, "--- \nlou: is my cat\n", "request returned proper data");


$res = request($t->get(url => '/serialize/empty_serialized'));
is $res->content, "--- \nfoo: bar\n", 'normal case ok';
ok $res->header('Content-Length'), 'set content-length when we serialize';

$res = request($t->get(url => '/serialize/empty_not_serialized_blank'));
is $res->content, '', "body explicitly set to '' results in '' content";
ok !$res->header('Content-Length'), "body explicitly set to '' - no automatic content-length";

$res = request($t->get(url => '/serialize/explicit_view'));
is $res->content, '', "view explicitly set to '' results in '' content";
ok !$res->header('Content-Length'), "view explicitly set to '' - no automatic content-length";

done_testing;
