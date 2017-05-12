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
# test employee commands as admin user

#!perl
use 5.012;
use strict;
use warnings;
use utf8;

#use App::CELL::Test::LogToFile;
use App::CELL qw( $CELL $log $meta $site );
use App::Dochazka::CLI qw( $debug_mode );
use App::Dochazka::CLI::Parser qw( process_command );
use App::Dochazka::CLI::Test qw( init_unit );
use App::Dochazka::CLI::Util qw( authenticate_to_server );
use Data::Dumper;
use Test::More;
use Test::Warnings;

$debug_mode = 1;

my ( $cmd, $rv );

$rv = init_unit();
plan skip_all => "init_unit failed with status " . $rv->text unless $rv->ok;

$rv = authenticate_to_server( user => 'root', password => 'immutable', quiet => 1 );
if ( $rv->not_ok and $rv->{'http_status'} =~ m/500 Can\'t connect/ ) {
    plan skip_all => "Can't connect to server";
}

isnt( $meta->MREST_CLI_URI_BASE, undef, 'MREST_CLI_URI_BASE is defined after initialization' );

#=====================================
# EMPLOYEE
# EMPLOYEE SHOW
# EMPLOYEE PROFILE
# EMPLOYEE_SPEC
# EMPLOYEE_SPEC SHOW
# EMPLOYEE_SPEC PROFILE
#======================================

$cmd = "EMPLOYEE";
$rv = process_command( $cmd );
ok( ref( $rv ) eq 'App::CELL::Status' );
is( $rv->level, 'OK' );
is( $rv->code, 'DOCHAZKA_CLI_NORMAL_COMPLETION' );
like( $rv->payload, qr/Nick:\s+root/ );
like( $rv->payload, qr/Dochazka EID:\s+1/ );
#like( $rv->payload, qr/Privlevel:\s+admin/ );

$cmd = "EMPLOYEE PROFILE";
$rv = process_command( $cmd );
ok( ref( $rv ) eq 'App::CELL::Status' );
is( $rv->level, 'OK' );
is( $rv->code, 'DOCHAZKA_CLI_NORMAL_COMPLETION' );
like( $rv->payload, qr/Nick:\s+root/ );
like( $rv->payload, qr/Dochazka EID:\s+1/ );
#like( $rv->payload, qr/Privlevel:\s+admin/ );

note( 'EMPLOYEE_SPEC on self always works' );
$cmd = "EMPLOYEE=root PROFILE";
$rv = process_command( $cmd );
ok( ref( $rv ) eq 'App::CELL::Status' );
is( $rv->level, 'OK' );
like( $rv->payload, qr/Nick:\s+root/ );
like( $rv->payload, qr/Dochazka EID:\s+1/ );
#like( $rv->payload, qr/Privlevel:\s+admin/ );

note( 'EMPLOYEE_SPEC on a different employee => also works, because root is an admin' );
$cmd = "EMPLOYEE=demo SHOW";
$rv = process_command( $cmd );
ok( ref( $rv ) eq 'App::CELL::Status' );
is( $rv->level, 'OK' );
like( $rv->payload, qr/Nick:\s+demo/ );
like( $rv->payload, qr/Dochazka EID:\s+2/ );
#like( $rv->payload, qr/Privlevel:\s+passerby/ );

note( 'EMPLOYEE_SPEC on worker' );
$cmd = "EMPLOYEE=worker PROFILE";
$rv = process_command( $cmd );
ok( ref( $rv ) eq 'App::CELL::Status' );
is( $rv->level, 'OK' );
like( $rv->payload, qr/Nick:\s+worker/ );
my ( $worker_eid ) = $rv->payload =~ m/Dochazka EID:\s+(\d+)/;
like( $rv->payload, qr/Dochazka EID:\s+$worker_eid/ );
#like( $rv->payload, qr/Privlevel:\s+active/ );

note( 'EMPLOYEE_SPEC on worker, using EID instead of nick' );
$cmd = "EMPLOYEE=$worker_eid PROFILE";
$rv = process_command( $cmd );
ok( ref( $rv ) eq 'App::CELL::Status' );
is( $rv->level, 'OK' );
like( $rv->payload, qr/Nick:\s+worker/ );
like( $rv->payload, qr/Dochazka EID:\s+$worker_eid/ );
#like( $rv->payload, qr/Privlevel:\s+active/ );

