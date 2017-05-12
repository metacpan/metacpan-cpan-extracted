use strict;
use warnings;
use Test::More;
use Test::Requires qw(YAML::Syck);
use FindBin;

use lib ("$FindBin::Bin/lib", "$FindBin::Bin/../lib", "$FindBin::Bin/broken");
use Test::Rest;

# YAML 
my $t = Test::Rest->new('content_type' => 'text/x-yaml');

use_ok 'Catalyst::Test', 'Test::Catalyst::Action::REST';

my $req = $t->get(url => '/serialize/test?content-type=text/x-yaml');
$req->remove_header('Content-Type');
my $res = request($req);
ok( $res->is_success, 'GET the serialized request succeeded' );
my $data = <<EOH;
--- 
lou: is my cat
EOH
is( $res->content, $data, "Request returned proper data");

1;

done_testing;
