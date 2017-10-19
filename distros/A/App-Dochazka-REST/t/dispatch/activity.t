# *************************************************************************
# Copyright (c) 2014-2017, SUSE LLC
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
# test activity resources
#

#!perl
use 5.012;
use strict;
use warnings;

#use App::CELL::Test::LogToFile;
use App::CELL qw( $log $meta $site );
use App::Dochazka::REST::Test;
use Data::Dumper;
use JSON;
use Plack::Test;
use Test::JSON;
use Test::More;
use Test::Warnings;

note( 'initialize, connect to database, and set up a testing plan' );
my $app = initialize_regression_test();

note( 'instantiate Plack::Test object' );
my $test = Plack::Test->create( $app );

my $res;

# takes PARAMHASH with either 'aid => ...' or 'code => ...'
sub disable_testing_activity {
    my %PH = @_;
    my $resource;
    if ( $PH{aid} ) {
        $resource = "activity/aid/$PH{aid}";
    } elsif ( $PH{code} ) {
        $resource = "activity/code/$PH{code}";
    }
    my $status = req( $test, 200, 'root', 'PUT', $resource, '{ "disabled" : true }' );
    is( $status->level, 'OK', "Disable Testing Activity 2" );
    is( $status->code, 'DOCHAZKA_CUD_OK', "Disable Testing Activity 3" );
    is( ref( $status->payload ), 'HASH', "Disable Testing Activity 4" );
    my $act = $status->payload;
    ok( $act->{aid} > 8, "Disable Testing Activity 5" );
    ok( $act->{disabled}, "Disable Testing Activity 6" );
    return App::Dochazka::REST::Model::Activity->spawn( $act );
}

note( "create testing employees with 'active' and 'inactive' privlevels" );
create_active_employee( $test );
create_inactive_employee( $test );


note( '=======================' );
note( '"activity/aid" resource' );
note( '=======================' );
my $base = 'activity/aid';
docu_check($test, "$base");

note( "GET, PUT on $base" );
foreach my $method ( 'GET', 'PUT' ) {
    foreach my $user ( 'demo', 'active', 'root', 'WOMBAT5', 'WAMBLE owdkmdf 5**' ) {
        req( $test, 405, $user, $method, $base );
    }
}

note( "POST on $base" );
my $foowop = create_testing_activity( code => 'FOOWOP' );
my $aid_of_foowop = $foowop->aid;

note( 'test if expected behavior behaves as expected (update)' );
my $activity_obj = '{ "aid" : ' . $aid_of_foowop . ', "long_desc" : "wop wop ng", "remark" : "puppy" }';
req( $test, 403, 'demo', 'POST', $base, $activity_obj );
req( $test, 403, 'active', 'POST', $base, $activity_obj );
my $status = req( $test, 200, 'root', 'POST', $base, $activity_obj );
is( $status->level, 'OK', "POST $base 4" );
is( $status->code, 'DOCHAZKA_CUD_OK', "POST $base 5" );
ok( defined $status->payload );
is( $status->payload->{'remark'}, 'puppy', "POST $base 6" );
is( $status->payload->{'long_desc'}, 'wop wop ng', "POST $base 7" );

note( 'non-existent AID and also out of range' );
$activity_obj = '{ "aid" : 3434342342342, "long_desc" : 3434341, "remark" : 34334342 }';
dbi_err( $test, 500, 'root', 'POST', $base, $activity_obj, qr/out of range for type integer/ );

note( 'non-existent AID' );
$activity_obj = '{ "aid" : 342342342, "long_desc" : 3434341, "remark" : 34334342 }';
req( $test, 404, 'root', 'POST', $base, $activity_obj );

note( 'throw a couple curve balls' );
my $weirded_object = '{ "copious_turds" : 555, "long_desc" : "wang wang wazoo", "disabled" : "f" }';
req( $test, 400, 'root', 'POST', $base, $weirded_object );

my $no_closing_bracket = '{ "copious_turds" : 555, "long_desc" : "wang wang wazoo", "disabled" : "f"';
req( $test, 400, 'root', 'POST', $base, $no_closing_bracket );

$weirded_object = '{ "aid" : "!!!!!", "long_desc" : "down it goes" }';
dbi_err( $test, 500, 'root', 'POST', $base, $weirded_object, qr/invalid input syntax for integer/ );

note( 'delete the testing activity' );
delete_testing_activity( $aid_of_foowop );