note( 'EMPLOYEE_SPEC on non-existent employee' );
$cmd = "EMPLOYEE=99999 PROFILE";
$rv = process_command( $cmd );
ok( ref( $rv ) eq 'App::CELL::Status' );
is( $rv->level, 'ERR' );
is( $rv->code, 'REST_ERROR' );
like( $rv->payload, qr/DISPATCH_SEARCH_EMPTY/ );
is( $rv->{'http_status'}, '404 Not Found' );


#==========================================
# EMPLOYEE LIST
# EMPLOYEE LIST _TERM
#==========================================

note( 'Get list of all employee nicks' );
$cmd = "EMPLOYEE LIST";
$rv = process_command( $cmd );
ok( ref( $rv ) eq 'App::CELL::Status' );
is( $rv->level, 'OK' );
like( $rv->payload, qr/List of employees with priv level ->all<-/ );


#==========================================
# EMPLOYEE SET SEC_ID _TERM
# EMPLOYEE_SPEC SET SEC_ID _TERM
#==========================================

note( 'Set my own secondary ID' );
$cmd = "EMPLOYEE SET SEC_ID test123";
$rv = process_command( $cmd );
ok( ref( $rv ) eq 'App::CELL::Status' );
is( $rv->level, 'OK' );
like( $rv->payload, qr/test123/ );

note( 'Check that it has really been set' );
$cmd = "GET employee nick root";
$rv = process_command( $cmd );
ok( ref( $rv ) eq 'App::CELL::Status' );
is( $rv->level, 'OK' );
is( $rv->code, 'DISPATCH_EMPLOYEE_FOUND' );
is( $rv->payload->{'sec_id'}, 'test123' );
is( $rv->payload->{'nick'}, 'root' );

note( 'Set someone else\'s secondary ID to the same thing' );
$cmd = "EMPLOYEE=worker SET SEC_ID test123";
$rv = process_command( $cmd );
ok( ref( $rv ) eq 'App::CELL::Status' );
ok( $rv->not_ok );
like( $rv->payload, qr/duplicate key value violates unique constraint/ );

note( 'Set someone else\'s secondary ID to HAMBURG_SUBST' );
$cmd = "EMPLOYEE=worker SET SEC_ID HAMBURG_SUBST";
$rv = process_command( $cmd );
ok( ref( $rv ) eq 'App::CELL::Status' );
ok( $rv->ok );
like( $rv->payload, qr/HAMBURG_SUBST/ );

note( 'Check that it really got set to HAMBURG_SUBST' );
$cmd = "GET employee nick worker";
$rv = process_command( $cmd );
ok( ref( $rv ) eq 'App::CELL::Status' );
is( $rv->level, 'OK' );
is( $rv->code, 'DISPATCH_EMPLOYEE_FOUND' );
is( $rv->payload->{'sec_id'}, 'HAMBURG_SUBST' );
is( $rv->payload->{'nick'}, 'worker' );

#==========================================
# EMPLOYEE_SPEC can also be:
#   nick=...
#   sec_id=...
#   eid=...
#==========================================

note( "set secondary ID of worker" );
$cmd = "nick=worker SET sec_id woofer";
$rv = process_command( $cmd );
ok( ref( $rv ) eq 'App::CELL::Status' );
is( $rv->level, 'OK' );
is( $rv->code, 'DOCHAZKA_CLI_NORMAL_COMPLETION' );

note( 'nick=worker' );
$cmd = "nick=worker PROFILE";
$rv = process_command( $cmd );
ok( ref( $rv ) eq 'App::CELL::Status' );
is( $rv->level, 'OK' );
like( $rv->payload, qr/Nick:\s+worker/ );
( $worker_eid ) = $rv->payload =~ m/Dochazka EID:\s+(\d+)/;
my ( $worker_sec_id) = $rv->payload =~ m/Secondary ID:\s+(\S+)/;
like( $rv->payload, qr/Dochazka EID:\s+$worker_eid/ );
like( $rv->payload, qr/Secondary ID:\s+$worker_sec_id/ );
#like( $rv->payload, qr/Privlevel:\s+active/ );

