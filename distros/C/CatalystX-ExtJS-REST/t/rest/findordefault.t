use Test::More  tests => 5;

use strict;
use warnings;

use HTTP::Request::Common;
use JSON;

use lib qw(t/lib);

use Test::WWW::Mechanize::Catalyst 'MyApp';

my $mech = Test::WWW::Mechanize::Catalyst->new();

$mech->add_header('Accept' => 'application/json');

$mech->get_ok('/findordefault/-10', undef, 'get non existing user');

ok(my $json = JSON::decode_json($mech->content), 'response is JSON response');

is($json->{data}->{name}, 'myname', 'user name is default');

is($json->{data}->{password}, 'mypassw0rd', 'password is default');

is($json->{data}->{id}, undef, 'id is not defined');