note( "DELETE on $base" );
req( $test, 405, 'demo', 'DELETE', $base );
req( $test, 405, 'root', 'DELETE', $base );
req( $test, 405, 'WOMBAT5', 'DELETE', $base );


note( '=============================' );
note( '"activity/aid/:aid" resource' );
note( '=============================' );
$base = 'activity/aid';
docu_check($test, "$base/:aid");

note( 'insert an activity and disable it here' );
my $foobar = create_testing_activity( code => 'FOOBAR' );
$foobar = disable_testing_activity( code => $foobar->code );
ok( $foobar->disabled, "$base/:aid testing activity is really disabled 1" );
my $aid_of_foobar = $foobar->aid;

note( "GET on $base/:aid" );

note( "fail as demo 403" );
req( $test, 403, 'demo', 'GET', "$base/1" );

note( "succeed as active AID 1" );
$status = req( $test, 200, 'active', 'GET', "$base/1" );
ok( $status->ok, "GET $base/:aid 2" );
is( $status->code, 'DISPATCH_ACTIVITY_FOUND', "GET $base/:aid 3" );
is_deeply( $status->payload, {
    aid => 1,
    code => 'WORK',
    long_desc => 'Work',
    remark => 'dbinit',
    disabled => 0,
}, "GET $base/:aid 4" );

note( "fail invalid (non-integer) AID" );
req( $test, 400, 'active', 'GET', "$base/jj" );

note( "fail non-existent AID" );
req( $test, 404, 'active', 'GET', "$base/444" );

note( "succeed disabled AID" );
$status = req( $test, 200, 'active', 'GET', "$base/$aid_of_foobar" );
is( $status->level, 'OK', "GET $base/:aid 13" );
is( $status->code, 'DISPATCH_ACTIVITY_FOUND', "GET $base/:aid 14" );
is_deeply( $status->payload, {
    aid => $aid_of_foobar,
    code => 'FOOBAR',
    long_desc => undef,
    remark => undef,
    disabled => 1,
}, "GET $base/:aid 15" );

note( "PUT on $base/:aid" );
$activity_obj = '{ "code" : "FOOBAR", "long_desc" : "The bar of foo", "remark" : "Change is good" }';
# - test with demo fail 405
req( $test, 403, 'active', 'PUT', "$base/$aid_of_foobar", $activity_obj );

note( 'test with root success' );
$status = req( $test, 200, 'root', 'PUT', "$base/$aid_of_foobar", $activity_obj );
is( $status->level, 'OK', "PUT $base/:aid 3" );
is( $status->code, 'DOCHAZKA_CUD_OK', "PUT $base/:aid 4" );
is( ref( $status->payload ), 'HASH', "PUT $base/:aid 5" );

note( 'make an Activity object out of the payload' );
$foobar = App::Dochazka::REST::Model::Activity->spawn( $status->payload );
is( $foobar->long_desc, "The bar of foo", "PUT $base/:aid 5" );
is( $foobar->remark, "Change is good", "PUT $base/:aid 6" );
ok( $foobar->disabled, "PUT $base/:aid 7" );

note( 'test with root no request body' );
req( $test, 400, 'root', 'PUT', "$base/$aid_of_foobar" );

note( 'test with root fail invalid JSON' );
req( $test, 400, 'root', 'PUT', "$base/$aid_of_foobar", '{ asdf' );

note( 'test with root fail invalid AID' );
req( $test, 400, 'root', 'PUT', "$base/asdf", '{ "legal":"json" }' );

note( 'with valid JSON that is not what we are expecting' );
req( $test, 400, 'root', 'PUT', "$base/$aid_of_foobar", '0' );

note( 'with valid JSON that has some bogus properties' );
req( $test, 400, 'root', 'PUT', "$base/$aid_of_foobar", '{ "legal":"json" }' );

note( "POST on $base/:aid" );
req( $test, 405, 'demo', 'POST', "$base/1" );
req( $test, 405, 'active', 'POST', "$base/1" );
req( $test, 405, 'root', 'POST', "$base/1" );

note( "DELETE on $base/:aid" );

note( 'demo fail 403' );
req( $test, 403, 'demo', 'DELETE', "$base/1" );

note( 'active fail 403' );
req( $test, 403, 'active', 'DELETE', "$base/1" );

note( 'root success' );
note( "DELETE $base/$aid_of_foobar" );
$status = req( $test, 200, 'root', 'DELETE', "$base/$aid_of_foobar" );
is( $status->level, 'OK', "DELETE $base/:aid 3" );
is( $status->code, 'DOCHAZKA_CUD_OK', "DELETE $base/:aid 4" );

