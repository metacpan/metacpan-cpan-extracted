#
# This file is part of CatalystX-ExtJS-REST
#
# This software is Copyright (c) 2014 by Moritz Onken.
#
# This is free software, licensed under:
#
#   The (three-clause) BSD License
#
use Test::More;
use Benchmark qw(:all);
use strict;
use warnings;

BEGIN { $ENV{CATALYST_DEBUG} = 0; $ENV{DBIC_TRACE} = 0;};

use HTTP::Request::Common;
use JSON;

use lib qw(t/lib);

use Test::WWW::Mechanize::Catalyst 'MyApp';

my $mech = Test::WWW::Mechanize::Catalyst->new();

$mech->add_header('Accept' => 'application/json');

$mech->get_ok('/users', undef, 'request list of users');

ok(my $json = JSON::decode_json($mech->content), 'response is JSON response');

is($json->{results}, 0, 'no results');

my $res = $mech->request(POST '/user', [name => 'bar', password => 'foo']);

ok($json = JSON::decode_json($res->content), 'response is JSON response');

is($json->{success}, 'true', 'submission was successful');

is($res->header('location'), 'http://localhost/user/1', 'user location is set');

$mech->get_ok('/users', undef, 'request list of users');

ok($json = JSON::decode_json($mech->content), 'response is JSON response');

is($json->{results}, 1, 'one results');

diag "Getting one user";

timethis(250, sub { $mech->get('/user/1', undef, 'get user 1') });

diag "Creating 250 users";

timethis(250, sub { $mech->request(POST '/user', [name => 'bar', password => 'foo']); } );

diag "Get list of 250 users";

timethis(10, sub { $mech->get('/users', undef, 'request list of users'); } );

diag "Get list of 250 users";

timethis(10, sub { $mech->get('/users/hri', undef, 'request list of users'); } );

print $mech->content;