# *************************************************************************
# Copyright (c) 2014-2017, SUSE LLC
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
use App::CELL qw( $meta $site );
use Data::Dumper;
use App::Dochazka::REST::ConnBank qw( $dbix_conn );
use App::Dochazka::REST::Model::Employee qw(
    eid_exists
    get_all_sync_employees
    list_employees_by_priv
    nick_exists
);
use App::Dochazka::REST::Model::Shared qw( noof );
use App::Dochazka::REST::Test;
use Test::Fatal;
use Test::More;
use Test::Warnings;

note( 'initialize, connect to database, and set up a testing plan' );
initialize_regression_test();

note( 'get EID of root employee from DOCHAZKA_EID_OF_ROOT site parameter' );
# (root employee is created at dbinit time)
my $eid_of_root = $site->DOCHAZKA_EID_OF_ROOT;
ok( $eid_of_root, "EID of root is not zero or undef" );

note( 'define some helper subroutines' );

sub test_root_accessors {
    my $emp = shift;
    is( $emp->remark, 'dbinit' );
    is( $emp->supervisor, undef );
    is( $emp->sec_id, undef );
    is( $emp->nick, 'root' );
    is( $emp->eid, $eid_of_root );
    is( $emp->priv( $dbix_conn ), 'admin' );
    is( $emp->schedule( $dbix_conn ), undef );
    is( $emp->email, 'root@site.org' );
    is( $emp->fullname, 'Root Immutable' );
}

note( 'get initial number of employees' );
my $noof_employees = noof( $dbix_conn, 'employees' );
is( $noof_employees, 2, 'initial number of employees is 2' );

note( 'get initial employee nicks' );
my $status = list_employees_by_priv( $dbix_conn, 'all' );
test_employee_list( $status, [ 'demo', 'root' ] );

note( 'attempt to spawn an employee with an illegal attribute' );
like( exception { App::Dochazka::REST::Model::Employee->spawn( 'hooligan' => 'sneaking in' ); }, 
      qr/not listed in the validation options: hooligan/ );

note( 'spawn an empty employee object' );
my $emp = App::Dochazka::REST::Model::Employee->spawn;
is( ref( $emp ), 'App::Dochazka::REST::Model::Employee' );
isa_ok( $emp, 'App::Dochazka::REST::Model::Employee' );

note( 'try to reset the object in an illegal manner' );
like( exception { $emp->reset( 'hooligan' => 'sneaking in' ); }, 
      qr/not listed in the validation options: hooligan/ );

note( 'attempt to load a non-existent nick' );
$status = App::Dochazka::REST::Model::Employee->load_by_nick( $dbix_conn, 'mrfu' ); 
is( $status->level, 'NOTICE' );
is( $status->code, 'DISPATCH_NO_RECORDS_FOUND', "Mr. Fu's nick doesn't exist" );
is( $status->{'count'}, 0, "Mr. Fu's nick doesn't exist" );
ok( ! exists $status->{'payload'} );
ok( ! defined( $status->payload ) );

note( 'attempt to load root by nick' );
$status = App::Dochazka::REST::Model::Employee->load_by_nick( $dbix_conn, 'root' ); 
is( $status->level, 'OK' );
is( $status->code, 'DISPATCH_RECORDS_FOUND', "Root employee loaded into object" );
isa_ok( $status->payload, 'App::Dochazka::REST::Model::Employee' );

note( 'probe the object containing the root employee, using test_root_accessors()' );
test_root_accessors( $status->payload );

note( 're-load root employee, by EID this time' );
$status = App::Dochazka::REST::Model::Employee->load_by_eid( $dbix_conn, $eid_of_root ); 
is( $status->level, 'OK' );
is( $status->code, 'DISPATCH_RECORDS_FOUND', "Root employee loaded into object" );
isa_ok( $status->payload, 'App::Dochazka::REST::Model::Employee' );

note( 'probe the object containing the root employee, using test_root_accessors()' );
test_root_accessors( $status->payload );

note( 'get priv level of root using priv accessor' );
is( $status->payload->priv( $dbix_conn ), 'admin', "root is an admin" );

