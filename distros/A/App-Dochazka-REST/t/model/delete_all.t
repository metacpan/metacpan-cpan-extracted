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
# test delete_all_attendance_data()
#

#!perl
use 5.012;
use strict;
use warnings;

#use App::CELL::Test::LogToFile;
use App::Dochazka::Common qw( $today );
use App::Dochazka::REST::ConnBank qw( $dbix_conn );
use App::Dochazka::REST::Model::Schedhistory;
use App::Dochazka::REST::Model::Shared qw( noof );
use App::Dochazka::REST::Test;
use Plack::Test;
use Test::More;
use Test::Warnings;


note( 'initialize unit' );
my $app = initialize_regression_test();

note( 'instantiate Plack::Test object' );
my $test = Plack::Test->create( $app );
isa_ok( $test, 'Plack::Test::MockHTTP' );

note( 'create active employee' );
my $eid = create_active_employee( $test );

note( 'create testing schedule' );
my $sid = create_testing_schedule( $test );

note( 'create schedhistory record' );
my $shr = App::Dochazka::REST::Model::Schedhistory->spawn(
    eid => $eid,
    sid => $sid,
    effective => "1892-01-01 00:00"
);
my $status = $shr->insert( $faux_context );
is( $status->level, 'OK' );
is( $status->code, 'DOCHAZKA_CUD_OK' );

note( 'load WORK activity' );
$status = App::Dochazka::REST::Model::Activity->load_by_code( $dbix_conn, 'work' );
is( $status->code, 'DISPATCH_RECORDS_FOUND' );
my $work = $status->payload;
ok( $work->aid > 0 );

note( 'spawn and insert an interval object' );
my $int = App::Dochazka::REST::Model::Interval->spawn(
    eid => $eid,
    aid => $work->aid,
    intvl => "[$today 08:00, $today 12:00)",
    long_desc => "Testing testing",
);
is( noof( $dbix_conn, 'intervals' ), 0 );
$status = $int->insert( $faux_context );
is( $status->level, 'OK' );
is( $status->code, 'DOCHAZKA_CUD_OK' );
is( noof( $dbix_conn, 'intervals' ), 1 );
ok( $int->iid > 0 );
my $saved_iid = $int->iid;

note( 'spawn and insert a lock object' );
my $lock = App::Dochazka::REST::Model::Lock->spawn(
    eid => $eid,
    intvl => "[$today 00:00, $today 24:00)",
    remark => 'TESTING',
);
isa_ok( $lock, 'App::Dochazka::REST::Model::Lock' );
is( noof( $dbix_conn, 'locks' ), 0 );
$status = $lock->insert( $faux_context );
is( noof( $dbix_conn, 'locks' ), 1 );

note( 'delete all the attendance data we just created' );
delete_all_attendance_data();

done_testing;