note( 'really gone' );
req( $test, 404, 'active', 'GET', "$base/$aid_of_foobar" );

note( 'root fail invalid AID' );
req( $test, 400, 'root', 'DELETE', "$base/asd" );


note( '=============================' );
note( '"activity/all" resource' );
note( '=============================' );
$base = 'activity/all';
docu_check($test, $base);

note( 'insert an activity and disable it here' );
$foobar = create_testing_activity( code => 'FOOBAR' );
$aid_of_foobar = $foobar->aid;

note( "GET on $base" );
foreach my $user ( qw( demo active root ) ) {
    $status = req( $test, 200, $user, 'GET', $base );
    is( $status->level, 'OK', "GET $base 2" );
    is( $status->code, 'DISPATCH_RECORDS_FOUND', "GET $base 3" );
    is( $status->{count}, 9, "GET $base 4" );
    ok( exists $status->{payload}, "GET $base 5" );
    is( scalar @{ $status->payload }, 9, "GET $base 6" );
}

note( 'testing activity is present' );
ok( scalar( grep { $_->{code} eq 'FOOBAR'; } @{ $status->payload } ), "GET $base 7" );

note( 'disable the testing activity' );
$foobar = disable_testing_activity( code => $foobar->code );
ok( $foobar->disabled, "$base testing activity is really disabled 1" );

note( "there is now one less in GET $base payload" );
$status = req( $test, 200, 'root', 'GET', $base );
is( $status->level, 'OK' );
is( $status->code, 'DISPATCH_RECORDS_FOUND' );
is( $status->{count}, 8 );
ok( exists $status->{payload} );
is( scalar @{ $status->payload }, 8 );

note( 'and testing activity is absent' );
ok( ! scalar( grep { $_->{code} eq 'FOOBAR'; } @{ $status->payload } ), "GET $base 7" );

note( "PUT, POST, DELETE on $base" );
req( $test, 405, 'demo', 'PUT', $base );
req( $test, 405, 'active', 'PUT', $base );
req( $test, 405, 'root', 'PUT', $base );
req( $test, 405, 'demo', 'POST', $base );
req( $test, 405, 'active', 'POST', $base );
req( $test, 405, 'root', 'POST', $base );
req( $test, 405, 'demo', 'DELETE', $base );
req( $test, 405, 'active', 'DELETE', $base );
req( $test, 405, 'root', 'DELETE', $base );


note( '=============================' );
note( '"activity/all/disabled" resource' );
note( '=============================' );
$base = 'activity/all/disabled';
docu_check($test, $base);

note( "GET on $base" );

note( 'fail demo 403' );
req( $test, 403, 'demo', 'GET', $base );

note( 'succeed root' );
$status = req( $test, 200, 'root', 'GET', $base );
is( $status->level, 'OK', "GET $base 2" );
is( $status->code, 'DISPATCH_RECORDS_FOUND', "GET $base 3" );

note( "count is 9 with disabled FOOBAR activity" );
is( $status->{count}, 9, "GET $base 4" ); 
ok( exists $status->{payload}, "GET $base 5" );
is( scalar @{ $status->payload }, 9, "GET $base 6" );

note( "get the disabled activity" );
ok( scalar( grep { $_->{code} eq 'FOOBAR'; } @{ $status->payload } ), "GET $base 7" );


note( "PUT, POST, DELETE on $base" );
req( $test, 405, 'demo', 'PUT', $base );
req( $test, 405, 'active', 'PUT', $base );
req( $test, 405, 'root', 'PUT', $base );
req( $test, 405, 'demo', 'POST', $base );
req( $test, 405, 'active', 'POST', $base );
req( $test, 405, 'root', 'POST', $base );
req( $test, 405, 'demo', 'DELETE', $base );
req( $test, 405, 'active', 'DELETE', $base );
req( $test, 405, 'root', 'DELETE', $base );

note( "delete the disabled testing activity" );
delete_testing_activity( $aid_of_foobar );


note( "=============================" );
note( "'activity/code' resource" );
note( "=============================" );
$base = 'activity/code';
docu_check($test, "$base");

note( "GET, PUT on $base" );
req( $test, 405, 'demo', 'GET', $base );
req( $test, 405, 'active', 'GET', $base );
req( $test, 405, 'root', 'GET', $base );
req( $test, 405, 'demo', 'PUT', $base );
req( $test, 405, 'active', 'PUT', $base );
req( $test, 405, 'root', 'PUT', $base );

