# ************************************************************************* 
# Copyright (c) 2014-2015, SUSE LLC
# 
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
# 
# 1. Redistributions of source code must retain the above copyright notice,
# this list of conditions and the following disclaimer.
# 
# 2. Redistributions in binary form must reproduce the above copyright
# notice, this list of conditions and the following disclaimer in the
# documentation and/or other materials provided with the distribution.
# 
# 3. Neither the name of SUSE LLC nor the names of its contributors may be
# used to endorse or promote products derived from this software without
# specific prior written permission.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.
# ************************************************************************* 
#
# test top-level resources
#

#!perl
use 5.012;
use strict;
use warnings;

#use App::CELL::Test::LogToFile;
use App::CELL qw( $meta $site );
use App::Dochazka::REST::Test;
use Data::Dumper;
use JSON;
use Plack::Test;
use Test::JSON;
use Test::More;
use Test::Warnings;


note( "initialize, connect to database, and set up a testing plan" );
my $app = initialize_regression_test();

note( "instantiate Plack::Test object");
my $test = Plack::Test->create( $app );

#diag( "Just created a " . ref( $test ) . " object for testing" );

my $res;


note( '=============================' );
note( '"/" resource' );
note( '=============================' );
docu_check($test, "/");

note( 'GET ""' );
note( '- as demo' );
my $status = req( $test, 200, 'demo', 'GET', '/' );
is( $status->level, 'OK' );
is( $status->code, 'DISPATCH_NOOP' );

note( '- as root' );
$status = req( $test, 200, 'root', 'GET', '/' );
is( $status->level, 'OK' );
is( $status->code, 'DISPATCH_NOOP' );

note( 'PUT ""' );
note( '- as demo' );
$status = req( $test, 200, 'demo', 'PUT', '/' );
is( $status->level, 'OK' );
is( $status->code, 'DISPATCH_NOOP' );

note( 'PUT ""' );
note( '- as root' );
$status = req( $test, 200, 'root', 'PUT', '/' );
is( $status->level, 'OK' );
is( $status->code, 'DISPATCH_NOOP' );

note( 'POST ""' );
note( '- as demo' );
$status = req( $test, 200, 'demo', 'POST', '/' );
is( $status->level, 'OK' );
is( $status->code, 'DISPATCH_NOOP' );

note( 'POST ""' );
note( '- as root' );
$status = req( $test, 200, 'root', 'POST', '/' );
is( $status->level, 'OK' );
is( $status->code, 'DISPATCH_NOOP' );

note( 'DELETE ""' );
note( '- as demo' );
$status = req( $test, 200, 'demo', 'DELETE', '/' );
is( $status->level, 'OK' );
is( $status->code, 'DISPATCH_NOOP' );

note( '- as root' );
$status = req( $test, 200, 'root', 'DELETE', '/' );
is( $status->level, 'OK' );
is( $status->code, 'DISPATCH_NOOP' );


note( '=============================' );
note( '"bugreport" resource' );
note( '=============================' );
docu_check($test, "bugreport");

note( 'GET bugreport' );

note( '- as demo' );
$status = req( $test, 200, 'demo', 'GET', 'bugreport' );
is( $status->level, 'OK' );
is( $status->code, 'DISPATCH_BUGREPORT' );
ok( exists $status->payload->{'report_bugs_to'} );

note( '- as root' );
$status = req( $test, 200, 'root', 'GET', 'bugreport' );
is( $status->level, 'OK' );
is( $status->code, 'DISPATCH_BUGREPORT' );
ok( exists $status->payload->{'report_bugs_to'} );

note( 'PUT bugreport -> 405' );
req( $test, 405, 'demo', 'PUT', 'bugreport' );
req( $test, 405, 'root', 'PUT', 'bugreport' );

note( 'POST bugreport -> 405');
req( $test, 405, 'demo', 'PUT', 'bugreport' );
req( $test, 405, 'root', 'PUT', 'bugreport' );

note( 'DELETE bugreport -> 405' );
req( $test, 405, 'demo', 'DELETE', 'bugreport' );
req( $test, 405, 'root', 'DELETE', 'bugreport' );


my $eid_of_inactive = create_inactive_employee( $test );
my $eid_of_active = create_active_employee( $test );


