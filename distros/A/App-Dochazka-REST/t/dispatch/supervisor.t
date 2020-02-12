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
# test if supervisors can view attendance data of their reports
#

#!perl
use 5.012;
use strict;
use warnings;

#use App::CELL::Test::LogToFile;
use App::CELL qw( $meta $site );
use App::Dochazka::Common qw( $today );
use App::Dochazka::REST::ConnBank qw( $dbix_conn );
use App::Dochazka::REST::Model::Schedule;
use App::Dochazka::REST::Test;
use Data::Dumper;
use JSON;
use Plack::Test;
use Test::More;
use Test::Warnings;


note( 'initialize, connect to database, and set up a testing plan' );
my $app = initialize_regression_test();

note( 'instantiate Plack::Test object');
my $test = Plack::Test->create( $app );

note( 'create a testing schedule' );
my $sid = create_testing_schedule( $test );

note( 'create testing user boss' );
my $boss_eid = create_active_employee( $test );
req( $test, 200, 'root', 'PUT', "employee/eid/$boss_eid", "{ \"nick\" : \"boss\" }" );
req( $test, 200, 'root', 'PUT', "employee/eid/$boss_eid", "{ \"password\" : \"boss\" }" );

note( 'create testing user peon' );
my $peon_eid = create_active_employee( $test );
req( $test, 200, 'root', 'PUT', "employee/eid/$peon_eid", "{ \"nick\" : \"peon\" }" );
req( $test, 200, 'root', 'PUT', "employee/eid/$peon_eid", "{ \"supervisor\" : $boss_eid }" );
req( $test, 200, 'root', 'PUT', "employee/eid/$peon_eid", "{ \"password\" : \"peon\" }" );

note( 'create testing user active' );
my $active_eid = create_active_employee( $test );

note( 'give \'peon\' a schedule as of 1957-01-01 00:00 so he can enter some attendance intervals' );
my @shid_for_deletion;
my $status = req( $test, 201, 'root', 'POST', "schedule/history/nick/peon", <<"EOH" );
{ "sid" : $sid, "effective" : "1957-01-01 00:00" }
EOH
is( $status->level, "OK" );
is( $status->code, "DOCHAZKA_CUD_OK" );
ok( $status->{'payload'} );
ok( $status->{'payload'}->{'shid'} );
push @shid_for_deletion, $status->{'payload'}->{'shid'};

note( 'boss can see peon profile' );
$status = req( $test, 200, 'boss', 'GET', 'employee/nick/peon' );
is( $status->level, 'OK' );
is( $status->code, 'DISPATCH_EMPLOYEE_FOUND' );
is( $status->payload->{'nick'}, 'peon' );

note( 'peon cannot see boss profile' );
$status = req( $test, 403, 'peon', 'GET', 'employee/nick/boss' );
is( $status->level, 'ERR' );
is( $status->code, 'DISPATCH_KEEP_TO_YOURSELF' );

note( 'get AID of work' );
my $aid_of_work = get_aid_by_code( $test, 'WORK' );

note( 'peon does some work' );
$status = req( $test, 201, 'peon', 'POST', 'interval/new', <<"EOH" );
{ "aid" : $aid_of_work, "intvl" : "[1957-01-02 08:00, 1957-01-03 08:00)" }
EOH
is( $status->level, 'OK' );
is( $status->code, 'DOCHAZKA_CUD_OK' );
ok( $status->{'payload'} );
ok( $status->{'payload'}->{'iid'} );
my $iid = $status->payload->{'iid'};

note( 'peon can see his work using GET interval/iid/:iid' );
$status = req( $test, 200, 'peon', 'GET', "interval/iid/$iid" );
is( $status->level, 'OK' );
is( $status->code, 'DISPATCH_INTERVAL_FOUND' );
ok( $status->{'payload'} );
ok( $status->{'payload'}->{'iid'} );
is( $status->{'payload'}->{'iid'}, $iid );

note( 'boss can see peon\'s work using GET interval/iid/:iid' );
$status = req( $test, 200, 'boss', 'GET', "interval/iid/$iid" );
is( $status->level, 'OK' );
is( $status->code, 'DISPATCH_INTERVAL_FOUND' );
ok( $status->{'payload'} );
ok( $status->{'payload'}->{'iid'} );
is( $status->{'payload'}->{'iid'}, $iid );

note( 'boss goes inactive' );
$status = req( $test, 201, 'root', 'POST', "priv/history/eid/$boss_eid", 
    '{ "effective":"1893-01-01", "priv":"inactive" }' );
is( $status->code, 'DOCHAZKA_CUD_OK' );
my $phid = $status->payload->{'phid'};
ok( $phid );

