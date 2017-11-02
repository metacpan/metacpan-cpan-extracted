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
# test priv_during_range() and schedule_change_during_range() employee methods

#!perl
use 5.012;
use strict;
use warnings;

#use App::CELL::Test::LogToFile;
use App::CELL qw( $log $meta $site );
use Data::Dumper;
use App::Dochazka::REST::ConnBank qw( $dbix_conn );
use App::Dochazka::REST::Model::Employee qw( nick_exists eid_exists );
use App::Dochazka::REST::Model::Shared qw( noof );
use App::Dochazka::REST::Test;
use Plack::Test;
use Test::More;
use Test::Warnings;

my ( $note, $phobj, $range, $shobj, $status, $ts, $tsr );

note( $note = 'initialize, connect to database, and set up a testing plan' );
$log->info( "=== $note" );
my $app = initialize_regression_test();

note( $note = 'instantiate Plack::Test object' );
$log->info( "=== $note" );
my $test = Plack::Test->create( $app );

note( $note = 'get initial number of employees' );
$log->info( "=== $note" );
my $noof_employees = noof( $dbix_conn, 'employees' );

note( $note = 'root employee is created at dbinit time' );
$log->info( "=== $note" );
my $eid_of_root = $site->DOCHAZKA_EID_OF_ROOT;

note( $note = 'spawn \"mrfu\" Employee object' );
$log->info( "=== $note" );
my $emp = App::Dochazka::REST::Model::Employee->spawn( 
    nick => 'mrfu',
    fullname => 'Mr. Fu',
    email => 'mrfu@example.com',
    sec_id => 1024,
);
isa_ok( $emp, 'App::Dochazka::REST::Model::Employee' );

note( $note = 'insert mrfu' );
$log->info( "=== $note" );
$status = $emp->insert( $faux_context );
is( $status->level, 'OK', "Mr. Fu inserted" );
is( noof( $dbix_conn, 'employees' ), 3 );

note( $note = 're-load mrfu' );
$log->info( "=== $note" );
$status = $emp->load_by_nick( $dbix_conn, 'mrfu' );
is( $status->code, 'DISPATCH_RECORDS_FOUND', "mrfu re-load success" );
my $mrfu = $status->payload;
is( $mrfu->nick, 'mrfu' );
is( $mrfu->sec_id, 1024 );

note( $note = 'spawn \"mrsfu\" Employee object' );
$log->info( "=== $note" );
$emp = App::Dochazka::REST::Model::Employee->spawn( 
    nick => 'mrsfu',
    sec_id => 78923,
    email => 'consort@futown.orient.cn',
    fullname => 'Mrs. Fu',
);
isa_ok( $emp, 'App::Dochazka::REST::Model::Employee' );

note( $note = 'insert mrsfu' );
$log->info( "=== $note" );
$status = $emp->insert( $faux_context );
is( $status->level, "OK", "Mrs. Fu inserted" );

note( $note = 're-load mrsfu' );
$log->info( "=== $note" );
$status = $emp->load_by_nick( $dbix_conn, 'mrsfu' );
is( $status->code, 'DISPATCH_RECORDS_FOUND', "mrsfu re-load success" );
my $mrsfu = $status->payload;
is( $mrsfu->nick, 'mrsfu', "Mrs. Fu's nick is the right string" );
is( $mrsfu->sec_id, 78923, "Mrs. Fu's secondary ID is the right string" );


note( $note = '============================' );
$log->info( "=== $note" );
note( $note = 'priv_change_during_range with zero privhistory records' );
$log->info( "=== $note" );
note( $note = '============================' );
$log->info( "=== $note" );


note( $note = 'no priv change on empty priv history: 1' );
$log->info( "=== $note" );
$range = "( 1997-01-01, 1997-01-02 )";
is( $mrfu->priv_change_during_range( $dbix_conn, $range ), 0,
    "mrfu no priv change during $range" );

note( $note = 'no priv change on empty priv history: 2' );
$log->info( "=== $note" );
$range = "[ 1987-01-01, 2007-01-02 )";
is( $mrfu->priv_change_during_range( $dbix_conn, $range ), 0,
    "mrfu no priv change during $range" );

note( $note = 'no priv change on empty priv history: 3' );
$log->info( "=== $note" );
$range = "( 1997-01-01, 1997-01-02 )";
is( $mrsfu->priv_change_during_range( $dbix_conn, $range ), 0,
    "mrsfu no priv change during $range" );

note( $note = 'no priv change on empty priv history: 4' );
$log->info( "=== $note" );
$range = "[ 1987-01-01, 2007-01-02 )";
is( $mrsfu->priv_change_during_range( $dbix_conn, $range ), 0,
    "mrsfu no priv change during $range" );


note( $note = '============================' );
$log->info( "=== $note" );
note( $note = 'priv_change_during_range with single privhistory record' );
$log->info( "=== $note" );
note( $note = '============================' );
$log->info( "=== $note" );


