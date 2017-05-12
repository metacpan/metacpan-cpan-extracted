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
# test the "disabled_to_zero" trigger
#

#!perl
use 5.012;
use strict;
use warnings;

#use App::CELL::Test::LogToFile;
use App::CELL qw( $meta $site );
use Data::Dumper;
use App::Dochazka::REST::ConnBank qw( $dbix_conn );
use App::Dochazka::REST::Test;
use Test::More;
use Test::Warnings;

note( "initialize, connect to database, and set up a testing plan" );
initialize_regression_test();

my @acode_to_delete;
my @scode_to_delete;

note( 'insert a row' );
test_sql_success( $dbix_conn, 1, <<"SQL" );
INSERT INTO activities (code) VALUES ('WADA_DADA')
SQL
push @acode_to_delete, 'WADA_DADA';

test_sql_success( $dbix_conn, 1, <<"SQL" );
INSERT INTO schedules (scode, schedule) VALUES (999, 'NORMALCY IS BAD, BE DIFFERENT')
SQL
push @scode_to_delete, '999';

note( 'select it back, noting that disable is set to zero' );
my ( $aid, $code, $disabled ) = do_select_single( $dbix_conn, 
    "SELECT aid, code, disabled FROM activities WHERE code='WADA_DADA'" );
is( $code, 'WADA_DADA' );
is( $disabled, 0 );

my ( $scode, $sdisabled ) = do_select_single( $dbix_conn, 
    "SELECT scode, disabled FROM schedules WHERE scode='999'" );
is( $scode, 999 );
is( $sdisabled, 0 );

note( 'failed attempt to update disabled to NULL' );
test_sql_success( $dbix_conn, 1, <<"SQL" );
UPDATE activities SET disabled=NULL WHERE aid=$aid
SQL

test_sql_success( $dbix_conn, 1, <<"SQL" );
UPDATE schedules SET disabled=NULL WHERE scode='$scode'
SQL

note( 'select it back, noting that disable is set to a false value (and not undef)' );
( $aid, $code, $disabled ) = do_select_single( $dbix_conn, 
    "SELECT aid, code, disabled FROM activities WHERE code='WADA_DADA'" );
is( $code, 'WADA_DADA' );
is( $disabled, 0 );

( $scode, $sdisabled ) = do_select_single( $dbix_conn, 
    "SELECT scode, disabled FROM schedules WHERE scode='999'" );
is( $scode, 999 );
is( $disabled, 0 );

note( 'cleanup' );
foreach my $acode ( @acode_to_delete ) {
    test_sql_success( $dbix_conn, 1, <<"SQL" );
DELETE FROM activities WHERE code='$acode';
SQL
}
foreach my $scode ( @scode_to_delete ) {
    test_sql_success( $dbix_conn, 1, <<"SQL" );
DELETE FROM schedules WHERE scode='$scode';
SQL
}

done_testing;