note( "POST on $base" );

note( "insert: expected behavior" );
$activity_obj = '{ "code" : "FOOWANG", "long_desc" : "wang wang wazoo", "disabled" : "f" }';
req( $test, 403, 'demo', 'POST', $base, $activity_obj );
req( $test, 403, 'active', 'POST', $base, $activity_obj );
$status = req( $test, 200, 'root', 'POST', $base, $activity_obj );
is( $status->level, 'OK', "POST $base 4" );
is( $status->code, 'DOCHAZKA_CUD_OK', "POST $base 5" );
my $aid_of_foowang = $status->payload->{'aid'};

note( "update: expected behavior" );
$activity_obj = '{ "code" : "FOOWANG", "remark" : "this is only a test" }';
req( $test, 403, 'demo', 'POST', $base, $activity_obj );
req( $test, 403, 'active', 'POST', $base, $activity_obj );
$status = req( $test, 200, 'root', 'POST', $base, $activity_obj );
is( $status->level, 'OK', "POST $base 4" );
is( $status->code, 'DOCHAZKA_CUD_OK', "POST $base 5" );
is( $status->payload->{'remark'}, 'this is only a test', "POST $base 6" );
is( $status->payload->{'long_desc'}, 'wang wang wazoo', "POST $base 7" );

note( "throw a couple curve balls" );
$weirded_object = '{ "copious_turds" : 555, "long_desc" : "wang wang wazoo", "disabled" : "f" }';
req( $test, 400, 'root', 'POST', $base, $weirded_object );

$no_closing_bracket = '{ "copious_turds" : 555, "long_desc" : "wang wang wazoo", "disabled" : "f"';
req( $test, 400, 'root', 'POST', $base, $no_closing_bracket );

$weirded_object = '{ "code" : "!!!!!", "long_desc" : "down it goes" }';
dbi_err( $test, 500, 'root', 'POST', $base, $weirded_object, qr/check constraint "kosher_code"/ );

note( "delete the testing activity" );
delete_testing_activity( $aid_of_foowang );

note( "DELETE on $base" );
foreach my $user ( qw( demo active root ) ) {
    req( $test, 405, $user, 'DELETE', $base ); 
}


note( "=============================" );
note( "'activity/code/:code' resource" );
note( "=============================" );
$base = 'activity/code';
docu_check($test, "$base/:code");

note( 'insert an activity' );
$foobar = create_testing_activity( code => 'FOOBAR', remark => 'bazblat' );
$aid_of_foobar = $foobar->aid;

note( "GET on $base/:code" );

#note( 'insufficient privlevel' );
#req( $test, 403, 'demo', 'GET', "$base/WORK" ); # get code 1

note( 'positive test for WORK activity' );
$status = req( $test, 200, 'root', 'GET', "$base/WORK" ); # get code 1
is( $status->level, "OK", "GET $base/:code 2" );
is( $status->code, 'DISPATCH_ACTIVITY_FOUND', "GET $base/:code 3" );
is_deeply( $status->payload, {
    aid => 1,
    code => 'WORK',
    long_desc => 'Work',
    remark => 'dbinit',
    disabled => 0,
}, "GET $base/:code 4" );

note( 'positive test with FOOBAR activity we created above' );
$status = req( $test, 200, 'root', 'GET', "$base/FOOBAR" );
is( $status->level, "OK", "GET $base/:code 5" );
is( $status->code, 'DISPATCH_ACTIVITY_FOUND', "GET $base/:code 6" );
is_deeply( $status->payload, {
    aid => $aid_of_foobar,
    code => 'FOOBAR',
    long_desc => undef,
    remark => 'bazblat',
    disabled => 0,
}, "GET $base/:code 7" );

note( 'non-existent code' );
req( $test, 404, 'root', 'GET', "$base/jj" );

note( 'invalid code' );
foreach my $invalid_code ( 
    '!!!! !134@@',
    'whiner*44',
    '@=1337',
    '/ninety/nine/luftbalons//',
) {
    foreach my $user ( qw( root demo ) ) {
        req( $test, 400, $user, 'GET', "$base/$invalid_code" );
    }
}

note( "PUT on $base/:code" );
$activity_obj = '{ "code" : "FOOBAR", "long_desc" : "baz waz wazoo", "remark" : "Full of it", "disabled" : "f" }';