note( 'spawn an employee object for Mr. Fu' );
$emp = App::Dochazka::REST::Model::Employee->spawn( 
    nick => 'mrfu',
    fullname => 'Mr. Fu',
    email => 'mrfu@example.com',
    sec_id => 1024,
);
isa_ok( $emp, 'App::Dochazka::REST::Model::Employee' );

note( 'insert Mr. Fu into employees table' );
$status = $emp->insert( $faux_context );
is( $status->level, 'OK', "Mr. Fu inserted" );
my $eid_of_mrfu = $emp->{eid};
#diag( "eid of mrfu is $eid_of_mrfu" );
is( noof( $dbix_conn, 'employees' ), 3, "Total number of employees is now 3" );
$status = list_employees_by_priv( $dbix_conn, 'all' );
test_employee_list( $status, [ 'demo', 'mrfu', 'root' ] );

note( 'load Mr. Fu by secondary ID (success)' );
$status = App::Dochazka::REST::Model::Employee->load_by_sec_id( $dbix_conn, 1024 );
is( $status->level, 'OK' );
is( $status->code, 'DISPATCH_RECORDS_FOUND', "load_by_sec_id returned OK status" );

note( 'load Mr. Fu by secondary ID (failure)' );
$status = App::Dochazka::REST::Model::Employee->load_by_sec_id( $dbix_conn, 1025 );
is( $status->level, 'NOTICE' );
is( $status->code, 'DISPATCH_NO_RECORDS_FOUND', "load_by_sec_id returned OK status" );

note( 'nick_exists and eid_exists functions' );
ok( nick_exists( $dbix_conn, 'mrfu' ) );
ok( nick_exists( $dbix_conn, 'root' ) );
ok( nick_exists( $dbix_conn, 'demo' ) );
ok( eid_exists( $dbix_conn, $eid_of_mrfu ) );  
ok( eid_exists( $dbix_conn, $eid_of_root ) );  
ok( ! nick_exists( $dbix_conn, 'fandango' ) ); 
ok( ! nick_exists( $dbix_conn, 'barbarian' ) ); 
ok( ! eid_exists( $dbix_conn, 1341 ) ); 
ok( ! eid_exists( $dbix_conn, 554 ) ); 

note( 'spawn another object (still Mr. Fu)' );
$status = App::Dochazka::REST::Model::Employee->load_by_eid( $dbix_conn, $eid_of_mrfu );
is( $status->code, 'DISPATCH_RECORDS_FOUND', "load_by_eid returned OK status" );
my $mrfu = $status->payload;
is( $mrfu->{eid}, $eid_of_mrfu, "EID matches that of Mr. Fu" );
is( $mrfu->{nick}, 'mrfu', "Nick should be mrfu" );

note( 'get_all_sync_employees() returns nothing' );
$status = get_all_sync_employees( $dbix_conn );
is( $status->level, 'NOTICE' );
is( $status->code, 'DISPATCH_NO_RECORDS_FOUND' );

note( 'set Mr. Fu sync property to true' );
ok( ! $mrfu->sync );
is( $mrfu->sync, 0 );
$mrfu->sync( 1 );
ok( $mrfu->sync );
is( $mrfu->sync, 1 );

note( 'update Mr. Fu database record' );
$status = $mrfu->update( $faux_context );
is( $status->level, 'OK', 'Mr. Fu database record updated' );
is( $status->code, 'DOCHAZKA_CUD_OK' );
ok( $status->payload );
is( $status->payload->sync, 1 );

note( 'get_all_sync_employees() returns Mr. Fu' );
$status = get_all_sync_employees( $dbix_conn );
is( $status->level, 'OK' );
is( $status->code, 'DISPATCH_RECORDS_FOUND' );
ok( $status->payload );
is( ref( $status->payload ), 'ARRAY' );
is( scalar( @{ $status->payload } ), 1 );
is( $status->payload->[0]->nick, 'mrfu' );

note( 'spawn Mrs. Fu object' );
$emp = App::Dochazka::REST::Model::Employee->spawn( 
    nick => 'mrsfu',
    sec_id => 78923,
    email => 'consort@futown.orient.cn',
    fullname => 'Mrs. Fu',
);
isa_ok( $emp, 'App::Dochazka::REST::Model::Employee' );

