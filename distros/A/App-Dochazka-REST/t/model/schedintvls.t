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
# unit tests for scratch schedules
#

#!perl
use 5.012;
use strict;
use warnings;

#use App::CELL::Test::LogToFile;
use App::CELL qw( $meta $site );
use Data::Dumper;
#use App::Dochazka::Common qw( $today $yesterday $tomorrow );
use App::Dochazka::REST::ConnBank qw( $dbix_conn );
use App::Dochazka::REST::Model::Employee;
use App::Dochazka::REST::Model::Schedhistory;
use App::Dochazka::REST::Model::Schedintvls;
use App::Dochazka::REST::Model::Shared qw( noof );
use App::Dochazka::REST::Test;
use Test::More;
use Test::Warnings;


note( "initialize, connect to database, and set up a testing plan" );
initialize_regression_test();

note( 'spawn a schedintvls object' );
my $sto = App::Dochazka::REST::Model::Schedintvls->spawn;
isa_ok( $sto, 'App::Dochazka::REST::Model::Schedintvls' );
ok( $sto->ssid > 0 );

note( 'attempt to insert bogus intervals individually' );
my $bogus_intvls = [
        [ "[)" ],
        [ "[,)" ],
        [ "(2014-07-14 09:00, 2014-07-14 17:05)" ],
        [ "[2014-07-14 09:00, 2014-07-14 17:05]" ],
	[ "[,2014-07-14 17:00)" ],
        [ "[2014-07-14 17:15,)" ],
        [ "[2014-07-14 09:00, 2014-07-14 17:07)" ],
        [ "[2014-07-14 08:57, 2014-07-14 17:05)" ],
        [ "[2014-07-14 06:43, 2014-07-14 25:00)" ],
    ];
map {
        $sto->{intvls} = $_;
        my $status = $sto->insert( $dbix_conn );
        #diag( $status->level . ' ' . $status->text );
        is( $status->level, 'ERR' ); 
    } @$bogus_intvls;

note( 'check that no records made it into the database' );
is( noof( $dbix_conn, 'schedintvls' ), 0 );

note( 'attempt to slip in a bogus interval by hiding it among normal intervals' );
$bogus_intvls = [
        "[)",
        "[,)",
        "(2014-07-14 09:00, 2014-07-14 17:05)",
        "[2014-07-14 09:00, 2014-07-14 17:05]",
	"[,2014-07-14 17:00)",
        "[2014-07-14 17:15,)",
        "[2014-07-14 09:00, 2014-07-14 17:07)",
        "[2014-07-14 08:57, 2014-07-14 17:05)",
        "[2014-07-14 06:43, 2014-07-14 25:00)",
        "[2015-07-14 06:45, 2015-07-14 24:00)",
    ];
map {
        $sto->{intvls} = [
            "[2014-07-14 10:00, 2014-07-14 10:15)",
            "[2014-07-14 10:15, 2014-07-14 10:30)",
            $_,
            "[2014-07-14 11:15, 2014-07-14 11:30)",
            "[2014-07-14 11:30, 2014-07-14 11:45)",
        ];
        my $status = $sto->insert( $dbix_conn );
        is( $status->level, 'ERR' );
        is( $status->code, 'DOCHAZKA_DBI_ERR' );
        #diag( $status->code . ' ' . $status->text );
        is( noof( $dbix_conn, 'schedintvls' ), 0 );
     } @$bogus_intvls;

note( 'this set of intervals is fine' );
$sto->{intvls} = [
    "[2014-07-14 10:00, 2014-07-14 10:15)",
    "[2014-07-14 10:15, 2014-07-14 10:30)",
    "[2014-07-14 11:15, 2014-07-14 11:30)",
    "[2014-07-14 11:30, 2014-07-14 11:45)",
    "[2014-07-21 00:00, 2014-07-21 10:00)",
];
my $status = $sto->insert( $dbix_conn );
is( $status->level, 'OK' );
ok( $status->code, 'DOCHAZKA_SCHEDINTVLS_INSERT_OK' );
$status = $sto->delete( $dbix_conn );
is( $status->level, 'OK' );
ok( $status->code, 'DOCHAZKA_CUD_OK' );

note( 'these are not so good' );
$bogus_intvls = [
    "[2014-07-21 00:00, 2014-07-21 10:05)",
    "[2014-07-21 00:00, 2014-07-21 10:10)",
    "[2014-07-21 00:00, 2014-07-21 10:15)",
    "[2015-07-21 00:00, 2015-07-21 10:05)",
    "[2014-07-21 00:00, 2025-07-21 10:05)",
];
map {
        $sto->{intvls} = [
            "[2014-07-14 10:00, 2014-07-14 10:15)",
            "[2014-07-14 10:15, 2014-07-14 10:30)",
            "[2014-07-14 11:15, 2014-07-14 11:30)",
            "[2014-07-14 11:30, 2014-07-14 11:45)",
            $_,
        ];
        $status = $sto->insert( $dbix_conn );
        is( $status->level, 'ERR' );
        ok( $status->code, 'DOCHAZKA_CUD_OK' );
        like( $status->text, qr/schedule intervals must fall within a 7-day range/ );
        #diag( $status->code . ' ' . $status->text );
        is( noof( $dbix_conn, 'schedintvls' ), 0 );
     } @$bogus_intvls;

note( 'tear down' );
$status = delete_all_attendance_data();
BAIL_OUT(0) unless $status->ok;

done_testing;
