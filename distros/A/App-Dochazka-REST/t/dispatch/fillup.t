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
# test 'interval/fillup' and 'interval/scheduled' resources
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

my ( $note, $resource, $status );

#note( 'start with a clean slate' );
#$status = delete_all_attendance_data();
#BAIL_OUT(0) unless $status->ok;

note( 'get AID of WORK' );
my $aid_of_work = get_aid_by_code( $test, 'WORK' );

note( $note = 'create a testing schedule' );
$log->info( "=== $note" );
my $sid = create_testing_schedule( $test );

note( $note = 'create testing employee \'active\' with \'active\' privlevel' );
$log->info( "=== $note" );
my $eid_of_active = create_active_employee( $test );

note( $note = 'give \'active\' a schedule as of 1957-01-01 00:00 so it can enter attendance intervals' );
$log->info( "=== $note" );
$status = req( $test, 201, 'root', 'POST', "schedule/history/nick/active", <<"EOH" );
{ "sid" : $sid, "effective" : "1957-01-01 00:00" }
EOH
is( $status->level, "OK" );
is( $status->code, "DOCHAZKA_CUD_OK" );
ok( $status->{'payload'} );
ok( $status->{'payload'}->{'shid'} );
#ok( $status->{'payload'}->{'schedule'} );

note( $note = 'create testing employee \'inactive\' with \'inactive\' privlevel' );
$log->info( "=== $note" );
my $eid_inactive = create_inactive_employee( $test );

note( $note = 'create testing employee \'bubba\' with \'active\' privlevel' );
$log->info( "=== $note" );
my $eid_bubba = create_bare_employee( { nick => 'bubba', password => 'bubba' } )->eid;
$status = req( $test, 201, 'root', 'POST', 'priv/history/nick/bubba', <<"EOH" );
{ "eid" : $eid_bubba, "priv" : "active", "effective" : "1967-06-17 00:00" }
EOH
is( $status->level, "OK" );
is( $status->code, "DOCHAZKA_CUD_OK" );
$status = req( $test, 200, 'root', 'GET', 'priv/nick/bubba' );
is( $status->level, "OK" );
is( $status->code, "DISPATCH_EMPLOYEE_PRIV" );
ok( $status->{'payload'} );
is( $status->{'payload'}->{'priv'}, 'active' );

note( $note = 'create a testing interval' );
$log->info( "=== $note" );
my $int = create_testing_interval(
    eid => $eid_of_active,
    aid => $aid_of_work,
    intvl => "[2014-10-01 08:00, 2014-10-01 12:00)",
);

note( $note = "test _extract_employee_spec method" );
$log->info( "=== $note" );
note( $note = "test _extract_activity_spec method" );
$log->info( "=== $note" );
note( $note = "test _extract_date_list_or_tsrange method" );
$log->info( "=== $note" );
foreach $resource ( 'interval/fillup', 'interval/scheduled' ) {
    $status = req( $test, 400, 'active', 'POST', $resource, <<"EOH" );
    { "eid" : $eid_of_active }
EOH
    is( $status->level, "ERR" );
    is( $status->code, 'DISPATCH_DATE_LIST_OR_TSRANGE' );
}

note( $note = "test some malformed tsranges" );
$log->info( "=== $note" );
my @failing_tsranges = (
    '[]',
    '{asf}',
    '[2014-01-01: 2015-01-01)',
    'wamble wumble womble',
);
foreach my $tsrange ( @failing_tsranges ) {
    foreach $resource ( 'interval/fillup', 'interval/scheduled' ) {
        $status = req( $test, 500, 'active', 'POST', $resource, <<"EOH" );
        { "eid" : $eid_of_active, "tsrange" : "$tsrange" }
EOH
        is( $status->level, "ERR" );
        like( $status->text, qr/malformed range literal/ );
    }
}

