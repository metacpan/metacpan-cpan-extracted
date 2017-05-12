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
# Tests for Util.pm functions:
# + authenticate_to_server
#

#!perl
use 5.012;
use strict;
use warnings;

use App::CELL qw( $CELL $log $meta $site );
use App::Dochazka::CLI qw( $current_emp $current_priv );
use App::Dochazka::CLI::Test qw( init_unit );
use App::Dochazka::CLI::Util qw( authenticate_to_server );
use Data::Dumper;
use Test::More;
use Test::Warnings;

my ( $status, $rv, $rv_type );

note( 'init_cli_client' );
$rv = init_unit();
diag( Dumper $rv ) unless $rv->ok;

note( 'authenticate_to_server as root' );
$rv = authenticate_to_server( user => 'root', password => 'immutable', quiet => 1 );
if ( $rv->not_ok and $rv->{'http_status'} =~ m/500 Can\'t connect/ ) {
    plan skip_all => "Can't connect to server";
}

isnt( $meta->MREST_CLI_URI_BASE, undef, 'MREST_CLI_URI_BASE is defined after initialization' );

#note( "authenticate to server with no arguments" );
#is( $current_emp, undef, '$current_emp is undefined before authentication' );
#is( $current_priv, undef, '$current_priv is undefined before authentication' );
#$rv = authenticate_to_server();
#is( $rv->level, 'OK' );
#is( $rv->code, 'DOCHAZKA_CLI_AUTHENTICATION_OK' );
#is( $meta->CURRENT_EMPLOYEE_NICK, 'demo', 'authenticate_to_server nick defaults to demo' );
#is( $meta->CURRENT_EMPLOYEE_PASSWORD, 'demo', 'authenticate_to_server password defaults to demo' );
#is( ref( $current_emp ), 'App::Dochazka::Common::Model::Employee', 'authenticate_to_server created Employee object' );
#is( $current_emp->nick, 'demo', 'the Employee object has the right nick' );
#is( $current_priv, 'passerby', 'authenticate_to_server set $current_priv properly' );

done_testing;