note( $note = "make mrfu inactive as of 1995-01-01 00:00" );
$log->info( "=== $note" );
$status = req( $test, 201, 'root', 'POST', "priv/history/eid/" . $mrfu->eid, 
    '{ "effective":"1995-01-01 00:00", "priv":"inactive", "remark":"mrfu test 1995-01-01" }' );
ok( $status->ok );
is( $status->code, 'DOCHAZKA_CUD_OK', "mrfu privhistory record insert OK" );
my $phid_of_mrfu_01 = $status->payload->{'phid'};
ok( $phid_of_mrfu_01 > 0 );

note( $note = "make mrsfu active as of 1997-01-01 00:00" );
$log->info( "=== $note" );
$status = req( $test, 201, 'root', 'POST', "priv/history/eid/" . $mrsfu->eid, 
    '{ "effective":"1997-01-01 00:00", "priv":"active", "remark":"mrsfu test 1997-01-01" }' );
ok( $status->ok );
is( $status->code, 'DOCHAZKA_CUD_OK', "mrsfu privhistory record insert OK" );
my $phid_of_mrsfu = $status->payload->{'phid'};
ok( $phid_of_mrsfu > 0 );

note( $note = 'ranges that definitely have no priv change: 1' );
$log->info( "=== $note" );
$range = "( 1997-01-01, 1997-01-02 )";
is( $mrfu->priv_change_during_range( $dbix_conn, $range ), 0,
    "mrfu no priv change during $range" );

note( $note = 'ranges that definitely have no priv change: 2' );
$log->info( "=== $note" );
$range = "[ 1996-12-31, 1997-01-02 )";
is( $mrfu->priv_change_during_range( $dbix_conn, $range ), 0,
    "mrfu: no priv change during $range" );

note( $note = 'ranges that definitely have no priv change: 3' );
$log->info( "=== $note" );
$range = "( 1996-12-31, 1997-01-02 ]";
is( $mrfu->priv_change_during_range( $dbix_conn, $range ), 0,
    "mrfu: no priv change during $range" );

note( $note = 'ranges that definitely have no priv change: 4' );
$log->info( "=== $note" );
$range = "[ 1996-12-31, 1997-01-02 ]";
is( $mrfu->priv_change_during_range( $dbix_conn, $range ), 0,
    "mrfu: no priv change during $range" );

note( $note = 'ranges that definitely have a change: 1' );
$log->info( "=== $note" );
$range = "( 1994-12-1 00:00, 1995-1-31 00:00 )";
is( $mrfu->priv_change_during_range( $dbix_conn, $range ), 1,
    "mrfu has priv change during $range" );

note( $note = 'ranges that definitely have a change: 2' );
$log->info( "=== $note" );
$range = "[ 1994-12-1 00:00, 1995-1-31 00:00 )";
is( $mrfu->priv_change_during_range( $dbix_conn, $range ), 1,
    "mrfu has priv change during $range" );

note( $note = 'ranges that definitely have a change: 3' );
$log->info( "=== $note" );
$range = "( 1994-12-1 00:00, 1995-01-31 00:00 ]";
is( $mrfu->priv_change_during_range( $dbix_conn, $range ), 1,
    "mrfu has priv change during $range" );

note( $note = 'ranges that definitely have a change: 4' );
$log->info( "=== $note" );
$range = "[ 1994-12-1 00:00, 1995-01-31 00:00 ]";
is( $mrfu->priv_change_during_range( $dbix_conn, $range ), 1,
    "mrfu has priv change during $range" );

note( $note = 'borderline priv level change - negative 1' );
$log->info( "=== $note" );
$range = "[ 1995-01-01 00:00, 1995-01-01 00:01 )";
is( $mrfu->priv_change_during_range( $dbix_conn, $range ), 0,
    "mrfu: no priv change during borderline range $range" );

note( $note = 'borderline priv level change - negative 2' );
$log->info( "=== $note" );
$range = "[ 1994-12-31 24:00, 1995-01-01 00:01 )";
is( $mrfu->priv_change_during_range( $dbix_conn, $range ), 0,
    "mrfu: no priv change during borderline range $range" );

note( $note = 'borderline priv level change - negative 3' );
$log->info( "=== $note" );
$range = "[ 1995-01-01, 1995-01-01 ]";
is( $mrfu->priv_change_during_range( $dbix_conn, $range ), 0,
    "mrfu: no priv change during borderline range $range" );

note( $note = 'borderline priv level change - negative 4' );
$log->info( "=== $note" );
$range = "( 1994-12-31 23:59, 1994-12-31 24:00 ]";
is( $mrfu->priv_change_during_range( $dbix_conn, $range ), 0,
    "mrfu: no priv change during borderline range $range" );

