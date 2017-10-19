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
# test schedule (non-history) resources
#

#!perl
use 5.012;
use strict;
use warnings;

#use App::CELL::Test::LogToFile;
use App::CELL qw( $meta $site );
use App::Dochazka::Common qw( $today $yesterday $tomorrow );
use App::Dochazka::REST::ConnBank qw( $dbix_conn );
use App::Dochazka::REST::Model::Schedhistory;
use App::Dochazka::REST::Model::Schedule qw( sid_exists );
use App::Dochazka::REST::Test;
use Data::Dumper;
use JSON;
use Plack::Test;
use Test::JSON;
use Test::More;


note( "initialize, connect to database, and set up a testing plan" );
my $app = initialize_regression_test();

note( "instantiate Plack::Test object");
my $test = Plack::Test->create( $app );

my $res;

my $ts_eid_active = create_active_employee( $test );
my $ts_eid_inactive = create_inactive_employee( $test );

note( '===========================================' );
note( '"schedule/all" resource' );
note( '===========================================' );
my $base = "schedule/all";
docu_check($test, $base);

my $ts_sid = create_testing_schedule( $test );

note( 'GET' );

note( "GET $base as demo user" );
req( $test, 403, 'demo', 'GET', $base );

foreach my $user ( 'inactive', 'active', 'root' ) {
    note( "GET $base as $user user" );
    my $status = req( $test, 200, $user, 'GET', $base );
    is( $status->level, 'OK' );
    is( $status->code, "DISPATCH_RECORDS_FOUND" );
    is( $status->{'count'}, 2 );
    ok( exists $status->payload->[1]->{'sid'} );
    ok( $status->payload->[1]->{'sid'} > 0 );
    is( $ts_sid, $status->payload->[1]->{'sid'} );
}

note( 'add six more schedules to the pot' );
my @sid_range;
foreach my $day ( 3..10 ) {
    my $intvls = { "schedule" => [ 
        "[2000-01-" . ( $day + 1 ) . " 12:30, 2000-01-" . ( $day + 1 ) . " 16:30)",
        "[2000-01-" . ( $day + 1 ) . " 08:00, 2000-01-" . ( $day + 1 ) . " 12:00)",
        "[2000-01-" . ( $day ) . " 12:30, 2000-01-" . ( $day ) . " 16:30)",
        "[2000-01-" . ( $day ) . " 08:00, 2000-01-" . ( $day ) . " 12:00)",
        "[2000-01-" . ( $day - 1 ) . " 12:30, 2000-01-" . ( $day - 1 ) . " 16:30)",
        "[2000-01-" . ( $day - 1 ) . " 08:00, 2000-01-" . ( $day - 1 ) . " 12:00)",
    ] };  
    my $intvls_json = JSON->new->utf8->canonical(1)->encode( $intvls );

    note( "day $day schedule/new request as root" );
    my $status = req( $test, 201, 'root', 'POST', "schedule/new", $intvls_json );
    is( $status->level, 'OK' );
    ok( $status->code eq 'DISPATCH_SCHEDULE_INSERT_OK' or $status->code eq 'DISPATCH_SCHEDULE_EXISTS' );
    ok( exists $status->{'payload'} );
    ok( exists $status->payload->{'sid'} );
    my $sid = $status->payload->{'sid'};
    ok( sid_exists( $dbix_conn, $sid ) );
    push @sid_range, $sid;
}

note( 'test a non-existent SID' );
ok( ! sid_exists( $dbix_conn, 53434 ), "non-existent SID" );

note( 'now we have seven active (i.e., non-disabled) schedules' );
my $status = req( $test, 200, 'root', 'GET', $base );
is( $status->level, 'OK' );
is( $status->code, "DISPATCH_RECORDS_FOUND" );
is( $status->{'count'}, 8 );

note( 'disable one at random' );
$status = req( $test, 200, 'root', 'PUT', "schedule/sid/" . $sid_range[3], '{ "disabled":true }' );
is( $status->level, 'OK' );
is( $status->code, 'DOCHAZKA_CUD_OK' );

