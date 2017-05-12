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
# basic unit tests for schedules and schedule intervals
#

#!perl
use 5.012;
use strict;
use warnings;

#use App::CELL::Test::LogToFile;
use App::CELL qw( $meta $site );
use Data::Dumper;
use App::Dochazka::Common qw( $today $yesterday $tomorrow );
use App::Dochazka::REST::ConnBank qw( $dbix_conn );
use App::Dochazka::REST::Model::Employee;
use App::Dochazka::REST::Model::Schedule qw( sid_exists );
use App::Dochazka::REST::Model::Schedhistory;
use App::Dochazka::REST::Model::Schedintvls;
use App::Dochazka::REST::Model::Shared qw( noof );
use App::Dochazka::REST::Test;
use Test::JSON;
use Test::More; 
use Test::Warnings;

note('initialize');
initialize_regression_test();

my $today_ts = $today . " 00:00:00";

note('spawn and insert employee object');
is( noof( $dbix_conn, "employees" ), 2 );

my $emp = App::Dochazka::REST::Model::Employee->spawn(
    nick => 'mrsched',
    remark => 'SCHEDULE TESTING OBJECT',
);
my $status = $emp->insert( $faux_context );
ok( $status->ok, "Schedule testing object inserted" );
ok( $emp->eid > 0, "Schedule testing object has an EID" );

my $schedule = test_schedule_model( [
    "[$tomorrow 12:30, $tomorrow 16:30)",
    "[$tomorrow 08:00, $tomorrow 12:00)",
    "[$today 12:30, $today 16:30)",
    "[$today 08:00, $today 12:00)",
    "[$yesterday 12:30, $yesterday 16:30)",
    "[$yesterday 08:00, $yesterday 12:00)",
] );

note('Attempt to change the "schedule" field to a bogus string');
my $saved_sched_obj = $schedule->clone;
$schedule->schedule( 'BOGUS STRING' );
is( $schedule->schedule, 'BOGUS STRING' );
$status = $schedule->update( $faux_context );
is( $status->level, 'OK' );
my $new_sched_obj = App::Dochazka::REST::Model::Schedule->spawn( $status->payload );
ok( $schedule->compare( $saved_sched_obj ) );
ok( $schedule->compare_disabled( $saved_sched_obj ) );

note('Attempt to change the "sid" field');
$saved_sched_obj = $schedule->clone;
#diag( Dumper $saved_sched_obj );
#BAIL_OUT(0);
$schedule->sid( 99943 );
is( $schedule->{sid}, 99943 );
$status = $schedule->update( $faux_context );
is( $status->level, 'OK' );
is( $status->{'DBI_return_value'}, '0E0' );
# but the value in the database is unchanged - the 'sid' and 'schedule' fields are never updated
$status = App::Dochazka::REST::Model::Schedule->load_by_sid( $dbix_conn, $saved_sched_obj->sid );
is( $status->level, 'OK' );
is( $status->payload->{sid}, $saved_sched_obj->sid ); # no real change
$schedule = $status->payload;
note('(in other words, nothing changed)');

note('Make a bogus schedintvls object and attempt to delete it');
my $bogus_intvls = App::Dochazka::REST::Model::Schedintvls->spawn;
$status = $bogus_intvls->delete( $dbix_conn );
is( $status->level, 'WARN', "Could not delete bogus intervals" );

note('Attempt to re-insert the same schedule');
my $sid_copy = $schedule->sid;        # store a local copy of the SID
my $sched_copy = $schedule->schedule; # store a local copy of the schedule (JSON)
$schedule->reset;		      # reset object to factory settings
$schedule->{schedule} = $sched_copy;  # set up object to "re-insert" the same schedule
is( $schedule->{sid}, undef, "SID is undefined at this point" );
$status = $schedule->insert( $faux_context );
if( $status->level ne 'OK' ) {
    diag( Dumper $status );
    diag( "Bailing out at MARK 01" );
    BAIL_OUT(0);
}
ok( $status->ok );
is( $schedule->{sid}, $sid_copy );    # SID is unchanged

note('attempt to insert the same schedule string in a completely new schedule object');
is( noof( $dbix_conn, 'schedules' ), 1, "schedules row count is 1" );
my $schedule2 = App::Dochazka::REST::Model::Schedule->spawn(
    schedule => $sched_copy,
    remark => 'DUPLICATE',
);
is_valid_json( $schedule2->schedule, "String is valid JSON" );
$status = $schedule2->insert( $faux_context );
ok( $schedule2->sid > 0, "SID was assigned" );
ok( $status->ok, "Schedule insert OK" );
is( $schedule2->sid, $sid_copy, "But SID is the same as before" );
is( noof( $dbix_conn, 'schedules' ), 1, "schedules row count is still 1" );

#note('tests for get_schedule_json function');
#my $json = get_schedule_json( $sid_copy );
#is( ref( $json ), 'ARRAY' );
#is( get_schedule_json( 994), undef, "Non-existent SID" );

note('Now that we finally have the schedule safely in the database, we can assign it to the employee (Mr. Sched) by inserting a record in the schedhistory table');
my $schedhistory = App::Dochazka::REST::Model::Schedhistory->spawn(
    eid => $emp->{eid},
    sid => $schedule->{sid},
    effective => $today,
    remark => 'TESTING',
);
isa_ok( $schedhistory, 'App::Dochazka::REST::Model::Schedhistory', "schedhistory object is an object" );

