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
# some tests to demonstrate work with the privhistory table
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

note( 'insert an innocent privhistory record' );
test_sql_success( $dbix_conn, 1, <<"SQL" );
INSERT INTO privhistory (eid, priv, effective) VALUES ($eid_of_demo, 'active', '2000-01-01')
SQL

note( 'select it back' );
my ( $phid ) = do_select_single( $dbix_conn, <<"SQL", $eid_of_demo );
SELECT phid FROM privhistory
WHERE eid=? and priv='active'
SQL
ok( $phid > 0 );

note( 'give it an innocent remark' );
test_sql_success( $dbix_conn, 1, <<"SQL" );
UPDATE privhistory SET remark = 'I am foobar!'
WHERE phid = $phid
SQL

note( 'select the new remark back' );
my ( $remark ) = do_select_single( $dbix_conn, <<"SQL", $phid );
SELECT remark FROM privhistory
WHERE phid = ?
SQL
is( $remark, 'I am foobar!' );

note( 'delete the record, so it doesn\'t cause issues later' );
test_sql_success( $dbix_conn, 1, <<"SQL" );
DELETE FROM privhistory
WHERE phid = $phid
SQL

done_testing;