note( 'now we have six active (i.e., non-disabled) schedules' );
$status = req( $test, 200, 'root', 'GET', $base );
is( $status->level, 'OK' );
is( $status->code, "DISPATCH_RECORDS_FOUND" );
is( $status->{'count'}, 7 );

note( 'PUT, POST, DELETE -> 405' );
foreach my $user ( qw( demo root ) ) {
    foreach my $method ( qw( PUT POST DELETE ) ) {
        req( $test, 405, $user, $method, $base );
    }
}

note( '===========================================' );
note( '"schedule/all/disabled" resource' );
note( '===========================================' );
$base = "schedule/all/disabled";
docu_check($test, $base);

note( 'GET' );

note( "GET $base as demo user" );
req( $test, 403, 'demo', 'GET', $base );

note( "GET $base as inactive user" );
req( $test, 403, 'inactive', 'GET', $base );

note( "GET $base as active user" );
req( $test, 403, 'active', 'GET', $base );

note( "GET $base as root user" );
$status = req( $test, 200, 'root', 'GET', $base );
is( $status->level, 'OK' );
is( $status->code, "DISPATCH_RECORDS_FOUND" );
is( $status->{'count'}, 8 );

note( 'delete two schedules' );
my $counter = 0;
foreach my $sid ( @sid_range[1..2] ) {
    $counter += 1;
    $status = req( $test, 200, 'root', 'DELETE', "schedule/sid/$sid" );
    is( $status->level, 'OK' );
    is( $status->code, 'DOCHAZKA_CUD_OK' );
}
is( $counter, 2 );

note( 'DEFAULT schedule must be preserved after any deletion' );
$status = req( $test, 200, 'root', 'GET', "schedule/scode/DEFAULT" );
is( $status->level, 'OK' );
is( $status->code, 'DISPATCH_SCHEDULE_FOUND' );
is( $status->payload->{'scode'}, 'DEFAULT' );

note( 'now only 4 when disabled are not counted' );
$status = req( $test, 200, 'root', 'GET', 'schedule/all' );
is( $status->level, 'OK' );
is( $status->code, "DISPATCH_RECORDS_FOUND" );
is( $status->{'count'}, 5 );

note( 'the total number has dropped from 7 to 5' );
req( $test, 403, 'demo', 'GET', $base );
$status = req( $test, 200, 'root', 'GET', $base );
is( $status->level, 'OK' );
is( $status->code, "DISPATCH_RECORDS_FOUND" );
is( $status->{'count'}, 6 );

note( 'delete them' );
my $obj = App::Dochazka::REST::Model::Schedule->spawn;
foreach my $schedule ( @{ $status->payload } ) {
    $obj->reset( $schedule );
    next if $obj->scode eq 'DEFAULT';
    ok( sid_exists( $dbix_conn, $obj->sid ) );
    $status = req( $test, 200, 'root', 'DELETE', "schedule/sid/" . $obj->sid );
    is( $status->level, 'OK' );
    is( $status->code, 'DOCHAZKA_CUD_OK' );
    ok( ! sid_exists( $dbix_conn, $obj->sid ) );
}


note( 'DEFAULT schedule must be preserved after any deletion' );
$status = req( $test, 200, 'root', 'GET', "schedule/scode/DEFAULT" );
is( $status->level, 'OK' );
is( $status->code, 'DISPATCH_SCHEDULE_FOUND' );
is( $status->payload->{'scode'}, 'DEFAULT' );

note( 'count should now be one' );
$status = req( $test, 200, 'root', 'GET', 'schedule/all/disabled' );
is( $status->level, 'OK' );
is( $status->code, "DISPATCH_RECORDS_FOUND" );
is( $status->{'count'}, 1 );

note( 'PUT, POST, DELETE -> 405' );
foreach my $user ( qw( demo root ) ) {
    foreach my $method ( qw( PUT POST DELETE ) ) {
        req( $test, 405, $user, $method, $base );
    }
}

#delete_testing_schedule( $ts_sid );


note( '===========================================' );
note( '"schedule/eid/:eid/?:ts" resource' );
note( '===========================================' );
$base = "schedule/eid";
docu_check($test, "$base/:eid/?:ts");

$ts_sid = create_testing_schedule( $test );