note( $note = 'borderline priv level change - negative 5' );
$log->info( "=== $note" );
$range = "( 1995-01-01 00:00, 1995-01-02 ]";
is( $mrfu->priv_change_during_range( $dbix_conn, $range ), 0,
    "mrfu: no priv change during borderline range $range" );

note( $note = 'borderline priv level change - negative 6' );
$log->info( "=== $note" );
$range = "[ 1994-12-31 00:00, 1994-12-31 24:00 )";
is( $mrfu->priv_change_during_range( $dbix_conn, $range ), 0,
    "mrfu: no priv change during borderline range $range" );

note( $note = 'borderline priv level change - positive 1' );
$log->info( "=== $note" );
$range = "[ 1994-12-31 23:59, 1995-01-01 00:01 )";
is( $mrfu->priv_change_during_range( $dbix_conn, $range ), 1,
    "mrfu has priv change during borderline range $range" );

note( $note = 'borderline priv level change - positive 2' );
$log->info( "=== $note" );
$range = "( 1994-01-01, 1995-01-01 00:01 ]";
is( $mrfu->priv_change_during_range( $dbix_conn, $range ), 1,
    "mrfu has priv change during borderline range $range" );


note( $note = '============================' );
$log->info( "=== $note" );
note( $note = 'priv_change_during_range with two privhistory records' );
$log->info( "=== $note" );
note( $note = '============================' );
$log->info( "=== $note" );


note( $note = "make mrfu inactive as of 1995-01-02 00:00" );
$log->info( "=== $note" );
$status = req( $test, 201, 'root', 'POST', "priv/history/eid/" . $mrfu->eid, 
    '{ "effective":"1995-01-02 00:00", "priv":"inactive", "remark":"mrfu test 1995-01-02" }' );
ok( $status->ok );
is( $status->code, 'DOCHAZKA_CUD_OK', "mrfu privhistory record insert OK" );
my $phid_of_mrfu_02 = $status->payload->{'phid'};
ok( $phid_of_mrfu_02 > 0 );

note( $note = "make mrsfu active as of 1997-01-02 00:00" );
$log->info( "=== $note" );
$status = req( $test, 201, 'root', 'POST', "priv/history/eid/" . $mrsfu->eid, 
    '{ "effective":"1997-01-02 00:00", "priv":"active", "remark":"mrsfu test 1997-01-02" }' );
ok( $status->ok );
is( $status->code, 'DOCHAZKA_CUD_OK', "mrsfu privhistory record insert OK" );
my $phid_of_mrsfu_02 = $status->payload->{'phid'};
ok( $phid_of_mrsfu_02 > 0 );

note( $note = 'ranges that definitely have no priv change: 1' );
$log->info( "=== $note" );
$range = "( 1997-01-01, 1997-01-02 )";
is( $mrfu->priv_change_during_range( $dbix_conn, $range ), 0,
    "mrfu no priv change during $range" );

note( $note = 'ranges that definitely have no priv change: 2' );
$log->info( "=== $note" );
$range = "[ 1996-12-31, 1997-01-02 )";
is( $mrfu->priv_change_during_range( $dbix_conn, $range ), 0,
    "mrfu: no priv change during $range" );

note( $note = 'ranges that definitely have no priv change: 3' );
$log->info( "=== $note" );
$range = "( 1996-12-31, 1997-01-02 ]";
is( $mrfu->priv_change_during_range( $dbix_conn, $range ), 0,
    "mrfu: no priv change during $range" );

note( $note = 'ranges that definitely have no priv change: 4' );
$log->info( "=== $note" );
$range = "[ 1996-12-31, 1997-01-02 ]";
is( $mrfu->priv_change_during_range( $dbix_conn, $range ), 0,
    "mrfu: no priv change during $range" );

note( $note = 'ranges that definitely have a change: 1' );
$log->info( "=== $note" );
$range = "( 1994-12-1 00:00, 1995-1-31 00:00 )";
is( $mrfu->priv_change_during_range( $dbix_conn, $range ), 2,
    "mrfu has priv change during $range" );

note( $note = 'ranges that definitely have a change: 2' );
$log->info( "=== $note" );
$range = "[ 1994-12-1 00:00, 1995-1-31 00:00 )";
is( $mrfu->priv_change_during_range( $dbix_conn, $range ), 2,
    "mrfu has priv change during $range" );

note( $note = 'ranges that definitely have a change: 3' );
$log->info( "=== $note" );
$range = "( 1994-12-1 00:00, 1995-01-31 00:00 ]";
is( $mrfu->priv_change_during_range( $dbix_conn, $range ), 2,
    "mrfu has priv change during $range" );

note( $note = 'ranges that definitely have a change: 4' );
$log->info( "=== $note" );
$range = "[ 1994-12-1 00:00, 1995-01-31 00:00 ]";
is( $mrfu->priv_change_during_range( $dbix_conn, $range ), 2,
    "mrfu has priv change during $range" );