note( 'demo fail 403' );
req( $test, 403, 'demo', 'PUT', "$base/FOOBAR", $activity_obj );
req( $test, 403, 'active', 'PUT', "$base/FOOBAR", $activity_obj );

note( 'root success' );
$status = req( $test, 200, 'root', 'PUT', "$base/FOOBAR", $activity_obj );
is( $status->level, "OK", "PUT $base/:code 3" );
is( $status->code, 'DOCHAZKA_CUD_OK', "PUT $base/:code 4" );

note( 'demo: no content body' );
req( $test, 403, 'demo', 'PUT', "$base/FOOBAR" );

note( 'active: no content body' );
req( $test, 403, 'active', 'PUT', "$base/FOOBAR" );

note( 'root: no content body' );
req( $test, 400, 'root', 'PUT', "$base/FOOBAR" );
req( $test, 400, 'root', 'PUT', "$base/FOOBAR_NEW" );

note( 'root: invalid JSON' );
req( $test, 400, 'root', 'PUT', "$base/FOOBAR", '{ asdf' );

note( 'root: invalid code' );
req( $test, 400, 'root', 'PUT', "$base/!!!!", '{ "legal":"json" }' );

note( 'root: valid JSON that is not what we are expecting' );
req( $test, 400, 'root', 'PUT', "$base/FOOBAR", '0' );
req( $test, 400, 'root', 'PUT', "$base/FOOBAR_NEW", '0' );

note( 'root: update with combination of valid and invalid properties' );
$status = req( $test, 200, 'root', 'PUT', "$base/FOOBAR", 
    '{ "nick":"FOOBAR", "remark":"Nothing much", "sister":"willy\'s" }' );
is( $status->level, 'OK', "PUT $base/FOOBAR 21" );
is( $status->code, 'DOCHAZKA_CUD_OK', "PUT $base/FOOBAR 22" );
is( $status->payload->{'remark'}, "Nothing much", "PUT $base/FOOBAR 23" );
ok( ! exists( $status->payload->{'nick'} ), "PUT $base/FOOBAR 24" );
ok( ! exists( $status->payload->{'sister'} ), "PUT $base/FOOBAR 25" );

note( 'root: insert with combination of valid and invalid properties' );
$status = req( $test, 200, 'root', 'PUT', "$base/FOOBARPUS", 
    '{ "nick":"FOOBAR", "remark":"Nothing much", "sister":"willy\'s" }' );
is( $status->level, 'OK', "PUT $base/FOOBAR 27" );
is( $status->code, 'DOCHAZKA_CUD_OK', "PUT $base/FOOBAR 28" );
is( $status->payload->{'remark'}, "Nothing much", "PUT $base/FOOBAR 29" );
ok( ! exists( $status->payload->{'nick'} ), "PUT $base/FOOBAR 30" );
ok( ! exists( $status->payload->{'sister'} ), "PUT $base/FOOBAR 31" );

note( "POST on $base/:code" );
req( $test, 405, 'demo', 'POST', "$base/WORK" );
req( $test, 405, 'active', 'POST', "$base/WORK" );
req( $test, 405, 'root', 'POST', "$base/WORK" );

note( "DELETE on $base/:code" );

note( 'demo fail 403 once' );
req( $test, 403, 'demo', 'DELETE', "$base/FOOBAR1" );

note( 'root fail 404' );
req( $test, 404, 'root', 'DELETE', "$base/FOOBAR1" );

note( 'demo fail 403 a second time' );
req( $test, 403, 'demo', 'DELETE', "$base/FOOBAR" );

note( "root success: DELETE $base/FOOBAR" );
$status = req( $test, 200, 'root', 'DELETE', "$base/FOOBAR" );
is( $status->level, 'OK', "DELETE $base/FOOBAR 3" );
is( $status->code, 'DOCHAZKA_CUD_OK', "DELETE $base/FOOBAR 4" );

note( "really gone" );
req( $test, 404, 'root', 'GET', "$base/FOOBAR" );

note( "root: fail invalid code" );
req( $test, 400, 'root', 'DELETE', "$base/!!!" );

note( "delete FOOBARPUS, too" );
$status = req( $test, 200, 'root', 'DELETE', "$base/foobarpus" );
is( $status->level, 'OK', "DELETE $base/foobarpus 2" );
is( $status->code, 'DOCHAZKA_CUD_OK', "DELETE $base/foobarpus 3" );

note( "teardown" );
$status = delete_all_attendance_data();
if ( $status->not_ok ) {
    diag( Dumper $status );
    BAIL_OUT(0);
}

done_testing;
