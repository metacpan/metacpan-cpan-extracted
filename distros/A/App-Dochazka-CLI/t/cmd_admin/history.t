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
# test history commands as admin user

#!perl
use 5.012;
use strict;
use warnings;

use App::CELL qw( $CELL $log $meta $site );
use App::Dochazka::CLI::Parser qw( process_command );
use App::Dochazka::CLI::Test qw( init_unit );
use App::Dochazka::CLI::Util qw( authenticate_to_server );
use App::Dochazka::Common::Model::Privhistory;
use App::Dochazka::Common::Model::Schedhistory;
use Data::Dumper;
use Test::More;
use Test::Warnings;

my ( $cmd, $rv );

note( 'initialize unit' );
$rv = init_unit();
plan skip_all => "init_unit failed with status " . $rv->text unless $rv->ok;

note( 'authenticate to server' );
$rv = authenticate_to_server( user => 'root', password => 'immutable', quiet => 1 );
if ( $rv->not_ok and $rv->{'http_status'} =~ m/500 Can\'t connect/ ) {
    plan skip_all => "Can't connect to server";
}

isnt( $meta->MREST_CLI_URI_BASE, undef, 'MREST_CLI_URI_BASE is defined after initialization' );

note( '****************************************************************************' );
note( 'In t/001-init.t we created an employee "worker" with privlevel "active"' );
note( 'This privlevel was achieved by inserting a record in the privhistory table' );
note( 'Since t/001-init.t always runs first, we can assume that "worker" will have' );
note( 'one and only one privhistory record at this point.' );
note( '****************************************************************************' );

note( 'get the privhistory record of "worker"' );
$cmd = "GET priv history nick worker";
$rv = process_command( $cmd );
is( ref( $rv ), 'App::CELL::Status' );
is( $rv->level, 'OK' );
ok( defined $rv->payload );
ok( exists $rv->payload->{'history'} );
is( scalar @{ $rv->payload->{'history'} }, 1 );

note( 'get the PHID of that record' );
my $worker_phid = $rv->payload->{'history'}->[0]->{'phid'};
ok( $worker_phid > 1 );

note( 'display privhistory of "worker"' );
$cmd = "EMPL=worker PRIV HISTORY";
$rv = process_command( $cmd );
is( ref( $rv ), 'App::CELL::Status' );
is( $rv->level, 'OK' );
like( $rv->payload, qr/Privilege history of worker/ );

note( 'look for the PHID in the PRIV HISTORY output' );
like( $rv->payload, qr/^$worker_phid/m );

note( 'change the remark on that record' );
$cmd = "PHID=$worker_phid SET REMARK I am the walrus";
$rv = process_command( $cmd );
is( ref( $rv ), 'App::CELL::Status' );
is( $rv->level, 'OK' );
ok( defined $rv->payload );
my $ph = App::Dochazka::Common::Model::Privhistory->spawn( %{ $rv->payload } );
is( ref( $ph ), 'App::Dochazka::Common::Model::Privhistory' );
is( $ph->remark, 'I am the walrus' );

note( 're-fetch the privhistory record' );
$cmd = "GET priv history phid $worker_phid";
$rv = process_command( $cmd );
is( ref( $rv ), 'App::CELL::Status' );
is( $rv->level, 'OK' );
ok( defined $rv->payload );
my $ph_compare = App::Dochazka::Common::Model::Privhistory->spawn( %{ $rv->payload } );
is( ref( $ph_compare ), 'App::Dochazka::Common::Model::Privhistory' );
is( $ph_compare->remark, 'I am the walrus' );

note( 'get the schedhistory record of "worker"' );
$cmd = "GET schedule history nick worker";
$rv = process_command( $cmd );
is( ref( $rv ), 'App::CELL::Status' );
is( $rv->level, 'OK' );
ok( defined $rv->payload );
ok( exists $rv->payload->{'history'} );
is( scalar @{ $rv->payload->{'history'} }, 1 );

note( 'get the SHID of that record' );
my $worker_shid = $rv->payload->{'history'}->[0]->{'shid'};
ok( $worker_shid > 0 );

note( 'display schedule history of "worker"' );
$cmd = "EMPL=worker SCHEDULE HISTORY";
$rv = process_command( $cmd );
is( ref( $rv ), 'App::CELL::Status' );
is( $rv->level, 'OK' );
like( $rv->payload, qr/Schedule history of worker/ );

note( 'look for the SHID in the SCHEDULE HISTORY output' );
like( $rv->payload, qr/^$worker_shid/m );

note( 'change the remark on that record' );
$cmd = "SHID=$worker_shid SET REMARK I am the Pepik";
$rv = process_command( $cmd );
is( ref( $rv ), 'App::CELL::Status' );
is( $rv->level, 'OK' );
ok( defined $rv->payload );
my $sh = App::Dochazka::Common::Model::Schedhistory->spawn( %{ $rv->payload } );
is( ref( $sh ), 'App::Dochazka::Common::Model::Schedhistory' );
is( $sh->remark, 'I am the Pepik' );

note( 're-fetch the schedhistory record' );
$cmd = "GET schedule history shid $worker_shid";
$rv = process_command( $cmd );
is( ref( $rv ), 'App::CELL::Status' );
is( $rv->level, 'OK' );
ok( defined $rv->payload );
my $sh_compare = App::Dochazka::Common::Model::Schedhistory->spawn( %{ $rv->payload } );
is( ref( $sh_compare ), 'App::Dochazka::Common::Model::Schedhistory' );
is( $sh_compare->remark, 'I am the Pepik' );

done_testing;