note( $note = 'borderline priv level change - negative 1' );
$log->info( "=== $note" );
$range = "[ 1995-01-01 00:00, 1995-01-01 00:01 )";
is( $mrfu->priv_change_during_range( $dbix_conn, $range ), 0,
    "mrfu: no priv change during borderline range $range" );

note( $note = 'borderline priv level change - negative 2' );
$log->info( "=== $note" );
$range = "[ 1994-12-31 24:00, 1995-01-01 00:01 )";
is( $mrfu->priv_change_during_range( $dbix_conn, $range ), 0,
    "mrfu: no priv change during borderline range $range" );

note( $note = 'borderline priv level change - negative 3' );
$log->info( "=== $note" );
$range = "[ 1995-01-01, 1995-01-01 ]";
is( $mrfu->priv_change_during_range( $dbix_conn, $range ), 0,
    "mrfu: no priv change during borderline range $range" );

note( $note = 'borderline priv level change - negative 4' );
$log->info( "=== $note" );
$range = "( 1994-12-31 23:59, 1994-12-31 24:00 ]";
is( $mrfu->priv_change_during_range( $dbix_conn, $range ), 0,
    "mrfu: no priv change during borderline range $range" );

note( $note = 'borderline priv level change - negative 5' );
$log->info( "=== $note" );
$range = "( 1995-01-02 00:00, 1995-01-02 24:00 ]";
is( $mrfu->priv_change_during_range( $dbix_conn, $range ), 0,
    "mrfu: no priv change during borderline range $range" );

note( $note = 'borderline priv level change - negative 6' );
$log->info( "=== $note" );
$range = "[ 1994-12-31 00:00, 1994-12-31 24:00 )";
is( $mrfu->priv_change_during_range( $dbix_conn, $range ), 0,
    "mrfu: no priv change during borderline range $range" );

note( $note = 'borderline priv level change - negative 7' );
$log->info( "=== $note" );
$range = "( 1995-01-02, 1995-01-02 00:01 ]";
is( $mrfu->priv_change_during_range( $dbix_conn, $range ), 0,
    "mrfu has priv change during borderline range $range" );

note( $note = 'borderline priv level change - positive 1' );
$log->info( "=== $note" );
$range = "[ 1994-12-31 23:59, 1995-01-01 00:01 )";
is( $mrfu->priv_change_during_range( $dbix_conn, $range ), 1,
    "mrfu has priv change during borderline range $range" );

note( $note = 'borderline priv level change - positive 2' );
$log->info( "=== $note" );
$range = "[ 1995-1-1 23:59, 1995-01-02 00:01 )";
is( $mrfu->priv_change_during_range( $dbix_conn, $range ), 1,
    "mrfu has priv change during borderline range $range" );

note( $note = 'borderline priv level change - positive 3' );
$log->info( "=== $note" );
$range = "( 1994-01-01, 1995-01-01 00:01 ]";
is( $mrfu->priv_change_during_range( $dbix_conn, $range ), 1,
    "mrfu has priv change during borderline range $range" );


note( $note = '============================' );
$log->info( "=== $note" );
note( $note = 'schedule_change_during_range with zero schedhistory records' );
$log->info( "=== $note" );
note( $note = '============================' );
$log->info( "=== $note" );


note( $note = 'no sched change on empty sched history: 1' );
$log->info( "=== $note" );
$range = "( 1997-01-01, 1997-01-02 )";
is( $mrfu->schedule_change_during_range( $dbix_conn, $range ), 0,
    "mrfu no sched change during $range" );

note( $note = 'no sched change on empty sched history: 2' );
$log->info( "=== $note" );
$range = "[ 1987-01-01, 2007-01-02 )";
is( $mrfu->schedule_change_during_range( $dbix_conn, $range ), 0,
    "mrfu no sched change during $range" );

note( $note = 'no sched change on empty sched history: 3' );
$log->info( "=== $note" );
$range = "( 1997-01-01, 1997-01-02 )";
is( $mrsfu->schedule_change_during_range( $dbix_conn, $range ), 0,
    "mrsfu no sched change during $range" );

note( $note = 'no sched change on empty sched history: 4' );
$log->info( "=== $note" );
$range = "[ 1987-01-01, 2007-01-02 )";
ok( ! $mrsfu->schedule_change_during_range( $dbix_conn, $range  ),
    "mrsfu no sched change during $range" );


note( $note = '============================' );
$log->info( "=== $note" );
note( $note = 'schedule_change_during_range with single schedhistory record' );
$log->info( "=== $note" );
note( $note = '============================' );
$log->info( "=== $note" );


note( $note = 'create a testing schedule' );
$log->info( "=== $note" );
my $test_sid = create_testing_schedule( $test );

note( $note = "give mrfu schedule as of 1995-01-01 00:00" );
$log->info( "=== $note" );
$status = req( $test, 201, 'root', 'POST', "schedule/history/eid/" . $mrfu->eid, 
    "{ \"effective\":\"1995-01-01 00:00\", \"sid\":$test_sid, \"remark\":\"mrfu test 1995-01-01\" }" );
