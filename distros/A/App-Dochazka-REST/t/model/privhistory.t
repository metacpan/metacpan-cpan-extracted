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

#!perl
use 5.012;
use strict;
use warnings;

#use App::CELL::Test::LogToFile;
use App::CELL qw( $log $meta $site );
use Data::Dumper;
use App::Dochazka::Common qw( $today $yesterday $tomorrow );
use App::Dochazka::REST::ConnBank qw( $dbix_conn );
use App::Dochazka::REST::Model::Employee;
use App::Dochazka::REST::Model::Privhistory qw( phid_exists get_privhistory );
use App::Dochazka::REST::Model::Shared qw( noof );
use App::Dochazka::REST::Test;
use Test::More;
use Test::Warnings;

note( 'initialize, connect to database, and set up a testing plan' );
initialize_regression_test();

my $today_ts = $today . " 00:00:00";
my $tomorrow_ts = $tomorrow . " 00:00:00";
my $yesterday_ts = $yesterday . " 00:00:00";

note( 'insert a testing employee' );
my $emp = App::Dochazka::REST::Model::Employee->spawn(
        nick => 'mrprivhistory',
   );
my $status = $emp->insert( $faux_context );
ok( $status->ok, "Inserted Mr. Privhistory" );

note( 'assign an initial privilege level to the employee' );
my $ins_eid = $emp->eid;
my $ins_priv = 'active';
my $ins_effective = $today_ts;
my $ins_remark = 'TESTING';
my $priv = App::Dochazka::REST::Model::Privhistory->spawn(
              eid => $ins_eid,
              priv => $ins_priv,
              effective => $ins_effective,
              remark => $ins_remark,
          );
is( $priv->phid, undef, "phid undefined before INSERT" );
$status = $priv->insert( $faux_context );
diag( $status->text ) if $status->not_ok;
ok( $status->ok, "Post-insert status ok" );
ok( $priv->phid > 0, "INSERT assigned an phid" );
is( $priv->remark, $ins_remark, "remark survived INSERT" );