note( "bestow testing schedule upon the inactive employee" );
$status = req( $test, 201, 'root', 'POST', "/schedule/history/eid/$ts_eid_inactive", 
    '{ "effective":"2014-10-10", "sid":' . $ts_sid . ' }' );
is( $status->level, 'OK' );
is( $status->code, 'DOCHAZKA_CUD_OK' );
ok( exists $status->{payload} );
ok( $status->payload->{shid} );
my $ts_shid = $status->payload->{shid};

note( 'GET' );

note( 'root has no schedule' );
req( $test, 403, 'demo', 'GET', "$base/1" );
req( $test, 404, 'root', 'GET', "$base/1" );

note( 'as root, with timestamp before 1892' );
req( $test, 404, 'root', 'GET', "$base/1/1891-12-31 23:59" );

note( 'as root, with timestamp 1892-01-01 01:01' );
req( $test, 404, 'root', 'GET', "$base/1/1892-01-01 00:01" );

note( 'get inactive\'s schedule in many different ways' );
foreach my $spec ( 
    [ 'root', "$base/$ts_eid_inactive" ], 
    [ 'root', "/schedule/nick/inactive" ],
    [ 'inactive', "/schedule/self" ],
    [ 'root', "$base/$ts_eid_inactive/2015-06-01 00:00" ], 
    [ 'root', "/schedule/nick/inactive/2015-06-01 00:00" ],
    [ 'inactive', "/schedule/self/2015-06-01 00:00" ],
   ) {

    note( 'GET ' . $spec->[1] . ' as ' . $spec->[0] );
    $status = req( $test, 200, $spec->[0], 'GET', $spec->[1] );
    is( $status->level, 'OK' );
    if ( $spec->[1] =~ m/2015-06-01/ ) {
        is( $status->code, "DISPATCH_EMPLOYEE_SCHEDULE_AS_AT" );
    } else {
        is( $status->code, "DISPATCH_EMPLOYEE_SCHEDULE" );
    }
    ok( exists( $status->{payload} ) );
    ok( $status->payload->{eid} > 1 );
    is( $status->payload->{nick}, 'inactive' );
    ok( exists( $status->payload->{schedule} ) );
    note( 'payload is a schedule object' );
    my $sch = App::Dochazka::REST::Model::Schedule->spawn( %{ $status->payload->{schedule} } );
    is( $sch->scode, 'KOBOLD' );
}

note( 'attempt to GET inactive\'s schedule at a time when it didn\'t have one assigned' );
foreach my $spec ( [ 'root', "$base/$ts_eid_inactive/1955-06-01 00:00" ], 
                   [ 'root', "/schedule/nick/inactive/1955-06-01 00:00" ], 
                   [ 'inactive', "/schedule/self/1955-06-01 00:00" ] ) {
    note( 'GET ' . $spec->[1] . ' as ' . $spec->[0] );
    req( $test, 404, $spec->[0], 'GET', $spec->[1] );
}

note( "GET $base/5343 (non-existent EID)" );
req( $test, 404, 'root', 'GET', "$base/5343" );

note( "GET $base/-33 (negative EID)" );
req( $test, 404, 'root', 'GET', "$base/-33" );

note( "GET $base/34343.33322.22.21 (non-integer EID)" );
req( $test, 400, 'root', 'GET', "$base/34343.33322.22.21" );

note( "GET $base/a thousand clarinets (non-integer EID)" );
req( $test, 400, 'root', 'GET', "$base/a thousand clarinets" );

note( "GET $base/sad;f3.** * @#/ 12341 12 jjj (non-integer EID combined with invalid timestamp)" );
req( $test, 400, 'root', 'GET', "$base/sad;f3.** * @#/ 12341 12 jjj" );

note( "GET $base/2/ 12341 12 jjj (valid EID, stupid timestamp)" );
dbi_err( $test, 500, 'root', 'GET', "$base/2/ 12341 12 jjj", undef,
    qr/invalid input syntax for type timestamp with time zone/ );

note( "GET $base/999/ 12341 12 jjj (valid EID, stupid timestamp)" );
req( $test, 404, 'root', 'GET', "$base/999/ 12341 12 jjj" );

