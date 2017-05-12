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
# test that our model does not allow ID ('eid', 'aid', 'iid', etc.) fields
# to be changed in the database
#

#!perl
use 5.012;
use strict;
use warnings;

#use App::CELL::Test::LogToFile;
use App::CELL qw( $meta $site );
use App::Dochazka::REST::Model::Activity;
use App::Dochazka::REST::Test;
use Test::More;
use Test::Warnings;


note( "initialize, connect to database, and set up a testing plan" );
initialize_regression_test();

note( "dispatch map enabling 'gen_...' functions to be called from within the loop" );
note( '- these functions are imported automatically from App::Dochazka::REST::Test' );
my %d_map = (
    'activity' => \&gen_activity,
    'employee' => \&gen_employee,
    'interval' => \&gen_interval,
    'lock' => \&gen_lock,
    'privhistory' => \&gen_privhistory,
    'schedhistory' => \&gen_schedhistory,
    'schedule' => \&gen_schedule,
);

note( 'the id map enabling the ID property/accessor to be referred to from within the loop' );
my %id_map = (
    'activity' => 'aid',
    'employee' => 'eid',
    'interval' => 'iid',
    'lock' => 'lid',
    'privhistory' => 'phid',
    'schedhistory' => 'shid',
    'schedule' => 'sid',
);

note( 'the main testing loop - note that only activity and employee' );
note( 'are working because the gen_... functions for the others have' );
note( 'yet to be implemented.' );
foreach my $cl ( 
    'activity',
    'employee',
#    'interval',
#    'lock',
#    'privhistory',
#    'schedhistory',
#    'schedule',
) {

    note( "Testing model class: $cl" );

    note( 'first, create a test object' );
    my $testobj = $d_map{$cl}->( 'create' );

    note( 'second, create a pristine clone of that object to compare against' );
    my $testclone = $testobj->clone;

    note( 'When created in this testing context, the test object\'s ID will' );
    note( 'be a low integer value, most probably *not* 2397. This test' );
    note( 'exercises the immutability of the ID by attempting to change the' );
    note( 'ID to 2397' );
    ok( $testobj->{$id_map{$cl}} != 2397, "Initial ID is not 2397" );
    $testobj->{$id_map{$cl}} = 2397; # force-set ID to 2397
    is( $testobj->{$id_map{$cl}}, 2397, "Object ID is 2397" );
    my $status = $testobj->update( $faux_context ); # attempt to update database
    is( $status->level, 'OK' ); # all green haha
    is( $testobj->{$id_map{$cl}}, 2397 ); # oops!
    note( 'object not restored, even though no records were affected' );
    note( 'in other words, the object is no longer in sync with the database' );
    note( 'but this is our own fault for changing the ID' );
    note( '---------------------------------------------' );
    note( ' ' );
    note( 'restore object to pristine state' );
    $testobj->{$id_map{$cl}} = $testclone->{$id_map{$cl}};
    is_deeply( $testobj, $testclone );
    
    note( 'retrieve test object from database and check that it didn\'t change' );
    $status = $d_map{$cl}->( 'retrieve' );
    is_deeply( $testclone, $status->payload );
    
    note( 'attempt to change ID to a totally bogus value -- note that this cannot' );
    note( 'work because the update method plugs the id value into the WHERE clause' );
    note( 'of the SQL statement' );
    $testobj->{$id_map{$cl}} = '-153jjj*';
    is( $testobj->{$id_map{$cl}}, '-153jjj*' );
    $status = $testobj->update( $faux_context );
    is( $status->level, 'ERR' );
    is( $status->code, 'DOCHAZKA_DBI_ERR' );
    like( $status->text, qr/invalid input syntax for integer/ );
    is( $testobj->{$id_map{$cl}}, '-153jjj*' );   # EID is set wrong
    
    note( 'restore object to pristine state' );
    $testobj->{$id_map{$cl}} = $testclone->{$id_map{$cl}};
    is_deeply( $testobj, $testclone );
    
    note( "attempt to change ID to 'undef'" );
    $testobj->{$id_map{$cl}} = undef;
    is( $testobj->{$id_map{$cl}}, undef );
    $status = $testobj->update( $faux_context );
    is( $status->level, 'ERR' );
    is( $status->code, 'DOCHAZKA_MALFORMED_400' );
    
    note( 'restore object to pristine state' );
    $testobj->{$id_map{$cl}} = $testclone->{$id_map{$cl}};
    is_deeply( $testobj, $testclone );
    
    note( "attempt to change ID to '' (empty string)" );
    $testobj->{$id_map{$cl}} = '';
    is( $testobj->{$id_map{$cl}}, '' );
    $status = $testobj->update( $faux_context );
    is( $status->level, 'ERR' );
    is( $status->code, 'DOCHAZKA_MALFORMED_400' );

    note( 'restore object to pristine state' );
    $testobj->{$id_map{$cl}} = $testclone->{$id_map{$cl}};
    is_deeply( $testobj, $testclone );

    note( 'delete the database record' );
    $d_map{$cl}->( 'delete' );

    note( 'gone' );
    $status = $d_map{$cl}->( 'retrieve' );
    is( $status->level, 'NOTICE' );
    is( $status->code, 'DISPATCH_NO_RECORDS_FOUND' );
}

note( 'tear down' );
my $status = delete_all_attendance_data();
BAIL_OUT(0) unless $status->ok;

done_testing;