note( '=============================' );
note( '"dbstatus" resource' );
note( '=============================' );
my $base = 'dbstatus';
docu_check( $test, $base );

note( 'GET' );

note( '- as demo' );
req( $test, 403, 'demo', 'GET', $base );

note( '- as inactive, active, and root' );
foreach my $user ( 'inactive', 'active', 'root' ) {
    $status = req( $test, 200, $user, 'GET', $base );
    is( $status->level, 'OK' );
    is( $status->code, 'DOCHAZKA_DBSTATUS' );
}

note( 'PUT, POST, DELETE -> 405' );
foreach my $method ( 'PUT', 'POST', 'DELETE' ) {
    foreach my $user ( qw( demo inactive active root ) ) {
        req( $test, 405, $user, $method, $base );
    }
}


note( '=============================' );
note( '"docu" resource' );
note( '=============================' );

note( '=============================' );
note( '"docu/text" resource' );
note( '=============================' );

note( '=============================' );
note( '"docu/html" resource' );
note( '=============================' );

$base = 'docu/html';
docu_check($test, $base);

note( 'GET docu -> 405' );
req( $test, 405, 'demo', 'GET', $base );
req( $test, 405, 'root', 'GET', $base );

note( 'PUT docu -> 405' );
req( $test, 405, 'demo', 'PUT', $base );
req( $test, 405, 'root', 'PUT', $base );

note( 'POST docu' );
note( '- be nice' );
$status = req( $test, 200, 'demo', 'POST', $base, '"echo"' );
is( $status->level, 'OK' );
is( $status->code, 'DISPATCH_ONLINE_DOCUMENTATION' );
ok( exists $status->payload->{'resource'} );
is( $status->payload->{'resource'}, 'echo' );
ok( exists $status->payload->{'documentation'} );
my $docustr = $status->payload->{'documentation'};
my $docustr_len = length( $docustr );
ok( $docustr_len > 10 );
like( $docustr, qr/echoes/ );

note( '- ask nicely for documentation of a slightly more complicated resource' );
$status = req( $test, 200, 'demo', 'POST', $base, '"param/:type/:param"' );
is( $status->level, 'OK' );
is( $status->code, 'DISPATCH_ONLINE_DOCUMENTATION' );
ok( exists $status->payload->{'resource'} );
is( $status->payload->{'resource'}, 'param/:type/:param' );
ok( exists $status->payload->{'documentation'} );
ok( length( $status->payload->{'documentation'} ) > 10 );
isnt( $status->payload->{'documentation'}, $docustr, "We are not getting the same string over and over again" );
isnt( $docustr_len, length( $status->payload->{'documentation'} ), "We are not getting the same string over and over again" );

note( '- ask nicely for documentation of the "/" resource' );
$status = req( $test, 200, 'demo', 'POST', $base, '"/"' );
is( $status->level, 'OK' );
is( $status->code, 'DISPATCH_ONLINE_DOCUMENTATION' );
ok( exists $status->payload->{'resource'} );
is( $status->payload->{'resource'}, '/' );
ok( exists $status->payload->{'documentation'} );
ok( length( $status->payload->{'documentation'} ) > 10 );
isnt( $status->payload->{'documentation'}, $docustr, "We are not getting the same string over and over again" );
isnt( $docustr_len, length( $status->payload->{'documentation'} ), "We are not getting the same string over and over again" );

note( '- be nice but not careful (non-existent resource)' );
$status = req( $test, 404, 'demo', 'POST', $base, '"echop"' );
is( $status->text, 'Could not find resource definition for echop');

note( '- be pathological (invalid JSON)' );
req( $test, 400, 'demo', 'POST', $base, 'bare, unquoted string will never pass for JSON' );
req( $test, 400, 'demo', 'POST', $base, '[ 1, 2' );

note( 'DELETE docu -> 405' );
req( $test, 405, 'demo', 'DELETE', $base );
req( $test, 405, 'root', 'DELETE', $base );
    

note( '=============================' );
note( '"echo" resource' );
note( '=============================' );
docu_check($test, "echo");

note( 'GET echo -> 405' );
$status = req( $test, 405, 'demo', 'GET', 'echo' );
$status = req( $test, 405, 'root', 'GET', 'echo' );

