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
# some tests to demonstrate work with the schedhistory table
#

#!perl
use 5.012;
use strict;
use warnings;

#use App::CELL::Test::LogToFile;
use App::CELL qw( $meta $site );
use App::Dochazka::REST::ConnBank qw( $dbix_conn );
use App::Dochazka::REST::Test;
use Data::Dumper;
use Test::More;
use Test::Warnings;

note( 'initialize, connect to database, and set up a testing plan' );
initialize_regression_test();

note( 'get EID of root employee' );
my ( $eid_of_root ) = do_select_single( $dbix_conn, $site->DBINIT_SELECT_EID_OF, 'root' );
is( $eid_of_root, $site->DOCHAZKA_EID_OF_ROOT, "EID of root is correct" );
is( $eid_of_root, 1, "EID of root is 1" );

note( 'get EID of demo employee' );
my ( $eid_of_demo ) = do_select_single( $dbix_conn, $site->DBINIT_SELECT_EID_OF, 'demo' );
is( $eid_of_demo, $site->DOCHAZKA_EID_OF_DEMO, "EID of demo is correct" );
is( $eid_of_demo, 2, "EID of demo is 2" );

note( 'get SID of default schedule' );
my ( $sid ) = do_select_single( $dbix_conn, <<"SQL", 'DEFAULT' );
SELECT sid FROM schedules
WHERE scode=?
SQL

note( 'insert an innocent schedhistory record' );
test_sql_success( $dbix_conn, 1, <<"SQL" );
INSERT INTO schedhistory (eid, sid, effective) VALUES ($eid_of_demo, $sid, '2000-01-01')
SQL

note( 'select it back' );
my ( $shid ) = do_select_single( $dbix_conn, <<"SQL", $eid_of_demo );
SELECT shid FROM schedhistory
WHERE eid=? and sid=$sid
SQL
ok( $shid > 0 );

note( 'select it back with scode' );
my ( $scode ) = do_select_single( $dbix_conn, <<"SQL", $shid );
SELECT sch.scode AS scode FROM SCHEDHISTORY his, SCHEDULES sch
WHERE sch.sid = his.sid AND his.shid = ?
SQL
ok( $scode eq "DEFAULT" );

note( 'insert a schedule without an scode' );
my ( $sid_without_scode ) = do_select_single( $dbix_conn, <<"SQL" );
INSERT INTO schedules (schedule)
VALUES ('[{"high_dow":"MON","high_time":"12:00","low_dow":"MON","low_time":"08:00"}]')
RETURNING sid
SQL
#diag( "SID without scode is " . $sid_without_scode );

note( 'insert an innocent schedhistory record' );
my ( $shid_without_scode ) = do_select_single( $dbix_conn, <<"SQL" );
INSERT INTO schedhistory (eid, sid, effective)
VALUES ($eid_of_demo, $sid_without_scode, '2000-01-02')
RETURNING shid
SQL
#diag( "SHID without scode is " . $shid_without_scode );

note( 'select schedhistory record with scode when scode is not there' );
my ( $t_sid, $t_scode ) = do_select_single( $dbix_conn, <<"SQL", $shid_without_scode );
SELECT sch.sid AS sid, sch.scode AS scode FROM SCHEDHISTORY his, SCHEDULES sch
WHERE sch.sid = his.sid AND his.shid = ?
SQL
is( $t_sid, $sid_without_scode );
is( $t_scode, undef );

note( 'give it an innocent remark' );
test_sql_success( $dbix_conn, 1, <<"SQL" );
UPDATE schedhistory SET remark = 'I am foobar!'
WHERE shid = $shid
SQL

note( 'select the new remark back' );
my ( $remark ) = do_select_single( $dbix_conn, <<"SQL", $shid );
SELECT remark FROM schedhistory
WHERE shid = ?
SQL
is( $remark, 'I am foobar!' );

note( 'delete the record, so it doesn\'t cause issues later' );
test_sql_success( $dbix_conn, 1, <<"SQL" );
DELETE FROM schedhistory
WHERE shid = $shid
SQL

done_testing;
