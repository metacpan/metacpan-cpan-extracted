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
# some tests to ensure/demonstrate that current_priv stored procedure
# works as advertised
#

#!perl
use 5.012;
use strict;
use warnings;

#use App::CELL::Test::LogToFile;
use App::CELL qw( $meta $site );
use Data::Dumper;
use App::Dochazka::REST::ConnBank qw( $dbix_conn );
use App::Dochazka::REST::Model::Shared qw( select_single );
use App::Dochazka::REST::Test;
use Test::More;
use Test::Warnings;


note( "initialize, connect to database, and set up a testing plan" );
initialize_regression_test();

note( 'get EID of root employee, the hard way, and sanity-test it' );
my ( $eid_of_root ) = do_select_single( $dbix_conn, $site->DBINIT_SELECT_EID_OF, 'root' );
is( $eid_of_root, $site->DOCHAZKA_EID_OF_ROOT );

note( "get root's current privilege level, the hard way" );
my ( $priv ) = do_select_single( $dbix_conn, "SELECT current_priv(?)", $eid_of_root );
is( $priv, "admin", "root is admin" );

note( 'insert a new employee' );
test_sql_success($dbix_conn, 1, <<SQL);
INSERT INTO employees (nick) VALUES ('bubba')
SQL

note( 'get bubba EID' );
my ( $eid_of_bubba ) = do_select_single( $dbix_conn, "SELECT eid FROM employees WHERE nick=?", 'bubba' );
ok( $eid_of_bubba > 2 );

note( 'get bubba\'s current privilege level (none; defaults to \'passerby\')' );
( $priv ) = do_select_single( $dbix_conn, "SELECT current_priv(?)", $eid_of_bubba );
is( $priv, "passerby", "bubba is a passerby" );

note( 'get priv level of non-existent employee (will be \'passerby\')' );
( $priv ) = do_select_single( $dbix_conn, "SELECT current_priv(?)", 0 );
is( $priv, "passerby", "non-existent EID 0 is a passerby" );

note( "get priv level of another non-existent employee (will be 'passerby')" );
( $priv ) = do_select_single( $dbix_conn, "SELECT current_priv(?)", 44 );
is( $priv, "passerby", "non-existent EID 44 is a passerby" );

note( 'make bubba an admin, but not until the year 3000' );
test_sql_success($dbix_conn, 1, <<SQL);
INSERT INTO privhistory (eid, priv, effective) 
VALUES ($eid_of_bubba, 'admin', '3000-01-01')
SQL

note( 'test his current priv level - still passerby' );
( $priv ) = do_select_single( $dbix_conn, "SELECT current_priv(?)", $eid_of_bubba );
is( $priv, "passerby", "bubba is still a passerby" );

note( 'test his priv level at 2999-12-31 23:59:59' );
( $priv ) = do_select_single( $dbix_conn, "SELECT priv_at_timestamp(?, ?)", $eid_of_bubba, '2999-12-31 23:59:59' );
is( $priv, "passerby", "bubba still a passerby" );

note( 'test his priv level at 3001-06-30 14:34' );
( $priv ) = do_select_single( $dbix_conn, "SELECT priv_at_timestamp(?, ?)", $eid_of_bubba, '3001-06-30 14:34' );
is( $priv, "admin", "bubba finally made admin" );

note( 'attempt to delete his employee record -- FAIL' );
test_sql_failure($dbix_conn, qr/violates foreign key constraint/, <<SQL);
DELETE FROM employees WHERE eid=$eid_of_bubba
SQL

note( 'attempt to change his EID -- FAIL' );
test_sql_failure($dbix_conn, qr/employees\.eid field is immutable/, <<SQL);
UPDATE employees SET eid=55 WHERE eid=$eid_of_bubba
SQL

note( 'delete bubba privhistory' );
test_sql_success($dbix_conn, 1, <<SQL);
DELETE FROM privhistory WHERE eid=$eid_of_bubba
SQL

note( 'delete bubba employee' );
test_sql_success($dbix_conn, 1, <<SQL);
DELETE FROM employees WHERE eid=$eid_of_bubba
SQL

done_testing;