note( $note = "The testing schedule has intervals on Fri, Sat, and Sun" );
$log->info( "=== $note" );
note( $note = "Run fillup over a Thu-Mon tsrange" );
$log->info( "=== $note" );
foreach $resource ( 'interval/fillup', 'interval/scheduled' ) {
    $status = req( $test, 200, 'active', 'POST', $resource, <<"EOH" );
    { "eid" : $eid_of_active, "tsrange" : "[ 2014-09-04 00:00, 2014-09-08 24:00 )" }
EOH
    is( ref( $status->payload ), 'HASH' );
    is( $status->{'count'}, 6 );
    ok( exists( $status->payload->{'success'} ) );
    ok( exists( $status->payload->{'success'}->{'count'} ) );
    is( $status->payload->{'success'}->{'count'}, 6 );
    ok( exists( $status->payload->{'failure'} ) );
    ok( exists( $status->payload->{'failure'}->{'count'} ) );
    is( $status->payload->{'failure'}->{'count'}, 0 );
}

note( $note = "Run fillup over a Thu-Mon tsrange where Sat, Sun are holidays" );
$log->info( "=== $note" );
foreach $resource ( 'interval/fillup', 'interval/scheduled' ) {
    $status = req( $test, 200, 'active', 'POST', $resource, <<"EOH" );
    { "eid" : $eid_of_active, "tsrange" : "[ 1960-12-22 00:00, 1960-12-26 24:00 )" }
EOH
    is( ref( $status->payload ), 'HASH' );
    is( $status->{'count'}, 2 );
    ok( exists( $status->payload->{'success'} ) );
    ok( exists( $status->payload->{'success'}->{'count'} ) );
    is( $status->payload->{'success'}->{'count'}, 2 );
    ok( exists( $status->payload->{'failure'} ) );
    ok( exists( $status->payload->{'failure'}->{'count'} ) );
    is( $status->payload->{'failure'}->{'count'}, 0 );
}

note( $note = "Fillup with date list; intervals on 1960-12-23 will be skipped" );
$log->info( "=== $note" );
$status = req( $test, 200, 'active', 'POST', 'interval/fillup', <<"EOH" );
{ "eid" : $eid_of_active, "date_list" : [ "1960-12-22", "1960-12-23", "1960-12-27", "1960-12-30" ] }
EOH
is( ref( $status->payload ), 'HASH' );
is( $status->{'count'}, 2 );
ok( exists( $status->payload->{'success'} ) );
ok( exists( $status->payload->{'success'}->{'count'} ) );
is( $status->payload->{'success'}->{'count'}, 2 );
ok( exists( $status->payload->{'failure'} ) );
ok( exists( $status->payload->{'failure'}->{'count'} ) );
is( $status->payload->{'failure'}->{'count'}, 0 );

note( $note = "Scheduled with date list" );
$log->info( "=== $note" );
$status = req( $test, 200, 'active', 'POST', 'interval/scheduled', <<"EOH" );
{ "eid" : $eid_of_active, "date_list" : [ "1960-12-22", "1960-12-23", "1960-12-27", "1960-12-30" ] }
EOH
is( ref( $status->payload ), 'HASH' );
is( $status->{'count'}, 4 );
ok( exists( $status->payload->{'success'} ) );
ok( exists( $status->payload->{'success'}->{'count'} ) );
is( $status->payload->{'success'}->{'count'}, 4 );
ok( exists( $status->payload->{'failure'} ) );
ok( exists( $status->payload->{'failure'}->{'count'} ) );
is( $status->payload->{'failure'}->{'count'}, 0 );

note( $note = "Fillup with a date list that results in no intervals created" );
$log->info( "=== $note" );
foreach $resource ( 'interval/fillup', 'interval/scheduled' ) {
    $status = req( $test, 200, 'active', 'POST', $resource, <<"EOH" );
    { "eid" : $eid_of_active, "date_list" : [ 
        "2016-01-05",
        "2016-01-06"
    ] }
EOH
    is( $status->level, 'OK' );
    is( $status->code, 'DISPATCH_NO_SCHEDULED_INTERVALS_CREATED' );
    is( $status->{'count'}, 0 );
}

note( 'tear down' );
$status = delete_all_attendance_data();
BAIL_OUT(0) unless $status->ok;

done_testing;
