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
# tests of "root immutability" triggers
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

note( 'attempt to insert a new root employee' );
test_sql_failure( $dbix_conn, qr/duplicate key value/, <<SQL );
INSERT INTO employees (eid, nick) VALUES ($eid_of_root, 'root')
SQL

note( 'attempt to insert a new root employee in another way' );
test_sql_failure( $dbix_conn, qr/duplicate key value/, <<SQL );
INSERT INTO employees (nick) VALUES ('root')
SQL

note( "attempt to change EID of root employee" );
test_sql_failure( $dbix_conn, qr/employees\.eid field is immutable/, <<SQL);
UPDATE employees SET eid=55 WHERE eid=$eid_of_root
SQL

note( 'attempt to change nick of root employee' );
test_sql_failure( $dbix_conn, qr/root employee is immutable/, <<SQL);
UPDATE employees SET nick = 'Bubba' WHERE eid=$eid_of_root
SQL

# we _can_ change fullname of root employee, though not recommended to do so
#diag( 'change fullname of root employee' );
#my $rv = $dbh->do( <<SQL , undef, 'El Rooto', $eid_of_root ) or die( $dbh->errstr );
#UPDATE employees SET fullname=? WHERE eid=?
#SQL
#is( $rv, 1, "root employee's email changed" );

# and we _can_ change the email of root employee -- a site might want to
# send email to root
#diag( 'change email of root employee' );
#$rv = $dbh->do( <<SQL , undef, 'root@site.org', $eid_of_root ) or die( $dbh->errstr );
#UPDATE employees SET email=? WHERE eid=?
#SQL
#is( $rv, 1, "root employee's email changed" );

note( 'change root passhash and salt' );
test_sql_success( $dbix_conn, 1, <<"SQL" );
UPDATE employees SET passhash='\$1\$iT4NN7aG\$EPzMy7jnV3w.rFZ/HLSu21', salt='0+iOssyc' WHERE eid=$eid_of_root
SQL

note( 'change it back' );
test_sql_success( $dbix_conn, 1, <<"SQL" );
UPDATE employees SET passhash = '82100e9bd4757883b4627b3bafc9389663e7be7f76a1273508a7a617c9dcd917428a7c44c6089477c8e1d13e924343051563d2d426617b695f3a3bff74e7c003', salt = '341755e03e1f163f829785d1d19eab9dee5135c0' WHERE eid = $eid_of_root
SQL

note( 'attempt to delete the root employee' );
test_sql_failure( $dbix_conn, qr/root employee is immutable/, <<SQL );
DELETE FROM employees WHERE eid=$eid_of_root
SQL

note( 'attempt to update the root employee in another way' );
test_sql_failure( $dbix_conn, qr/root employee is immutable/, <<SQL );
UPDATE employees SET nick = 'Bubba' WHERE nick='root'
SQL

note( 'attempt to delete the root employee in another way' );
test_sql_failure( $dbix_conn, qr/root employee is immutable/, <<SQL );
DELETE FROM employees WHERE nick='root'
SQL

note( 'attempt to insert a second privhistory row for root employee' );
test_sql_failure( $dbix_conn, qr/root employee is immutable/, <<SQL );
INSERT INTO privhistory (eid, priv, effective)
VALUES ($eid_of_root, 'passerby', '2000-01-01')
SQL

note( 'attempt to update root\'s single privhistory row' );
test_sql_failure( $dbix_conn, qr/root employee is immutable/, <<SQL );
UPDATE privhistory SET priv='passerby' WHERE eid=$eid_of_root
SQL

note( 'attempt to delete root\'s single privhistory row, effectively rendering him a passerby' );
test_sql_failure( $dbix_conn, qr/root employee is immutable/, <<SQL );
DELETE FROM privhistory WHERE eid=$eid_of_root
SQL

done_testing;