ok( $status->ok );
is( $status->code, 'DOCHAZKA_CUD_OK', "mrfu schedhistory record insert OK" );
my $shid_of_mrfu_01 = $status->payload->{'shid'};
ok( $shid_of_mrfu_01 > 0 );

note( $note = "give mrsfu schedule as of 1997-01-01 00:00" );
$log->info( "=== $note" );
$status = req( $test, 201, 'root', 'POST', "schedule/history/eid/" . $mrsfu->eid, 
    "{ \"effective\":\"1997-01-01 00:00\", \"sid\":$test_sid, \"remark\":\"mrsfu test 1997-01-01\" }" );
ok( $status->ok );
is( $status->code, 'DOCHAZKA_CUD_OK', "mrsfu schedhistory record insert OK" );
my $shid_of_mrsfu_01 = $status->payload->{'shid'};
ok( $shid_of_mrsfu_01 > 0 );

note( $note = 'ranges that definitely have no change: 1' );
$log->info( "=== $note" );
$range = "( 1997-01-01, 1997-01-02 )";
is( $mrfu->schedule_change_during_range( $dbix_conn, $range ), 0,
    "mrfu no schedule change during $range" );

note( $note = 'ranges that definitely have no change: 2' );
$log->info( "=== $note" );
$range = "[ 1996-12-31, 1997-01-02 )";
is( $mrfu->schedule_change_during_range( $dbix_conn, $range ), 0,
    "mrfu: no schedule change during $range" );

note( $note = 'ranges that definitely have no change: 3' );
$log->info( "=== $note" );
$range = "( 1996-12-31, 1997-01-02 ]";
is( $mrfu->schedule_change_during_range( $dbix_conn, $range ), 0,
    "mrfu: no schedule change during $range" );

note( $note = 'ranges that definitely have no change: 4' );
$log->info( "=== $note" );
$range = "[ 1996-12-31, 1997-01-02 ]";
is( $mrfu->schedule_change_during_range( $dbix_conn, $range ), 0,
    "mrfu: no schedule change during $range" );

note( $note = 'ranges that definitely have a change: 1' );
$log->info( "=== $note" );
$range = "( 1994-12-1 00:00, 1995-1-31 00:00 )";
is( $mrfu->schedule_change_during_range( $dbix_conn, $range ), 1,
    "mrfu has schedule change during $range" );

note( $note = 'ranges that definitely have a change: 2' );
$log->info( "=== $note" );
$range = "[ 1994-12-1 00:00, 1995-1-31 00:00 )";
is( $mrfu->schedule_change_during_range( $dbix_conn, $range ), 1,
    "mrfu has schedule change during $range" );

note( $note = 'ranges that definitely have a change: 3' );
$log->info( "=== $note" );
$range = "( 1994-12-1 00:00, 1995-01-31 00:00 ]";
is( $mrfu->schedule_change_during_range( $dbix_conn, $range ), 1,
    "mrfu has schedule change during $range" );

note( $note = 'ranges that definitely have a change: 4' );
$log->info( "=== $note" );
$range = "[ 1994-12-1 00:00, 1995-01-31 00:00 ]";
is( $mrfu->schedule_change_during_range( $dbix_conn, $range ), 1,
    "mrfu has schedule change during $range" );

note( $note = 'borderline schedule change - negative 1' );
$log->info( "=== $note" );
$range = "[ 1995-01-01 00:00, 1995-01-01 00:01 )";
is( $mrfu->schedule_change_during_range( $dbix_conn, $range ), 0,
    "mrfu: no schedule change during borderline range $range" );

note( $note = 'borderline schedule change - negative 2' );
$log->info( "=== $note" );
$range = "[ 1994-12-31 24:00, 1995-01-01 00:01 )";
is( $mrfu->schedule_change_during_range( $dbix_conn, $range ), 0,
    "mrfu: no schedule change during borderline range $range" );

note( $note = 'borderline schedule change - negative 3' );
$log->info( "=== $note" );
$range = "[ 1995-01-01, 1995-01-01 ]";
is( $mrfu->schedule_change_during_range( $dbix_conn, $range ), 0,
    "mrfu: no schedule change during borderline range $range" );

note( $note = 'borderline schedule change - negative 4' );
$log->info( "=== $note" );
$range = "( 1994-12-31 23:59, 1994-12-31 24:00 ]";
is( $mrfu->schedule_change_during_range( $dbix_conn, $range ), 0,
    "mrfu: no schedule change during borderline range $range" );

note( $note = 'borderline schedule change - negative 5' );
$log->info( "=== $note" );
$range = "( 1995-01-01 00:00, 1995-01-02 ]";
is( $mrfu->schedule_change_during_range( $dbix_conn, $range ), 0,
    "mrfu: no schedule change during borderline range $range" );