note( 'do a dastardly deed (insert the same privhistory row a second time)');
my $dastardly_sh = App::Dochazka::REST::Model::Privhistory->spawn(
    eid => $ins_eid,
    priv => $ins_priv,
    effective => $ins_effective,
    remark => 'Dastardly',
);
is( ref( $dastardly_sh ), 'App::Dochazka::REST::Model::Privhistory', "privhistory object is an object" );
$status = undef;
$status = $dastardly_sh->insert( $faux_context );
is( $status->level, 'ERR', "ERR privhistory insert ERR" );
is( $status->code, 'DOCHAZKA_DBI_ERR' );
like( $status->text, qr/duplicate key value violates unique constraint \"privhistory_eid_effective_key\"/ );

note( 'get the entire privhistory record just inserted' );
$status = $priv->load_by_eid( $dbix_conn, $emp->eid );
ok( $status->ok, "No DBI error" );
is( $status->code, 'DISPATCH_RECORDS_FOUND', "Record loaded" );
$priv->reset( $status->payload );
is( $priv->eid, $ins_eid );
is( $priv->priv, $ins_priv );
like( $priv->effective, qr/$ins_effective\+\d{2}/ );
is( $priv->remark, $ins_remark );
ok( $priv->phid > 0 );

note( 'use update method to change the remark' );
$priv->remark( "I am foodom!" );
is( $priv->remark, "I am foodom!" );
$status = $priv->update( $faux_context );
ok( $status->ok, "No DBI error" );
ok( $status->code, 'DOCHAZKA_CUD_OK' );
isnt( $priv->remark, $ins_remark );
is( $priv->remark, "I am foodom!" );

note( 'spawn a fresh object and try it again' );
$status = App::Dochazka::REST::Model::Privhistory->load_by_eid( $dbix_conn, $emp->eid );
ok( $status->ok, "No DBI error" );
is( $status->code, 'DISPATCH_RECORDS_FOUND', "Record loaded" );
my $priv2 = $status->payload;
is( $priv2->eid, $ins_eid );
is( $priv2->priv, $ins_priv );
like( $priv2->effective, qr/$ins_effective\+\d{2}/ );
is( $priv2->remark, "I am foodom!" );

note( 'get Mr. Priv History\'s priv level as of yesterday' );
$status = App::Dochazka::REST::Model::Privhistory->load_by_eid( $dbix_conn, $emp->eid, $yesterday_ts );
is( $status->level, 'NOTICE' );
is( $status->code, 'DISPATCH_NO_RECORDS_FOUND', "Shouldn't return any rows" );
is( $emp->priv( $dbix_conn, $yesterday_ts ), 'passerby' );
is( $emp->priv( $dbix_conn, $today_ts ), 'active' );

note( 'Get Mr. Privhistory\'s record again' );
$status = App::Dochazka::REST::Model::Privhistory->load_by_eid( $dbix_conn, $emp->eid );
ok( $status->ok, "No DBI error" );
is( $status->code, 'DISPATCH_RECORDS_FOUND', "Record loaded" );
$priv->reset( $status->payload );
#diag( Dumper( $priv ) );

note( 'Count of privhistory records should be 2' );
is( noof( $dbix_conn, "privhistory" ), 2 );

note( 'test get_privhistory' );
$status = get_privhistory( $faux_context, eid => $emp->eid, tsrange => "[$today_ts, $tomorrow_ts)" );
ok( $status->ok, "Privhistory record found" );
my $ph = $status->payload->{'history'};
is( scalar @$ph, 1, "One record" );

note( 'backwards tsrange triggers DBI error' );
$status = get_privhistory( $faux_context, eid => $emp->eid, tsrange => "[$tomorrow_ts, $today_ts)" );
is( $status->level, 'ERR' );
is( $status->code, 'DOCHAZKA_DBI_ERR', "backwards tsrange triggers DBI error" );

note( 'add another record within the range' );
my $priv3 = App::Dochazka::REST::Model::Privhistory->spawn(
              eid => $ins_eid,
              priv => 'passerby',
              effective => "$today 02:00",
              remark => $ins_remark,
          );
is( $priv3->phid, undef, "phid undefined before INSERT" );
$status = $priv3->insert( $faux_context );
diag( $status->text ) if $status->not_ok;
ok( $status->ok, "Post-insert status ok" );
ok( $priv3->phid > 0, "INSERT assigned an phid" );

note( 'test get_privhistory again -- do we get two records?' );
$status = get_privhistory( $faux_context, eid => $emp->eid, tsrange => "[$today_ts, $tomorrow_ts)" );
ok( $status->ok, "Privhistory record found" );
$ph = $status->payload->{'history'};
is( scalar @$ph, 2, "Two records" );
#diag( Dumper( $ph ) );

note( 'delete the privhistory records we just inserted' );
foreach my $priv_fields ( @$ph ) {
    my $priv = App::Dochazka::REST::Model::Privhistory->spawn( %$priv_fields );
    my $phid = $priv->phid;
    ok( phid_exists( $dbix_conn, $phid ) );
    $status = $priv->delete( $faux_context );
    ok( ! phid_exists( $dbix_conn, $phid ) );
    ok( $status->ok, "DELETE OK" );
    $priv->reset;
    $status = $priv->load_by_id( $dbix_conn, $phid );
    is( $status->level, "NOTICE" );
    is( $status->code, 'DISPATCH_NO_RECORDS_FOUND' );
}

note( 'After deleting all the records we inserted, there should still be' );
note( "one left (root's)" );
is( noof( $dbix_conn, "privhistory" ), 1 );

note( 'Total number of employees should now be 2 (root, demo and Mr. Privhistory)' );
is( noof( $dbix_conn, 'employees' ), 3 );

note( 'Delete Mr. Privhistory himself, too, to clean up' );
$status = $emp->delete( $faux_context );
ok( $status->ok );
is( noof( $dbix_conn, 'employees' ), 2 );

note( 'tear down' );
$status = delete_all_attendance_data();
BAIL_OUT(0) unless $status->ok;

done_testing;
