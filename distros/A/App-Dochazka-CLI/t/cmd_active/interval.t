# ************************************************************************* 
# Copyright (c) 2014-2016, SUSE LLC
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
# test INTERVAL commands as user with privlevel active

#!perl
use 5.012;
use strict;
use warnings;

use App::CELL qw( $CELL $log $meta $site );
use App::Dochazka::CLI qw( $prompt_date $prompt_century $prompt_year $prompt_month $prompt_day );
use App::Dochazka::CLI::Parser qw( process_command );
use App::Dochazka::CLI::Test qw( delete_interval_test fetch_interval_test init_unit );
use App::Dochazka::CLI::Util qw( authenticate_to_server );
use Data::Dumper;
use Test::More;
use Test::Warnings;

my ( $cmd, $rv );

$rv = init_unit();
plan skip_all => "init_unit failed with status " . $rv->text unless $rv->ok;

$rv = authenticate_to_server( user => 'worker', password => 'worker', quiet => 1 );
if ( $rv->not_ok and $rv->{'http_status'} =~ m/500 Can\'t connect/ ) {
    plan skip_all => "Can't connect to server";
}

isnt( $meta->MREST_CLI_URI_BASE, undef, 'MREST_CLI_URI_BASE is defined after initialization' );

note( 'INTERVAL displays today\'s intervals (but there are none)' );
$cmd = "INTERVAL";
$rv = process_command( $cmd );
is( ref( $rv ), 'App::CELL::Status' );
is( $rv->level, 'OK' );
like( $rv->payload, qr/No attendance intervals found in tsrange/ );

my $iid;

note( 'set prompt date to 2015-01-01' );
$cmd = "PROMPT 2015-01-01";
$rv = process_command( $cmd );
is( ref( $rv ), 'App::CELL::Status' );
is( $rv->level, 'OK' );
is( $rv->code, 'DOCHAZKA_CLI_PROMPT_DATE_CHANGED' );

note( "Prompt century, etc. have changed as expected" );
is( $prompt_century, 20 );
is( $prompt_year, 2015 );
is( $prompt_month+0, 1 );
is( $prompt_day+0, 1 );

note( 'enter an interval without specifying a date; see that prompt date is used' );
note( $cmd = "INTERVAL 6:30-7:00 WORK" );
$rv = process_command( $cmd );
is( ref( $rv ), 'App::CELL::Status' );
is( $rv->level, 'OK' );
is( $rv->code, 'DOCHAZKA_CLI_NORMAL_COMPLETION' );
( $iid ) = $rv->payload =~ m/\AInterval IID (\d+)/;
like( $rv->payload, qr/\AInterval IID \d+.*2015-01-01.*06:30.*2015-01-01.*07:00.*WORK/ms,
    "IID $iid inserted");

note( 'enter interval with non-existent activity' );
note( $cmd = "INTERVAL 6:30-7:00 PRDBANK" );
$rv = process_command( $cmd );
is( ref( $rv ), 'App::CELL::Status' );
is( $rv->level, 'ERR' );
is( $rv->code, 'DOCHAZKA_CLI_WRONG_ACTIVITY' );
like( $rv->text, qr/Activity -\>PRDBANK\<- does not exist \(use ACTIVITY ALL command to list activities\)/ );

note( 'fetch the interval' );
my $payload = fetch_interval_test( '', '' );
like( $payload, qr/06:30.+07:00/ );

delete_interval_test( $iid );

note( 'use +1 notation to specify the day after the prompt date' );
note( $cmd = "INTERVAL +1 6:30-7:00 WORK Teststr_foobarbaz" );
$rv = process_command( $cmd );
is( ref( $rv ), 'App::CELL::Status' );
is( $rv->level, 'OK' );
is( $rv->code, 'DOCHAZKA_CLI_NORMAL_COMPLETION' );
( $iid ) = $rv->payload =~ m/\AInterval IID (\d+)/;
like( $rv->payload, qr/\AInterval IID \d+.*2015-01-02.*06:30.*2015-01-02.*07:00.*WORK/ms,
    "IID $iid inserted");

note( 'fetch the interval using YYYY-MM-DD notation' );
fetch_interval_test( "2015-01-02", "Teststr_foobarbaz" );

delete_interval_test( $iid );


done_testing;