note( $note = 'borderline schedule change - negative 6' );
$log->info( "=== $note" );
$range = "[ 1994-12-31 00:00, 1994-12-31 24:00 )";
is( $mrfu->schedule_change_during_range( $dbix_conn, $range ), 0,
    "mrfu: no schedule change during borderline range $range" );

note( $note = 'borderline schedule change - positive 1' );
$log->info( "=== $note" );
$range = "[ 1994-12-31 23:59, 1995-01-01 00:01 )";
is( $mrfu->schedule_change_during_range( $dbix_conn, $range ), 1,
    "mrfu has schedule change during borderline range $range" );

note( $note = 'borderline schedule change - positive 2' );
$log->info( "=== $note" );
$range = "( 1994-01-01, 1995-01-01 00:01 ]";
is( $mrfu->schedule_change_during_range( $dbix_conn, $range ), 1,
    "mrfu has schedule change during borderline range $range" );


note( $note = '============================' );
$log->info( "=== $note" );
note( $note = 'schedule_change_during_range with two schedhistory records' );
$log->info( "=== $note" );
note( $note = '============================' );
$log->info( "=== $note" );


note( $note = "give mrfu schedule as of 1995-01-02 00:00" );
$log->info( "=== $note" );
$status = req( $test, 201, 'root', 'POST', "schedule/history/eid/" . $mrfu->eid, 
    "{ \"effective\":\"1995-01-02 00:00\", \"sid\":$test_sid, \"remark\":\"mrfu test 1995-01-02\" }" );
ok( $status->ok );
is( $status->code, 'DOCHAZKA_CUD_OK', "mrfu schedhistory record insert OK" );
my $shid_of_mrfu_02 = $status->payload->{'shid'};
ok( $shid_of_mrfu_02 > 0 );

note( $note = "give mrsfu schedule as of 1997-01-02 00:00" );
$log->info( "=== $note" );
$status = req( $test, 201, 'root', 'POST', "schedule/history/eid/" . $mrsfu->eid, 
    "{ \"effective\":\"1997-01-02 00:00\", \"sid\":$test_sid, \"remark\":\"mrsfu test 1997-01-02\" }" );
ok( $status->ok );
is( $status->code, 'DOCHAZKA_CUD_OK', "mrsfu schedhistory record insert OK" );
my $shid_of_mrsfu_02 = $status->payload->{'shid'};
ok( $shid_of_mrsfu_02 > 0 );

note( $note = 'ranges that definitely have no schedule change: 1' );
$log->info( "=== $note" );
$range = "( 1997-01-01, 1997-01-02 )";
is( $mrfu->schedule_change_during_range( $dbix_conn, $range ), 0,
    "mrfu no schedule change during $range" );

note( $note = 'ranges that definitely have no schedule change: 2' );
$log->info( "=== $note" );
$range = "[ 1996-12-31, 1997-01-02 )";
is( $mrfu->schedule_change_during_range( $dbix_conn, $range ), 0,
    "mrfu: no schedule change during $range" );

note( $note = 'ranges that definitely have no schedule change: 3' );
$log->info( "=== $note" );
$range = "( 1996-12-31, 1997-01-02 ]";
is( $mrfu->schedule_change_during_range( $dbix_conn, $range ), 0,
    "mrfu: no schedule change during $range" );

note( $note = 'ranges that definitely have no schedule change: 4' );
$log->info( "=== $note" );
$range = "[ 1996-12-31, 1997-01-02 ]";
is( $mrfu->schedule_change_during_range( $dbix_conn, $range ), 0,
    "mrfu: no schedule change during $range" );

note( $note = 'ranges that definitely have a change: 1' );
$log->info( "=== $note" );
$range = "( 1994-12-1 00:00, 1995-1-31 00:00 )";
is( $mrfu->schedule_change_during_range( $dbix_conn, $range ), 2,
    "mrfu has schedule change during $range" );

note( $note = 'ranges that definitely have a change: 2' );
$log->info( "=== $note" );
$range = "[ 1994-12-1 00:00, 1995-1-31 00:00 )";
is( $mrfu->schedule_change_during_range( $dbix_conn, $range ), 2,
    "mrfu has schedule change during $range" );

note( $note = 'ranges that definitely have a change: 3' );
$log->info( "=== $note" );
$range = "( 1994-12-1 00:00, 1995-01-31 00:00 ]";
is( $mrfu->schedule_change_during_range( $dbix_conn, $range ), 2,
    "mrfu has schedule change during $range" );

note( $note = 'ranges that definitely have a change: 4' );
$log->info( "=== $note" );
$range = "[ 1994-12-1 00:00, 1995-01-31 00:00 ]";
is( $mrfu->schedule_change_during_range( $dbix_conn, $range ), 2,
    "mrfu has schedule change during $range" );