note( 'insert Mrs. Fu into employees table' );
$status = $emp->insert( $faux_context );
ok( $status->ok, "Mrs. Fu inserted" );
my $eid_of_mrsfu = $emp->{eid};
isnt( $eid_of_mrsfu, $eid_of_mrfu, "Mr. and Mrs. Fu are distinct entities" );

note( 'recycle the object by assigning undef to each attribute' );
$status = $emp->reset;
foreach my $prop ( App::Dochazka::REST::Model::Employee->attrs ) {
    is( $emp->get( $prop), undef );
}

note( 'attempt to load a non-existent EID' );
$status = $emp->load_by_eid( $dbix_conn, 443 );
is( $status->level, 'NOTICE' );
is( $status->code, 'DISPATCH_NO_RECORDS_FOUND', "Nick ID 443 does not exist" );
is( $status->{'count'}, 0, "Nick ID 443 does not exist" );

note( 'attempt to load a non-existent nick' );
$status = $emp->load_by_nick( $dbix_conn, 'smithfarm' );
is( $status->level, 'NOTICE' );
is( $status->code, 'DISPATCH_NO_RECORDS_FOUND' );
is( $status->{'count'}, 0 );

note( 'load Mrs. Fu' );
$status = $emp->load_by_nick( $dbix_conn, 'mrsfu' );
is( $status->code, 'DISPATCH_RECORDS_FOUND', "Nick mrsfu exists" );
$emp = $status->payload;
is( $emp->nick, 'mrsfu', "Mrs. Fu's nick is the right string" );
is( $emp->sec_id, 78923, "Mrs. Fu's secondary ID is the right string" );

note( 'update Mrs. Fu by setting fullname attribute to a new value' );
$emp->fullname( "Mrs. Fu that's Ma'am to you" );
is( $emp->fullname, "Mrs. Fu that's Ma'am to you" );
$status = $emp->update( $faux_context );
ok( $status->ok, "UPDATE status is OK" );
$status = App::Dochazka::REST::Model::Employee->load_by_nick( $dbix_conn, 'mrsfu' );
is( $status->code, 'DISPATCH_RECORDS_FOUND', "Nick mrsfu exists" );
my $emp2 = $status->payload;
is_deeply( $emp, $emp2 );

note( "pathologically change Mrs. Fu's nick to null" );
my $saved_nick = $emp->nick;
$emp->{'nick'} = undef;
$status = $emp->update( $faux_context );
ok( $status->not_ok );
is( $status->level, 'ERR' );
is( $status->code, 'DOCHAZKA_DBI_ERR' );
$emp->nick( $saved_nick );

note( "attempt to change Mr. Fu's supervisor to Mr. Fu - i.e. he would supervise himself" );
$mrfu->supervisor( $eid_of_mrfu );
$status = $mrfu->update( $faux_context );
is( $status->level, 'ERR' );
is( $status->code, 'DOCHAZKA_DBI_ERR' );

note( "Mrs. Fu is Mr. Fu's supervisor" );
$status = App::Dochazka::REST::Model::Employee->load_by_nick( $dbix_conn, 'mrfu' );
is( $status->code, 'DISPATCH_RECORDS_FOUND', "Nick mrsfu exists" );
$mrfu = $status->payload;

note( "Mr. Fu's supervisor changed to $eid_of_mrsfu" );
$mrfu->supervisor( $eid_of_mrsfu );
$status = $mrfu->update( $faux_context );
ok( $status->ok, "UPDATE status is OK" );
is( $mrfu->supervisor, $eid_of_mrsfu );

note( "List Mrs. Fu's team" );
$status = $emp->team_nicks( $dbix_conn );
is( $status->level, 'OK' );
is( $status->code, 'DISPATCH_LIST_EMPLOYEE_NICKS_TEAM' );
is_deeply( $status->payload, [ 'mrfu' ] );

note( "attempt to change Mrs. Fu's EID" );
my $saved_eid = $emp->eid;
ok( $saved_eid > 1 );
my $bogus_eid = 34342;
$emp->eid( $bogus_eid );
ok( $emp->eid != $saved_eid );
ok( $saved_eid != $emp->eid );
is( $emp->eid, $bogus_eid );
$status = $emp->update( $faux_context );
is( $status->level, "OK" );
is( $status->code, 'DOCHAZKA_CUD_OK' );

