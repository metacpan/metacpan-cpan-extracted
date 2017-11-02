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
# unit tests for fillup
#

#!perl
use 5.012;
use strict;
use warnings;

#use App::CELL::Test::LogToFile;
use App::CELL qw( $CELL $log $meta $site );
use Data::Dumper;
use App::Dochazka::REST::ConnBank qw( $dbix_conn );
use App::Dochazka::REST::Holiday qw(
    canon_to_ymd
    get_tomorrow
);
use App::Dochazka::REST::Model::Interval qw(
    delete_intervals_by_eid_and_tsrange
    fetch_intervals_by_eid_and_tsrange
);
use App::Dochazka::REST::Fillup;
use App::Dochazka::REST::Model::Tempintvl;
use App::Dochazka::REST::Model::Shared qw(
    noof
    schedule_by_eid
);
use App::Dochazka::REST::Model::Schedhistory;
use App::Dochazka::REST::Test;
use Test::More;
use Test::Fatal;

my ( $note, $status );

# given a Fillup object with populated context, reset it
# without clobbering the context
sub reset_obj {
    my $obj = shift;
    my $saved_context = $obj->context;
    $obj->reset;
    $obj->context( $saved_context );
    return;
}

note( $note = 'initialize, connect to database, and set up a testing plan' );
$log->info( "=== $note" );
initialize_regression_test();

note( $note = 'start with a clean slate' );
$log->info( "=== $note" );
$status = delete_all_attendance_data();
BAIL_OUT(0) unless $status->ok;

note( $note = 'tempintvls table should be empty' );
$log->info( "=== $note" );
if ( 0 != noof( $dbix_conn, 'tempintvls') ) {
    diag( "tempintvls table is not empty; bailing out!" );
    BAIL_OUT(0);
}

note( $note = 'make a testing fillup object' );
$log->info( "=== $note" );
my $fo = bless {}, 'App::Dochazka::REST::Fillup';

note( $note = 'test accessors on empty object' );
$log->info( "=== $note" );
{
    no strict 'refs';
    map {
        is( $fo->$_, undef, "$_ property is undef" );
    } keys %App::Dochazka::REST::Fillup::attr;
}

note( $note = 'populate() sets tiid property' );
$log->info( "=== $note" );
$fo->populate();
ok( $fo->tiid > 0 );

note( $note = 'accessors can be used to set values - non-pathological' );
$log->info( "=== $note" );
{
    my %attr_test = (
        act_obj => App::Dochazka::REST::Model::Activity->spawn,
        constructor_status => $CELL->status_ok,
        context => {},
        date_list => [],
        dry_run => 0,
        emp_obj => App::Dochazka::REST::Model::Employee->spawn,
        intervals => [],
        long_desc => '',
        remark => '',
        tiid => '',
        tsrange => {},
        tsranges => [],
    );
    map 
    {
        my $throwaway = $attr_test{ $_ };
        $fo->$_( $throwaway );
        is( $fo->$_, $throwaway );
    } keys %attr_test;
}

note( $note = 'further test inherited accessors pathological' );
$log->info( "=== $note" );
{
    my %attr_test = (
        act_obj => '',
        constructor_status => '',
        context => [],
        date_list => {},
        dry_run => [],
        emp_obj => '',
        intervals => {},
        long_desc => {},
        remark => {},
        tiid => {},
        tsrange => '',
        tsranges => '',
    );
    map 
    {
        my $throwaway = $attr_test{ $_ };
        like(
            exception { $fo->$_( $throwaway ) },
            qr/which is not one of the allowed types:/
        );
    } keys %attr_test;
}

note( $note = 'further test selected accessors non-pathological' );
$log->info( "=== $note" );

my $context = { 'heaven' => 'angel' };
$fo->context( $context  );
is( $fo->context, $context );

my $emp = App::Dochazka::REST::Model::Employee->spawn;
$fo->emp_obj( $emp );
is( $fo->emp_obj, $emp );

my $act = App::Dochazka::REST::Model::Activity->spawn;
$fo->act_obj( $act );
is( $fo->act_obj, $act );

my $dl = [ '2016-01-01', '2016-01-02', '2016-01-03' ];
$fo->date_list( $dl );
is( $fo->date_list, $dl );

$status = $CELL->status_ok( 'DOCHAZKA_ALL_GREEN' );
$fo->constructor_status( $status );
is( $fo->constructor_status, $status );

note( $note = 'further test selected accessors pathological' );
$log->info( "=== $note" );
like( 
    exception { $fo->constructor_status( App::Dochazka::REST::Model::Activity->spawn ) }, 
    qr/was not a.*it is a/
);
like( 
    exception { $fo->act_obj( $CELL->status_ok ) }, 
    qr/was not a.*it is a/
);
like( 
    exception { $fo->emp_obj( $CELL->status_ok ) }, 
    qr/was not a.*it is a/
);

note( $note = "vet empty context" );
$log->info( "=== $note" );
$status = $fo->_vet_context();
ok( $status->not_ok );

note( $note = "populate context attribute" );
$log->info( "=== $note" );
$status = $fo->_vet_context( context => $faux_context );
ok( $status->ok );

note( $note = "context should now be OK" );
$log->info( "=== $note" );
ok( $fo->context );
is( ref( $fo->context ), 'HASH' );
isa_ok( $fo->context->{dbix_conn}, 'DBIx::Connector' );

note( $note = 'quickly test canon_to_ymd' );
$log->info( "=== $note" );
my @ymd = canon_to_ymd( '2015-01-01' );
is( ref( \@ymd ), 'ARRAY' );
is( $ymd[0], '2015' );
is( $ymd[1], '01' );
is( $ymd[2], '01' );

note( $note = 'test the reset method' );
$log->info( "=== $note" );
my $saved_context = $fo->context;
$fo->reset;
my %test_attrs = %App::Dochazka::REST::Fillup::attr;
delete( $test_attrs{tiid} );
map { is( $fo->{ $_ }, undef ); } keys %test_attrs;
$fo->context( $saved_context );
is( $fo->context, $saved_context );

note( $note = 'test the _vet_date_spec method' );
$log->info( "=== $note" );
$status = $fo->_vet_date_spec(
    date_list => [ qw( 2016-01-01 2016-01-02 2016-01-03 ) ],
);
ok( $status->ok );
$status = $fo->_vet_date_spec(
    tsrange => 'bubba', # can be any scalar, not necessarily a valid tsrange
);
ok( $status->ok );
$status = $fo->_vet_date_spec(
    date_list => [ qw( 2016-01-01 2016-01-02 2016-01-03 ) ],
    tsrange => 'bubba', # can be any scalar, not necessarily a valid tsrange
);
ok( $status->not_ok );
$status = $fo->_vet_date_spec();
ok( $status->not_ok );
$status = $fo->_vet_date_spec(
    date_list => undef,
    tsrange => undef,
);
ok( $status->not_ok );
isnt( $fo->context, undef );

note( $note = 'vet some valid date lists' );
$log->info( "=== $note" );

note( $note = 'valid date list #1' );
$log->info( "=== $note" );
reset_obj( $fo );
is( $fo->date_list, undef );
is( $fo->tsrange, undef );
$dl = [ qw( 2016-01-01 2016-01-02 2016-01-03 ) ];
$status = $fo->_vet_date_list( date_list => $dl );
ok( $status->ok );
isnt( $fo->context, undef );
is_deeply( 
    $fo->date_list, 
    [ qw( 2016-01-01 2016-01-02 2016-01-03 ) ], 
    "date_list property initialized" 
);
is_deeply(
    $fo->tsrange,
    { tsrange => '["2016-01-01 00:00:00+01","2016-01-04 00:00:00+01")' }
);
is_deeply( 
    $fo->tsranges,
    [ 
        { tsrange => '["2016-01-01 00:00:00+01","2016-01-02 00:00:00+01")' }, 
        { tsrange => '["2016-01-02 00:00:00+01","2016-01-03 00:00:00+01")' }, 
        { tsrange => '["2016-01-03 00:00:00+01","2016-01-04 00:00:00+01")' }, 
    ], 
    "tsrange property initialized"
);

note( $note = 'valid date list #2' );
$log->info( "=== $note" );
reset_obj( $fo );
is( $fo->date_list, undef );
is( $fo->tsrange, undef );
$dl = [ qw( 1892-12-31 ) ];
$status = $fo->_vet_date_list( date_list => $dl );
ok( $status->ok );
is_deeply(
    $fo->date_list,
    [ qw( 1892-12-31 ) ],
    "date_list property initialized"
);
is_deeply(
    $fo->tsrange,
    { tsrange => '["1892-12-31 00:00:00+01","1893-01-01 00:00:00+01")' }
);
is_deeply(
    $fo->tsranges,
    [
        { tsrange => '["1892-12-31 00:00:00+01","1893-01-01 00:00:00+01")' },
    ],
    "tsrange property initialized"
);

