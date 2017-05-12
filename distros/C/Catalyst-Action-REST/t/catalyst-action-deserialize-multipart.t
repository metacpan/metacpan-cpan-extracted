use strict;
use warnings;
use Test::More;
use Test::Requires qw(YAML::Syck);
use YAML::Syck;
use FindBin;

use lib ("$FindBin::Bin/lib", "$FindBin::Bin/../lib", "$FindBin::Bin/broken");
use Test::Rest;

my $t = Test::Rest->new('content_type' => 'multipart/mixed; boundary=----------------------------0b922a55b662');

use_ok 'Catalyst::Test', 'Test::Catalyst::Action::REST';
my $url = '/deserializemultipart/test';

my $req = $t->put( url => $url, data => qq(------------------------------0b922a55b662\r\nContent-Disposition: form-data; name="REST"; filename="-"\r\nContent-Type: text/x-yaml\r\n\r\n---\r\nkitty: LouLou\r\n------------------------------0b922a55b662\r\nContent-Disposition: form-data; name="other"; filename="foo.txt"\r\nContent-Type: application/octet-stream\r\n\r\nanother part\r\n------------------------------0b922a55b662--\r\n));
my $res = request($req);

ok( $res->is_success, 'PUT Deserialize request succeeded' );
is( $res->content, "LouLou|12", "Request returned deserialized data");

done_testing;