note( $note = 'borderline schedule change - negative 1' );
$log->info( "=== $note" );
$range = "[ 1995-01-01 00:00, 1995-01-01 00:01 )";
is( $mrfu->schedule_change_during_range( $dbix_conn, $range ), 0,
    "mrfu: no schedule change during borderline range $range" );

note( $note = 'borderline schedule change - negative 2' );
$log->info( "=== $note" );
$range = "[ 1994-12-31 24:00, 1995-01-01 00:01 )";
is( $mrfu->schedule_change_during_range( $dbix_conn, $range ), 0,
    "mrfu: no schedule change during borderline range $range" );

note( $note = 'borderline schedule change - negative 3' );
$log->info( "=== $note" );
$range = "[ 1995-01-01, 1995-01-01 ]";
is( $mrfu->schedule_change_during_range( $dbix_conn, $range ), 0,
    "mrfu: no schedule change during borderline range $range" );

note( $note = 'borderline schedule change - negative 4' );
$log->info( "=== $note" );
$range = "( 1994-12-31 23:59, 1994-12-31 24:00 ]";
is( $mrfu->schedule_change_during_range( $dbix_conn, $range ), 0,
    "mrfu: no schedule change during borderline range $range" );

note( $note = 'borderline schedule change - negative 5' );
$log->info( "=== $note" );
$range = "( 1995-01-02 00:00, 1995-01-02 24:00 ]";
is( $mrfu->schedule_change_during_range( $dbix_conn, $range ), 0,
    "mrfu: no schedule change during borderline range $range" );

note( $note = 'borderline schedule change - negative 6' );
$log->info( "=== $note" );
$range = "[ 1994-12-31 00:00, 1994-12-31 24:00 )";
is( $mrfu->schedule_change_during_range( $dbix_conn, $range ), 0,
    "mrfu: no schedule change during borderline range $range" );

note( $note = 'borderline schedule change - negative 7' );
$log->info( "=== $note" );
$range = "( 1995-01-02, 1995-01-02 00:01 ]";
is( $mrfu->schedule_change_during_range( $dbix_conn, $range ), 0,
    "mrfu has schedule change during borderline range $range" );

note( $note = 'borderline schedule change - positive 1' );
$log->info( "=== $note" );
$range = "[ 1994-12-31 23:59, 1995-01-01 00:01 )";
is( $mrfu->schedule_change_during_range( $dbix_conn, $range ), 1,
    "mrfu has schedule change during borderline range $range" );

note( $note = 'borderline schedule change - positive 2' );
$log->info( "=== $note" );
$range = "[ 1995-1-1 23:59, 1995-01-02 00:01 )";
is( $mrfu->schedule_change_during_range( $dbix_conn, $range ), 1,
    "mrfu has schedule change during borderline range $range" );

note( $note = 'borderline schedule change - positive 3' );
$log->info( "=== $note" );
$range = "( 1994-01-01, 1995-01-01 00:01 ]";
is( $mrfu->schedule_change_during_range( $dbix_conn, $range ), 1,
    "mrfu has schedule change during borderline range $range" );


note( $note = '============================' );
$log->info( "=== $note" );
note( $note = 'privhistory_at_timestamp, valid arguments' );
$log->info( "=== $note" );
note( $note = '============================' );
$log->info( "=== $note" );


$ts = '1995-01-01';
$phobj = $mrfu->privhistory_at_timestamp( $dbix_conn, $ts );
isa_ok( $phobj, 'App::Dochazka::REST::Model::Privhistory' );
is( $phobj->phid, $phid_of_mrfu_01, "The prevailing privhistory at $ts" );
is( $phobj->remark, 'mrfu test 1995-01-01' );

$ts = '1995-01-01 00:00';
$phobj = $mrfu->privhistory_at_timestamp( $dbix_conn, $ts );
isa_ok( $phobj, 'App::Dochazka::REST::Model::Privhistory' );
is( $phobj->phid, $phid_of_mrfu_01, "The prevailing privhistory at $ts" );
is( $phobj->remark, 'mrfu test 1995-01-01' );

$ts = '2005-01-01';
$phobj = $mrfu->privhistory_at_timestamp( $dbix_conn, $ts );
isa_ok( $phobj, 'App::Dochazka::REST::Model::Privhistory' );
is( $phobj->phid, $phid_of_mrfu_02, "The prevailing privhistory at $ts" );
is( $phobj->remark, 'mrfu test 1995-01-02' );

$ts = '1985-01-01';
$phobj = $mrfu->privhistory_at_timestamp( $dbix_conn, $ts );
isa_ok( $phobj, 'App::Dochazka::REST::Model::Privhistory' );
is( $phobj->phid, undef, "The prevailing privhistory at $ts" );
is( $phobj->remark, undef );


note( $note = '============================' );
$log->info( "=== $note" );
note( $note = 'privhistory_at_timestamp, except with tsrange argument instead of timestamp' );
$log->info( "=== $note" );
note( $note = '============================' );
$log->info( "=== $note" );