note( $note = 'demonstrate how _vet_date_list does some limited canonicalizafon' );
$log->info( "=== $note" );
reset_obj( $fo );
is( $fo->date_list, undef );
is( $fo->tsrange, undef );
$dl = [ qw( 2016-1-1 ) ];
$status = $fo->_vet_date_list( date_list => $dl );
ok( $status->ok );
is_deeply( $fo->date_list, [ qw( 2016-01-01 ) ] );

note( $note = 'vet some invalid date lists' );
$log->info( "=== $note" );

note( $note = 'invalid date list #1 - empty list' );
$log->info( "=== $note" );
reset_obj( $fo );
is( $fo->date_list, undef );
is( $fo->tsrange, undef );
$dl = [];
$status = $fo->_vet_date_list( date_list => $dl );
is( $status->level, 'ERR' );
is( $status->code, 'DOCHAZKA_EMPTY_DATE_LIST' );

note( $note = 'invalid date list #2 - list consisting of one bogus value' );
$log->info( "=== $note" );
reset_obj( $fo );
$dl = [ 'bbub' ];
$status = $fo->_vet_date_list( date_list => $dl );
is( $status->level, 'ERR' );
is( $status->code, 'DOCHAZKA_INVALID_DATE_IN_DATE_LIST' );

note( $note = 'invalid date list #3 - list consisting of one bogus and one non-bogus value' );
$log->info( "=== $note" );
reset_obj( $fo );
$dl = [ '2016-01-01', 'bbub' ];
$status = $fo->_vet_date_list( date_list => $dl );
is( $status->level, 'ERR' );
is( $status->code, 'DOCHAZKA_INVALID_DATE_IN_DATE_LIST' );

note( $note = 'attempt to _vet_tsrange bogus tsranges individually' );
$log->info( "=== $note" );
reset_obj( $fo );
isnt( $fo->context, undef );
my $bogus = [
        "[)",
        "[,)",
        "[ ,)",
        "(2014-07-34 09:00, 2014-07-14 17:05)",
        "[2014-07-14 09:00, 2014-07-14 25:05]",
        "( 2014-07-34 09:00, 2014-07-14 17:05)",
        "[2014-07-14 09:00, 2014-07-14 25:05 ]",
	"[,2014-07-14 17:00)",
	"[ ,2014-07-14 17:00)",
        "[2014-07-14 17:15,)",
        "[2014-07-14 17:15, )",
        "[ infinity, infinity)",
	"[ infinity,2014-07-14 17:00)",
        "[2014-07-14 17:15,infinity)",
    ];
map {
        my $status = $fo->_vet_tsrange( tsrange => $_ );
        #diag( $status->level . ' ' . $status->text );
        is( $status->level, 'ERR', "$_ is a bogus tsrange" ); 
    } @$bogus;

note( $note = 'vet a too-long tsrange' );
$log->info( "=== $note" );
$status = $fo->_vet_tsrange( tsrange => '[ 2015-1-1, 2016-1-2 )' );
is( $status->level, 'ERR' );
is( $status->code, 'DOCHAZKA_FILLUP_TSRANGE_TOO_LONG' );

note( $note = 'vet a non-bogus tsrange' );
$log->info( "=== $note" );
$status = $fo->_vet_tsrange( tsrange => '[ "Jan 1, 2015", 2015-12-31 )' );
is( $status->level, 'OK' );
is( $status->code, 'SUCCESS' );
like( $fo->tsranges->[0]->{'tsrange'}, qr/^\["2015-01-01 00:00:00...","2015-12-31 00:00:00..."\)$/ );
is( $fo->tsranges->[0]->{'lower_canon'}, '2014-12-31' );
is( $fo->tsranges->[0]->{'upper_canon'}, '2016-01-01' );
is_deeply( $fo->tsranges->[0]->{'lower_ymd'}, [ 2014, 12, 31 ] );
is_deeply( $fo->tsranges->[0]->{'upper_ymd'}, [ 2016, 1, 1 ] );

note( $note = 'but not fully vetted yet' );
$log->info( "=== $note" );
ok( ! $fo->vetted );

note( $note = 'vet a non-bogus employee (no schedule)' );
$log->info( "=== $note" );
reset_obj( $fo );
$fo->_vet_date_list( date_list => [ '2016-01-01' ] );
$status = App::Dochazka::REST::Model::Employee->load_by_eid( $dbix_conn, 1 );
$status = $fo->_vet_employee( emp_obj => $status->payload );
is( $status->level, 'ERR' );
is( $status->code, 'DISPATCH_EMPLOYEE_NO_SCHEDULE' );

note( $note = 'if employee object lacks an eid property, die' );
$log->info( "=== $note" );
my $bogus_emp = App::Dochazka::REST::Model::Employee->spawn( nick => 'bogus');
like( 
    exception { $fo->_vet_employee( emp_obj => $bogus_emp ); },
    qr/AKLDWW###%AAAAAH!/,
);

note( $note = 'we do not try to vet non-existent employee objects here, because the Tempintvls' );
$log->info( "=== $note" );
note( $note = 'class is designed to be called from Dispatch.pm *after* the employee has been' );
$log->info( "=== $note" );
note( $note = 'determined to exist' );
$log->info( "=== $note" );

note( $note = 'create a testing employee with nick "active"' );
$log->info( "=== $note" );
my $active = create_bare_employee( { nick => 'active', password => 'active' } );
push my @eids_to_delete, $active->eid;

note( $note = 'vet active - no privhistory' );
$log->info( "=== $note" );
$status = $fo->_vet_employee( emp_obj => $active );
is( $status->level, 'ERR' );
is( $status->code, 'DISPATCH_EMPLOYEE_NO_PRIVHISTORY' );

note( $note = 'give active a privhistory' );
$log->info( "=== $note" );
my $ins_eid = $active->eid;
my $ins_priv = 'active';
my $ins_effective = "1892-01-01";
my $ins_remark = 'TESTING';
my $priv = App::Dochazka::REST::Model::Privhistory->spawn(
              eid => $ins_eid,
              priv => $ins_priv,
              effective => $ins_effective,
              remark => $ins_remark,
          );
is( $priv->phid, undef, "phid undefined before INSERT" );
$status = $priv->insert( $faux_context );
diag( Dumper $status->text ) if $status->not_ok;
ok( $status->ok, "Post-insert status ok" );
ok( $priv->phid > 0, "INSERT assigned an phid" );
is( $priv->remark, $ins_remark, "remark survived INSERT" );
push my @phids_to_delete, $priv->phid;

note( $note = 'vet active - no schedule' );
$log->info( "=== $note" );
$status = $fo->_vet_employee( emp_obj => $active );
is( $status->level, 'ERR' );
is( $status->code, 'DISPATCH_EMPLOYEE_NO_SCHEDULE' );

note( $note = 'create a testing schedule MON-FRI 08:00-12:00, 12:30-16:30' );
$log->info( "=== $note" );
my $schedule1 = test_schedule_model( [ 
    '[ 1998-05-04 08:00, 1998-05-04 12:00 )',
    '[ 1998-05-04 12:30, 1998-05-04 16:30 )',
    '[ 1998-05-05 08:00, 1998-05-05 12:00 )',
    '[ 1998-05-05 12:30, 1998-05-05 16:30 )',
    '[ 1998-05-06 08:00, 1998-05-06 12:00 )',
    '[ 1998-05-06 12:30, 1998-05-06 16:30 )',
    '[ 1998-05-07 08:00, 1998-05-07 12:00 )',
    '[ 1998-05-07 12:30, 1998-05-07 16:30 )',
    '[ 1998-05-08 08:00, 1998-05-08 12:00 )',
    '[ 1998-05-08 12:30, 1998-05-08 16:30 )',
] );
push my @sids_to_delete, $schedule1->sid;

note( $note = 'give active a schedhistory' );
$log->info( "=== $note" );
my $schedhistory = App::Dochazka::REST::Model::Schedhistory->spawn(
    eid => $active->eid,
    sid => $schedule1->sid,
    effective => "1892-01-01",
    remark => 'TESTING',
);
my $first_active_eid = $active->eid;
isa_ok( $schedhistory, 'App::Dochazka::REST::Model::Schedhistory', "schedhistory object is an object" );
$status = $schedhistory->insert( $faux_context );
is( $status->level, 'OK' );
is( $status->code, 'DOCHAZKA_CUD_OK' );
push my @shids_to_delete, $schedhistory->shid;
is( noof( $dbix_conn, "schedhistory" ), 1 );

