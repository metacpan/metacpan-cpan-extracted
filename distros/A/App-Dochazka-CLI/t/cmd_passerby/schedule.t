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
# test schedule commands as a passerby

#!perl
use 5.012;
use strict;
use warnings;

use App::CELL qw( $CELL $log $meta $site );
use App::Dochazka::CLI::Parser qw( process_command );
use App::Dochazka::CLI::Test qw( init_unit );
use App::Dochazka::CLI::Util qw( authenticate_to_server );
use Data::Dumper;
use Test::More;
use Test::Warnings;

my ( $cmd, $rv );

note( 'initialize unit' );
$rv = init_unit();
plan skip_all => "init_unit failed with status " . $rv->text unless $rv->ok;

note( 'authenticate to server' );
$rv = authenticate_to_server( user => 'demo', password => 'demo', quiet => 1 );
if ( $rv->not_ok and $rv->{'http_status'} =~ m/500 Can\'t connect/ ) {
    plan skip_all => "Can't connect to server";
}

isnt( $meta->MREST_CLI_URI_BASE, undef, 'MREST_CLI_URI_BASE is defined after initialization' );

$cmd = "SCHEDULE DUMP";
$rv = process_command( $cmd );
is( ref( $rv ), 'App::CELL::Status' );
is( $rv->level, 'OK' );
is( $rv->code, 'DOCHAZKA_CLI_MEMSCHED_EMPTY' );
is( $rv->payload, '' );

$cmd = "SCHEDULE MEMORY";
$rv = process_command( $cmd );
is( ref( $rv ), 'App::CELL::Status' );
is( $rv->level, 'OK' );
is( $rv->code, 'DOCHAZKA_CLI_MEMSCHED_EMPTY' );
is( $rv->payload, '' );

$cmd = 'SCHEDULE MON 8:00-12:30';
$rv = process_command( $cmd );
is( ref( $rv ), 'App::CELL::Status' );
is( $rv->level, 'OK' );
is( $rv->code, 'DOCHAZKA_CLI_MEMSCHED' );
like( $rv->payload, qr/\A\Q[ MON 08:00, MON 12:30 )\E\n\z/ );

$cmd = 'SCHEDULE CLEAR';
$rv = process_command( $cmd );
is( ref( $rv ), 'App::CELL::Status' );
is( $rv->level, 'OK' );
is( $rv->code, 'DOCHAZKA_CLI_MEMSCHED_EMPTY' );

$cmd = "SCHEDULE MEMORY";
$rv = process_command( $cmd );
is( ref( $rv ), 'App::CELL::Status' );
is( $rv->level, 'OK' );
is( $rv->code, 'DOCHAZKA_CLI_MEMSCHED_EMPTY' );
is( $rv->payload, '' );

$cmd = "SCHEDULE ALL 9:30-11:00";
$rv = process_command( $cmd );
is( ref( $rv ), 'App::CELL::Status' );
is( $rv->level, 'OK' );
is( $rv->payload, '[ MON 09:30, MON 11:00 )
[ TUE 09:30, TUE 11:00 )
[ WED 09:30, WED 11:00 )
[ THU 09:30, THU 11:00 )
[ FRI 09:30, FRI 11:00 )
');

# doing the same thing again does not add any new entries ...
$cmd = "SCHEDULE ALL 9:30-11:00";
$rv = process_command( $cmd );
is( ref( $rv ), 'App::CELL::Status' );
is( $rv->level, 'OK' );
is( $rv->payload, '[ MON 09:30, MON 11:00 )
[ TUE 09:30, TUE 11:00 )
[ WED 09:30, WED 11:00 )
[ THU 09:30, THU 11:00 )
[ FRI 09:30, FRI 11:00 )
');

# ... but even a slight difference enables the entries
# to be added, even though the schedule is hopeless
# and will never make it into the database
$cmd = "SCHEDULE ALL 9:30-11:01";
$rv = process_command( $cmd );
is( ref( $rv ), 'App::CELL::Status' );
is( $rv->level, 'OK' );
is( $rv->payload, '[ MON 09:30, MON 11:00 )
[ MON 09:30, MON 11:01 )
[ TUE 09:30, TUE 11:00 )
[ TUE 09:30, TUE 11:01 )
[ WED 09:30, WED 11:00 )
[ WED 09:30, WED 11:01 )
[ THU 09:30, THU 11:00 )
[ THU 09:30, THU 11:01 )
[ FRI 09:30, FRI 11:00 )
[ FRI 09:30, FRI 11:01 )
');

done_testing;
