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
# basic unit tests for activities
#

#!perl
use 5.012;
use strict;
use warnings;

#use App::CELL::Test::LogToFile;
use App::CELL qw( $meta $site );
use Data::Dumper;
use App::Dochazka::REST::ConnBank qw( $dbix_conn );
use App::Dochazka::REST::Model::Activity qw( aid_by_code aid_exists code_exists get_all_activities );
use App::Dochazka::REST::Test;
use Test::Fatal;
use Test::More;
use Test::Warnings;


note( "initialize, connect to database, and set up a testing plan" );
initialize_regression_test();

note( 'spawn two activity objects' );
my $act = App::Dochazka::REST::Model::Activity->spawn;
isa_ok( $act, 'App::Dochazka::REST::Model::Activity' );
my $act2 = App::Dochazka::REST::Model::Activity->spawn;
isa_ok( $act2, 'App::Dochazka::REST::Model::Activity' );

note( 'they are the same' );
ok( $act->compare( $act2 ) );

note( 'set a property' );
my $a = "prdy vody";
$act->remark( $a );
$act2->remark( $a );
is( $act->remark, $a );
is( $act2->remark, $a );
ok( $act->compare( $act2 ) );  # still the same
ok( $act2->compare( $act ) );

$act2->remark( "jine fody" );
ok( ! $act->compare( $act2 ) );  # different

note( 'reset the activities' );
$act->reset;
$act2->reset;
ok( $act->compare( $act2 ) );
foreach my $prop ( qw( aid code long_desc disabled ) ) {
    is( $act->{$prop}, undef );
    is( $act2->{$prop}, undef );
}

note( 'test existence and viability of initial set of activities' );
note( 'this also conducts positive tests of load_by_code and load_by_aid' );
foreach my $actdef ( @{ $site->DOCHAZKA_ACTIVITY_DEFINITIONS } ) {
    my $status = App::Dochazka::REST::Model::Activity->load_by_code( $dbix_conn, $actdef->{code} );
    is( $status->code, 'DISPATCH_RECORDS_FOUND' ); 
    is( $status->level, 'OK' );
    $act = $status->payload; 
    is( $act->code, $actdef->{code} );
    is( $act->long_desc, $actdef->{long_desc} );
    is( $act->remark, 'dbinit' );
    is( $act->disabled, 0 );
    $status = App::Dochazka::REST::Model::Activity->load_by_aid( $dbix_conn, $act->aid );
    is( $status->level, 'OK' );
    is( $status->code, 'DISPATCH_RECORDS_FOUND' ); 
    $act2 = $status->payload;
    is_deeply( $act, $act2 );
}

note( 'test get_all_activities function' );
my $status = get_all_activities( $dbix_conn );
is( $status->level, 'OK' );
is( $status->code, 'DISPATCH_RECORDS_FOUND' );
is( scalar( @{ $status->payload } ), scalar( @{ $site->DOCHAZKA_ACTIVITY_DEFINITIONS } ) );
is( $status->{'count'}, scalar( @{ $site->DOCHAZKA_ACTIVITY_DEFINITIONS } ) );
my $initial_noof_act = $status->{'count'};

note( 'test some bad parameters' );
like( exception { $act2->load_by_aid( $dbix_conn, undef ) }, 
      qr/not one of the allowed types/ );
like( exception { $act2->load_by_code( $dbix_conn, undef ) }, 
      qr/not one of the allowed types/ );
like( exception { App::Dochazka::REST::Model::Activity->load_by_aid( $dbix_conn, undef ) }, 
      qr/not one of the allowed types/ );
like( exception { App::Dochazka::REST::Model::Activity->load_by_code( $dbix_conn, undef ) }, 
      qr/not one of the allowed types/ );

note( 'load non-existent activity' );
$status = App::Dochazka::REST::Model::Activity->load_by_code( $dbix_conn, 'orneryFooBarred' );
is( $status->level, 'NOTICE' );
is( $status->code, 'DISPATCH_NO_RECORDS_FOUND' );
ok( ! exists( $status->{'payload'} ) );
ok( ! defined( $status->payload ) );

note( 'load existent activity' );
$status = App::Dochazka::REST::Model::Activity->load_by_code( $dbix_conn, 'wOrK' );
is( $status->level, 'OK' );
is( $status->code, 'DISPATCH_RECORDS_FOUND' );
my $work = $status->payload;
ok( $work->aid );
ok( $work->code );
is( $work->code, 'WORK' );

my $work_aid = aid_by_code( $dbix_conn, 'WoRk' );
is( $work_aid, $work->aid, "get AID of 'WORK' using 'aid_by_code'" );
like ( exception { $work_aid = aid_by_code( $dbix_conn, ( 1..6 ) ); },
       qr/but 2 were expected/ );

is( aid_by_code( $dbix_conn, 'orneryFooBarred' ), undef, 'aid_by_code returns undef if code does not exist' );

