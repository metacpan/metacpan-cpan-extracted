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
# test priv_during_range() and schedule_change_during_range() employee methods

#!perl
use 5.012;
use strict;
use warnings;

#use App::CELL::Test::LogToFile;
use App::CELL qw( $meta $site );
use Data::Dumper;
use App::Dochazka::REST::ConnBank qw( $dbix_conn );
use App::Dochazka::REST::Model::Employee qw( nick_exists eid_exists );
use App::Dochazka::REST::Model::Shared qw( noof );
use App::Dochazka::REST::Test;
use Plack::Test;
use Test::Fatal;
use Test::More;
use Test::Warnings;


note( 'initialize, connect to database, and set up a testing plan' );
my $app = initialize_regression_test();

note( 'instantiate Plack::Test object' );
my $test = Plack::Test->create( $app );

note( 'get initial number of employees' );
my $noof_employees = noof( $dbix_conn, 'employees' );

note( 'root employee is created at dbinit time' );
my $eid_of_root = $site->DOCHAZKA_EID_OF_ROOT;

note( 'spawn mrfu' );
my $emp = App::Dochazka::REST::Model::Employee->spawn( 
    nick => 'mrfu',
    fullname => 'Mr. Fu',
    email => 'mrfu@example.com',
    sec_id => 1024,
);
isa_ok( $emp, 'App::Dochazka::REST::Model::Employee' );

note( 'insert mrfu' );
my $status = $emp->insert( $faux_context );
is( $status->level, 'OK', "Mr. Fu inserted" );
is( noof( $dbix_conn, 'employees' ), 3 );

note( 're-load mrfu' );
$status = $emp->load_by_nick( $dbix_conn, 'mrfu' );
is( $status->code, 'DISPATCH_RECORDS_FOUND', "mrfu re-load success" );
my $mrfu = $status->payload;
is( $mrfu->nick, 'mrfu' );
is( $mrfu->sec_id, 1024 );

note( 'spawn mrsfu' );
$emp = App::Dochazka::REST::Model::Employee->spawn( 
    nick => 'mrsfu',
    sec_id => 78923,
    email => 'consort@futown.orient.cn',
    fullname => 'Mrs. Fu',
);
isa_ok( $emp, 'App::Dochazka::REST::Model::Employee' );

note( 'insert mrsfu' );
$status = $emp->insert( $faux_context );
ok( $status->ok, "Mrs. Fu inserted" );

note( 're-load mrsfu' );
$status = $emp->load_by_nick( $dbix_conn, 'mrsfu' );
is( $status->code, 'DISPATCH_RECORDS_FOUND', "mrsfu re-load success" );
my $mrsfu = $status->payload;
is( $mrsfu->nick, 'mrsfu', "Mrs. Fu's nick is the right string" );
is( $mrsfu->sec_id, 78923, "Mrs. Fu's secondary ID is the right string" );

my $test_sid = create_testing_schedule( $test );

note( "make mrfu inactive as of 1995-01-01 00:00" );
$status = req( $test, 201, 'root', 'POST', "priv/history/eid/" . $mrfu->eid, 
    '{ "effective":"1995-01-01 00:00", "priv":"inactive", "remark":"mrfu test" }' );
ok( $status->ok );
is( $status->code, 'DOCHAZKA_CUD_OK', "mrfu privhistory record insert OK" );
my $phid_of_mrfu = $status->payload->{'phid'};
ok( $phid_of_mrfu > 0 );

note( "give mrfu schedule as of 1995-01-01 00:00" );
$status = req( $test, 201, 'root', 'POST', "schedule/history/eid/" . $mrfu->eid, 
    "{ \"effective\":\"1995-01-01 00:00\", \"sid\":$test_sid, \"remark\":\"mrfu test\" }" );
ok( $status->ok );
is( $status->code, 'DOCHAZKA_CUD_OK', "mrfu schedhistory record insert OK" );
my $shid_of_mrfu = $status->payload->{'shid'};
ok( $shid_of_mrfu > 0 );

note( "make mrsfu active as of 1997-01-01 00:00" );
$status = req( $test, 201, 'root', 'POST', "priv/history/eid/" . $mrsfu->eid, 
    '{ "effective":"1997-01-01 00:00", "priv":"active", "remark":"mrsfu test" }' );