note( 'PUT echo -> 405' );
$status = req( $test, 405, 'demo', 'PUT', 'echo' );
$status = req( $test, 405, 'root', 'PUT', 'echo' );

note( 'POST echo' );
note( '- as root, with legal JSON' );
$status = req( $test, 200, 'root', 'POST', 'echo', '{ "username": "foo", "password": "bar" }' );
is( $status->level, 'OK' );
is( $status->code, 'ECHO_REQUEST_ENTITY' );
ok( exists $status->payload->{'username'} );
is( $status->payload->{'username'}, 'foo' );
ok( exists $status->payload->{'password'} );
is( $status->payload->{'password'}, 'bar' );

note( '- with illegal JSON' );
$status = req( $test, 400, 'root', 'POST', 'echo', '{ "username": "foo", "password": "bar"' );

note( '- with empty request body, as demo' );
$status = req( $test, 403, 'demo', 'POST', 'echo' );

note( '- with empty request body' );
$status = req( $test, 200, 'root', 'POST', 'echo' );
is( $status->level, 'OK' );
is( $status->code, 'ECHO_REQUEST_ENTITY' );
ok( exists $status->{'payload'} );
is( $status->payload, undef );

note( 'DELETE echo -> 405' );
$status = req( $test, 405, 'demo', 'DELETE', 'echo' );
$status = req( $test, 405, 'root', 'DELETE', 'echo' );

note( '=============================' );
note( '"forbidden" resource' );
note( '=============================' );
docu_check($test, "forbidden");
foreach my $user ( qw( demo root ) ) {
    foreach my $method ( qw( GET PUT POST DELETE ) ) {
        $status = req( $test, 403, 'demo', 'GET', 'forbidden' );
    }
}

note( '=============================' );
note( '"param/:type/:param" resource' );
note( '=============================' );
$base = "param";
docu_check($test, "param/:type/:param");

note( 'POST' );
is( $meta->META_DOCHAZKA_UNIT_TESTING, 1 );

$status = req( $test, 200, 'root', 'PUT', "$base/meta/META_DOCHAZKA_UNIT_TESTING", '"foobar"' );
is( $status->level, 'OK' );
is( $status->code, 'CELL_OVERWRITE_META_PARAM' );
is( $meta->META_DOCHAZKA_UNIT_TESTING, 'foobar' );

$status = req( $test, 200, 'root', 'PUT', "$base/meta/META_DOCHAZKA_UNIT_TESTING", '1' );
is( $status->level, 'OK' );
is( $status->code, 'CELL_OVERWRITE_META_PARAM' );
is( $meta->META_DOCHAZKA_UNIT_TESTING, 1 );

note( 'GET' );

note( 'non-existent and otherwise bogus parameters' );
foreach my $base ( "$base/meta", "$base/site" ) {
    foreach my $user ( qw( demo root ) ) {
        # these are bogus in that the resource does not exist
        req( $test, 400, $user, 'GET', "$base/" );
        req( $test, 400, $user, 'GET', "$base/META_DOCHAZKA_UNIT_TESTING/foobar" );
        req( $test, 400, $user, 'GET', "$base/bla bla bal" );
        req( $test, 400, $user, 'GET', "$base//////1/1/234/20" );
        req( $test, 400, $user, 'GET', "$base/{}" );
        req( $test, 400, $user, 'GET', "$base/-1" );
        req( $test, 400, $user, 'GET', "$base/0" );
        req( $test, 400, $user, 'GET', "$base/" . '\b\b\o\o\g\\' );
        req( $test, 400, $user, 'GET', "$base/" . '\b\b\o\o\\' );
        req( $test, 400, $user, 'GET', "$base/**0" );
        req( $test, 400, $user, 'GET', "$base/}lieutenant" );
        req( $test, 400, $user, 'GET', "$base/<HEAD><tail><body>&nbsp;" );
    }
    my $mapping = { "demo" => 403, "root" => 404 };
    foreach my $user ( qw( demo root ) ) {
        # these are bogus in that the parameter does not exist
        req( $test, $mapping->{$user}, $user, 'GET', "$base/DOCHEEEHAWHAZKA_appname" );
        req( $test, $mapping->{$user}, $user, 'GET', "$base/abc123" );
        req( $test, $mapping->{$user}, $user, 'GET', "$base/null" );
    }
}

