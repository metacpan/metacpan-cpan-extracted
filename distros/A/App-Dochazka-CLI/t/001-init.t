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
# create 'worker' and 'absent' employees (active and inactive privlevel)
# but only if they aren't already there -- be idempotent

#!perl
use 5.012;
use strict;
use warnings;

#use App::CELL::Test::LogToFile;
use App::Dochazka::CLI qw( $debug_mode );
use App::Dochazka::CLI::Parser qw( process_command );
use App::Dochazka::CLI::Util qw( authenticate_to_server );
use App::Dochazka::CLI::Test qw( init_unit );
use Data::Dumper;
use Test::More;
use Test::Warnings;

$debug_mode = 1;

sub create_employees_carefully {
    my ( $nick, $privlevel, $fullname ) = @_;
    my ( $cmd, $rv, $status );

    $cmd = "EMPLOYEE=$nick PROFILE";
    $rv = process_command( $cmd );
    is( ref( $rv ), 'App::CELL::Status' );
    unless ( $rv->level eq 'OK' and $rv->code eq 'DOCHAZKA_CLI_NORMAL_COMPLETION' ) {

        # create employee $nick and assign privlevel $privlevel
        $cmd = "PUT employee nick $nick { \"fullname\" : \"$fullname\", \"password\" : \"$nick\" }";
        $rv = process_command( $cmd );
        is( ref( $rv ), 'App::CELL::Status' );
        is( $rv->{'http_status'}, '200 OK' );
        is( $rv->code, 'DOCHAZKA_CUD_OK' );

        $cmd = "POST priv history nick $nick { \"priv\" : \"$privlevel\", \"effective\" : \"2000-01-01 00:00\" }";
        $rv = process_command( $cmd );
        is( ref( $rv ), 'App::CELL::Status' );
        is( $rv->{'http_status'}, '201 Created' );
        is( $rv->code, 'DOCHAZKA_CUD_OK' );

    }

}

sub create_testing_schedule {
    my ( $cmd, $rv );

    note( "Create a testing schedule" );

    $cmd = "SCHEDULE ALL 8:00-12:00";
    $rv = process_command( $cmd );
    is( ref( $rv ), 'App::CELL::Status' );
    is( $rv->level, 'OK', "process_command( $cmd ) returned OK status" );
    is( $rv->{'http_status'}, undef );

    $cmd = "SCHEDULE ALL 12:30-16:30";
    $rv = process_command( $cmd );
    is( ref( $rv ), 'App::CELL::Status' );
    is( $rv->level, 'OK', "process_command( $cmd ) returned OK status" );
    is( $rv->{'http_status'}, undef );

    $cmd = "SCHEDULE SCODE KOBOLD";
    $rv = process_command( $cmd );
    is( ref( $rv ), 'App::CELL::Status' );
    is( $rv->level, 'OK', "process_command( $cmd ) returned OK status" );
    is( $rv->{'http_status'}, undef );

    $cmd = "SCHEDULE NEW";
    $rv = process_command( $cmd );
    is( ref( $rv ), 'App::CELL::Status' );
    is( $rv->level, 'OK', "process_command( $cmd ) returned OK status" );
    is( $rv->{'http_status'}, '200 OK' );

}


my ( $cmd, $rv, $rv_type, $status );

$rv = init_unit();
$rv_type = ref( $rv );
if ( $rv_type ne 'App::CELL::Status' or $rv->not_ok ) {
    diag "init_unit returned unexpected status:";
    diag( Dumper $rv );
    BAIL_OUT(0);
}

$rv = authenticate_to_server( user => 'root', password => 'immutable', quiet => 1 );
$rv_type = ref( $rv );
if ( $rv_type ne 'App::CELL::Status' or $rv->not_ok ) {
    if ( $rv->{'http_status'} =~ m/500 Can\'t connect/ ) {
        plan skip_all => "Can't connect to server";
    } else {
        diag "authenticate_to_server returned unexpected status:";
        diag( Dumper $rv );
        BAIL_OUT(0);
    }
}

create_employees_carefully( 'worker', 'active', 'Joe Working Stiff' );

create_employees_carefully( 'absent', 'inactive', 'On Leave Dude' );

create_testing_schedule();

$cmd = "EMPLOYEE=worker SCODE=KOBOLD 2015-01-01";
$rv = process_command( $cmd );
is( ref( $rv ), 'App::CELL::Status' );
if ( $rv->level eq 'OK' ) {
    # schedule history record did not exist and was just now created
    is( $rv->code, 'DOCHAZKA_CLI_SCHEDULE_HISTORY_ADD' );
} else {
    # schedule history record already existed
    is( $rv->code, 'DOCHAZKA_DBI_ERR' );
    like( $rv->text, qr/duplicate key value violates unique constraint "schedhistory_eid_effective_key"/ );
}

done_testing;
