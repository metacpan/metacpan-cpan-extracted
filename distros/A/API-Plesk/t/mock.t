use strict;
use warnings;

use Carp;
use Test::More;
use Data::Dumper;

use lib qw(t lib);
use TestData;

BEGIN {
    plan tests => 6;
    use_ok( 'API::Plesk::Mock' );
}

my $api = API::Plesk::Mock->new( %TestData::plesk_valid_params );

isa_ok( $api, 'API::Plesk::Mock', 'STATIC call new' );

$api->mock_response('some xml');
is($api->mock_response, 'some xml');

$api->mock_error('some error');
is($api->mock_error, 'some error');


$api->mock_response('<packet version="1.6.3.0"><dns><add_rec><result><status>ok</status><id>17</id></result></add_rec></dns></packet>');
$api->mock_error('');

my $res = $api->dns->add_rec(
    'site-id' => 1,
     type     => 'NS',
     host     => 'Mysite.com',
     value    => 'ns.Mysite.com.',
);
is(ref $res, 'API::Plesk::Response');
is($res->id, 17);
