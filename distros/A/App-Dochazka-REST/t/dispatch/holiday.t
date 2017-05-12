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
# test 'holiday' top-level resources
#

#!perl
use 5.012;
use strict;
use warnings;

#use App::CELL::Test::LogToFile;
use App::CELL qw( $meta $site );
use App::Dochazka::REST::Test;
use Data::Dumper;
use JSON;
use Plack::Test;
use Test::JSON;
use Test::More;
use Test::Warnings;

#plan skip_all => "WIP";

note( "initialize, connect to database, and set up a testing plan" );
my $app = initialize_regression_test();

note( "instantiate Plack::Test object");
my $test = Plack::Test->create( $app );

#diag( "Just created a " . ref( $test ) . " object for testing" );

my $res;


#=============================
# "/holiday/:tsrange" resource
#=============================
docu_check($test, "holiday/:tsrange");

note( "provoke a 400 error (1)" );
$res = req( $test, 400, 'demo', 'GET', 'holiday/[,)' );
is( $res->level, 'ERR' );
is( $res->code, 'DOCHAZKA_UNBOUNDED_TSRANGE' );

note( "provoke a 400 error (2)" );
$res = req( $test, 400, 'demo', 'GET', 'holiday/[2015-01-01,)' );
is( $res->level, 'ERR' );
is( $res->code, 'DOCHAZKA_UNBOUNDED_TSRANGE' );

note( "provoke a 400 error (3)" );
$res = req( $test, 400, 'demo', 'GET', 'holiday/[,2015-01-01)' );
is( $res->level, 'ERR' );
is( $res->code, 'DOCHAZKA_UNBOUNDED_TSRANGE' );

note( "range with explicit infinity (1)" );
$res = req( $test, 400, 'demo', 'GET', 'holiday/[ "1-nov-2014",infinity )' );
is( $res->level, 'ERR' );
is( $res->code, 'DOCHAZKA_UNBOUNDED_TSRANGE' );

note( "range with explicit infinity (2)" );
$res = req( $test, 400, 'demo', 'GET', 'holiday/[,infinity )' );
is( $res->level, 'ERR' );
is( $res->code, 'DOCHAZKA_UNBOUNDED_TSRANGE' );

note( "range with explicit infinity (3)" );
$res = req( $test, 400, 'demo', 'GET', 'holiday/[ infinity, infinity )' );
is( $res->level, 'ERR' );
is( $res->code, 'DOCHAZKA_UNBOUNDED_TSRANGE' );

note( "provoke a 500 error (1)" );
$res = req( $test, 500, 'demo', 'GET', 'holiday/[ , )' );
is( $res->level, 'ERR' );
is( $res->code, 'DOCHAZKA_DBI_ERR' );

note( "provoke a 500 error (2)" );
$res = req( $test, 500, 'demo', 'GET', 'holiday/[ 2015-01-01, )' );
is( $res->level, 'ERR' );
is( $res->code, 'DOCHAZKA_DBI_ERR' );

note( "provoke a 500 error (3)" );
$res = req( $test, 500, 'demo', 'GET', 'holiday/[ ,2015-01-01 )' );
is( $res->level, 'ERR' );
is( $res->code, 'DOCHAZKA_DBI_ERR' );

note( "provoke a 500 error (4)" );
$res = req( $test, 500, 'demo', 'GET', 'holiday/[ , infinity )' );
is( $res->level, 'ERR' );
is( $res->code, 'DOCHAZKA_DBI_ERR' );

note( "legal range 1" );
$res = req( $test, 200, 'demo', 'GET', 'holiday/[ 2014-04-23,2015-01-01 )' );
is( $res->level, 'OK' );
is( $res->code, 'DOCHAZKA_HOLIDAYS_IN_TSRANGE' );
ok( $res->payload );
is( ref( $res->payload ), 'HASH' );

note( "legal range 2" );
$res = req( $test, 200, 'demo', 'GET', 'holiday/["May 1, 2013", "February 4, 2015")' );
is( $res->level, 'OK' );
is( $res->code, 'DOCHAZKA_HOLIDAYS_IN_TSRANGE' );
ok( $res->payload );
is( ref( $res->payload ), 'HASH' );
is_deeply( $res->payload, {
         '2013-05-01' => '',
         '2013-05-08' => '',
         '2013-07-05' => '',
         '2013-07-06' => '',
         '2013-09-28' => '',
         '2013-10-28' => '',
         '2013-11-17' => '',
         '2013-12-24' => '',
         '2013-12-25' => '',
         '2013-12-26' => '',
         '2014-01-01' => '',
         '2014-04-20' => '',
         '2014-04-21' => '',
         '2014-05-01' => '',
         '2014-05-08' => '',
         '2014-07-05' => '',
         '2014-07-06' => '',
         '2014-09-28' => '',
         '2014-10-28' => '',
         '2014-11-17' => '',
         '2014-12-24' => '',
         '2014-12-25' => '',
         '2014-12-26' => '',
         '2015-01-01' => '',
} );

note( 'tear down' );
my $status = delete_all_attendance_data();
BAIL_OUT(0) unless $status->ok;

done_testing;