ok( $status->ok );
is( $status->code, 'DOCHAZKA_CUD_OK', "mrsfu privhistory record insert OK" );
my $phid_of_mrsfu = $status->payload->{'phid'};
ok( $phid_of_mrsfu > 0 );

note( "give mrsfu schedule as of 1997-01-01 00:00" );
$status = req( $test, 201, 'root', 'POST', "schedule/history/eid/" . $mrsfu->eid, 
    "{ \"effective\":\"1997-01-01 00:00\", \"sid\":$test_sid, \"remark\":\"mrsfu test\" }" );
ok( $status->ok );
is( $status->code, 'DOCHAZKA_CUD_OK', "mrsfu schedhistory record insert OK" );
my $shid_of_mrsfu = $status->payload->{'shid'};
ok( $shid_of_mrsfu > 0 );

note( '===END_OF_SET_UP===' );

my $range;


note( 'priv_change_during_range' );

note( 'ranges that definitely have no change' );
$range = "( 1997-01-01, 1997-01-02 )";
ok( ! $mrfu->priv_change_during_range( $dbix_conn, $range  ),
    "mrfu no priv change during $range" );

$range = "[ 1996-12-31, 1997-01-02 )";
ok( ! $mrfu->priv_change_during_range( $dbix_conn, $range  ),
    "mrfu: no priv change during $range" );

$range = "( 1996-12-31, 1997-01-02 ]";
ok( ! $mrfu->priv_change_during_range( $dbix_conn, $range  ),
    "mrfu: no priv change during $range" );

$range = "[ 1996-12-31, 1997-01-02 ]";
ok( ! $mrfu->priv_change_during_range( $dbix_conn, $range  ),
    "mrfu: no priv change during $range" );

note( 'ranges that definitely have a change' );
$range = "( 1994-12-31, 1995-01-02 )";
ok( $mrfu->priv_change_during_range( $dbix_conn, $range  ),
    "mrfu has priv change during $range" );

$range = "[ 1994-12-31, 1995-01-02 )";
ok( $mrfu->priv_change_during_range( $dbix_conn, $range  ),
    "mrfu has priv change during $range" );

$range = "( 1994-12-31, 1995-01-02 ]";
ok( $mrfu->priv_change_during_range( $dbix_conn, $range  ),
    "mrfu has priv change during $range" );

$range = "[ 1994-12-31, 1995-01-02 ]";
ok( $mrfu->priv_change_during_range( $dbix_conn, $range  ),
    "mrfu has priv change during $range" );

note( 'borderline priv level change - negative' );
$range = "[ 1995-01-01 00:00, 1995-01-02 )";
ok( ! $mrfu->priv_change_during_range( $dbix_conn, $range  ),
    "mrfu: no priv change during borderline range $range" );

$range = "( 1994-01-01, 1994-12-31 24:00 ]";
ok( ! $mrfu->priv_change_during_range( $dbix_conn, $range  ),
    "mrfu: no priv change during borderline range $range" );

note( 'borderline priv level change - positive' );
$range = "[ 1994-12-31 23:59, 1995-01-02 )";
ok( $mrfu->priv_change_during_range( $dbix_conn, $range  ),
    "mrfu has priv change during borderline range $range" );

$range = "( 1994-01-01, 1995-01-01 00:01 ]";
ok( $mrfu->priv_change_during_range( $dbix_conn, $range  ),
    "mrfu has priv change during borderline range $range" );

note( 'schedule_change_during_range' );

note( 'ranges that definitely have no change' );
$range = "( 1997-01-01, 1997-01-02 )";
ok( ! $mrfu->schedule_change_during_range( $dbix_conn, $range  ),
    "mrfu no schedule change during $range" );

$range = "[ 1996-12-31, 1997-01-02 )";
ok( ! $mrfu->schedule_change_during_range( $dbix_conn, $range  ),
    "mrfu: no schedule change during $range" );

$range = "( 1996-12-31, 1997-01-02 ]";
ok( ! $mrfu->schedule_change_during_range( $dbix_conn, $range  ),
    "mrfu: no schedule change during $range" );

$range = "[ 1996-12-31, 1997-01-02 ]";
ok( ! $mrfu->schedule_change_during_range( $dbix_conn, $range  ),
    "mrfu: no schedule change during $range" );