note( "GET $base/999/2999-01-33 00:-1 (valid EID, valid timestamp)" );
req( $test, 404, 'root', 'GET', "$base/999/2999-01-33 00:-1" );

note( "GET $base/1/2999-01-33 00:-1 (valid EID, valid timestamp)" );
dbi_err( $test, 500, 'root', 'GET', "$base/1/2999-01-33 00:-1", undef,
    qr#date/time field value out of range# );

note( "GET $base/1/wanger (wanger)" );
dbi_err( $test, 500, 'root', 'GET', "$base/1/wanger", undef,
    qr/invalid input syntax for type timestamp/ );


note( 'PUT, POST, DELETE -> 405' );
foreach my $user ( qw( demo root ) ) {
    foreach my $method ( qw( PUT POST DELETE ) ) {
        foreach my $baz ( "$base/1", "$base/1/1892-01-01" ) {
            req( $test, 405, $user, $method, $baz );
        }
    }
}

note( "delete inactive's schedule history record" );
$status = req( $test, 200, 'root', 'DELETE', "/schedule/history/shid/$ts_shid" );
is( $status->level, 'OK' );
is( $status->code, 'DOCHAZKA_CUD_OK' );

note( "delete the testing schedule itself" );
delete_testing_schedule( $ts_sid );

note( '===========================================' );
note( '"schedule/new" resource' );
note( '===========================================' );
$base = "schedule/new";
docu_check( $test, $base );

note( 'GET, PUT -> 405' );
req( $test, 405, 'demo', 'GET', $base );
req( $test, 405, 'root', 'GET', $base );
req( $test, 405, 'demo', 'PUT', $base );
req( $test, 405, 'root', 'PUT', $base );

note( "test typical workflow for this resource, $base" );
note( '- set up an array of schedule intervals for testing' );
my $intvls = { "schedule" => [
    "[$tomorrow 12:30, $tomorrow 16:30)",
    "[$tomorrow 08:00, $tomorrow 12:00)",
    "[$today 12:30, $today 16:30)",
    "[$today 08:00, $today 12:00)",
    "[$yesterday 12:30, $yesterday 16:30)",
    "[$yesterday 08:00, $yesterday 12:00)",
], "scode" => 'testfoo' };
my $intvls_json = JSON->new->utf8->canonical(1)->encode( $intvls );

note( 'POST' );

note( '- request as demo will fail with 403' );
req( $test, 403, 'demo', 'POST', $base, $intvls_json );

note( '- request as root with no request body will return 400' );
req( $test, 400, 'root', 'POST', $base );

note( '- request as root' );
$status = req( $test, 201, 'root', 'POST', $base, $intvls_json );
diag( Dumper $status ) unless $status->ok;
is( $status->level, 'OK' );
is( $status->code, 'DISPATCH_SCHEDULE_INSERT_OK' );
ok( exists $status->{'payload'} );
ok( exists $status->payload->{'sid'} );
ok( exists $status->payload->{'scode'} );
my $sid = $status->payload->{'sid'};
my $scode = $status->payload->{'scode'};
is( $scode, 'testfoo' );

note( '- request the same schedule - code should change to DISPATCH_SCHEDULE_EXISTS' );
$status = req( $test, 201, 'root', 'POST', $base, $intvls_json );
diag( Dumper $status ) unless $status->ok;
is( $status->level, 'OK' );
is( $status->code, 'DISPATCH_SCHEDULE_EXISTS' );
ok( exists $status->{'payload'} );
ok( exists $status->payload->{'sid'} );
is( $status->payload->{'sid'}, $sid );

note( '- and now delete the schedules record (schedintvls records are already gone)' );
$status = req( $test, 200, 'root', 'DELETE', "schedule/sid/$sid" );
diag( Dumper $status ) unless $status->ok;
is( $status->code, 'DOCHAZKA_CUD_OK' );

note( '- count should now be one' );
$status = req( $test, 200, 'root', 'GET', 'schedule/all/disabled' );
is( $status->level, 'OK' );
is( $status->code, "DISPATCH_RECORDS_FOUND" );
is( $status->{'count'}, 1 );

note( '- for the next test case, insert a testing schedule _without_ an scode' );
$intvls = { "schedule" => [
    "[$today 12:30, $today 16:30)",
    "[$today 08:00, $today 12:00)",
] };
$intvls_json = JSON->new->utf8->canonical(1)->encode( $intvls );
$status = req( $test, 201, 'root', 'POST', $base, $intvls_json );
diag( Dumper $status ) unless $status->ok;
is( $status->level, 'OK' );
is( $status->code, 'DISPATCH_SCHEDULE_INSERT_OK' );
ok( exists $status->{'payload'} );
ok( exists $status->payload->{'sid'} );
ok( exists $status->payload->{'scode'} );
ok( ! defined $status->payload->{'scode'} );
$sid = $status->payload->{'sid'};

note( '- now, change the scode and insert again' );
$intvls = { "schedule" => [
    "[$today 12:30, $today 16:30)",
    "[$today 08:00, $today 12:00)",
], "scode" => 'WANGERFETZ' };
$intvls_json = JSON->new->utf8->canonical(1)->encode( $intvls );
$status = req( $test, 201, 'root', 'POST', $base, $intvls_json );
diag( Dumper $status ) unless $status->ok;
is( $status->level, 'OK' );
is( $status->code, 'DISPATCH_SCHEDULE_UPDATE_OK' );
ok( exists $status->{'payload'} );
ok( exists $status->payload->{'sid'} );
ok( exists $status->payload->{'scode'} );
is( $status->payload->{'sid'}, $sid );
is( $status->payload->{'scode'}, 'WANGERFETZ' );

note( 'use GET, just to make sure' );
$status = req( $test, 200, 'root', 'GET', "schedule/scode/WANGERFETZ" );
is( $status->level, 'OK' );
is( $status->code, 'DISPATCH_SCHEDULE_FOUND' );
ok( exists $status->{'payload'} );
ok( exists $status->payload->{'sid'} );
ok( exists $status->payload->{'scode'} );
is( $status->payload->{'sid'}, $sid );
is( $status->payload->{'scode'}, 'WANGERFETZ' );

note( 'now insert the same schedule again, but with a different scode' );
$intvls = { "schedule" => [
    "[$today 12:30, $today 16:30)",
    "[$today 08:00, $today 12:00)",
], "scode" => 'DIFFERENT_WANGER' };
$intvls_json = JSON->new->utf8->canonical(1)->encode( $intvls );
$status = req( $test, 201, 'root', 'POST', $base, $intvls_json );
is( $status->payload->{'sid'}, $sid );
is( $status->payload->{'scode'}, 'WANGERFETZ' );

note( 'update WANGERFETZ, replacing WANGERFETZ with NULL' );
$status = req( $test, 200, 'root', 'PUT', "schedule/scode/WANGERFETZ", '{ "scode" : null }' );
is( $status->level, 'OK' );
is( $status->code, 'DOCHAZKA_CUD_OK' );
ok( exists $status->{'payload'} );
ok( exists $status->payload->{'sid'} );
ok( exists $status->payload->{'scode'} );
is( $status->payload->{'sid'}, $sid );
is( $status->payload->{'scode'}, undef );

note( 'delete WANGERFETZ, so it doesn\'t trip us up later' );
$status = req( $test, 200, 'root', 'DELETE', "schedule/sid/$sid" );
ok( $status->ok );

note( 'DELETE -> 405' );
req( $test, 405, 'demo', 'DELETE', $base );
req( $test, 405, 'root', 'DELETE', $base );


note( '===========================================' );
note( '"schedule/nick/:nick/?:ts" resource' );
note( '===========================================' );
$base = "schedule/nick";
docu_check($test, "$base/:nick/?:ts");

note( 'GET' );

note( "GET $base/root as demo" );
req( $test, 403, 'demo', 'GET', "$base/root" );

note( "GET $base/root as root" );
req( $test, 404, 'root', 'GET', "$base/root" );

note( "GET $base/root as root, with timestamp before 1892-01-01" );
req( $test, 404, 'root', 'GET', "$base/root/1891-12-31 23:59" );

note( "GET $base/root as root, with timestamp 1892-01-01 00:00" );
req( $test, 404, 'root', 'GET', "$base/root/1892-01-01 00:01" );

note( 'non-existent nick' );
req( $test, 404, 'root', 'GET', "$base/wanger" );

note( 'negative nick (does not pass validations)' );
req( $test, 400, 'root', 'GET', "$base/-33" );

note( 'stupid nick (fails on validations)' );
req( $test, 400, 'root', 'GET', "$base/34343.33322.22.21" );

note( 'stupid nick (fails on validations)' );
req( $test, 400, 'root', 'GET', "$base/a thousand clarinets" );

note( 'stupid nick (fails on validations)' );
req( $test, 400, 'root', 'GET', "$base/sad;f3.** * @#/ 12341 12 jjj" );

note( 'stupid ts' );
dbi_err( $test, 500, 'root', 'GET', "$base/demo/ 12341 12 jjj", undef,
    qr/invalid input syntax for type timestamp/ );

note( 'valid nick, stupid timestamp' );
req( $test, 404, 'root', 'GET', "$base/wanger/ 12341 12 jjj" );

note( 'valid nick, valid timestamp' );
req( $test, 404, 'root', 'GET', "$base/wanger/2999-01-33 00:-1" );

note( 'valid nick, valid timestamp' );
dbi_err( $test, 500, 'root', 'GET', "$base/root/2999-01-33 00:-1", undef,
    qr#date/time field value out of range# );

note( 'wanger' );
#req( $test, 404, 'root', 'GET', "$base/root/wanger" );
dbi_err( $test, 500, 'root', 'GET', "$base/root/wanger", undef,
    qr/invalid input syntax for type timestamp/ );

note( 'PUT, POST, DELETE -> 405' );
foreach my $user ( qw( demo root ) ) {
    foreach my $method ( qw( PUT POST DELETE ) ) {
        foreach my $baz ( "$base/root", "$base/root/1892-01-01" ) {
            req( $test, 405, $user, $method, $baz );
        }
    }
}


note( '=============================' );
note( '"schedule/self/?:ts" resource' );
note( '=============================' );
$base = "schedule/self";
docu_check($test, "$base/?:ts");

note( 'GET' );

note( "GET $base as demo, but demo has no schedule history" );
req( $test, 404, 'demo', 'GET', $base );

note( "GET $base as root, but root has no schedule history, either" );
req( $test, 404, 'root', 'GET', $base );

note( "GET $base as root, with timestamp before 1892 A.D." );
req( $test, 404, 'root', 'GET', "$base/1891-12-31 23:59" );

note( "GET $base as root, with timestamp 1892-01-01 00:00" );
req( $test, 404, 'root', 'GET', "$base/1892-01-01 00:01" );

note( "wanger" );
dbi_err( $test, 500, 'root', 'GET', "$base/wanger", undef,
    qr/invalid input syntax for type timestamp/ );

note( "stupid ts" );
dbi_err( $test, 500, 'root', 'GET', "$base/ 12341 12 jjj", undef, 
    qr/invalid input syntax for type timestamp/ );

note( "valid nick, valid timestamp" );
dbi_err( $test, 500, 'root', 'GET', "$base/2999-01-33 00:-1", undef,
    qr#date/time field value out of range# );

note( 'PUT, POST, DELETE -> 405' );
foreach my $user ( qw( demo root ) ) {
    foreach my $method ( qw( PUT POST DELETE ) ) {
        foreach my $baz ( $base, "$base/1892-01-01" ) {
            req( $test, 405, $user, $method, $baz );
        }
    }
}


note( '===========================================' );
note( '"schedule/sid/:sid" resource' );
note( '===========================================' );
$base = 'schedule/sid';
docu_check( $test, "$base/:sid" );

$sid = create_testing_schedule( $test );

note( 'GET' );
$status = req( $test, 200, 'root', 'GET', "$base/$sid" );
diag( Dumper $status ) unless $status->ok;
#diag( Dumper $status );
is( $status->level, 'OK' );
is( $status->code, 'DISPATCH_SCHEDULE_FOUND' );
is( $status->payload->{'disabled'}, 0 );
is( $status->payload->{'remark'}, undef );
is( $status->payload->{'schedule'}, '[{"high_dow":"FRI","high_time":"12:00","low_dow":"FRI","low_time":"08:00"},{"high_dow":"FRI","high_time":"16:30","low_dow":"FRI","low_time":"12:30"},{"high_dow":"SAT","high_time":"12:00","low_dow":"SAT","low_time":"08:00"},{"high_dow":"SAT","high_time":"16:30","low_dow":"SAT","low_time":"12:30"},{"high_dow":"SUN","high_time":"12:00","low_dow":"SUN","low_time":"08:00"},{"high_dow":"SUN","high_time":"16:30","low_dow":"SUN","low_time":"12:30"}]' );
ok( $status->payload->{'sid'} > 0 );
is( $status->payload->{'sid'}, $sid );

note( 'POST -> 405' );
req( $test, 405, 'demo', 'POST', "$base/1" );
req( $test, 405, 'root', 'POST', "$base/1" );

note( 'PUT' );

note( 'add a remark to the schedule' );
req( $test, 403, 'demo', 'PUT', "$base/$sid" );
$status = req( $test, 200, 'root', 'PUT', "$base/$sid", '{ "remark" : "foobar" }' );
is( $status->level, 'OK' );
is( $status->code, 'DOCHAZKA_CUD_OK' );
ok( exists( $status->{'payload'} ) );
ok( defined( $status->payload ) );
ok( exists( $status->{'payload'}->{'remark'} ) );
ok( defined( $status->{'payload'}->{'remark'} ) );
is( $status->{'payload'}->{'remark'}, "foobar" );

note( 'verify with GET' );
$status = req( $test, 200, 'root', 'GET', "$base/$sid" );
is( $status->level, 'OK' );
is( $status->code, 'DISPATCH_SCHEDULE_FOUND' );
is( $status->payload->{'remark'}, 'foobar' );

note( 'disable the schedule in the wrong way' );
dbi_err( $test, 500, 'root', 'PUT', "$base/$sid", '{ "pebble" : [1,2,3], "disabled":"hoogar" }',
    qr/invalid input syntax for type boolean/ );

note( 'disable the schedule in the right way' );
$status = req( $test, 200, 'root', 'PUT', "$base/$sid", '{ "pebble" : [1,2,3], "disabled":true }' );
is( $status->level, 'OK' );
is( $status->code, 'DOCHAZKA_CUD_OK' );

note( 'add an scode' );
req( $test, 403, 'demo', 'PUT', "$base/$sid" );
$status = req( $test, 200, 'root', 'PUT', "$base/$sid", '{ "scode" : "bazblare" }' );
is( $status->level, 'OK' );
is( $status->code, 'DOCHAZKA_CUD_OK' );
ok( exists( $status->{'payload'} ) );
ok( defined( $status->payload ) );
ok( exists( $status->{'payload'}->{'scode'} ) );
ok( defined( $status->{'payload'}->{'scode'} ) );
is( $status->{'payload'}->{'scode'}, "bazblare" );

note( 'verify with GET' );
$status = req( $test, 200, 'root', 'GET', "$base/$sid" );
is( $status->level, 'OK' );
is( $status->code, 'DISPATCH_SCHEDULE_FOUND' );
is( $status->payload->{'scode'}, 'bazblare' );

note( 'DELETE' );

note( 'delete the testing schedule' );
$status = req( $test, 200, 'root', 'DELETE', "$base/$sid" );
is( $status->level, 'OK' );
is( $status->code, 'DOCHAZKA_CUD_OK' );


note( '===========================================' );
note( '"schedule/scode/:scode" resource' );
note( '===========================================' );
$base = 'schedule/scode';
docu_check( $test, "$base/:scode" );

note( "create testing schedule with scode == 'KOBOLD'" );
$sid = create_testing_schedule( $test );
$scode = 'KOBOLD';

note( 'GET' );
$status = req( $test, 200, 'root', 'GET', "schedule/sid/$sid" );
diag( Dumper $status ) unless $status->ok;
#diag( Dumper $status );
is( $status->level, 'OK' );
is( $status->code, 'DISPATCH_SCHEDULE_FOUND' );
is( $status->payload->{'disabled'}, 0 );
is( $status->payload->{'remark'}, undef );
is( $status->payload->{'schedule'}, '[{"high_dow":"FRI","high_time":"12:00","low_dow":"FRI","low_time":"08:00"},{"high_dow":"FRI","high_time":"16:30","low_dow":"FRI","low_time":"12:30"},{"high_dow":"SAT","high_time":"12:00","low_dow":"SAT","low_time":"08:00"},{"high_dow":"SAT","high_time":"16:30","low_dow":"SAT","low_time":"12:30"},{"high_dow":"SUN","high_time":"12:00","low_dow":"SUN","low_time":"08:00"},{"high_dow":"SUN","high_time":"16:30","low_dow":"SUN","low_time":"12:30"}]' );
is( $status->payload->{'scode'}, $scode );

note( 'POST -> 405' );
req( $test, 405, 'demo', 'POST', "$base/1" );
req( $test, 405, 'root', 'POST', "$base/1" );

note( 'PUT' );

note( 'add a remark to the schedule' );
req( $test, 403, 'demo', 'PUT', "$base/$scode" );
$status = req( $test, 200, 'root', 'PUT', "$base/$scode", '{ "remark" : "foobar" }' );
is( $status->level, 'OK' );
is( $status->code, 'DOCHAZKA_CUD_OK' );
ok( exists( $status->{'payload'} ) );
ok( defined( $status->payload ) );
ok( exists( $status->{'payload'}->{'remark'} ) );
ok( defined( $status->{'payload'}->{'remark'} ) );
is( $status->{'payload'}->{'remark'}, "foobar" );

note( 'verify with GET' );
$status = req( $test, 200, 'root', 'GET', "$base/$scode" );
is( $status->level, 'OK' );
is( $status->code, 'DISPATCH_SCHEDULE_FOUND' );
is( $status->payload->{'remark'}, 'foobar' );

note( 'disable the schedule in the wrong way' );
dbi_err( $test, 500, 'root', 'PUT', "$base/$scode", '{ "pebble" : [1,2,3], "disabled":"hoogar" }',
    qr/invalid input syntax for type boolean/ );

note( 'disable the schedule in the right way' );
$status = req( $test, 200, 'root', 'PUT', "$base/$scode", '{ "pebble" : [1,2,3], "disabled":true }' );
is( $status->level, 'OK' );
is( $status->code, 'DOCHAZKA_CUD_OK' );

note( 'change the scode' );
req( $test, 403, 'demo', 'PUT', "$base/$scode" );
$status = req( $test, 200, 'root', 'PUT', "$base/$scode", '{ "scode" : "bazblare" }' );
is( $status->level, 'OK' );
is( $status->code, 'DOCHAZKA_CUD_OK' );
ok( exists( $status->{'payload'} ) );
ok( defined( $status->payload ) );
ok( exists( $status->{'payload'}->{'scode'} ) );
ok( defined( $status->{'payload'}->{'scode'} ) );
is( $status->{'payload'}->{'scode'}, "bazblare" );

note( 'verify with GET' );
$status = req( $test, 200, 'root', 'GET', "$base/bazblare" );
is( $status->level, 'OK' );
is( $status->code, 'DISPATCH_SCHEDULE_FOUND' );
is( $status->payload->{'scode'}, 'bazblare' );

note( 'DELETE' );

note( 'delete the testing schedule' );
$status = req( $test, 200, 'root', 'DELETE', "$base/bazblare" );
is( $status->level, 'OK' );
is( $status->code, 'DOCHAZKA_CUD_OK' );

note( 'tear down' );
$status = delete_all_attendance_data();
BAIL_OUT(0) unless $status->ok;

note( 'DEFAULT schedule must be preserved' );
$status = req( $test, 200, 'root', 'GET', "$base/DEFAULT" );
is( $status->level, 'OK' );
is( $status->code, 'DISPATCH_SCHEDULE_FOUND' );
is( $status->payload->{'scode'}, 'DEFAULT' );

done_testing;