note( 'inactive boss can still see peon\'s work using GET interval/iid/:iid' );
$status = req( $test, 200, 'boss', 'GET', "interval/iid/$iid" );
is( $status->level, 'OK' );
is( $status->code, 'DISPATCH_INTERVAL_FOUND' );
ok( $status->{'payload'} );
ok( $status->{'payload'}->{'iid'} );
is( $status->{'payload'}->{'iid'}, $iid );

note( 'restore boss\'s active status' );
$status = req( $test, 200, 'root', 'DELETE', "priv/history/phid/$phid" );
is( $status->code, 'DOCHAZKA_CUD_OK' );

note( 'active can\'t see peon\'s work using GET interval/iid/:iid' );
$status = req( $test, 403, 'active', 'GET', "interval/iid/$iid" );
is( $status->level, 'ERR' );
is( $status->code, 'DISPATCH_KEEP_TO_YOURSELF' );

note( 'peon can see his own interval using a range' );
my @variants = ( "self", "nick/peon", "eid/$peon_eid" );
for my $variant ( @variants ) {
    $status = req( $test, 200, 'peon', 'GET', 'interval/self/( "1957-01-01", "1957-01-31" )' );
    is( $status->level, 'OK' );
    is( $status->code, 'DISPATCH_RECORDS_FOUND' );
    is( ref( $status->payload ), 'ARRAY' );
    is( scalar( @{ $status->payload } ), 1 );
    is( ref( $status->payload->[0] ), 'HASH' );
    is( $status->payload->[0]->{'iid'}, $iid );
}

note( 'boss can see his peon\'s interval using a range' );
@variants = ( "nick/peon", "eid/$peon_eid" );
for my $variant ( @variants ) {
    $status = req( $test, 200, 'boss', 'GET', 
        "interval/$variant/( \"1957-01-01\", \"1957-01-31\" )" );
    is( $status->level, 'OK' );
    is( $status->code, 'DISPATCH_RECORDS_FOUND' );
    is( ref( $status->payload ), 'ARRAY' );
    is( scalar( @{ $status->payload } ), 1 );
    is( ref( $status->payload->[0] ), 'HASH' );
    is( $status->payload->[0]->{'iid'}, $iid );
}

note( 'boss goes inactive' );
$status = req( $test, 201, 'root', 'POST', "priv/history/eid/$boss_eid", 
    '{ "effective":"1893-01-01", "priv":"inactive" }' );
is( $status->code, 'DOCHAZKA_CUD_OK' );
$phid = $status->payload->{'phid'};
ok( $phid );

note( 'inactive boss can still see peon\'s work using a range' );
@variants = ( "nick/peon", "eid/$peon_eid" );
for my $variant ( @variants ) {
    $status = req( $test, 200, 'boss', 'GET', 
        "interval/$variant/( \"1957-01-01\", \"1957-01-31\" )" );
    is( $status->level, 'OK' );
    is( $status->code, 'DISPATCH_RECORDS_FOUND' );
    is( ref( $status->payload ), 'ARRAY' );
    is( scalar( @{ $status->payload } ), 1 );
    is( ref( $status->payload->[0] ), 'HASH' );
    is( $status->payload->[0]->{'iid'}, $iid );
}

note( 'restore boss\'s active status' );
$status = req( $test, 200, 'root', 'DELETE', "priv/history/phid/$phid" );
is( $status->code, 'DOCHAZKA_CUD_OK' );

note( 'active cannot see peon\'s intervals using a range' );
@variants = ( "nick/peon", "eid/$peon_eid" );
for my $variant ( @variants ) {
    $status = req( $test, 403, 'active', 'GET', 
        "interval/$variant/( \"1957-01-01\", \"1957-01-31\" )" );
    is( $status->level, 'ERR' );
    is( $status->code, 'DISPATCH_KEEP_TO_YOURSELF' );
}

note( 'peon locks month' );
$status = req( $test, 201, 'peon', 'POST', 'lock/new', 
    "{ \"intvl\" : \"[ 1957-01-01 00:00, 1957-01-31 24:00 )\" }" );
is( $status->level, 'OK' );
is( $status->code, "DOCHAZKA_CUD_OK" );
is( $status->payload->{'eid'}, $peon_eid );
my $lid = $status->payload->{'lid'};
ok( $lid );
like( $status->payload->{'intvl'}, qr/1957/ );

note( 'peon can see his own lock using GET lock/lid/:lid' );
$status = req( $test, 200, 'peon', 'GET', "lock/lid/$lid" );
is( $status->level, 'OK' );
is( $status->code, 'DISPATCH_LOCK_FOUND' );
ok( $status->{'payload'} );
ok( $status->{'payload'}->{'lid'} );
is( $status->{'payload'}->{'lid'}, $lid );

