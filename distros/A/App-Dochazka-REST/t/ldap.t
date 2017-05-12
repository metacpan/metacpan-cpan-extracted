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
# LDAP authentication unit - runs only if $site->DOCHAZKA_LDAP is true
#

#!perl
use 5.012;
use strict;
use warnings;

#use App::CELL::Test::LogToFile;
use App::CELL qw( $meta $site );
use Data::Dumper;
use App::Dochazka::REST::ConnBank qw( $dbix_conn );
use App::Dochazka::REST::Model::Employee qw( nick_exists );
use App::Dochazka::REST::Test;
use Plack::Test;
use Test::More;
use Test::Warnings;


note( 'initialize, connect to database, and set up a testing plan' );
my $app = initialize_regression_test();

note( 'instantiate Plack::Test object' );
my $test = Plack::Test->create( $app );
isa_ok( $test, 'Plack::Test::MockHTTP' );

SKIP: {
    skip "LDAP testing disabled", 2 unless $site->DOCHAZKA_LDAP;
    diag( "DOCHAZKA_LDAP is " . $site->DOCHAZKA_LDAP );

    my $ex = $site->DOCHAZKA_LDAP_TEST_UID_EXISTENT;
    my $noex = $site->DOCHAZKA_LDAP_TEST_UID_NON_EXISTENT;
    my ( $emp, $status );


    note( '####################################################' );
    note( 'TESTS OF THE ldap_exists() FUNCTION' );
    note( '####################################################' );

    note( 'known existent LDAP user exists in LDAP' );
    ok( App::Dochazka::REST::LDAP::ldap_exists( $ex ) );

    note( 'known non-existent LDAP user does not exist in LDAP' );
    ok( ! App::Dochazka::REST::LDAP::ldap_exists( $noex ) );


    note( '####################################################' );
    note( 'DATA MODEL TESTS' );
    note( '####################################################' );

    note( 'create object for LDAP user' );
    my $ex_obj = App::Dochazka::REST::Model::Employee->spawn(
        'nick' => $ex,
        'sync' => 1,
    );
    my $noex_obj = App::Dochazka::REST::Model::Employee->spawn(
        'nick' => $noex,
        'sync' => 1,
    );
    my $root_obj = App::Dochazka::REST::Model::Employee->spawn(
        'nick' => 'root',
        'sync' => 1,
    );

    note( "System users cannot be synced from LDAP" );
    $emp = $root_obj->clone();
    $status = $emp->ldap_sync();
    ok( $status->not_ok, "Employee sync operation failed" );
    is( $status->code, 'DOCHAZKA_LDAP_SYSTEM_USER_NOSYNC', "and for the right reason" );

    note( "Test that existing LDAP user can be synced" );
    note( "------------------------------------------" );

    note( "1. assert that $ex employee object has non-nick properties unpopulated" );
    $emp = $ex_obj->clone();
    my @props = grep( !/^nick/, keys( %{ $site->DOCHAZKA_LDAP_MAPPING } ) );
    foreach my $prop ( @props ) {
        is( $emp->{$prop}, undef, "$prop property is undef" );
    }

    note( "2. populate $ex employee object from LDAP: succeed" );
    $status = $emp->ldap_sync();
    diag( Dumper $status ) unless $status->ok;
    ok( $status->ok, "Employee sync operation succeeded" );
    is( $status->code, 'DOCHAZKA_LDAP_SYNC_SUCCESS' );

    note( "3. assert that mapped properties now have values - these could only have come from LDAP" );
    foreach my $prop ( @props ) {
        ok( $emp->{$prop}, "$prop property has value " . $emp->{$prop} );
    }

    note( "Test that non-existing LDAP user can *not* be synced" );
    note( "----------------------------------------------------" );

    note( "1. populate $noex employee object from LDAP: fail" );
    $emp = $noex_obj->clone();
    $status = $emp->ldap_sync();
    ok( $status->not_ok );


    note( '####################################################' );
    note( 'DISPATCH TESTS' );
    note( '####################################################' );

    note( "GET employee/nick/$noex/ldap returns 404" );
    req( $test, 404, 'root', 'GET', "employee/nick/$noex/ldap" );

    note( "PUT employee/nick/$noex/ldap returns 404" );
    req( $test, 404, 'root', 'PUT', "employee/nick/$noex/ldap" );

    note( "GET employee/nick/$ex/ldap returns 200" );
    $status = req( $test, 200, 'root', 'GET', "employee/nick/$ex/ldap" );
    is( $status->level, 'OK' );
    ok( $status->payload, "There is a payload" );
    map {
        my $value = $status->payload->{$_};
        ok( $value, "$_ property has value $value" );
    } @props;

    note( 'Ensure that LDAP user does not exist in Dochazka database' );
    $status = App::Dochazka::REST::Model::Employee->load_by_nick( $dbix_conn, $ex ); 
    $emp->delete( $faux_context ) if $status->ok;

    note( 'Assert that LDAP user does not exist in Dochazka database' );
    $status = App::Dochazka::REST::Model::Employee->load_by_nick( $dbix_conn, $ex ); 
    is( $status->level, 'NOTICE' );
    is( $status->code, 'DISPATCH_NO_RECORDS_FOUND', "nick doesn't exist" );
    is( $status->{'count'}, 0, "nick doesn't exist" );
    ok( ! exists $status->{'payload'} );
    ok( ! defined( $status->payload ) );

    note( "PUT employee/nick/$ex/ldap" );
    $status = req( $test, 200, 'root', 'PUT', "employee/nick/$ex/ldap" );
    is( $status->level, 'OK' );
    is( $status->code, 'DOCHAZKA_CUD_OK' );

    note( "Assert that $ex employee exists in Dochazka database" );
    $status = App::Dochazka::REST::Model::Employee->load_by_nick( $dbix_conn, $ex ); 
    is( $status->code, 'DISPATCH_RECORDS_FOUND', "Nick $ex exists" );
    $emp = $status->payload;
    is( $emp->nick, $ex, "Nick is the right string" );

    note( "Assert that mapped properties have values" );
    foreach my $prop ( @props ) {
        ok( $emp->{$prop}, "$prop property has value " . $emp->{$prop} );
    }

    note( "Assert that employee $ex is a passerby" );
    is( $emp->nick, $ex );
    is( $emp->priv( $dbix_conn ), 'passerby' );
    my $eid = $emp->eid;
    ok( $eid > 0 );

    note( "Make $ex an active employee" );
    $status = req( $test, 201, 'root', 'POST', "priv/history/eid/$eid", 
        "{ \"effective\":\"1892-01-01\", \"priv\":\"active\" }" );
    ok( $status->ok, "New privhistory record created for $ex" );
    is( $status->code, 'DOCHAZKA_CUD_OK', "Status code is as expected" );

    note( "Employee $ex is an active" );
    is( $emp->priv( $dbix_conn ), 'active' );

    note( "Depopulate fullname field" );
    my $saved_fullname = $emp->fullname;
    $emp->fullname( undef );
    is( $emp->fullname, undef );
    $status = $emp->update( $faux_context );
    ok( $status->ok );

    note( "Assert that fullname field is empty" );
    $status = req( $test, 200, 'root', 'GET', "employee/nick/$ex" );
    is( $status->level, 'OK' );
    is( $status->payload->{fullname}, undef );

    note( "Set password of employee $ex to \"$ex\"" );
    $status = req( $test, 200, 'root', 'PUT', "employee/nick/$ex", 
        "{\"password\":\"$ex\"}" );
    is( $status->level, 'OK' );

    note( "PUT employee/nick/$ex/ldap" );
    $status = req( $test, 200, $ex, 'PUT', "employee/nick/$ex/ldap" );
    is( $status->level, 'OK' );

    note( "Assert that fullname field is populated as expected" );
    $status = req( $test, 200, 'root', 'GET', "employee/nick/$ex" );
    is( $status->level, 'OK' );
    is( $status->payload->{fullname}, $saved_fullname );

    note( "Cleanup" );
    $status = delete_all_attendance_data();
    BAIL_OUT(0) unless $status->ok;
}

done_testing;