note( $note = 'vet active - all green' );
$log->info( "=== $note" );
$status = $fo->_vet_employee( emp_obj => $active );
is( $status->level, "OK" );
is( $status->code, "SUCCESS" );
isa_ok( $fo->{'emp_obj'}, 'App::Dochazka::REST::Model::Employee' );
is( $fo->{'emp_obj'}->eid, $active->eid );
is( $fo->{'emp_obj'}->nick, 'active' );
my $active_obj = $fo->{'emp_obj'};

note( $note = 'but not fully vetted yet' );
$log->info( "=== $note" );
ok( ! $fo->vetted );

note( $note = 'get AID of WORK' );
$log->info( "=== $note" );
$status = App::Dochazka::REST::Model::Activity->load_by_code( $dbix_conn, 'WORK' );
is( $status->level, 'OK' );
is( $status->code, 'DISPATCH_RECORDS_FOUND' );
isa_ok( $status->payload, 'App::Dochazka::REST::Model::Activity' );
my $activity = $status->payload;
#diag( "AID of WORK: " . $activity->aid );

note( $note = 'vet activity (default)' );
$log->info( "=== $note" );
$status = $fo->_vet_activity;
is( $status->level, 'OK' );
is( $status->code, 'SUCCESS' );
isa_ok( $fo->{'act_obj'}, 'App::Dochazka::REST::Model::Activity' ); 
is( $fo->{'act_obj'}->code, 'WORK' );
is( $fo->{'act_obj'}->aid, $activity->aid );
is( $fo->{'aid'}, $activity->aid );

note( $note = 'vet non-existent activity 1' );
$log->info( "=== $note" );
$status = $fo->_vet_activity( aid => 'WORBLE' );
is( $status->level, 'ERR' );
is( $status->code, 'DOCHAZKA_DBI_ERR' );

note( $note = 'vet non-existent activity 2' );
$log->info( "=== $note" );
$status = $fo->_vet_activity( aid => '-1' );
is( $status->level, 'ERR' );
is( $status->code, 'DOCHAZKA_GENERIC_NOT_EXIST' );
is( $status->text, 'There is no activity with AID ->-1<-' );

$note = 'vet non-existent activity 3';
note( $note = $note );
$log->info( "=== $note" );
$log->info( "*** $note" );
$status = $fo->_vet_activity( aid => '0' );
is( $status->level, 'ERR' );
is( $status->code, 'DOCHAZKA_GENERIC_NOT_EXIST' );
is( $status->text, 'There is no activity with AID ->0<-' );

note( $note = 'vet activity WORK by explicit AID' );
$log->info( "=== $note" );
$status = $fo->_vet_activity( aid => $activity->aid );
is( $status->level, 'OK' );
is( $status->code, 'SUCCESS' );
isa_ok( $fo->{'act_obj'}, 'App::Dochazka::REST::Model::Activity' ); 
is( $fo->{'act_obj'}->code, 'WORK' );
is( $fo->{'act_obj'}->aid, $activity->aid );
is( $fo->{'aid'}, $activity->aid );

note( $note = 'vetted now true' );
$log->info( "=== $note" );
ok( $fo->vetted );

note( $note = 'change the tsrange' );
$log->info( "=== $note" );
$status = $fo->_vet_tsrange( tsrange => '[ "April 28, 1998" 10:00, 1998-05-6 10:00 )' );
is( $status->level, 'OK' );
is( $status->code, 'SUCCESS' );
like( $fo->tsrange->{'tsrange'}, qr/^\["1998-04-28 10:00:00...","1998-05-06 10:00:00..."\)/ );

note( $note = 'proceed with fillup' );
$log->info( "=== $note" );
is( $fo->intervals, undef );
$status = $fo->fillup_tempintvls;
is( $status->level, 'OK' );
is( $status->code, 'DOCHAZKA_TEMPINTVLS_INSERT_OK' );
is( ref( $fo->intervals ), 'ARRAY' );
my %should_be_intvls = (
    '["1998-04-27 08:00:00+02","1998-04-27 12:00:00+02")' => '',
    '["1998-04-27 12:30:00+02","1998-04-27 16:30:00+02")' => '',
    '["1998-04-28 08:00:00+02","1998-04-28 12:00:00+02")' => '',
    '["1998-04-28 12:30:00+02","1998-04-28 16:30:00+02")' => '',
    '["1998-04-29 08:00:00+02","1998-04-29 12:00:00+02")' => '',
    '["1998-04-29 12:30:00+02","1998-04-29 16:30:00+02")' => '',
    '["1998-04-30 08:00:00+02","1998-04-30 12:00:00+02")' => '',
    '["1998-04-30 12:30:00+02","1998-04-30 16:30:00+02")' => '',
    '["1998-05-04 08:00:00+02","1998-05-04 12:00:00+02")' => '',
    '["1998-05-04 12:30:00+02","1998-05-04 16:30:00+02")' => '',
    '["1998-05-05 08:00:00+02","1998-05-05 12:00:00+02")' => '',
    '["1998-05-05 12:30:00+02","1998-05-05 16:30:00+02")' => '',
    '["1998-05-06 08:00:00+02","1998-05-06 12:00:00+02")' => '',
    '["1998-05-06 12:30:00+02","1998-05-06 16:30:00+02")' => '',
    '["1998-05-07 08:00:00+02","1998-05-07 12:00:00+02")' => '',
    '["1998-05-07 12:30:00+02","1998-05-07 16:30:00+02")' => '',
);
map { delete $should_be_intvls{$_->intvl} if exists $should_be_intvls{$_->intvl}; }
    @{ $fo->intervals };
is( scalar( keys( %should_be_intvls ) ), 0 );

note( $note = 'commit (dry run)' );
$log->info( "=== $note" );
$fo->dry_run( 1 );
$status = $fo->commit;
is( $status->level, 'OK' );
is( $status->code, 'DISPATCH_SCHEDULED_INTERVALS_IDENTIFIED' );
is( $status->{count}, 11 );

note( $note = '1998-05-01 should not appear anywhere, as it is a holiday' );
$log->info( "=== $note" );
my $jumbled_together = join( '', @{ $status->payload->{"success"}->{"intervals"} } );
ok( ! ( $jumbled_together =~ m/1998-05-01/ ) );

note( $note = 'Check for more-or-less exact deep match' );
$log->info( "=== $note" );
my $intervals = $status->payload->{"success"}->{"intervals"};
like( $intervals->[0]->intvl, qr/^\["1998-04-28 10:00:00...","1998-04-28 12:00:00..."\)$/ );
like( $intervals->[1]->intvl, qr/^\["1998-04-28 12:30:00...","1998-04-28 16:30:00..."\)$/ );
like( $intervals->[2]->intvl, qr/^\["1998-04-29 08:00:00...","1998-04-29 12:00:00..."\)$/ );
like( $intervals->[3]->intvl, qr/^\["1998-04-29 12:30:00...","1998-04-29 16:30:00..."\)$/ );
like( $intervals->[4]->intvl, qr/^\["1998-04-30 08:00:00...","1998-04-30 12:00:00..."\)$/ );
like( $intervals->[5]->intvl, qr/^\["1998-04-30 12:30:00...","1998-04-30 16:30:00..."\)$/ );
like( $intervals->[6]->intvl, qr/^\["1998-05-04 08:00:00...","1998-05-04 12:00:00..."\)$/ );
like( $intervals->[7]->intvl, qr/^\["1998-05-04 12:30:00...","1998-05-04 16:30:00..."\)$/ );
like( $intervals->[8]->intvl, qr/^\["1998-05-05 08:00:00...","1998-05-05 12:00:00..."\)$/ );
like( $intervals->[9]->intvl, qr/^\["1998-05-05 12:30:00...","1998-05-05 16:30:00..."\)$/ );
like( $intervals->[10]->intvl, qr/^\["1998-05-06 08:00:00...","1998-05-06 10:00:00..."\)$/ );

note( $note = 'test the new() method' );
$log->info( "=== $note" );
my $fo2 = App::Dochazka::REST::Fillup->new(
    context => $faux_context,
    tsrange => '[ 1998-04-28 10:00:00, 1998-05-06 10:00:00 )',
    emp_obj => $active,
    dry_run => 1,
);
isa_ok( $fo2, 'App::Dochazka::REST::Fillup' );
is( $fo2->dry_run, 1 );
ok( $fo2->constructor_status );
isa_ok( $fo2->constructor_status, 'App::CELL::Status' );
is( $fo2->constructor_status->level, "OK" );
like( $fo2->tsrange->{'tsrange'}, qr/^\["1998-04-28 10:00:00...","1998-05-06 10:00:00..."\)$/ );