note( 'boss can see peon\'s lock using GET lock/lid/:lid' );
$status = req( $test, 200, 'boss', 'GET', "lock/lid/$lid" );
is( $status->level, 'OK' );
is( $status->code, 'DISPATCH_LOCK_FOUND' );
ok( $status->{'payload'} );
ok( $status->{'payload'}->{'lid'} );
is( $status->{'payload'}->{'lid'}, $lid );

note( 'boss goes inactive' );
$status = req( $test, 201, 'root', 'POST', "priv/history/eid/$boss_eid", 
    '{ "effective":"1893-01-01", "priv":"inactive" }' );
is( $status->code, 'DOCHAZKA_CUD_OK' );
$phid = $status->payload->{'phid'};
ok( $phid );

note( 'inactive boss can\'t see peon\'s lock using GET lock/lid/:lid' );
$status = req( $test, 403, 'boss', 'GET', "lock/lid/$lid" );
is( $status->code, 'DISPATCH_ACL_CHECK_FAILED' ); 
is( $status->text, 'ACL check failed for resource lock/lid/:lid' );

note( 'restore boss\'s active status' );
$status = req( $test, 200, 'root', 'DELETE', "priv/history/phid/$phid" );
is( $status->code, 'DOCHAZKA_CUD_OK' );

note( 'active can\'t see peon\'s lock using GET lock/lid/:lid' );
$status = req( $test, 403, 'active', 'GET', "lock/lid/$lid" );
is( $status->level, 'ERR' );
is( $status->code, 'DISPATCH_KEEP_TO_YOURSELF' );

note( 'peon can see his own lock using a range' );
@variants = ( "self", "nick/peon", "eid/$peon_eid" );
for my $variant ( @variants ) {
    $status = req( $test, 200, 'peon', 'GET', 'lock/self/( "1957-01-01", "1957-01-31" )' );
    is( $status->level, 'OK' );
    is( $status->code, 'DISPATCH_RECORDS_FOUND' );
    is( ref( $status->payload ), 'ARRAY' );
    is( scalar( @{ $status->payload } ), 1 );
    is( ref( $status->payload->[0] ), 'HASH' );
    is( $status->payload->[0]->{'lid'}, $lid );
}

note( 'boss can see his peon\'s lock using a range' );
@variants = ( "nick/peon", "eid/$peon_eid" );
for my $variant ( @variants ) {
    $status = req( $test, 200, 'boss', 'GET', 
        "lock/$variant/( \"1957-01-01\", \"1957-01-31\" )" );
    is( $status->level, 'OK' );
    is( $status->code, 'DISPATCH_RECORDS_FOUND' );
    is( ref( $status->payload ), 'ARRAY' );
    is( scalar( @{ $status->payload } ), 1 );
    is( ref( $status->payload->[0] ), 'HASH' );
    is( $status->payload->[0]->{'lid'}, $lid );
}

note( 'boss goes inactive' );
$status = req( $test, 201, 'root', 'POST', "priv/history/eid/$boss_eid", 
    '{ "effective":"1893-01-01", "priv":"inactive" }' );
is( $status->code, 'DOCHAZKA_CUD_OK' );
$phid = $status->payload->{'phid'};
ok( $phid );

note( 'inactive boss can\'t see peon\'s lock using a range' );
@variants = ( "nick/peon", "eid/$peon_eid" );
for my $variant ( @variants ) {
    $status = req( $test, 403, 'boss', 'GET', "lock/$variant/( \"1957-01-01\", \"1957-01-31\" )" );
    is( $status->code, 'DISPATCH_ACL_CHECK_FAILED' ); 
    like( $status->text, qr/ACL check failed for resource lock/ );
}

note( 'restore boss\'s active status' );
$status = req( $test, 200, 'root', 'DELETE', "priv/history/phid/$phid" );
is( $status->code, 'DOCHAZKA_CUD_OK' );

note( 'active cannot see peon\'s locks using a range' );
@variants = ( "nick/peon", "eid/$peon_eid" );
for my $variant ( @variants ) {
    $status = req( $test, 403, 'active', 'GET', 
        "lock/$variant/( \"1957-01-01\", \"1957-01-31\" )" );
    is( $status->level, 'ERR' );
    is( $status->code, 'DISPATCH_KEEP_TO_YOURSELF' );
}

note( 'tear down' );
$status = delete_all_attendance_data();
BAIL_OUT(0) unless $status->ok;

done_testing;
