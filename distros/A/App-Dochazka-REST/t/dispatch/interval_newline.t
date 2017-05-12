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
# test interval resources when description contains one or more newline characters
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

plan skip_all => "WIP";

note( "initialize, connect to database, and set up a testing plan" );
my $app = initialize_regression_test();

note( "instantiate Plack::Test object");
my $test = Plack::Test->create( $app );

my $res;

note( 'create a testing schedule' );
my $sid = create_testing_schedule( $test );

note( 'create testing employee \'active\' with \'active\' privlevel' );
my $eid_active = create_active_employee( $test );

note( 'give \'active\' and \'root\' a schedule as of 1957-01-01 00:00 so these two employees can enter some attendance intervals' );
my @shid_for_deletion;
foreach my $user ( 'active', 'root' ) {
    my $status = req( $test, 201, 'root', 'POST', "schedule/history/nick/$user", <<"EOH" );
{ "sid" : $sid, "effective" : "1957-01-01 00:00" }
EOH
    is( $status->level, "OK" );
    is( $status->code, "DOCHAZKA_CUD_OK" );
    ok( $status->{'payload'} );
    ok( $status->{'payload'}->{'shid'} );
    push @shid_for_deletion, $status->{'payload'}->{'shid'};
    #ok( $status->{'payload'}->{'schedule'} );
}

note( 'get AID of WORK' );
my $aid_of_work = get_aid_by_code( $test, 'WORK' );

note( 'insert a testing interval' );
my @iid_for_deletion;
my $status = req( $test, 201, 'root', 'POST', 'interval/new', <<"EOH" );
{ "eid" : $eid_active, "aid" : $aid_of_work, "intvl" : "[2014-10-01 08:00, 2014-10-01 12:00)" }
EOH
is( $status->level, 'OK' );
is( $status->code, 'DOCHAZKA_CUD_OK' );
ok( $status->{'payload'} );
is( $status->{'payload'}->{'aid'}, $aid_of_work );
ok( $status->{'payload'}->{'iid'} );
push @iid_for_deletion, $status->{'payload'}->{'iid'};

note( 'create a string containing newlines' );
my $nlstr = <<"EOH";
Now
is
the
time
EOH

#note( 'create a testing interval with newline string' );
#$status = req( $test, 201, 'root', 'POST', 'interval/new', <<"EOH" );
#{ "eid" : $eid_active, "aid" : $aid_of_work, "intvl" : "[2014-10-01 08:00, 2014-10-01 12:00)",
#"long_desc" : "$nlstr" }
#EOH
#is( $status->level, 'OK' );
#is( $status->code, 'DOCHAZKA_CUD_OK' );
#ok( $status->{'payload'} );
#is( $status->{'payload'}->{'aid'}, $aid_of_work );
#ok( $status->{'payload'}->{'iid'} );
#push @iid_for_deletion, $status->{'payload'}->{'iid'};
#

note( 'delete all testing intervals' );
foreach my $iid ( @iid_for_deletion ) {
    req( $test, 200, 'root', 'DELETE', "interval/iid/$iid" );
}

note( 'delete all schedule history records' );
foreach my $shid ( @shid_for_deletion ) {
    req( $test, 200, 'root', 'DELETE', "schedule/history/shid/$shid" );
}

note( 'delete the testing employee' );
delete_employee_by_nick( $test, 'active' );

note( 'delete the testing schedule' );
delete_testing_schedule( $sid );
    
done_testing;
