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
# test fix of fillup bug #67
# https://github.com/smithfarm/dochazka-rest/issues/67
#

#!perl
use 5.012;
use strict;
use warnings;

#use App::CELL::Test::LogToFile;
use App::CELL qw( $log $meta $site );
use App::Dochazka::REST::Test;
use Data::Dumper;
use JSON;
use Plack::Test;
use Test::JSON;
use Test::More;
use Test::Warnings;

note( 'initialize, connect to database, and set up a testing plan' );
my $app = initialize_regression_test();

note( 'instantiate Plack::Test object' );
my $test = Plack::Test->create( $app );

my ( $note, $status );

#note( 'start with a clean slate' );
#$status = delete_all_attendance_data();
#BAIL_OUT(0) unless $status->ok;

note( 'get AID of WORK' );
my $aid_of_work = get_aid_by_code( $test, 'WORK' );

note( $note = 'create a testing schedule' );
$log->info( "=== $note" );
my $sid = create_testing_schedule( $test );

note( $note = 'create testing employee \'active\' with \'active\' privlevel' );
$log->info( "=== $note" );
my $eid_of_active = create_active_employee( $test );
my $active = App::Dochazka::REST::Model::Employee->load_by_eid(
    $faux_context->{dbix_conn},
    $eid_of_active
)->payload;

note( $note = 'give \'active\' a schedule as of 1957-01-01 00:00 so it can enter attendance intervals' );
$log->info( "=== $note" );
$status = req( $test, 201, 'root', 'POST', "schedule/history/nick/active", <<"EOH" );
{ "sid" : $sid, "effective" : "1957-01-01 00:00" }
EOH
is( $status->level, "OK" );
is( $status->code, "DOCHAZKA_CUD_OK" );
ok( $status->{'payload'} );
ok( $status->{'payload'}->{'shid'} );
#ok( $status->{'payload'}->{'schedule'} );

note( $note = 'create testing employee \'inactive\' with \'inactive\' privlevel' );
$log->info( "=== $note" );
my $eid_inactive = create_inactive_employee( $test );

note( $note = 'create testing employee \'bubba\' with \'active\' privlevel' );
$log->info( "=== $note" );
my $eid_bubba = create_bare_employee( { nick => 'bubba', password => 'bubba' } )->eid;
$status = req( $test, 201, 'root', 'POST', 'priv/history/nick/bubba', <<"EOH" );
{ "eid" : $eid_bubba, "priv" : "active", "effective" : "1967-06-17 00:00" }
EOH
is( $status->level, "OK" );
is( $status->code, "DOCHAZKA_CUD_OK" );
$status = req( $test, 200, 'root', 'GET', 'priv/nick/bubba' );
is( $status->level, "OK" );
is( $status->code, "DISPATCH_EMPLOYEE_PRIV" );
ok( $status->{'payload'} );
is( $status->{'payload'}->{'priv'}, 'active' );

note( $note = 'create a testing interval' );
$log->info( "=== $note" );
my $int = create_testing_interval(
    eid => $eid_of_active,
    aid => $aid_of_work,
    intvl => "[2014-10-01 08:00, 2014-10-01 12:00)",
);

note( $note = "Create fillup object over a Thu-Mon tsrange where Sat, Sun are holidays" );
$log->info( "=== $note" );
my $fo = App::Dochazka::REST::Fillup->new(
    context => $faux_context,
    tsrange => "[ 1960-12-22 00:00, 1960-12-26 24:00 )",
    emp_obj => $active,
    dry_run => 0,
    clobber => 0,
);
isa_ok( $fo, 'App::Dochazka::REST::Fillup' );
isa_ok( $fo->constructor_status, 'App::CELL::Status' );
ok( $fo->constructor_status );
is( $fo->dry_run, 0 );
like( $fo->tsrange->{'tsrange'}, qr/^\["1960-12-22 00:00:00...","1960-12-27 00:00:00..."\)$/ );

note( $note = "fillup_tempinvls() over a Thu-Mon tsrange where Sat, Sun are holidays" );
$log->info( "=== $note" );
$status = $fo->fillup_tempintvls;
ok( $status->ok );

note( $note = "examine the resulting intervals" );
$log->info( "=== $note" );
my $tempintvls = $fo->intervals;
is( ref( $tempintvls ), 'ARRAY' );
is( scalar( @$tempintvls ), 2 );
is( ref( $tempintvls->[0] ), 'App::Dochazka::REST::Model::Tempintvl' );
is( $tempintvls->[0]->intvl, '["1960-12-23 08:00:00+01","1960-12-23 12:00:00+01")' );
is( ref( $tempintvls->[1] ), 'App::Dochazka::REST::Model::Tempintvl' );
is( $tempintvls->[1]->intvl, '["1960-12-23 12:30:00+01","1960-12-23 16:30:00+01")' );

note( 'tear down' );
$status = delete_all_attendance_data();
BAIL_OUT(0) unless $status->ok;

done_testing;