note( $note = 'commit (dry run) on two objects; one created without new() and the other with' );
$log->info( "=== $note" );
my $count = 11;
foreach my $obj ( $fo, $fo2 ) {
    $obj->dry_run( 1 );
    $status = $obj->commit;
    is( $status->level, 'OK' );
    is( $status->code, 'DISPATCH_SCHEDULED_INTERVALS_IDENTIFIED' );
    my $intervals = $status->payload->{"success"}->{"intervals"};
    like( $intervals->[0]->intvl, qr/^\["1998-04-28 10:00:00...","1998-04-28 12:00:00..."\)$/ );
    like( $intervals->[1]->intvl, qr/^\["1998-04-28 12:30:00...","1998-04-28 16:30:00..."\)$/ );
    like( $intervals->[2]->intvl, qr/^\["1998-04-29 08:00:00...","1998-04-29 12:00:00..."\)$/ );
    like( $intervals->[3]->intvl, qr/^\["1998-04-29 12:30:00...","1998-04-29 16:30:00..."\)$/ );
    like( $intervals->[4]->intvl, qr/^\["1998-04-30 08:00:00...","1998-04-30 12:00:00..."\)$/ );
    like( $intervals->[5]->intvl, qr/^\["1998-04-30 12:30:00...","1998-04-30 16:30:00..."\)$/ );
    like( $intervals->[6]->intvl, qr/^\["1998-05-04 08:00:00...","1998-05-04 12:00:00..."\)$/ );
    like( $intervals->[7]->intvl, qr/^\["1998-05-04 12:30:00...","1998-05-04 16:30:00..."\)$/ );
    like( $intervals->[8]->intvl, qr/^\["1998-05-05 08:00:00...","1998-05-05 12:00:00..."\)$/ );
    like( $intervals->[9]->intvl, qr/^\["1998-05-05 12:30:00...","1998-05-05 16:30:00..."\)$/ );
    like( $intervals->[10]->intvl, qr/^\["1998-05-06 08:00:00...","1998-05-06 10:00:00..."\)$/ );
    is( scalar( @{ $intervals } ), $count );
    is( $status->{'count'}, $count );
}

note( $note = 'really commit the attendance intervals' );
$log->info( "=== $note" );
is( noof( $dbix_conn, 'intervals' ), 0 );
$fo2->dry_run( 0 );
$status = $fo2->commit;
is( $status->level, 'OK' );
is( $status->code, 'DISPATCH_SCHEDULED_INTERVALS_CREATED' );
is( $status->{count}, $count );
is( $status->payload->{'success'}->{count}, $count );
is( noof( $dbix_conn, 'intervals' ), $count );

note( $note = 'create a conflicting attendance interval #1' );
$log->info( "=== $note" );
my $conflicting_int = App::Dochazka::REST::Model::Interval->spawn(
    eid => $active->eid,
    aid => $activity->aid,
    intvl => "[ 1998-5-11 9:00, 1998-5-11 9:15 )",
);
$status = $conflicting_int->insert( $faux_context );
is( $status->level, 'OK' );
is( $status->code, 'DOCHAZKA_CUD_OK' );

note( $note = 'fillup_tempintvls to conflict #1' );
$log->info( "=== $note" );
$fo = App::Dochazka::REST::Fillup->new(
    context => $faux_context,
    tsrange => '[ 1998-05-09 00:00:00, 1998-05-15 24:00:00 )',
    emp_obj => $active,
    dry_run => 1,
);
isa_ok( $fo, 'App::Dochazka::REST::Fillup' );
ok( $fo->constructor_status );
isa_ok( $fo->constructor_status, 'App::CELL::Status' );
is( $fo->constructor_status->level, "OK" );
is( $fo->dry_run, 1 );
like( $fo->tsrange->{'tsrange'}, qr/^\["1998-05-09 00:00:00...","1998-05-16 00:00:00..."\)$/ );

note( $note = "commit fillup with conflict #1 - dry run" );
$log->info( "=== $note" );
$status = $fo->commit;
is( $status->level, 'OK' );
is( $status->code, 'DISPATCH_SCHEDULED_INTERVALS_IDENTIFIED' );
my $pl = $status->payload;
is( $pl->{'success'}->{count}, 11 );
is( $pl->{'failure'}->{count}, 0 );
my $success = $pl->{'success'}->{'intervals'};
like( $success->[0]->intvl, qr/^\["1998-05-11 08:00:00...","1998-05-11 09:00:00..."\)$/ );
like( $success->[1]->intvl, qr/^\["1998-05-11 09:15:00...","1998-05-11 12:00:00..."\)$/ );
like( $success->[2]->intvl, qr/^\["1998-05-11 12:30:00...","1998-05-11 16:30:00..."\)$/ );
like( $success->[3]->intvl, qr/^\["1998-05-12 08:00:00...","1998-05-12 12:00:00..."\)$/ );
like( $success->[4]->intvl, qr/^\["1998-05-12 12:30:00...","1998-05-12 16:30:00..."\)$/ );
like( $success->[5]->intvl, qr/^\["1998-05-13 08:00:00...","1998-05-13 12:00:00..."\)$/ );
like( $success->[6]->intvl, qr/^\["1998-05-13 12:30:00...","1998-05-13 16:30:00..."\)$/ );
like( $success->[7]->intvl, qr/^\["1998-05-14 08:00:00...","1998-05-14 12:00:00..."\)$/ );
like( $success->[8]->intvl, qr/^\["1998-05-14 12:30:00...","1998-05-14 16:30:00..."\)$/ );
like( $success->[9]->intvl, qr/^\["1998-05-15 08:00:00...","1998-05-15 12:00:00..."\)$/ );
like( $success->[10]->intvl, qr/^\["1998-05-15 12:30:00...","1998-05-15 16:30:00..."\)$/ );

note( $note = "commit fillup with conflict #1 - insert" );
$log->info( "=== $note" );
$fo->dry_run(0);
is( $fo->dry_run, 0 );
$status = $fo->commit;
is( $status->level, 'OK' );
is( $status->code, 'DISPATCH_SCHEDULED_INTERVALS_CREATED' );
my $pl = $status->payload;
is( $pl->{'success'}->{count}, 11 );
is( $pl->{'failure'}->{count}, 0 );
my $success = $pl->{'success'}->{'intervals'};
like( $success->[0]->intvl, qr/^\["1998-05-11 08:00:00...","1998-05-11 09:00:00..."\)$/ );
like( $success->[1]->intvl, qr/^\["1998-05-11 09:15:00...","1998-05-11 12:00:00..."\)$/ );
like( $success->[2]->intvl, qr/^\["1998-05-11 12:30:00...","1998-05-11 16:30:00..."\)$/ );
like( $success->[3]->intvl, qr/^\["1998-05-12 08:00:00...","1998-05-12 12:00:00..."\)$/ );
like( $success->[4]->intvl, qr/^\["1998-05-12 12:30:00...","1998-05-12 16:30:00..."\)$/ );
like( $success->[5]->intvl, qr/^\["1998-05-13 08:00:00...","1998-05-13 12:00:00..."\)$/ );
like( $success->[6]->intvl, qr/^\["1998-05-13 12:30:00...","1998-05-13 16:30:00..."\)$/ );
like( $success->[7]->intvl, qr/^\["1998-05-14 08:00:00...","1998-05-14 12:00:00..."\)$/ );
like( $success->[8]->intvl, qr/^\["1998-05-14 12:30:00...","1998-05-14 16:30:00..."\)$/ );
like( $success->[9]->intvl, qr/^\["1998-05-15 08:00:00...","1998-05-15 12:00:00..."\)$/ );
like( $success->[10]->intvl, qr/^\["1998-05-15 12:30:00...","1998-05-15 16:30:00..."\)$/ );

note( $note = "create fillup object with date_list instead of tsrange" );
$log->info( "=== $note" );
$fo = App::Dochazka::REST::Fillup->new(
    context => $faux_context,
    date_list => [ '1998-05-16', '1998-05-22', '1998-05-20' ],
    emp_obj => $active,
    dry_run => 0,
);
isa_ok( $fo, 'App::Dochazka::REST::Fillup' );
ok( $fo->constructor_status );
isa_ok( $fo->constructor_status, 'App::CELL::Status' );
is( $fo->constructor_status->level, "OK" );
is( $fo->dry_run, 0 );
like( $fo->tsrange->{'tsrange'}, qr/^\["1998-05-16 00:00:00...","1998-05-23 00:00:00..."\)$/ );