$tsr = '[ 1997-01-02 00:00, 1997-01-03 00:00 )';
note( $note = "mrfu privhistory record applicable at bogus timestamp $tsr" );
$phobj = $mrfu->privhistory_at_timestamp( $dbix_conn, $tsr );
isa_ok( $phobj, 'App::Dochazka::REST::Model::Privhistory' );
is( $phobj->phid, $phid_of_mrfu_02, "The prevailing privhistory at $ts" );
is( $phobj->remark, 'mrfu test 1995-01-02' );

$tsr = '[ 1995-01-01 00:00, 1997-01-03 00:00 )';
note( $note = "mrfu privhistory record applicable at bogus timestamp $tsr" );
$phobj = $mrfu->privhistory_at_timestamp( $dbix_conn, $tsr );
isa_ok( $phobj, 'App::Dochazka::REST::Model::Privhistory' );
is( $phobj->phid, $phid_of_mrfu_01, "The prevailing privhistory at $ts" );
is( $phobj->remark, 'mrfu test 1995-01-01' );

$tsr = '[ 1994-12-31 00:00, 1997-01-03 00:00 )';
note( $note = "mrfu privhistory record applicable at bogus timestamp $tsr" );
$phobj = $mrfu->privhistory_at_timestamp( $dbix_conn, $tsr );
isa_ok( $phobj, 'App::Dochazka::REST::Model::Privhistory' );
is( $phobj->phid, undef, "The prevailing privhistory at $ts" );
is( $phobj->remark, undef );


note( $note = '============================' );
$log->info( "=== $note" );
note( $note = 'schedhistory_at_timestamp, valid arguments' );
$log->info( "=== $note" );
note( $note = '============================' );
$log->info( "=== $note" );


$ts = '1997-01-01';
$shobj = $mrsfu->schedhistory_at_timestamp( $dbix_conn, $ts );
isa_ok( $shobj, 'App::Dochazka::REST::Model::Schedhistory' );
is( $shobj->shid, $shid_of_mrsfu_01, "The prevailing schedhistory at $ts" );
is( $shobj->remark, 'mrsfu test 1997-01-01' );

$ts = '2005-01-01';
$shobj = $mrsfu->schedhistory_at_timestamp( $dbix_conn, $ts );
isa_ok( $shobj, 'App::Dochazka::REST::Model::Schedhistory' );
is( $shobj->shid, $shid_of_mrsfu_02, "The prevailing schedhistory at $ts" );
is( $shobj->remark, 'mrsfu test 1997-01-02' );

$ts = '1985-01-01';
$shobj = $mrsfu->schedhistory_at_timestamp( $dbix_conn, $ts );
isa_ok( $shobj, 'App::Dochazka::REST::Model::Schedhistory' );
is( $shobj->shid, undef, "The prevailing schedhistory at $ts" );
is( $shobj->remark, undef );


note( $note = '============================' );
$log->info( "=== $note" );
note( $note = 'schedhistory_at_timestamp, except with tsrange argument instead of timestamp' );
$log->info( "=== $note" );
note( $note = '============================' );
$log->info( "=== $note" );


$tsr = '[ 1997-01-02 00:00, 1997-01-03 00:00 )';
note( $note = "mrfu schedhistory record applicable at $tsr" );
$shobj = $mrfu->schedhistory_at_timestamp( $dbix_conn, $tsr );
isa_ok( $shobj, 'App::Dochazka::REST::Model::Schedhistory' );
is( $shobj->shid, $shid_of_mrfu_02 );
is( $shobj->remark, 'mrfu test 1995-01-02' );

$tsr = '[ 1995-01-01 00:00, 1997-01-03 00:00 )';
note( $note = "mrfu schedhistory record applicable at $tsr" );
$shobj = $mrfu->schedhistory_at_timestamp( $dbix_conn, $tsr );
isa_ok( $shobj, 'App::Dochazka::REST::Model::Schedhistory' );
is( $shobj->shid, $shid_of_mrfu_01 );
is( $shobj->remark, 'mrfu test 1995-01-01' );

$tsr = '[ 1994-12-31 00:00, 1997-01-03 00:00 )';
note( $note = "mrfu schedhistory record applicable at $tsr" );
$shobj = $mrfu->schedhistory_at_timestamp( $dbix_conn, $tsr );
isa_ok( $shobj, 'App::Dochazka::REST::Model::Schedhistory' );
is( $shobj->shid, undef );
is( $shobj->remark, undef );


note( $note = '============================' );
$log->info( "=== $note" );
note( $note = 'TEARDOWN' );
$log->info( "=== $note" );
note( $note = '============================' );
$log->info( "=== $note" );


$status = delete_all_attendance_data();
BAIL_OUT(0) unless $status->ok;

done_testing;