note( 'metaparam-specific tests' );

note( '- try to use metaparam to access a site parameter' );
req( $test, 404, 'root', 'GET', "param/meta/DOCHAZKA_APPNAME" );

note( '- as root, existent parameter' );
$status = req( $test, 200, 'root', 'GET', 'param/meta/META_DOCHAZKA_UNIT_TESTING/' );
is( $status->level, 'OK' );
is( $status->code, 'MREST_PARAMETER_VALUE' );
is_deeply( $status->payload, { 'META_DOCHAZKA_UNIT_TESTING' => 1 } );

note( "- as root, existent parameter without trailing '/'" );
$status = req( $test, 200, 'root', 'GET', 'param/meta/META_DOCHAZKA_UNIT_TESTING' );
is( $status->level, 'OK' );
is( $status->code, 'MREST_PARAMETER_VALUE' );
is_deeply( $status->payload, { 'META_DOCHAZKA_UNIT_TESTING' => 1 } );

note( 'POST -> 405' );
foreach my $base ( "$base/meta", "$base/site" ) {
    foreach my $user ( qw( demo root ) ) {
        req( $test, 405, $user, 'POST', 'param/meta/META_DOCHAZKA_UNIT_TESTING' );
    }
}


note( '=============================' );
note( '"session" resource' );
note( '=============================' );
docu_check($test, "session");

note( 'GET session' );
$status = req( $test, 200, 'demo', 'GET', 'session' );
is( $status->level, 'OK' );
is( $status->code, 'DISPATCH_SESSION_DATA' );
ok( exists $status->payload->{'session'} );
ok( exists $status->payload->{'session_id'} );

note( 'N.B.: no session data when running via Plack::Test' );
#ok( exists $status->payload->{'session'}->{'ip_addr'} );
#ok( exists $status->payload->{'session'}->{'last_seen'} );
#ok( exists $status->payload->{'session'}->{'eid'} );

note( 'PUT, POST, DELETE -> 405' );
foreach my $user ( qw( demo root ) ) {
    foreach my $method ( qw( PUT POST DELETE ) ) {
        $status = req( $test, 405, $user, $method, 'session' );
    }
}


note( '=============================' );
note( '"version" resource' );
note( '=============================' );
docu_check($test, "version");

note( 'GET version' );
$status = req( $test, 200, 'demo', 'GET', 'version' );
is( $status->level, 'OK' );
is( $status->code, 'DISPATCH_VERSION' );
ok( exists $status->payload->{'version'} );

$status = req( $test, 200, 'root', 'GET', 'version' );
is( $status->level, 'OK' );
is( $status->code, 'DISPATCH_VERSION' );
ok( exists $status->payload->{'version'} );

note( 'PUT, POST, DELETE version -> 405' );
foreach my $user ( qw( demo root ) ) {
    foreach my $method ( qw( PUT POST DELETE ) ) {
        $status = req( $test, 405, $user, $method, 'version' );
    }
}


note( '=============================' );
note( '"whoami" resource' );
note( '=============================' );
docu_check($test, "whoami");

note( 'GET whoami' );
$status = req( $test, 200, 'demo', 'GET', 'whoami' );
is( $status->level, 'OK' );
ok( $status->code, 'DISPATCH_RECORDS_FOUND' );
ok( defined $status->payload );
ok( exists $status->payload->{'eid'} );
ok( exists $status->payload->{'nick'} );
ok( not exists $status->payload->{'priv'} );
is( $status->payload->{'nick'}, 'demo' );

$status = req( $test, 200, 'root', 'GET', 'whoami' );
is( $status->level, 'OK' );
ok( $status->code, 'DISPATCH_RECORDS_FOUND' );
ok( defined $status->payload );
ok( exists $status->payload->{'eid'} );
ok( exists $status->payload->{'nick'} );
ok( not exists $status->payload->{'priv'} );
is( $status->payload->{'nick'}, 'root' );

note( 'PUT, POST, DELETE whoami -> 405' );
foreach my $user ( qw( demo root ) ) {
    foreach my $method ( qw( PUT POST DELETE ) ) {
        $status = req( $test, 405, $user, $method, 'whoami' );
    }
}

delete_employee_by_nick( $test, 'active' );
delete_employee_by_nick( $test, 'inactive' );

done_testing;