note( $note = "commit fillup on date_list" );
$log->info( "=== $note" );
$status = $fo->commit;
is( $status->level, 'OK' );
is( $status->code, 'DISPATCH_SCHEDULED_INTERVALS_CREATED' );
#diag( "success count: " . $status->payload->{'success'}->{count} );
#diag( "failure count: " . $status->payload->{'failure'}->{count} );
my $success_hash = $status->payload->{'success'};
is( $success_hash->{count}, 4 );
# 1998-05-16 is a weekend, so it will be silently ignored
like( $success_hash->{intervals}->[0]->intvl, 
    qr/\["1998-05-20 08:00:00...","1998-05-20 12:00:00..."\)/ );
like( $success_hash->{intervals}->[1]->intvl, 
    qr/\["1998-05-20 12:30:00...","1998-05-20 16:30:00..."\)/ );
like( $success_hash->{intervals}->[2]->intvl, 
    qr/\["1998-05-22 08:00:00...","1998-05-22 12:00:00..."\)/ );
like( $success_hash->{intervals}->[3]->intvl, 
    qr/\["1998-05-22 12:30:00...","1998-05-22 16:30:00..."\)/ );
is( $status->payload->{'failure'}->{count}, 0 );

note( $note = 'fillup on a very short tsrange #1' );
$log->info( "=== $note" );
my $fo3 = App::Dochazka::REST::Fillup->new(
    context => $faux_context,
    tsrange => '[ 1998-06-01 10:00:00, 1998-06-01 10:30:00 )',
    emp_obj => $active,
    dry_run => 0,
);
isa_ok( $fo3, 'App::Dochazka::REST::Fillup' );
is( $fo3->dry_run, 0 );
ok( $fo3->constructor_status );
isa_ok( $fo3->constructor_status, 'App::CELL::Status' );
is( $fo3->constructor_status->level, "OK" );
like( $fo3->tsrange->{'tsrange'}, qr/^\["1998-06-01 10:00:00...","1998-06-01 10:30:00..."\)$/ );

note( $note = 'fillup commit very short tsrange #1' );
$log->info( "=== $note" );
$status = $fo3->commit;
is( $status->level, 'OK' );
is( $status->code, 'DISPATCH_SCHEDULED_INTERVALS_CREATED' );
$success_hash = $status->payload->{'success'};
is( $success_hash->{count}, 1 );
like( $success_hash->{intervals}->[0]->intvl, 
    qr/\["1998-06-01 10:00:00...","1998-06-01 10:30:00..."\)/ );
is( $status->payload->{'failure'}->{count}, 0 );

note( $note = 'fillup on a very short tsrange #2' );
$log->info( "=== $note" );
$fo3 = App::Dochazka::REST::Fillup->new(
    context => $faux_context,
    tsrange => '[ 1998-06-01 12:00:00, 1998-06-01 13:00:00 )',
    emp_obj => $active,
    dry_run => 0,
);
isa_ok( $fo3, 'App::Dochazka::REST::Fillup' );
is( $fo3->dry_run, 0 );
ok( $fo3->constructor_status );
isa_ok( $fo3->constructor_status, 'App::CELL::Status' );
is( $fo3->constructor_status->level, "OK" );
like( $fo3->tsrange->{'tsrange'}, qr/^\["1998-06-01 12:00:00...","1998-06-01 13:00:00..."\)$/ );

note( $note = 'fillup commit very short tsrange' );
$log->info( "=== $note" );
$status = $fo3->commit;
is( $status->level, 'OK' );
is( $status->code, 'DISPATCH_SCHEDULED_INTERVALS_CREATED' );
$success_hash = $status->payload->{'success'};
is( $success_hash->{count}, 1 );
like( $success_hash->{intervals}->[0]->intvl, 
    qr/\["1998-06-01 12:30:00...","1998-06-01 13:00:00..."\)/ );
is( $status->payload->{'failure'}->{count}, 0 );

note( $note = 'generate an excessively long date_list' );
$log->info( "=== $note" );
my $excessive_dl = [ '2017-01-01' ];
my $excessive_len = $site->DOCHAZKA_INTERVAL_FILLUP_MAX_DATELIST_ENTRIES + 1;
$count = 1;
my $loop_date = $excessive_dl->[0];
do {
    $loop_date = get_tomorrow( $loop_date );
    $excessive_dl->[$count] = $loop_date;
    $count += 1;
} while $count < $excessive_len;
is( scalar( @$excessive_dl ), $excessive_len );

note( $note = 'attempt to fillup_tempintvls with excessively long date_list' );
$log->info( "=== $note" );
$fo = App::Dochazka::REST::Fillup->new(
    context => $faux_context,
    date_list => $excessive_dl,
    emp_obj => $active,
    dry_run => 0,
);
isa_ok( $fo, 'App::Dochazka::REST::Fillup' );
ok( $fo->constructor_status );
isa_ok( $fo->constructor_status, 'App::CELL::Status' );
is( $fo->constructor_status->level, 'ERR' );
is( $fo->constructor_status->code, 'DOCHAZKA_INTERVAL_FILLUP_DATELIST_TOO_LONG' );

note( $note = "Create Fillup object \"fo4\" with a two-day tsrange" );
$log->info( "=== $note" );
my $fo4 = App::Dochazka::REST::Fillup->new(
    context => $faux_context,
    tsrange => '[ 1998-06-08 10:00:00, 1998-06-10 10:00:00 )',
    emp_obj => $active,
    clobber => 1,
    dry_run => 1,
);
isa_ok( $fo4, 'App::Dochazka::REST::Fillup' );
is( $fo4->dry_run, 1 );
ok( $fo4->constructor_status );
isa_ok( $fo4->constructor_status, 'App::CELL::Status' );
is( $fo4->constructor_status->level, "OK" );
like( $fo4->tsrange->{'tsrange'}, qr/^\["1998-06-08 10:00:00...","1998-06-10 10:00:00..."\)$/ );

note( $note = "Commit \$fo4 (dry_run, clobber)" );
$log->info( "=== $note" );
$status = $fo4->commit;
is( $status->level, 'OK' );
is( $status->code, 'DISPATCH_SCHEDULED_INTERVALS_IDENTIFIED' );

note( $note = "Commit \$fo4 (dry_run, clobber) returned intervals as expected" );
$log->info( "=== $note" );
$intervals = $status->payload->{"success"}->{"intervals"};
is(scalar @$intervals, 5 );
like( $intervals->[0]->intvl, qr/^\["1998-06-08 10:00:00...","1998-06-08 12:00:00..."\)$/ );
like( $intervals->[1]->intvl, qr/^\["1998-06-08 12:30:00...","1998-06-08 16:30:00..."\)$/ );
like( $intervals->[2]->intvl, qr/^\["1998-06-09 08:00:00...","1998-06-09 12:00:00..."\)$/ );
like( $intervals->[3]->intvl, qr/^\["1998-06-09 12:30:00...","1998-06-09 16:30:00..."\)$/ );
like( $intervals->[4]->intvl, qr/^\["1998-06-10 08:00:00...","1998-06-10 10:00:00..."\)$/ );

note( $note = "Introduce an attendance interval that conflicts with \$fo4" );
$log->info( "=== $note" );
$conflicting_int = App::Dochazka::REST::Model::Interval->spawn(
    eid => $active->eid,
    aid => $activity->aid,
    intvl => "[ 1998-6-9 14:00, 1998-6-9 14:15 )",
);
$status = $conflicting_int->insert( $faux_context );
is( $status->level, 'OK' );
is( $status->code, 'DOCHAZKA_CUD_OK' );

note( $note = "Commit \$fo4 (dry_run, clobber), take two" );
$log->info( "=== $note" );
$status = $fo4->commit;
is( $status->level, 'OK' );
is( $status->code, 'DISPATCH_SCHEDULED_INTERVALS_IDENTIFIED' );

note( $note = "Commit \$fo4 (dry_run, clobber), take two, returned the same intervals as before - conflict is ignored" );
$log->info( "=== $note" );
$intervals = $status->payload->{"success"}->{"intervals"};
is(scalar @$intervals, 5 );
like( $intervals->[0]->intvl, qr/^\["1998-06-08 10:00:00...","1998-06-08 12:00:00..."\)$/ );
like( $intervals->[1]->intvl, qr/^\["1998-06-08 12:30:00...","1998-06-08 16:30:00..."\)$/ );
like( $intervals->[2]->intvl, qr/^\["1998-06-09 08:00:00...","1998-06-09 12:00:00..."\)$/ );
like( $intervals->[3]->intvl, qr/^\["1998-06-09 12:30:00...","1998-06-09 16:30:00..."\)$/ );
like( $intervals->[4]->intvl, qr/^\["1998-06-10 08:00:00...","1998-06-10 10:00:00..."\)$/ );