note( 'ranges that definitely have a change' );
$range = "( 1994-12-31, 1995-01-02 )";
ok( $mrfu->schedule_change_during_range( $dbix_conn, $range  ),
    "mrfu has schedule change during $range" );

$range = "[ 1994-12-31, 1995-01-02 )";
ok( $mrfu->schedule_change_during_range( $dbix_conn, $range  ),
    "mrfu has schedule change during $range" );

$range = "( 1994-12-31, 1995-01-02 ]";
ok( $mrfu->schedule_change_during_range( $dbix_conn, $range  ),
    "mrfu has schedule change during $range" );

$range = "[ 1994-12-31, 1995-01-02 ]";
ok( $mrfu->schedule_change_during_range( $dbix_conn, $range  ),
    "mrfu has schedule change during $range" );

note( 'borderline priv level change - negative' );
$range = "[ 1995-01-01 00:00, 1995-01-02 )";
ok( ! $mrfu->schedule_change_during_range( $dbix_conn, $range  ),
    "mrfu: no schedule change during borderline range $range" );

$range = "( 1994-01-01, 1994-12-31 24:00 ]";
ok( ! $mrfu->schedule_change_during_range( $dbix_conn, $range  ),
    "mrfu: no schedule change during borderline range $range" );

note( 'borderline priv level change - positive' );
$range = "[ 1994-12-31 23:59, 1995-01-02 )";
ok( $mrfu->schedule_change_during_range( $dbix_conn, $range  ),
    "mrfu has schedule change during borderline range $range" );

$range = "( 1994-01-01, 1995-01-01 00:01 ]";
ok( $mrfu->schedule_change_during_range( $dbix_conn, $range  ),
    "mrfu has schedule change during borderline range $range" );


my ( $phobj, $shobj );

note( 'privhistory_at_timestamp' );

$phobj = undef;
$phobj = $mrfu->privhistory_at_timestamp( $dbix_conn, '1995-01-01' );
isa_ok( $phobj, 'App::Dochazka::REST::Model::Privhistory' );
is( $phobj->phid, $phid_of_mrfu );
is( $phobj->remark, 'mrfu test' );

$phobj = undef;
$phobj = $mrfu->privhistory_at_timestamp( $dbix_conn, '2005-01-01' );
isa_ok( $phobj, 'App::Dochazka::REST::Model::Privhistory' );
is( $phobj->phid, $phid_of_mrfu );
is( $phobj->remark, 'mrfu test' );

$phobj = undef;
$phobj = $mrfu->privhistory_at_timestamp( $dbix_conn, '1985-01-01' );
isa_ok( $phobj, 'App::Dochazka::REST::Model::Privhistory' );
is( $phobj->phid, undef );
is( $phobj->remark, undef );


note( 'privhistory_at_tsrange' );

my $tsr = '[ 1997-01-02 00:00, 1997-01-03 00:00 )';
note( "mrfu privhistory record applicable at $tsr" );
$phobj = undef;
$phobj = $mrfu->privhistory_at_timestamp( $dbix_conn, $tsr );
isa_ok( $phobj, 'App::Dochazka::REST::Model::Privhistory' );
is( $phobj->phid, $phid_of_mrfu );
is( $phobj->remark, 'mrfu test' );

$tsr = '[ 1995-01-01 00:00, 1997-01-03 00:00 )';
note( "mrfu privhistory record applicable at $tsr" );
$phobj = undef;
$phobj = $mrfu->privhistory_at_timestamp( $dbix_conn, $tsr );
isa_ok( $phobj, 'App::Dochazka::REST::Model::Privhistory' );
is( $phobj->phid, $phid_of_mrfu );
is( $phobj->remark, 'mrfu test' );

$tsr = '[ 1994-12-31 00:00, 1997-01-03 00:00 )';
note( "mrfu privhistory record applicable at $tsr" );
$phobj = undef;
$phobj = $mrfu->privhistory_at_timestamp( $dbix_conn, $tsr );
isa_ok( $phobj, 'App::Dochazka::REST::Model::Privhistory' );
is( $phobj->phid, undef );
is( $phobj->remark, undef );


note( 'schedhistory_at_timestamp' );