note( 'sec_id= on worker' );
$cmd = "sec_id=$worker_sec_id PROFILE";
$rv = process_command( $cmd );
ok( ref( $rv ) eq 'App::CELL::Status' );
is( $rv->level, 'OK' );
like( $rv->payload, qr/Nick:\s+worker/ );
like( $rv->payload, qr/Dochazka EID:\s+$worker_eid/ );
like( $rv->payload, qr/Secondary ID:\s+$worker_sec_id/ );
#like( $rv->payload, qr/Privlevel:\s+active/ );

note( 'eid= on worker' );
$cmd = "eid=$worker_eid PROFILE";
$rv = process_command( $cmd );
ok( ref( $rv ) eq 'App::CELL::Status' );
is( $rv->level, 'OK' );
like( $rv->payload, qr/Nick:\s+worker/ );
like( $rv->payload, qr/Dochazka EID:\s+$worker_eid/ );
like( $rv->payload, qr/Secondary ID:\s+$worker_sec_id/ );
#like( $rv->payload, qr/Privlevel:\s+active/ );

note( 'eid= on root' );
$cmd = "eid=1 PROFILE";
$rv = process_command( $cmd );
ok( ref( $rv ) eq 'App::CELL::Status' );
is( $rv->level, 'OK' );
like( $rv->payload, qr/Nick:\s+root/ );
like( $rv->payload, qr/Dochazka EID:\s+1/ );
#like( $rv->payload, qr/Privlevel:\s+admin/ );

#==========================================
# EMPLOYEE SET FULLNAME 
# EMPLOYEE_SPEC SET FULLNAME
#==========================================

note( 'EMPLOYEE SET FULLNAME as root' );
$cmd = 'EMPLOYEE SET FULLNAME Mr. Fullneck';
$rv = process_command( $cmd );
ok( ref( $rv ) eq 'App::CELL::Status' );
is( $rv->level, 'OK' );
is( $rv->code, 'DOCHAZKA_CLI_NORMAL_COMPLETION' );
like( $rv->payload, qr/\QProfile of employee root has been modified (fullname -> Mr. Fullneck)\E/ );

note( 'Check that root\'s fullname is really Mr. Fullneck' );
$cmd = 'GET employee self';
$rv = process_command( $cmd );
ok( ref( $rv ) eq 'App::CELL::Status' );
is( $rv->level, 'OK' );
is( $rv->code, 'DISPATCH_EMPLOYEE_CURRENT' );
is( $rv->payload->{'fullname'}, 'Mr. Fullneck' );


#==========================================
# EMPLOYEE_SPEC SUPERVISOR _TERM
# EMPLOYEE_SPEC SET SUPERVISOR _TERM
#==========================================

note( $cmd = 'EMPL=absent SUPERVISOR worker' );
$rv = process_command( $cmd );
ok( ref( $rv ) eq 'App::CELL::Status' );
is( $rv->level, 'OK' );
is( $rv->code, 'DOCHAZKA_CLI_NORMAL_COMPLETION' );
like( $rv->payload, qr/Reports to:\s+worker/ );

note( $cmd = 'POST employee nick { "nick" : "absent", "supervisor" : null }' );
$rv = process_command( $cmd );
ok( ref( $rv ) eq 'App::CELL::Status' );
is( $rv->level, 'OK' );
is( $rv->code, 'DOCHAZKA_CUD_OK' );
ok( ! defined( $rv->payload->{'supervisor'} ) );

note( $cmd = 'EMPL=absent PROFILE' );
$rv = process_command( $cmd );
ok( ref( $rv ) eq 'App::CELL::Status' );
is( $rv->level, 'OK' );
is( $rv->code, 'DOCHAZKA_CLI_NORMAL_COMPLETION' );
like( $rv->payload, qr/Reports to:\s+\(not set\)/ );

note( $cmd = 'EMPL=absent SET SUPERVISOR worker' );
$rv = process_command( $cmd );
ok( ref( $rv ) eq 'App::CELL::Status' );
is( $rv->level, 'OK' );
is( $rv->code, 'DOCHAZKA_CLI_NORMAL_COMPLETION' );
like( $rv->payload, qr/Reports to:\s+worker/ );

done_testing;