note( $note = "Commit \$fo4 (dry_run, no clobber)" );
$log->info( "=== $note" );
$fo4->clobber(0);
$status = $fo4->commit;
is( $status->level, 'OK' );
is( $status->code, 'DISPATCH_SCHEDULED_INTERVALS_IDENTIFIED' );

note( $note = "Commit \$fo4 (dry_run, no clobber) returned the intervals as expected - i.e., 100% schedule fulfillment is achieved" );
$log->info( "=== $note" );
$intervals = $status->payload->{"success"}->{"intervals"};
is(scalar @$intervals, 6 );
like( $intervals->[0]->intvl, qr/^\["1998-06-08 10:00:00...","1998-06-08 12:00:00..."\)$/ );
like( $intervals->[1]->intvl, qr/^\["1998-06-08 12:30:00...","1998-06-08 16:30:00..."\)$/ );
like( $intervals->[2]->intvl, qr/^\["1998-06-09 08:00:00...","1998-06-09 12:00:00..."\)$/ );
like( $intervals->[3]->intvl, qr/^\["1998-06-09 12:30:00...","1998-06-09 14:00:00..."\)$/ );
like( $intervals->[4]->intvl, qr/^\["1998-06-09 14:15:00...","1998-06-09 16:30:00..."\)$/ );
like( $intervals->[5]->intvl, qr/^\["1998-06-10 08:00:00...","1998-06-10 10:00:00..."\)$/ );

note( $note = "Add an interval that almost conflicts, but not quite" );
$log->info( "=== $note" );
my $conflict1 = App::Dochazka::REST::Model::Interval->spawn(
    eid => $active->eid,
    aid => $activity->aid,
    intvl => "[ 1998-6-8 8:00, 1998-6-8 10:00 )",
);
$status = $conflict1->insert( $faux_context );
is( $status->level, 'OK' );
is( $status->code, 'DOCHAZKA_CUD_OK' );

note( $note = "Commit \$fo4 (dry_run, clobber), take three" );
$log->info( "=== $note" );
$fo4->clobber(1);
$status = $fo4->commit;
is( $status->level, 'OK' );
is( $status->code, 'DISPATCH_SCHEDULED_INTERVALS_IDENTIFIED' );

note( $note = "Commit \$fo4 (dry_run, clobber), take three, returned the same intervals as before - both potentially conflicting intervals are ignored" );
$log->info( "=== $note" );
$intervals = $status->payload->{"success"}->{"intervals"};
is(scalar @$intervals, 5 );
like( $intervals->[0]->intvl, qr/^\["1998-06-08 10:00:00...","1998-06-08 12:00:00..."\)$/ );
like( $intervals->[1]->intvl, qr/^\["1998-06-08 12:30:00...","1998-06-08 16:30:00..."\)$/ );
like( $intervals->[2]->intvl, qr/^\["1998-06-09 08:00:00...","1998-06-09 12:00:00..."\)$/ );
like( $intervals->[3]->intvl, qr/^\["1998-06-09 12:30:00...","1998-06-09 16:30:00..."\)$/ );
like( $intervals->[4]->intvl, qr/^\["1998-06-10 08:00:00...","1998-06-10 10:00:00..."\)$/ );

note( $note = "Commit \$fo4 (dry_run, no clobber)" );
$log->info( "=== $note" );
$fo4->clobber(0);
$status = $fo4->commit;
is( $status->level, 'OK' );
is( $status->code, 'DISPATCH_SCHEDULED_INTERVALS_IDENTIFIED' );

note( $note = "Commit \$fo4 (dry_run, no clobber) returned the intervals as expected - i.e., 100% schedule fulfillment is achieved and the \"almost conflicting\" interval has no effect on the result" );
$log->info( "=== $note" );
$intervals = $status->payload->{"success"}->{"intervals"};
is(scalar @$intervals, 6 );
like( $intervals->[0]->intvl, qr/^\["1998-06-08 10:00:00...","1998-06-08 12:00:00..."\)$/ );
like( $intervals->[1]->intvl, qr/^\["1998-06-08 12:30:00...","1998-06-08 16:30:00..."\)$/ );
like( $intervals->[2]->intvl, qr/^\["1998-06-09 08:00:00...","1998-06-09 12:00:00..."\)$/ );
like( $intervals->[3]->intvl, qr/^\["1998-06-09 12:30:00...","1998-06-09 14:00:00..."\)$/ );
like( $intervals->[4]->intvl, qr/^\["1998-06-09 14:15:00...","1998-06-09 16:30:00..."\)$/ );
like( $intervals->[5]->intvl, qr/^\["1998-06-10 08:00:00...","1998-06-10 10:00:00..."\)$/ );

note( $note = "Add another interval that almost conflicts, but not quite" );
$log->info( "=== $note" );
my $conflict2 = App::Dochazka::REST::Model::Interval->spawn(
    eid => $active->eid,
    aid => $activity->aid,
    intvl => "[ 1998-6-10 10:00, 1998-6-10 12:00 )",
);
$status = $conflict2->insert( $faux_context );
is( $status->level, 'OK' );
is( $status->code, 'DOCHAZKA_CUD_OK' );

note( $note = "Commit \$fo4 (dry_run, clobber), take four" );
$log->info( "=== $note" );
$fo4->clobber(1);
$status = $fo4->commit;
is( $status->level, 'OK' );
is( $status->code, 'DISPATCH_SCHEDULED_INTERVALS_IDENTIFIED' );

note( $note = "Commit \$fo4 (dry_run, clobber), take four, returned the same intervals as before - all three potentially conflicting intervals are ignored" );
$log->info( "=== $note" );
$intervals = $status->payload->{"success"}->{"intervals"};
is(scalar @$intervals, 5 );
like( $intervals->[0]->intvl, qr/^\["1998-06-08 10:00:00...","1998-06-08 12:00:00..."\)$/ );
like( $intervals->[1]->intvl, qr/^\["1998-06-08 12:30:00...","1998-06-08 16:30:00..."\)$/ );
like( $intervals->[2]->intvl, qr/^\["1998-06-09 08:00:00...","1998-06-09 12:00:00..."\)$/ );
like( $intervals->[3]->intvl, qr/^\["1998-06-09 12:30:00...","1998-06-09 16:30:00..."\)$/ );
like( $intervals->[4]->intvl, qr/^\["1998-06-10 08:00:00...","1998-06-10 10:00:00..."\)$/ );

note( $note = "Commit \$fo4 (dry_run, no clobber)" );
$log->info( "=== $note" );
$fo4->clobber(0);
$status = $fo4->commit;
is( $status->level, 'OK' );
is( $status->code, 'DISPATCH_SCHEDULED_INTERVALS_IDENTIFIED' );

note( $note = "Commit \$fo4 (dry_run, no clobber) returned the intervals as expected - i.e., 100% schedule fulfillment is achieved and the \"almost conflicting\" intervals have no effect on the result" );
$log->info( "=== $note" );
$intervals = $status->payload->{"success"}->{"intervals"};
is(scalar @$intervals, 6 );
like( $intervals->[0]->intvl, qr/^\["1998-06-08 10:00:00...","1998-06-08 12:00:00..."\)$/ );
like( $intervals->[1]->intvl, qr/^\["1998-06-08 12:30:00...","1998-06-08 16:30:00..."\)$/ );
like( $intervals->[2]->intvl, qr/^\["1998-06-09 08:00:00...","1998-06-09 12:00:00..."\)$/ );
like( $intervals->[3]->intvl, qr/^\["1998-06-09 12:30:00...","1998-06-09 14:00:00..."\)$/ );
like( $intervals->[4]->intvl, qr/^\["1998-06-09 14:15:00...","1998-06-09 16:30:00..."\)$/ );
like( $intervals->[5]->intvl, qr/^\["1998-06-10 08:00:00...","1998-06-10 10:00:00..."\)$/ );

note( $note = "Delete both \"almost conflicting\" intervals" );
$log->info( "=== $note" );
$status = $conflict1->delete( $faux_context );
is( $status->level, 'OK' );
is( $status->code, 'DOCHAZKA_CUD_OK' );
$status = $conflict2->delete( $faux_context );
is( $status->level, 'OK' );
is( $status->code, 'DOCHAZKA_CUD_OK' );