note( ' . . . but nothing changed in the database because the UPDATE statement' );
note( 'in question does not set the eid at all. Not sure what to do about this.' );

note( 'reload from saved EID' );
$status = App::Dochazka::REST::Model::Employee->load_by_eid( $dbix_conn, $saved_eid );
is( $status->level, "OK" );
$emp = $status->payload;
is( $emp->eid, $saved_eid );
ok( $emp->eid != $bogus_eid );

note( 'test accessors' );
is( $emp->eid, $emp->{eid}, "accessor: eid" );
is( $emp->fullname, "Mrs. Fu that's Ma'am to you", "accessor: fullname" );
is( $emp->nick, $emp->{nick}, "accessor: nick" );
is( $emp->email, $emp->{email}, "accessor: email" );
is( $emp->passhash, $emp->{passhash}, "accessor: passhash" );
is( $emp->salt, $emp->{salt}, "accessor: salt" );
is( $emp->supervisor, undef, "accessor: supervisor" );
is( $emp->remark, $emp->{remark}, "accessor: remark" );
my $priv_of_mrsfu = $emp->priv( $dbix_conn );
is( $priv_of_mrsfu, "passerby", "accessor: priv" );
is( $emp->priv( $dbix_conn ), $priv_of_mrsfu, "accessor: priv" );

is( noof( $dbix_conn, 'employees' ), 4, "Number of employees is now 4" );
$status = list_employees_by_priv( $dbix_conn, 'all' );
test_employee_list( $status, [ 'demo', 'mrfu', 'mrsfu', 'root' ] );

note( 'Expurgate Mr. Fu' );
$status = $emp->load_by_nick( $dbix_conn, "mrfu" );
is( $status->code, 'DISPATCH_RECORDS_FOUND' );
$emp = $status->payload;
my $fu_eid = $emp->eid;
my $fu_nick = $emp->nick;
my $expurgated_fu = $emp->TO_JSON;
is( ref( $expurgated_fu ), 'HASH' );
is( $expurgated_fu->{eid}, $fu_eid );
is( $expurgated_fu->{nick}, $fu_nick );

note( 'Mr. Fu leave team of Mrs. Fu' );
$status = $emp->load_by_nick( $dbix_conn, "mrfu" );
ok( $status->ok );
is( $status->code, 'DISPATCH_RECORDS_FOUND' );
$emp = $status->payload;
$emp->supervisor( undef );
$status = $emp->update( $faux_context );
is( $status->level, "OK" );

note( 'Mrs. Fu team empty' );
$status = $emp->load_by_nick( $dbix_conn, "mrsfu" );
ok( $status->ok );
is( $status->code, 'DISPATCH_RECORDS_FOUND' );
$emp = $status->payload;
$status = $emp->team_nicks( $dbix_conn );
is( $status->level, 'OK' );
is( $status->code, 'DISPATCH_LIST_EMPLOYEE_NICKS_TEAM' );
is( $status->payload, undef );

note( 'delete Mr. and Mrs. Fu' );
$status = $emp->load_by_nick( $dbix_conn, "mrsfu" );
ok( $status->ok );
is( $status->code, 'DISPATCH_RECORDS_FOUND' );
$emp = $status->payload;
$status = $emp->delete( $faux_context );
ok( $status->ok );
$status = $emp->load_by_nick( $dbix_conn, "mrfu" );
ok( $status->ok );
is( $status->code, 'DISPATCH_RECORDS_FOUND' );
$emp = $status->payload;
$status = $emp->delete( $faux_context );
ok( $status->ok );

note( 'Employees table should now have the same number of records as at the beginning' );
is( noof( $dbix_conn, 'employees' ), $noof_employees );
$status = list_employees_by_priv( $dbix_conn, 'all' );
test_employee_list( $status, [ 'demo', 'root' ] );

note( 'tear down' );
$status = delete_all_attendance_data();
BAIL_OUT(0) unless $status->ok;

done_testing;