note('test schedhistory accessors');
is( $schedhistory->eid, $emp->{eid} );
is( $schedhistory->sid, $schedule->{sid} );
is( $schedhistory->effective, $today );
is( $schedhistory->remark, 'TESTING' );

$status = undef;
$status = $schedhistory->insert( $faux_context );
ok( $status->ok, "OK schedhistory insert OK" );
ok( defined( $schedhistory->shid), "schedhistory object has shid" );
ok( $schedhistory->shid > 0, "schedhistory object shid is > 0" );
is( $schedhistory->eid, $emp->{eid} );
is( $schedhistory->sid, $schedule->{sid} );
like( $schedhistory->effective, qr/$today_ts\+\d{2}/ );
is( $schedhistory->remark, 'TESTING' );
is( noof( $dbix_conn, 'schedhistory' ), 1 );

note('do a dastardly deed (insert the same schedhistory row a second time)');
my $dastardly_sh = App::Dochazka::REST::Model::Schedhistory->spawn(
    eid => $emp->{eid},
    sid => $schedule->{sid},
    effective => $today,
    remark => 'Dastardly',
);
isa_ok( $schedhistory, 'App::Dochazka::REST::Model::Schedhistory', "schedhistory object is an object" );
$status = undef;
$status = $dastardly_sh->insert( $faux_context );
is( $status->level, 'ERR', "OK schedhistory insert OK" );
is( $status->code, 'DOCHAZKA_DBI_ERR' );
like( $status->text, qr/duplicate key value violates unique constraint \"schedhistory_eid_effective_key\"/ );

note('and now Mr. Sched\'s employee object should contain the schedule');
$status = App::Dochazka::REST::Model::Employee->load_by_eid( $dbix_conn, $emp->{eid} );
is( $status->code, 'DISPATCH_RECORDS_FOUND' );

note('try to load the same schedhistory record into an empty object');
my $sh2 = App::Dochazka::REST::Model::Schedhistory->spawn;
isa_ok( $sh2, 'App::Dochazka::REST::Model::Schedhistory' );
$status = undef;
$status = $sh2->load_by_eid( $dbix_conn, $emp->eid ); # get the current record
ok( $status->ok );
is( $status->code, 'DISPATCH_RECORDS_FOUND' );
ok( ref $status->payload );
ok( $status->payload->isa( 'App::Dochazka::REST::Model::Schedhistory' ) );
$sh2->reset( $status->payload );
is( $sh2->shid, $schedhistory->shid );
is( $sh2->eid, $schedhistory->eid);
is( $sh2->sid, $schedhistory->sid);
is( $sh2->effective, $schedhistory->effective);
is( $sh2->remark, $schedhistory->remark);

note('Tomorrow this same schedhistory record will still be valid');
$sh2->reset;
$status = $sh2->load_by_eid( $dbix_conn, $emp->eid, $tomorrow );
ok( $status->ok );
is( $status->code, 'DISPATCH_RECORDS_FOUND' );
ok( ref $status->payload );
ok( $status->payload->isa( 'App::Dochazka::REST::Model::Schedhistory' ) );
$sh2->reset( $status->payload );
is( $sh2->shid, $schedhistory->shid );
my $shid_copy = $sh2->shid;
is( $sh2->eid, $schedhistory->eid);
is( $sh2->sid, $schedhistory->sid);
is( $sh2->effective, $schedhistory->effective);
is( $sh2->remark, $schedhistory->remark);

note('but it wasn\'t valid yesterday');
$sh2->reset;
$status = $sh2->load_by_eid( $dbix_conn, $emp->eid, $yesterday );
is( $status->level, 'NOTICE' );
is( $status->code, 'DISPATCH_NO_RECORDS_FOUND' );
is( $sh2->shid, undef );
is( $sh2->eid, undef );
is( $sh2->sid, undef );
is( $sh2->effective, undef );
is( $sh2->remark, undef );

note('CLEANUP:');
note('1. delete the schedhistory record');
is( noof( $dbix_conn, 'schedhistory' ), 1 );
$sh2->{shid} = $shid_copy;
$status = $sh2->delete( $faux_context );
diag( $status->text ) unless $status->ok;
ok( $status->ok );
is( noof( $dbix_conn, 'schedhistory' ), 0 );

note('2. delete the schedule');
is( noof( $dbix_conn, 'schedules' ), 1 );
ok( sid_exists( $dbix_conn, $sid_copy ) );
$status = $schedule->load_by_sid( $dbix_conn, $sid_copy );
is( $status->level, 'OK' );
is( $status->code, 'DISPATCH_RECORDS_FOUND' );
$schedule = $status->payload;
$status = $schedule->delete( $faux_context );
diag( $status->text ) unless $status->ok;
ok( $status->ok );
ok( ! sid_exists( $dbix_conn, $sid_copy ) );
is( noof( $dbix_conn, 'schedules' ), 0 );

note('3. delete the employee (Mr. Sched)');
is( noof( $dbix_conn, 'employees' ), 3, "number of employees == 3" );
$status = $emp->delete( $faux_context );
ok( $status->ok, "delete method returned ok status" );
is( noof( $dbix_conn, 'employees' ), 2, "number of employees == 2" );

note( 'tear down' );
$status = delete_all_attendance_data();
BAIL_OUT(0) unless $status->ok;

done_testing;