note( $note = "Insert an interval that overlaps the beginning of the fillup tsrange" );
$log->info( "=== $note" );
my $conflict3 = App::Dochazka::REST::Model::Interval->spawn(
    eid => $active->eid,
    aid => $activity->aid,
    intvl => "[ 1998-6-8 9:55, 1998-6-8 10:05 )",
);
$status = $conflict3->insert( $faux_context );
is( $status->level, 'OK' );
is( $status->code, 'DOCHAZKA_CUD_OK' );

note( $note = "Commit \$fo4 (dry_run, clobber), take five" );
$log->info( "=== $note" );
$fo4->clobber(1);
$status = $fo4->commit;
is( $status->level, 'OK' );
is( $status->code, 'DISPATCH_SCHEDULED_INTERVALS_IDENTIFIED' );

note( $note = "Commit \$fo4 (dry_run, clobber), take five, returned the same intervals as always" );
$log->info( "=== $note" );
$intervals = $status->payload->{"success"}->{"intervals"};
is(scalar @$intervals, 5 );
like( $intervals->[0]->intvl, qr/^\["1998-06-08 10:00:00...","1998-06-08 12:00:00..."\)$/ );
like( $intervals->[1]->intvl, qr/^\["1998-06-08 12:30:00...","1998-06-08 16:30:00..."\)$/ );
like( $intervals->[2]->intvl, qr/^\["1998-06-09 08:00:00...","1998-06-09 12:00:00..."\)$/ );
like( $intervals->[3]->intvl, qr/^\["1998-06-09 12:30:00...","1998-06-09 16:30:00..."\)$/ );
like( $intervals->[4]->intvl, qr/^\["1998-06-10 08:00:00...","1998-06-10 10:00:00..."\)$/ );

note( $note = "Commit \$fo4 (dry_run, no clobber)" );
$log->info( "=== $note" );
$fo4->clobber(0);
$status = $fo4->commit;
is( $status->level, 'OK' );
is( $status->code, 'DISPATCH_SCHEDULED_INTERVALS_IDENTIFIED' );

note( $note = "Commit \$fo4 (dry_run, no clobber) returned the intervals as expected - i.e., the first interval starts at 10:05 instead of 10:00" );
$log->info( "=== $note" );
$intervals = $status->payload->{"success"}->{"intervals"};
is(scalar @$intervals, 6 );
like( $intervals->[0]->intvl, qr/^\["1998-06-08 10:05:00...","1998-06-08 12:00:00..."\)$/ );
like( $intervals->[1]->intvl, qr/^\["1998-06-08 12:30:00...","1998-06-08 16:30:00..."\)$/ );
like( $intervals->[2]->intvl, qr/^\["1998-06-09 08:00:00...","1998-06-09 12:00:00..."\)$/ );
like( $intervals->[3]->intvl, qr/^\["1998-06-09 12:30:00...","1998-06-09 14:00:00..."\)$/ );
like( $intervals->[4]->intvl, qr/^\["1998-06-09 14:15:00...","1998-06-09 16:30:00..."\)$/ );
like( $intervals->[5]->intvl, qr/^\["1998-06-10 08:00:00...","1998-06-10 10:00:00..."\)$/ );

note( $note = "Insert an interval that overlaps the end of the fillup tsrange" );
$log->info( "=== $note" );
my $conflict3 = App::Dochazka::REST::Model::Interval->spawn(
    eid => $active->eid,
    aid => $activity->aid,
    intvl => "[ 1998-6-10 9:55, 1998-6-10 10:05 )",
);
$status = $conflict3->insert( $faux_context );
is( $status->level, 'OK' );
is( $status->code, 'DOCHAZKA_CUD_OK' );

note( $note = "Commit \$fo4 (dry_run, clobber), take six" );
$log->info( "=== $note" );
$fo4->clobber(1);
$status = $fo4->commit;
is( $status->level, 'OK' );
is( $status->code, 'DISPATCH_SCHEDULED_INTERVALS_IDENTIFIED' );

note( $note = "Commit \$fo4 (dry_run, clobber), take six, returned the same intervals as always" );
$log->info( "=== $note" );
$intervals = $status->payload->{"success"}->{"intervals"};
is(scalar @$intervals, 5 );
like( $intervals->[0]->intvl, qr/^\["1998-06-08 10:00:00...","1998-06-08 12:00:00..."\)$/ );
like( $intervals->[1]->intvl, qr/^\["1998-06-08 12:30:00...","1998-06-08 16:30:00..."\)$/ );
like( $intervals->[2]->intvl, qr/^\["1998-06-09 08:00:00...","1998-06-09 12:00:00..."\)$/ );
like( $intervals->[3]->intvl, qr/^\["1998-06-09 12:30:00...","1998-06-09 16:30:00..."\)$/ );
like( $intervals->[4]->intvl, qr/^\["1998-06-10 08:00:00...","1998-06-10 10:00:00..."\)$/ );

note( $note = "Commit \$fo4 (dry_run, no clobber)" );
$log->info( "=== $note" );
$fo4->clobber(0);
$status = $fo4->commit;
is( $status->level, 'OK' );
is( $status->code, 'DISPATCH_SCHEDULED_INTERVALS_IDENTIFIED' );

note( $note = "Commit \$fo4 (dry_run, no clobber) returned the expected intervals - i.e., the last interval ends at 09:55 instead of 10:00" );
$log->info( "=== $note" );
$intervals = $status->payload->{"success"}->{"intervals"};
is(scalar @$intervals, 6 );
foreach my $i ( 0..5 ) {
    isa_ok( $intervals->[$i], 'App::Dochazka::REST::Model::Interval' );
    is( $intervals->[$i]->iid, undef );
}
like( $intervals->[0]->intvl, qr/^\["1998-06-08 10:05:00...","1998-06-08 12:00:00..."\)$/ );
like( $intervals->[1]->intvl, qr/^\["1998-06-08 12:30:00...","1998-06-08 16:30:00..."\)$/ );
like( $intervals->[2]->intvl, qr/^\["1998-06-09 08:00:00...","1998-06-09 12:00:00..."\)$/ );
like( $intervals->[3]->intvl, qr/^\["1998-06-09 12:30:00...","1998-06-09 14:00:00..."\)$/ );
like( $intervals->[4]->intvl, qr/^\["1998-06-09 14:15:00...","1998-06-09 16:30:00..."\)$/ );
like( $intervals->[5]->intvl, qr/^\["1998-06-10 08:00:00...","1998-06-10 09:55:00..."\)$/ );

note( $note = "GET interval/nick/active/[ \"1998-06-08 00:00\", \"1998-06-10 24:00\" )" );
my @ARGS = (
    $faux_context->{'dbix_conn'},
    $active->eid,
    "[ \"1998-06-08 00:00\", \"1998-06-10 24:00\" )",
);
$status = fetch_intervals_by_eid_and_tsrange( @ARGS );
$intervals = $status->payload;
is(scalar @$intervals, 3 );
isa_ok( $intervals->[0], 'App::Dochazka::REST::Model::Interval' );
ok( $intervals->[0]->iid > 0 );
like( $intervals->[0]->intvl, qr/^\["1998-06-08 09:55:00...","1998-06-08 10:05:00..."\)$/ );
isa_ok( $intervals->[1], 'App::Dochazka::REST::Model::Interval' );
ok( $intervals->[1]->iid > 0 );
like( $intervals->[1]->intvl, qr/^\["1998-06-09 14:00:00...","1998-06-09 14:15:00..."\)$/ );
isa_ok( $intervals->[2], 'App::Dochazka::REST::Model::Interval' );
ok( $intervals->[2]->iid > 0 );
like( $intervals->[2]->intvl, qr/^\["1998-06-10 09:55:00...","1998-06-10 10:05:00..."\)$/ );

note( $note = "Commit \$fo4 - really insert the records" );
$log->info( "=== $note" );
$fo4->dry_run(0);
$fo4->clobber(0);
$status = $fo4->commit;
is( $status->level, 'OK' );
is( $status->code, 'DISPATCH_SCHEDULED_INTERVALS_CREATED' );