$shobj = undef;
$shobj = $mrsfu->schedhistory_at_timestamp( $dbix_conn, '1997-01-01' );
isa_ok( $shobj, 'App::Dochazka::REST::Model::Schedhistory' );
is( $shobj->shid, $shid_of_mrsfu );
is( $shobj->remark, 'mrsfu test' );

$shobj = undef;
$shobj = $mrsfu->schedhistory_at_timestamp( $dbix_conn, '2005-01-01' );
isa_ok( $shobj, 'App::Dochazka::REST::Model::Schedhistory' );
is( $shobj->shid, $shid_of_mrsfu );
is( $shobj->remark, 'mrsfu test' );

$shobj = undef;
$shobj = $mrsfu->schedhistory_at_timestamp( $dbix_conn, '1985-01-01' );
isa_ok( $shobj, 'App::Dochazka::REST::Model::Schedhistory' );
is( $shobj->shid, undef );
is( $shobj->remark, undef );


note( 'schedhistory_at_tsrange' );

$tsr = '[ 1997-01-02 00:00, 1997-01-03 00:00 )';
note( "mrfu schedhistory record applicable at $tsr" );
$shobj = undef;
$shobj = $mrfu->schedhistory_at_timestamp( $dbix_conn, $tsr );
isa_ok( $shobj, 'App::Dochazka::REST::Model::Schedhistory' );
is( $shobj->shid, $shid_of_mrfu );
is( $shobj->remark, 'mrfu test' );

$tsr = '[ 1995-01-01 00:00, 1997-01-03 00:00 )';
note( "mrfu schedhistory record applicable at $tsr" );
$shobj = undef;
$shobj = $mrfu->schedhistory_at_timestamp( $dbix_conn, $tsr );
isa_ok( $shobj, 'App::Dochazka::REST::Model::Schedhistory' );
is( $shobj->shid, $shid_of_mrfu );
is( $shobj->remark, 'mrfu test' );

$tsr = '[ 1994-12-31 00:00, 1997-01-03 00:00 )';
note( "mrfu schedhistory record applicable at $tsr" );
$shobj = undef;
$shobj = $mrfu->schedhistory_at_timestamp( $dbix_conn, $tsr );
isa_ok( $shobj, 'App::Dochazka::REST::Model::Schedhistory' );
is( $shobj->shid, undef );
is( $shobj->remark, undef );


note( '===BEGIN_OF_TEAR_DOWN===' );

$status = App::Dochazka::REST::Model::Privhistory->load_by_phid( $dbix_conn, $phid_of_mrfu );
ok( $status->ok, "mrfu privhistory record loaded" );
$phobj = $status->payload;
$status = $phobj->delete( $faux_context );
ok( $status->ok, "mrfu privhistory record deleted" );

$status = App::Dochazka::REST::Model::Privhistory->load_by_phid( $dbix_conn, $phid_of_mrsfu );
ok( $status->ok, "mrsfu privhistory record loaded" );
$phobj = $status->payload;
$status = $phobj->delete( $faux_context );
ok( $status->ok, "mrsfu privhistory record deleted" );

$status = App::Dochazka::REST::Model::Schedhistory->load_by_shid( $dbix_conn, $shid_of_mrfu );
ok( $status->ok, "mrfu schedhistory record loaded" );
$shobj = $status->payload;
$status = $shobj->delete( $faux_context );
ok( $status->ok, "mrfu schedhistory record deleted" );

$status = App::Dochazka::REST::Model::Schedhistory->load_by_shid( $dbix_conn, $shid_of_mrsfu );
ok( $status->ok, "mrsfu schedhistory record loaded" );
$shobj = $status->payload;
$status = $shobj->delete( $faux_context );
ok( $status->ok, "mrsfu schedhistory record deleted" );

delete_testing_schedule( $test_sid );

note( 'delete Mr. and Mrs. Fu' );
$status = $mrfu->delete( $faux_context );
ok( $status->ok );
$status = $mrsfu->delete( $faux_context );
ok( $status->ok );

note( 'employees table should now have the same number of records as at the beginning' );
is( noof( $dbix_conn, 'employees' ), $noof_employees, 'same' );

note( 'tear down' );
$status = delete_all_attendance_data();
BAIL_OUT(0) unless $status->ok;

done_testing;