note( 'insert an activity (success)' );
my $bogus_act = App::Dochazka::REST::Model::Activity->spawn(
    code => 'boguS',
    long_desc => 'An activity',
    remark => 'ACTIVITY',
);
note( "About to insert bogus_act" );
$status = $bogus_act->insert( $faux_context );
if ( $status->not_ok ) {
    diag( Dumper $status );
    BAIL_OUT(0);
}
is( $status->level, 'OK', "Insert activity with code 'bogus'" );
ok( defined( $bogus_act->aid ) );
ok( $bogus_act->aid > 0 );
# test code accessor method and code_to_upper trigger
is( $bogus_act->code, 'BOGUS' );
is( $bogus_act->long_desc, "An activity" );
is( $bogus_act->remark, 'ACTIVITY' );

note( 'try to insert the same activity again (fail with DOCHAZKA_DBI_ERR)' );
$status = $bogus_act->insert( $faux_context );
ok( $status->not_ok );
is( $status->level, 'ERR' );
is( $status->code, 'DOCHAZKA_DBI_ERR' );
like( $status->text, qr/Key \(code\)\=\(BOGUS\) already exists/ );

note( 'get_all_activities -> now there is one more' );
$status = get_all_activities( $dbix_conn );
is( $status->level, 'OK' );
is( $status->code, 'DISPATCH_RECORDS_FOUND' );
is( scalar( @{ $status->payload } ), ( $initial_noof_act + 1 ) );

note( 'update the activity (success)' );
$bogus_act->{code} = "bogosITYVille";
$bogus_act->{long_desc} = "A bogus activity that doesn't belong here";
$bogus_act->{remark} = "BOGUS ACTIVITY";
$bogus_act->{disabled} = 1;
#diag( "About to update bogus_act" );
$status = $bogus_act->update( $faux_context );
if ( $status->not_ok ) {
    diag( Dumper $status );
    BAIL_OUT(0);
}
is( $status->level, 'OK' );

note( 'test accessors' );
is( $bogus_act->code, 'BOGOSITYVILLE' );
is( $bogus_act->long_desc, "A bogus activity that doesn't belong here" );
is( $bogus_act->remark, 'BOGUS ACTIVITY' );
ok( $bogus_act->disabled );

note( 'update without affecting any records' );
$status = $bogus_act->update( $faux_context );
is( $status->level, 'OK' );
is( $status->code, 'DOCHAZKA_CUD_OK' );

note( 'load it and compare it' );
$status = App::Dochazka::REST::Model::Activity->load_by_code( $dbix_conn, $bogus_act->code );
is( $status->code, 'DISPATCH_RECORDS_FOUND' );
my $ba2 = $status->payload;
is( $ba2->code, 'BOGOSITYVILLE' );
is( $ba2->long_desc, "A bogus activity that doesn't belong here" );
is( $ba2->remark, 'BOGUS ACTIVITY' );

my $aid_of_bogus_act = $bogus_act->aid; 
my $code_of_bogus_act = $bogus_act->code; 

ok( aid_exists( $dbix_conn, $aid_of_bogus_act ) );
ok( code_exists( $dbix_conn, $code_of_bogus_act ) );

note( 'bogus activity is disabled, so the number of activities goes down by one' );
note( '- this also tests that get_all_activities defaults to NOT include disableds' );
$status = get_all_activities( $dbix_conn );
is( $status->level, 'OK' );
is( $status->code, 'DISPATCH_RECORDS_FOUND' );
is( $status->{'count'}, $initial_noof_act );

note( 'but if we include disableds in the count, it is one higher' );
$status = get_all_activities( $dbix_conn, disabled => 1 );
is( $status->level, 'OK' );
is( $status->code, 'DISPATCH_RECORDS_FOUND' );
is( $status->{'count'}, ( $initial_noof_act + 1 ) );
# - and BOGOSITYVILLE is there
ok( scalar( grep { $_->{'code'} eq 'BOGOSITYVILLE'; } @{ $status->payload } ) );

note( 'CLEANUP: delete the bogus activity' );
#diag( "About to delete bogus_act" );
$status = $bogus_act->delete( $faux_context );
if ( $status->not_ok ) {
    diag( Dumper $status );
    BAIL_OUT(0);
}
is( $status->level, 'OK' );

ok( ! aid_exists( $dbix_conn, $aid_of_bogus_act ) );
ok( ! code_exists( $dbix_conn, $code_of_bogus_act ) );

note( 'attempt to load the bogus activity - no longer there' );
$status = App::Dochazka::REST::Model::Activity->load_by_code( $dbix_conn, 'BOGUS' );
is( $status->level, 'NOTICE' );
is( $status->code, 'DISPATCH_NO_RECORDS_FOUND' );
is( $status->{'count'}, 0 );

note( 'look for BOGOSITYVILLE' );
$status = get_all_activities( $dbix_conn, disabled => 1 );
is( $status->level, 'OK' );
is( $status->code, 'DISPATCH_RECORDS_FOUND' );
is( $status->{'count'}, $initial_noof_act );

note( 'gone' );
ok( ! scalar( grep { $_->{'code'} eq 'BOGOSITYVILLE'; } @{ $status->payload } ) );

note( 'tear down' );
$status = delete_all_attendance_data();
BAIL_OUT(0) unless $status->ok;

done_testing;