note( $note = "Commit \$fo4 returned the expected intervals and they have iid populated" );
$log->info( "=== $note" );
$intervals = $status->payload->{"success"}->{"intervals"};
is(scalar @$intervals, 6 );
foreach my $i ( 0..5 ) {
    isa_ok( $intervals->[$i], 'App::Dochazka::REST::Model::Interval' );
    ok( $intervals->[$i]->iid > 0 );
}
like( $intervals->[0]->intvl, qr/^\["1998-06-08 10:05:00...","1998-06-08 12:00:00..."\)$/ );
like( $intervals->[1]->intvl, qr/^\["1998-06-08 12:30:00...","1998-06-08 16:30:00..."\)$/ );
like( $intervals->[2]->intvl, qr/^\["1998-06-09 08:00:00...","1998-06-09 12:00:00..."\)$/ );
like( $intervals->[3]->intvl, qr/^\["1998-06-09 12:30:00...","1998-06-09 14:00:00..."\)$/ );
like( $intervals->[4]->intvl, qr/^\["1998-06-09 14:15:00...","1998-06-09 16:30:00..."\)$/ );
like( $intervals->[5]->intvl, qr/^\["1998-06-10 08:00:00...","1998-06-10 09:55:00..."\)$/ );

note( $note = "GET interval/nick/active/[ \"1998-06-08 00:00\", \"1998-06-10 24:00\" )" );
my @ARGS = (
    $faux_context->{'dbix_conn'},
    $eids_to_delete[0],
    "[ \"1998-06-08 00:00\", \"1998-06-10 24:00\" )",
);
$status = fetch_intervals_by_eid_and_tsrange( @ARGS );
$intervals = $status->payload;
is(scalar @$intervals, 9 );
foreach my $i ( 0..8 ) {
    isa_ok( $intervals->[$i], 'App::Dochazka::REST::Model::Interval' );
    ok( $intervals->[$i]->iid > 0 );
}
like( $intervals->[0]->intvl, qr/^\["1998-06-08 09:55:00...","1998-06-08 10:05:00..."\)$/ );
like( $intervals->[1]->intvl, qr/^\["1998-06-08 10:05:00...","1998-06-08 12:00:00..."\)$/ );
like( $intervals->[2]->intvl, qr/^\["1998-06-08 12:30:00...","1998-06-08 16:30:00..."\)$/ );
like( $intervals->[3]->intvl, qr/^\["1998-06-09 08:00:00...","1998-06-09 12:00:00..."\)$/ );
like( $intervals->[4]->intvl, qr/^\["1998-06-09 12:30:00...","1998-06-09 14:00:00..."\)$/ );
like( $intervals->[5]->intvl, qr/^\["1998-06-09 14:00:00...","1998-06-09 14:15:00..."\)$/ );
like( $intervals->[6]->intvl, qr/^\["1998-06-09 14:15:00...","1998-06-09 16:30:00..."\)$/ );
like( $intervals->[7]->intvl, qr/^\["1998-06-10 08:00:00...","1998-06-10 09:55:00..."\)$/ );
like( $intervals->[8]->intvl, qr/^\["1998-06-10 09:55:00...","1998-06-10 10:05:00..."\)$/ );

note( $note = 'create a second testing schedule, exactly like the first except MON 08:00-12:00 is dropped' );
$log->info( "=== $note" );
my $schedule2 = test_schedule_model( [ 
    '[ 1998-05-04 12:30, 1998-05-04 16:30 )',
    '[ 1998-05-05 08:00, 1998-05-05 12:00 )',
    '[ 1998-05-05 12:30, 1998-05-05 16:30 )',
    '[ 1998-05-06 08:00, 1998-05-06 12:00 )',
    '[ 1998-05-06 12:30, 1998-05-06 16:30 )',
    '[ 1998-05-07 08:00, 1998-05-07 12:00 )',
    '[ 1998-05-07 12:30, 1998-05-07 16:30 )',
    '[ 1998-05-08 08:00, 1998-05-08 12:00 )',
    '[ 1998-05-08 12:30, 1998-05-08 16:30 )',
] );
push my @sids_to_delete, $schedule2->sid;

note( $note = "Put the second schedule in active\'s schedhistory, so we can test Fillup over a tsrange that has a schedule change in the middle of it" );
$log->info( "=== $note" );
my $second_active_eid = $active->eid;
is( $first_active_eid, $second_active_eid );
my $schedhistory2 = App::Dochazka::REST::Model::Schedhistory->spawn(
    eid => $active->eid,
    sid => $schedule2->sid,
    effective => "1998-06-15 00:00",
    remark => 'TESTING',
);
isa_ok( $schedhistory2, 'App::Dochazka::REST::Model::Schedhistory', "schedhistory object is an object" );
$status = $schedhistory2->insert( $faux_context );
is( $status->level, 'OK' );
is( $status->code, 'DOCHAZKA_CUD_OK' );
push my @shids_to_delete, $schedhistory2->shid;
is( noof( $dbix_conn, "schedhistory" ), 2 );

note( $note = "Get the prevailing schedule at \"1998-06-14 08:00:00\" and \"1998-06-15 08:00:00\" in order to assert there is a schedule change during the Fillup interval" );
$log->info( "=== $note" );
ok( $schedule1->sid > 0 );
ok( $schedule2->sid > 0 );
ok( $schedule1->sid != $schedule2->sid );
is( schedule_by_eid( $dbix_conn, $active->eid, "1998-06-14 08:00:00" ), $schedule1->sid );
#diag( "\$schedule1->sid == " . $schedule1->sid );
is( schedule_by_eid( $dbix_conn, $active->eid, "1998-06-15 08:00:00" ), $schedule2->sid );
#diag( "\$schedule2->sid == " . $schedule2->sid );
ok( ! $active->schedule_change_during_range( $dbix_conn, '[ 1900-06-14 00:00:00, 1900-06-16 24:00:00 )' ) );
ok( $active->schedule_change_during_range( $dbix_conn, '[ 1998-06-14 00:00:00, 1998-06-16 24:00:00 )' ) );
ok( $active->schedule_change_during_range( $dbix_conn, '[ 1998-06-14 23:55:00, 1998-06-15 00:05:00 )' ) );

note( $note = "Create Fillup object \"fo5\" with tsrange from SUN to TUE" );
$log->info( "=== $note" );
my $fo5 = App::Dochazka::REST::Fillup->new(
    context => $faux_context,
    tsrange => '[ 1998-06-14 00:00:00, 1998-06-16 24:00:00 )',
    emp_obj => $active,
    clobber => 1,
    dry_run => 1,
);
isa_ok( $fo5, 'App::Dochazka::REST::Fillup' );
ok( $fo5->constructor_status );
isa_ok( $fo5->constructor_status, 'App::CELL::Status' );
#diag( Dumper $fo5->constructor_status );
is( $fo5->constructor_status->level, "ERR" );
is( $fo5->constructor_status->code, "DOCHAZKA_EMPLOYEE_SCHEDULE_CHANGED" );

note( $note = "Delete the conflicting schedule change" );
$log->info( "=== $note" );
$status = $schedhistory2->delete( $faux_context );
isa_ok( $status, 'App::CELL::Status' );
is( $status->level, 'OK' );
is( $status->code, 'DOCHAZKA_CUD_OK' );
is( noof( $dbix_conn, "schedhistory" ), 1 );

note( $note = "Create Fillup object \"fo5\" with tsrange from SUN to TUE - second try" );
$log->info( "=== $note" );
$fo5 = App::Dochazka::REST::Fillup->new(
    context => $faux_context,
    tsrange => '[ 1998-06-14 00:00:00, 1998-06-16 24:00:00 )',
    emp_obj => $active,
    clobber => 1,
    dry_run => 1,
);
isa_ok( $fo5, 'App::Dochazka::REST::Fillup' );
ok( $fo5->constructor_status );
isa_ok( $fo5->constructor_status, 'App::CELL::Status' );
is( $fo5->constructor_status->level, "OK" );
is( $fo5->constructor_status->code, "DOCHAZKA_TEMPINTVLS_INSERT_OK" );

note( $note = "Commit \$fo5 (dry_run, clobber)" );
$log->info( "=== $note" );
$status = $fo5->commit;

note( $note = "Commit \$fo5 (dry_run, clobber) returned intervals as expected" );
$log->info( "=== $note" );
$intervals = $status->payload->{"success"}->{"intervals"};
is(scalar @$intervals, 4 );
like( $intervals->[0]->intvl, qr/^\["1998-06-15 08:00:00...","1998-06-15 12:00:00..."\)$/ );
like( $intervals->[1]->intvl, qr/^\["1998-06-15 12:30:00...","1998-06-15 16:30:00..."\)$/ );
like( $intervals->[2]->intvl, qr/^\["1998-06-16 08:00:00...","1998-06-16 12:00:00..."\)$/ );
like( $intervals->[3]->intvl, qr/^\["1998-06-16 12:30:00...","1998-06-16 16:30:00..."\)$/ );

note( $note = 'tear down' );
$log->info( "=== $note" );
$status = delete_all_attendance_data();
BAIL_OUT(0) unless $status->ok;

done_testing;
