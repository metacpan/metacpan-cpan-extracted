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
#
# test interval and lock resources, which are very similar
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

my $illegal = qr/illegal attendance interval/;


note( "initialize, connect to database, and set up a testing plan" );
my $app = initialize_regression_test();

note( "instantiate Plack::Test object");
my $test = Plack::Test->create( $app );

my $res;
my $note;

my %idmap = (
    "interval" => "iid",
    "lock" => "lid"
);

note( $note = 'create a testing schedule' );
$log->info( "=== $note" );
my $sid = create_testing_schedule( $test );

note( $note = 'create testing employee \'active\' with \'active\' privlevel' );
$log->info( "=== $note" );
my $eid_active = create_active_employee( $test );

note( $note = 'give \'active\' and \'root\' a schedule as of 1957-01-01 00:00 so these two employees can enter some attendance intervals' );
$log->info( "=== $note" );
foreach my $user ( 'active', 'root' ) {
    my $status = req( $test, 201, 'root', 'POST', "schedule/history/nick/$user", <<"EOH" );
{ "sid" : $sid, "effective" : "1957-01-01 00:00" }
EOH
    is( $status->level, "OK" );
    is( $status->code, "DOCHAZKA_CUD_OK" );
    ok( $status->{'payload'} );
    ok( $status->{'payload'}->{'shid'} );
    #ok( $status->{'payload'}->{'schedule'} );
}

note( 'create testing employee \'inactive\' with \'inactive\' privlevel' );
my $eid_inactive = create_inactive_employee( $test );

note( "create an active employee nicknamed 'super'" );
my $super = create_bare_employee( { nick => 'super', password => 'super' } );
my $eid_of_super = $super->eid;
my $status = req( $test, 201, 'root', 'POST', 'priv/history/nick/super', <<"EOH" );
{ "eid" : $eid_of_super, "priv" : "active", "effective" : "1967-06-17 00:00" }
EOH
is( $status->level, "OK" );
is( $status->code, "DOCHAZKA_CUD_OK" );
$status = req( $test, 200, 'root', 'GET', 'priv/nick/super' );
is( $status->level, "OK" );
is( $status->code, "DISPATCH_EMPLOYEE_PRIV" );
ok( $status->{'payload'} );
is( $status->{'payload'}->{'priv'}, 'active' );

note( 'create testing employee \'bubba\' with \'active\' privlevel' );
my $bubba = create_bare_employee( { nick => 'bubba', password => 'bubba' } );
my $eid_of_bubba = $bubba->eid;
$status = req( $test, 201, 'root', 'POST', 'priv/history/nick/bubba', <<"EOH" );
{ "eid" : $eid_of_bubba, "priv" : "active", "effective" : "1967-06-17 00:00" }
EOH
is( $status->level, "OK" );
is( $status->code, "DOCHAZKA_CUD_OK" );
$status = req( $test, 200, 'root', 'GET', 'priv/nick/bubba' );
is( $status->level, "OK" );
is( $status->code, "DISPATCH_EMPLOYEE_PRIV" );
ok( $status->{'payload'} );
is( $status->{'payload'}->{'priv'}, 'active' );

note( 'let super be active\'s supervisor' );
$status = req( $test, 200, 'root', 'PUT', 'employee/nick/active', <<"EOH" );
{ "supervisor" : $eid_of_super }
EOH
is( $status->level, "OK" );
is( $status->code, "DOCHAZKA_CUD_OK" );

sub test_interval_new {
    my ( $test ) = @_;
    # get AID of WORK
    my $aid_of_work = get_aid_by_code( $test, 'WORK' );
    
    note( 'in test_interval_new() function' );
    $status = req( $test, 201, 'root', 'POST', 'interval/new', <<"EOH" );
{ "eid" : $eid_active, "aid" : $aid_of_work, "intvl" : "[2014-10-01 08:00, 2014-10-01 12:00)" }
EOH
    if( $status->level ne 'OK' ) {
        diag( Dumper $status );
        BAIL_OUT(0);
    }
    is( $status->level, 'OK' );
    is( $status->code, 'DOCHAZKA_CUD_OK' );
    ok( $status->{'payload'} );
    is( $status->{'payload'}->{'aid'}, $aid_of_work );
    ok( $status->{'payload'}->{'iid'} );
    return $status->{'payload'}->{'iid'};
}

sub create_testing_lock {
    my ( $test ) = @_;
    
    note( 'in create_testing_lock() function' );
    $status = req( $test, 201, 'root', 'POST', 'lock/new', <<"EOH" );
{ "eid" : $eid_active, "intvl" : "[2013-06-01 00:00, 2013-06-30 24:00)" }
EOH
    if( $status->level ne 'OK' ) {
        diag( Dumper $status );
        BAIL_OUT(0);
    }
    is( $status->level, 'OK' );
    is( $status->code, 'DOCHAZKA_CUD_OK' );
    ok( $status->{'payload'} );
    ok( $status->{'payload'}->{'lid'} );
    return $status->{'payload'}->{'lid'};
}

my $test_iid = test_interval_new( $test );
my $test_lid = create_testing_lock( $test );

my @failing_tsranges = (
    '[]',
    '{asf}',
    '[2014-01-01: 2015-01-01)',
    'wamble wumble womble',
);

note( '=============================' );
note( '"interval/eid/:eid/:tsrange" resource' );
note( '"lock/eid/:eid/:tsrange" resource' );
note( '=============================' );
foreach my $il ( qw( interval lock ) ) {
    my $base = "$il/eid";
    docu_check($test, "$base/:eid/:tsrange");
    
    note( 'GET' );
    note( 'root has no intervals but these users can\'t find that out' );
    foreach my $user ( qw( demo inactive active ) ) {
        req( $test, 403, $user, 'GET', "$base/1/[,)" );
    }
    note( 'active has one interval in 2014 and one lock in 2013' );
    $status = req( $test, 200, 'root', 'GET',
        "$base/$eid_active/[2013-01-01 00:00, 2014-12-31 24:00)" );
    is( $status->level, 'OK' );
    is( $status->code, 'DISPATCH_RECORDS_FOUND' );
    is( $status->{'count'}, 1 );
    foreach my $tsr ( @failing_tsranges ) {
        note( 'tsranges that fail validations clause' );
        foreach my $user ( qw( demo inactive active root ) ) {
            req( $test, 400, $user, 'GET', "$base/1/$tsr" );
        }
    }
    
    note( 'PUT, POST' );
    foreach my $method ( qw( PUT POST ) ) {
        note( 'Testing method: $method' );
        foreach my $user ( 'demo', 'root', 'WAMBLE owdkmdf 5**' ) {
            req( $test, 405, $user, $method, "$base/2/[,)" );
        }
    }

    #note( 'DELETE' );
    #foreach my $user ( 'demo', 'root', 'WAMBLE owdkmdf 5**' ) {
    #    req( $test, 403, $user, 'DELETE', "$base/2/[,)" );
    #}
}

note( 'create an interval as active employee' );
my $aid_of_work = get_aid_by_code( $test, 'WORK' );
my $iae_interval_long_desc = 'iae interval';
$status = req( $test, 201, 'active', 'POST', 'interval/new', <<"EOH" );
{ "aid" : $aid_of_work, "intvl" : "[1958-01-02 08:00, 1958-01-03 08:00)", "long_desc" : "$iae_interval_long_desc" }
EOH
if ( $status->not_ok ) {
    diag( "MARK iae active" );
    diag( Dumper $status );
    BAIL_OUT(0);
}
is( $status->level, 'OK' );
is( $status->code, 'DOCHAZKA_CUD_OK' );
ok( $status->{'payload'} );
ok( $status->{'payload'}->{'iid'} );
my $iae_iid = $status->payload->{'iid'}; # store for later deletion

foreach my $user ( qw( root active super ) ) {
    note( "let $user use GET interval/eid/:eid/:tsrange to list it" );
    $status = req( $test, 200, $user, 'GET', "interval/eid/$eid_active/[ 1958-01-01, 1958-12-31 )" );
    is( $status->level, 'OK' );
    is( $status->code, 'DISPATCH_RECORDS_FOUND' );
    ok( defined( $status->payload ) );
    is( ref( $status->payload ), 'ARRAY' );
    is( scalar( @{ $status->payload } ), 1, "interval count is 1" );
    is( ref( $status->payload->[0] ), 'HASH' );
    is( $status->payload->[0]->{'long_desc'}, $iae_interval_long_desc );
    is( $status->payload->[0]->{'iid'}, $iae_iid );

    note( "let $user use GET interval/eid/:eid/:ts/:psqlint to list it" );
    $status = req( $test, 200, $user, 'GET', "interval/eid/$eid_active/1958-01-01/1 year" );
    is( $status->level, 'OK' );
    is( $status->code, 'DISPATCH_RECORDS_FOUND' );
    ok( defined( $status->payload ) );
    is( ref( $status->payload ), 'ARRAY' );
    is( scalar( @{ $status->payload } ), 1, "interval count is 1" );
    is( ref( $status->payload->[0] ), 'HASH' );
    is( $status->payload->[0]->{'long_desc'}, $iae_interval_long_desc );
    is( $status->payload->[0]->{'iid'}, $iae_iid );
}

note( "let active try to GET interval/eid/:eid/:tsrange on another user\'s intervals" );
$status = req( $test, 403, 'active', 'GET', "interval/eid/$eid_inactive/[ 1958-01-01, 1958-12-31 )" );
is( $status->level, 'ERR' );
is( $status->code, 'DISPATCH_KEEP_TO_YOURSELF' );

foreach my $user ( qw( inactive demo bubba ) ) {
    note( "let $user try GET interval/eid/:eid/:tsrange and get 403" );
    req( $test, 403, $user, 'GET', "interval/eid/$eid_active/[ 1958-01-01, 1958-12-31 )" );
}

note( 'delete the testing interval so it doesn\'t cause trouble later' );
$status = req( $test, 200, 'root', 'DELETE', "interval/iid/$iae_iid" );
ok( $status->ok );

note( 'create intervals for testing https://github.com/smithfarm/dochazka-rest/issues/50' );
$status = req( $test, 201, 'active', 'POST', 'interval/new', <<"EOH" );
{ "aid" : $aid_of_work, "intvl" : "[1980-01-02 23:00, 1980-01-03 01:00)", "long_desc" : "straddle 1" }
EOH
is( $status->level, 'OK' );
is( $status->code, 'DOCHAZKA_CUD_OK' );
$status = req( $test, 201, 'active', 'POST', 'interval/new', <<"EOH" );
{ "aid" : $aid_of_work, "intvl" : "[1980-01-03 08:00, 1980-01-03 12:00)", "long_desc" : "straddle 1" }
EOH
is( $status->level, 'OK' );
is( $status->code, 'DOCHAZKA_CUD_OK' );
$status = req( $test, 201, 'active', 'POST', 'interval/new', <<"EOH" );
{ "aid" : $aid_of_work, "intvl" : "[1980-01-03 23:00, 1980-01-04 01:00)", "long_desc" : "straddle 1" }
EOH
is( $status->level, 'OK' );
is( $status->code, 'DOCHAZKA_CUD_OK' );

note( 'have bubba try to delete all active\'s intervals in tsrange [1980-01-03 00:00, 1980-01-03 24:00)' );
req( $test, 403, 'bubba', 'DELETE', 'interval/nick/active/[1980-01-03 00:00, 1980-01-03 24:00)' );

note( 'have super delete all active\'s intervals in tsrange [1980-01-03 00:00, 1980-01-03 24:00)' );
note( 'only the one whole interval is deleted; two partial intervals are unaffected' );
$status = req( $test, 200, 'super', 'DELETE', 'interval/nick/active/[1980-01-03 00:00, 1980-01-03 24:00)' );
is( $status->level, 'OK' );
is( $status->code, 'DOCHAZKA_CUD_OK' );
is( $status->{'count'}, 1 );
is( $status->{'DBI_return_value'}, 1 );

note( 'delete all intervals in tsrange [1980-01-02 00:00, 1980-01-05 24:00)' );
$status = req( $test, 200, 'active', 'DELETE', 'interval/self/[1980-01-02 00:00, 1980-01-05 24:00)' );
is( $status->level, 'OK' );
is( $status->code, 'DOCHAZKA_CUD_OK' );
is( $status->{'count'}, 2 );
is( $status->{'DBI_return_value'}, 2 );

note( '=============================' );
note( 'interval/iid" resource' );
note( '"lock/lid" resource' );
note( '=============================' );
foreach my $il ( qw( interval lock ) ) {
    my $base = "$il/$idmap{$il}";
    docu_check($test, "$base");
    
    note( 'GET, PUT' );
    foreach my $method ( 'GET', 'PUT' ) {
        note( 'Testing method: $method' );
        foreach my $user ( 'demo', 'active', 'root', 'WOMBAT5', 'WAMBLE owdkmdf 5**' ) {
            req( $test, 405, $user, $method, $base );
        }
    }
    
    note( 'POST' );
    my $test_id = ( $il eq 'interval' ) ? $test_iid : $test_lid;
    # 
    note( 'test if expected behavior behaves as expected (update)' );
    my $int_obj = <<"EOH";
{ "$idmap{$il}" : $test_id, "remark" : "Sharpening pencils" }
EOH
    req( $test, 403, 'demo', 'POST', $base, $int_obj );
    req( $test, 403, 'inactive', 'POST', $base, $int_obj );

    if ( $il eq 'interval' ) {
         $status = req( $test, 200, 'active', 'POST', $base, $int_obj );
         if ( $status->not_ok ) {
             diag( "MARK foo1" );
             diag( Dumper $status );
             BAIL_OUT(0);
         }
         is( $status->level, 'OK', "POST $base 3" );
         is( $status->code, 'DOCHAZKA_CUD_OK', "POST $base 4" );
         is( $status->payload->{'iid'}, $test_iid, "POST $base 5" );
         is( $status->payload->{'remark'}, 'Sharpening pencils', "POST $base 7" );
    } else {
         req( $test, 403, 'active', 'POST', $base, $int_obj );
    }

    note( 'non-existent ID and also out of range' );
    $int_obj = <<"EOH";
{ "$idmap{$il}" : 3434342342342, "remark" : 34334342 }
EOH
    dbi_err( $test, 500, 'root', 'POST', $base, $int_obj, qr/out of range for type integer/ );
    
    note( 'non-existent ID' );
    $int_obj = <<"EOH";
{ "$idmap{$il}" : 342342342, "remark" : 34334342 }
EOH
    req( $test, 404, 'root', 'POST', $base, $int_obj );
    
    note( 'throw a couple curve balls: weirded object' );
    my $weirded_object = '{ "copious_turds" : 555, "long_desc" : "wang wang wazoo", "disabled" : "f" }';
    req( $test, 400, 'root', 'POST', $base, $weirded_object );
    
    note( 'throw a couple curve balls: no closing bracket' );
    my $no_closing_bracket = '{ "copious_turds" : 555, "long_desc" : "wang wang wazoo", "disabled" : "f"';
    req( $test, 400, 'root', 'POST', $base, $no_closing_bracket );
    
    note( 'throw a couple curve balls: weirded object 2' );
    $weirded_object = "{ \"$idmap{$il}\" : \"!!!!!\", \"remark\" : \"down it goes\" }";
    dbi_err( $test, 500, 'root', 'POST', $base, $weirded_object, qr/invalid input syntax for integer/ );
    
    note( 'can a different active employee edit active\'s interval?' );
    note( 'let bubba try it' );
    req( $test, 403, 'bubba', 'POST', "$il/$idmap{$il}", <<"EOH" );
{ "$idmap{$il}" : $test_id, "remark" : "mine" }
EOH

    note( 'can a different active employee edit active\'s interval?' );
    note( 'let active\'s supervisor try it' );
    req( $test, 403, 'super', 'POST', "$il/$idmap{$il}", <<"EOH" );
{ "$idmap{$il}" : $test_id, "remark" : "super was here" }
EOH

    note( 'now root will try to post an illegal interval' );
    dbi_err( $test, 500, 'root', 'POST', "$il/$idmap{$il}", <<"EOH", $illegal );
{ "$idmap{$il}" : $test_id, "intvl" : "(-infinity, today)" }
EOH
    
    note( 'unbounded tsrange' );
    dbi_err( $test, 500, 'root', 'POST', "$il/$idmap{$il}", 
        "{ \"$idmap{$il}\" : $test_id, \"intvl\" : \"[1957-01-01 00:00,)\" }", $illegal );
    
    note( 'DELETE' );
    req( $test, 405, 'demo', 'DELETE', $base );
    req( $test, 405, 'root', 'DELETE', $base );
    req( $test, 405, 'WOMBAT5', 'DELETE', $base );
}


note( "=============================" );
note( '"interval/iid/:iid" resource' );
note( '"lock/lid/:lid" resource' );
note( "=============================" );
foreach my $il ( qw( interval lock ) ) {
    my $base = "$il/$idmap{$il}";
    docu_check($test, "$base/:$idmap{$il}");

    my $test_id = ( $il eq 'interval' ) ? $test_iid : $test_lid;
    
    note( 'GET' );
    note( 'fail as demo 403' );
    req( $test, 403, 'demo', 'GET', "$base/$test_id" );
    
    note( 'succeed as active IID 1' );
    $status = req( $test, 200, 'active', 'GET', "$base/$test_id" );
    ok( $status->ok, "GET $base/:iid 2" );
    ok( $status->{'payload'} );
    is( $status->payload->{$idmap{$il}}, $test_id );
    is( $status->payload->{'eid'}, $eid_active );
    ok( $status->payload->{'intvl'} );
    if ( $il eq 'interval' ) {
        ok( $status->payload->{'aid'} );
        ok( exists $status->payload->{'long_desc'} );
        ok( $status->payload->{'remark'} );
        ok( ! defined $status->payload->{'long_desc'} );
    }
    
    note( 'fail invalid ID' );
    req( $test, 400, 'active', 'GET', "$base/jj" );

    note( 'fail non-existent IID' );
    req( $test, 404, 'active', 'GET', "$base/444" );
    
    note( 'PUT' );
    my $int_obj = '{ "remark" : "Change is good" }';
    note( 'test with demo fail 405' );
    req( $test, 403, 'demo', 'PUT', "$base/$test_id", $int_obj );
    note( 'test with root no request body' );
    req( $test, 400, 'root', 'PUT', "$base/$test_id" );
    note( 'test with root fail invalid JSON' );
    req( $test, 400, 'root', 'PUT', "$base/$test_id", '{ asdf' );
    note( 'test with root fail invalid IID' );
    req( $test, 400, 'root', 'PUT', "$base/asdf", '{ "legal":"json" }' );
    note( 'with valid JSON that is not what we are expecting (valid IID)' );
    req( $test, 400, 'root', 'PUT', "$base/$test_id", '0' );
    note( 'with valid JSON that has some bogus properties' );
    req( $test, 400, 'root', 'PUT', "$base/$test_id", '{ "legal":"json" }' );
    
    note( 'POST' );
    req( $test, 405, 'demo', 'POST', "$base/1" );
    req( $test, 405, 'active', 'POST', "$base/1" );
    req( $test, 405, 'root', 'POST', "$base/1" );
    
    note( 'DELETE' );
    note( 'first make sure there is something to delete' );
    $status = undef;
    $status = req( $test, 200, 'root', 'GET', "$base/$test_id" );
    is( $status->level, 'OK' );
    ok( $status->{"payload"} );
    is( $status->payload->{$idmap{$il}}, $test_id );

    ## - test with demo fail 403
    #req( $test, 403, 'demo', 'DELETE', "$base/$test_id" );
    ##
    ## - test with active fail 403
    #req( $test, 403, 'active', 'DELETE', "$base/$test_id" );
    #
    # - test with root success
    #diag( "DELETE $base/$test_id" );

    note( 'delete something testy' );
    $status = req( $test, 200, 'root', 'DELETE', "$base/$test_id" );
    is( $status->level, 'OK', "DELETE $base/:iid 3" );
    is( $status->code, 'DOCHAZKA_CUD_OK', "DELETE $base/:iid 4" );
    note( 'really gone' );
    req( $test, 404, 'active', 'GET', "$base/$test_id" );
    note( 'test with root fail invalid IID' );
    req( $test, 400, 'root', 'DELETE', "$base/asd" );
}


note( 're-create the testing intervals' );
$test_iid = test_interval_new( $test );
$test_lid = create_testing_lock( $test );


note( '=============================' );
note( 'The "interval/new" resource ( see below for tests common to both "interval/new" and "lock/new" )' );
note( '=============================' );
my $base = 'interval/new';
docu_check($test, $base);

note( 'GET, PUT' );
foreach my $method ( 'GET', 'PUT' ) {
    note( "Testing method: $method" );
    foreach my $user ( 'demo', 'active', 'root', 'WOMBAT5', 'WAMBLE owdkmdf 5**' ) {
        req( $test, 405, $user, $method, $base );
    }
}

note( 'POST' );

note( '- instigate a "403 Forbidden"' );
foreach my $user ( qw( demo inactive ) ) {
    req( $test, 403, $user, 'POST', $base, <<"EOH" );
{ "aid" : $aid_of_work, "intvl" : "[1957-01-02 08:00, 1957-01-03 08:00)" }
EOH
}

note( '- let active and root create themselves an interval and promptly delete it' );
foreach my $user ( qw( active root ) ) {
    $status = req( $test, 201, $user, 'POST', $base, <<"EOH" );
{ "aid" : $aid_of_work, "intvl" : "[1957-01-02 08:00, 1957-01-03 08:00)" }
EOH
    if ( $status->not_ok ) {
        diag( "MARK foo3 $user" );
        diag( Dumper $status );
        BAIL_OUT(0);
    }
    is( $status->level, 'OK' );
    is( $status->code, 'DOCHAZKA_CUD_OK' );
    ok( $status->{'payload'} );
    ok( $status->{'payload'}->{'iid'} );
    my $iid = $status->payload->{'iid'};

    $status = req( $test, 200, $user, 'DELETE', "/interval/iid/$iid" );
    is( $status->level, 'OK' );
    is( $status->code, 'DOCHAZKA_CUD_OK' );
}

note( '- as long as all required properties are present, JSON with bogus properties' );
note( '  will be accepted for insert operation (bogus properties will be silently ignored)' );
foreach my $rb ( 
    "{ \"aid\" : $aid_of_work, \"intvl\" : \"[1957-01-02 08:00, 1957-01-02 08:05)\", \"whinger\" : \"me\" }",
    "{ \"aid\" : $aid_of_work, \"intvl\" : \"[1957-01-03 08:00, 1957-01-03 08:05)\", \"horse\" : \"E-Or\" }",
    "{ \"aid\" : $aid_of_work, \"intvl\" : \"[1957-01-04 08:00, 1957-01-04 08:05)\", \"nine dogs\" : [ 1, 9 ] }",
) {
    $status = req( $test, 201, 'root', 'POST', $base, $rb );
    if ( $status->not_ok ) {
        diag( "MARK foo4: $rb");
        diag( Dumper $status );
        BAIL_OUT(0);
    }
    is( $status->level, 'OK' );
    is( $status->code, 'DOCHAZKA_CUD_OK' );
    ok( $status->{'payload'} );
    ok( $status->{'payload'}->{'iid'} );
    my $iid = $status->payload->{'iid'};

    $status = req( $test, 200, 'root', 'DELETE', "/interval/iid/$iid" );
    is( $status->level, 'OK' );
    is( $status->code, 'DOCHAZKA_CUD_OK' );
}

note( '- required property missing' );
req( $test, 400, 'root', 'POST', $base, <<"EOH" );
{ "intvl" : "[1957-01-02 08:00, 1957-01-02 08:00)", "whinger" : "me" }
EOH

note( '- nonsensical JSON' );
req( $test, 400, 'root', 'POST', $base, 0 );
req( $test, 400, 'root', 'POST', $base, '[ 1, 2, [1, 2], { "wombat":"five" } ]' );

note( 'DELETE' );
req( $test, 405, 'demo', 'DELETE', $base );
req( $test, 405, 'root', 'DELETE', $base );
req( $test, 405, 'WOMBAT5', 'DELETE', $base );


note( '=============================' );
note( '"lock/new" resource (see below for tests common to both "interval/new" and "lock/new" )' );
note( '=============================' );
$base = 'lock/new';
docu_check($test, $base);

note( 'GET, PUT -> 405' );
foreach my $method ( 'GET', 'PUT' ) {
    foreach my $user ( 'demo', 'active', 'root', 'WOMBAT5', 'WAMBLE owdkmdf 5**' ) {
        req( $test, 405, $user, $method, $base );
    }
}

note( 'POST' );
note ('instigate a "403 Forbidden"' );
foreach my $user ( qw( demo inactive ) ) {
    req( $test, 403, $user, 'POST', $base, <<"EOH" );
{ "intvl" : "[1957-01-02 00:00, 1957-01-03 24:00)" }
EOH
}

note( 'let active and root create themselves a lock' );
foreach my $user ( qw( active root ) ) {
    note( 'user == "active"' );
    $status = req( $test, 201, $user, 'POST', $base, <<"EOH" );
{ "intvl" : "[1957-01-02 00:00, 1957-01-03 24:00)" }
EOH
    if ( $status->not_ok ) {
        diag( "MARK foo5" );
        diag( Dumper $status );
        BAIL_OUT(0);
    }
    is( $status->level, 'OK' );
    is( $status->code, 'DOCHAZKA_CUD_OK' );
    ok( $status->{'payload'} );
    ok( $status->{'payload'}->{'lid'} );
    my $lid = $status->payload->{'lid'};
    note( "$user successfully created a lock" );

    note( "let $user try to add an intervals that overlap the locked period in various ways" );
    foreach my $intvl ( 
        '[1957-01-02 08:00, 1957-01-02 12:00)', # completely within the lock interval
        '[1957-01-03 23:00, 1957-01-04 01:00)', # extends past end of lock interval
        '[1957-01-02 08:00, today)',            # -- " -- but with 'today'
        '[1956-12-31 08:00, 1957-01-02 00:05)', # starts before beginning of lock interval
    ) {
        dbi_err( $test, 500, $user, 'POST', 'interval/new', 
            '{ "aid" : ' . $aid_of_work . ', "intvl" : "' . $intvl . '" }',
            qr/interval is locked/i 
        );
    }

    note( "'active' can't delete locks so we have to delete them as root" );
    $status = req( $test, 200, 'root', 'DELETE', "/lock/lid/$lid" );
    is( $status->level, 'OK' );
    is( $status->code, 'DOCHAZKA_CUD_OK' );
}

note( 'as long as all required properties are present, JSON with bogus properties' );
note( 'will be accepted for insert operation (bogus properties will be silently ignored)' );
foreach my $rb ( 
    "{ \"intvl\" : \"[1957-01-02 00:00, 1957-01-02 24:00)\", \"whinger\" : \"me\" }",
    "{ \"intvl\" : \"[1957-01-03 00:00, 1957-01-03 24:00)\", \"horse\" : \"E-Or\" }",
    "{ \"intvl\" : \"[1957-01-04 00:00, 1957-01-04 24:00)\", \"nine dogs\" : [ 1, 9 ] }"
) {
    $status = req( $test, 201, 'root', 'POST', $base, $rb );
    if ( $status->not_ok ) {
        diag( "MARK foo6" );
        diag( Dumper $status );
        BAIL_OUT(0);
    }
    is( $status->level, 'OK' );
    is( $status->code, 'DOCHAZKA_CUD_OK' );
    ok( $status->{'payload'} );
    ok( $status->{'payload'}->{'lid'} );
    my $lid = $status->payload->{'lid'};

    $status = req( $test, 200, 'root', 'DELETE', "/lock/lid/$lid" );
    is( $status->level, 'OK' );
    is( $status->code, 'DOCHAZKA_CUD_OK' );
}

note( 'required property missing' );
$status = req( $test, 400, 'root', 'POST', $base, <<"EOH" );
{ "whinger" : "me" }
EOH
is( $status->level, 'ERR' );
is( $status->code, 'DISPATCH_PROP_MISSING_IN_ENTITY' );

note( 'nonsensical JSON' );
$status = req( $test, 400, 'root', 'POST', $base, 0 );
$status = req( $test, 400, 'root', 'POST', $base, '[ 1, 2, [1, 2], { "wombat":"five" } ]' );

note( 'create an interval, lock it, and then try to update it and delete it' );

note( '- create interval' );
$status = req( $test, 201, 'root', 'POST', 'interval/new', <<"EOH" );
{ "aid" : $aid_of_work, "intvl" : "[1957-01-02 08:00, 1957-01-03 08:00)" }
EOH
is( $status->level, 'OK' );
is( $status->code, 'DOCHAZKA_CUD_OK' );
my $ti = $status->payload->{'iid'};

note( '- lock it' );
$status = req( $test, 201, 'root', 'POST', 'lock/new', <<"EOH" );
{ "intvl" : "[1957-01-01 00:00, 1957-02-01 00:00)" }
EOH
is( $status->level, 'OK' );
is( $status->code, 'DOCHAZKA_CUD_OK' );
my $tl = $status->payload->{'lid'};

note( '- try to update it' );
dbi_err( $test, 500, 'root', 'PUT', "interval/iid/$ti", 
    '{ "long_desc" : "I\'m changing this interval even though it\'s locked!" }',
    qr/interval is locked/ );

note( '- try to delete it' );
dbi_err( $test, 500, 'root', 'DELETE', "interval/iid/$ti", undef,
    qr/interval is locked/ );

note( '- remove the lock' );
$status = req( $test, 200, 'root', 'DELETE', "lock/lid/$tl" );
is( $status->level, 'OK' );
is( $status->code, 'DOCHAZKA_CUD_OK' );

note( '- now we can delete it' );
$status = req( $test, 200, 'root', 'DELETE', "interval/iid/$ti" );
is( $status->level, 'OK' );
is( $status->code, 'DOCHAZKA_CUD_OK' );

note( 'create a lock over the entire month of August 2014 and try to create' );
note( 'intervals that might be considered "edge cases"' );

$status = req( $test, 201, 'root', 'POST', 'lock/new', <<"EOH" );
{ "eid" : $eid_active, "intvl" : "[2014-08-01 00:00, 2014-09-01 00:00)" }
EOH
is( $status->level, 'OK' );
is( $status->code, 'DOCHAZKA_CUD_OK' );
my $tlid = $status->payload->{'lid'};
$status = req( $test, 200, 'root', 'GET', "lock/lid/$tlid" );
ok( $status->ok );

note( '- this one will be OK' );
$status = req( $test, 201, 'active', 'POST', 'interval/new', <<"EOH" );
{ "aid" : $aid_of_work, "eid" : $eid_active, "intvl" : "[2014-07-31 20:00, 2014-08-01 00:00)" }
EOH
is( $status->level, 'OK' );
is( $status->code, 'DOCHAZKA_CUD_OK' );
my $tiid = $status->payload->{'iid'};
$status = req( $test, 200, 'active', 'DELETE', "interval/iid/$tiid" );
is( $status->level, 'OK' );
is( $status->code, 'DOCHAZKA_CUD_OK' );
req( $test, 404, 'active', 'GET', "interval/iid/$tiid" );

note( '- illegal interval' );
dbi_err( $test, 500, 'active', 'POST', 'interval/new', 
    '{ "aid" : ' . $aid_of_work . ', "eid" : ' . $eid_active . 
        ', "intvl" : "[2014-07-31 20:00, 2014-08-01 00:00]" }', $illegal );

note( '- upper bound not evenly divisible by 5 minutes' );
dbi_err( $test, 500, 'active', 'POST', 'interval/new',
    '{ "aid" : '. $aid_of_work . ', "eid" : ' . $eid_active .
        ', "intvl" : "[2014-07-31 20:00, 2014-08-01 00:01)" }',
    qr/upper and lower bounds of interval must be evenly divisible by 5 minutes/ );

note( '- interval is locked' );
dbi_err( $test, 500, 'active', 'POST', 'interval/new',
    '{ "aid" : '. $aid_of_work . ', "eid" : ' . $eid_active .
        ', "intvl" : "[2014-07-31 20:00, 2014-08-01 00:05)" }',
    qr/interval is locked/ );

note( 'now let\'s try to attack upper bound of lock' );
note( '- this one looks like it might conflict with the lock\'s upper bound');
note( '  (2014-09-01), but since the upper bound is non-inclusive, the interval will');
note( '  be OK');

$status = req( $test, 201, 'active', 'POST', 'interval/new', <<"EOH" );
{ "aid" : $aid_of_work, "eid" : $eid_active, "intvl" : "[2014-09-01 00:00, 2014-09-01 04:00)" }
EOH
is( $status->level, 'OK' );
is( $status->code, 'DOCHAZKA_CUD_OK' );
$tiid = $status->payload->{'iid'};
$status = req( $test, 200, 'active', 'DELETE', "interval/iid/$tiid" );
is( $status->level, 'OK' );
is( $status->code, 'DOCHAZKA_CUD_OK' );
req( $test, 404, 'active', 'GET', "interval/iid/$tiid" );

note( '- conclusion: I see no way to create an unexpected conflict (famous last words)' );

note( 'CLEANUP: delete the lock' );
$status = req( $test, 200, 'root', 'DELETE', "lock/lid/$tlid" );
is( $status->level, 'OK' );
is( $status->code, 'DOCHAZKA_CUD_OK' );
req( $test, 404, 'root', 'GET', "lock/lid/$tlid" );

note( "have an active user try to create a lock on someone else's attendance" );

req( $test, 403, 'active', 'POST', $base, <<"EOH" );
{ "eid" : $eid_inactive, "intvl" : "[1957-02-01 00:00, 1957-03-01 00:00)" }
EOH

note( 'DELETE -> 405' );
req( $test, 405, 'demo', 'DELETE', $base );
req( $test, 405, 'root', 'DELETE', $base );
req( $test, 405, 'WOMBAT5', 'DELETE', $base );


note( "========================" );
note( "'/interval/new' resource" );
note( "'/lock/new' resource" );
note( "tests of many pathological intervals" );
note( "========================" );

note( "tests common to both /interval/new and /lock/new" );

foreach my $il ( qw( interval lock ) ) {

    note( "looping: il == $il" );

    note( 'initialize insert tests' );
    my $insert_base = "$il/new";
    my $insert_part1 = ( $il eq 'interval' ) 
        ? "{ \"aid\" : $aid_of_work, \"intvl\" : "
        : "{ \"intvl\" : ";

    note( 'initialize update tests' );
    my $test_id = ( $il eq 'interval' ) ? $test_iid : $test_lid;
    my $update_base = "$il/$idmap{$il}/$test_id";
    my $update_part1 = "{ \"$idmap{$il}\" : $test_id, \"intvl\" : ";

    note( 'intervals that trigger 400' );
    foreach my $i ( 
        '"(-infinity,today)"',
        '"(,infinity)"',
        '"[,)"',
        '"[,today)"',
        '"[today,)"',
        '"[now,)"',
        '"[ 1958-05-27 08:00, 1958-05-27 08:00 )"',
        '"( 1977-10-22 08:00, 1977-10-23 08:00 )"',
        '"[ 1977-10-22 08:00, 1977-10-23 08:00 ]"',
        '"( 1977-10-22 08:00, 1977-10-23 08:00 ]"',
    ) {
        #diag( "$insert_part1$i }" );
        dbi_err( $test, 500, 'root', 'POST', $insert_base, "$insert_part1$i }", $illegal );
        dbi_err( $test, 500, 'root', 'PUT', $update_base, "$update_part1$i }", $illegal );
    }

    note( 'intervals that trigger DOCHAZKA_DBI_ERR "No dates earlier than 1892-01-01 please"' );
    foreach my $i (
        '"[1865-10-01 00:00, 1865-11-01 00:00)"',
        '"[1891-10-01 00:00, 1892-11-01 00:00)"',
        '"[1891-12-31 23:59, 1892-11-01 00:00)"',
    ) {
        #diag( "$insert_part1$i }" );
        dbi_err( $test, 500, 'root', 'POST', $insert_base, "$insert_part1$i }",
            qr/No dates earlier than 1892-01-01 please/ );
    }

    note( 'intervals that trigger DOCHAZKA_DBI_ERR "malformed range literal"' );
    foreach my $i (
        '"infinity is my friend"',
        '"[whacko interval)"',
        '"[,now()::timestamp)"',
    ) {
        #diag( "$insert_part1$i }" );
        dbi_err( $test, 500, 'root', 'POST', $insert_base, "$insert_part1$i }",
            qr/malformed range literal/ );
    }

    note( "intervals that trigger DOCHAZKA_DBI_ERR 'upper and lower bounds (etc.)'" );
    foreach my $i (
        '"[ 1958-05-27 08:00, 1958-05-27 08:01 )"',
        '"[ 1958-05-27 08:00, 1958-05-27 08:02 )"',
        '"[ 1958-05-27 08:00, 1958-05-27 08:03 )"',
        '"[ 1958-05-27 08:00, 1958-05-27 08:04 )"',
        '"[ 1958-05-27 08:01, 1958-05-27 08:05 )"',
        '"[ 1958-05-27 08:02, 1958-05-27 08:05 )"',
        '"[ 1958-05-27 08:03, 1958-05-27 08:05 )"',
        '"[ 1958-05-27 08:04, 1958-05-27 08:05 )"',
    ) {
        #diag( "$insert_part1$i }" );
        dbi_err( $test, 500, 'root', 'POST', $insert_base, "$insert_part1$i }",
            qr/upper and lower bounds of interval must be evenly divisible by 5 minutes/ );
        dbi_err( $test, 500, 'root', 'PUT', $update_base, "$update_part1$i }",
            qr/upper and lower bounds of interval must be evenly divisible by 5 minutes/ );
    }
}


note( '=============================' );
note( '"interval/nick/:nick/:tsrange" resource' );
note( '"lock/nick/:nick/:tsrange" resource' );
note( '=============================' );

foreach my $il ( qw( interval lock ) ) {

    note( "looping: il == $il" );

    $base = "$il/nick";
    docu_check($test, "$base/:nick/:tsrange");

    note( 'GET' );
    note( "- these users have no intervals but these users can't find that out" );
    foreach my $user ( qw( demo inactive active ) ) {
        foreach my $nick ( qw( root whanger foobar tsw57 ) ) {
            req( $test, 403, $user, 'GET', "$base/$nick/[,)" );
        }
    }
    req( $test, 400, 'root', 'GET', "$base/-1/[,)" );

    note( "- active has one interval in 2014 and one lock in 2013" );
    $status = req( $test, 200, 'root', 'GET',
        "$base/active/[2013-01-01 00:00, 2014-12-31 24:00)" );
    is( $status->level, 'OK' );
    is( $status->code, 'DISPATCH_RECORDS_FOUND' );
    is( $status->{'count'}, 1 );

    note( "- tsranges that fail validations clause" );
    foreach my $tsr ( @failing_tsranges ) {
        foreach my $user ( qw( demo inactive active root ) ) {
            req( $test, 400, $user, 'GET', "$base/$user/$tsr" );
        }
    }
}

note( 'PUT, POST' );
foreach my $method ( qw( PUT POST DELETE ) ) {
    note( "Testing the $method method" );
    foreach my $user ( 'demo', 'root', 'WAMBLE owdkmdf 5**' ) {
        req( $test, 405, $user, $method, "$base/demo/[,)" );
    }
}

#note( 'DELETE' );
#foreach my $user ( 'demo', 'root', 'WAMBLE owdkmdf 5**' ) {
#    req( $test, 403, $user, 'DELETE', "$base/demo/[,)" );
#}

note( 'create an interval as active employee' );
my $ian_interval_long_desc = 'ian interval';
$status = req( $test, 201, 'active', 'POST', 'interval/new', <<"EOH" );
{ "aid" : $aid_of_work, "intvl" : "[1958-01-02 08:00, 1958-01-03 08:00)", "long_desc" : "$ian_interval_long_desc" }
EOH
if ( $status->not_ok ) {
    diag( "MARK ian active" );
    diag( Dumper $status );
    BAIL_OUT(0);
}
is( $status->level, 'OK' );
is( $status->code, 'DOCHAZKA_CUD_OK' );
ok( $status->{'payload'} );
ok( $status->{'payload'}->{'iid'} );
my $ian_iid = $status->payload->{'iid'}; # store for later deletion

foreach my $user ( qw( root active ) ) {

    note( "looping: user == $user" );

    note( "let $user use GET interval/nick/:nick/:tsrange to list it" );
    $status = req( $test, 200, $user, 'GET', "interval/nick/active/[ 1958-01-01, 1958-12-31 )" );
    is( $status->level, 'OK' );
    is( $status->code, 'DISPATCH_RECORDS_FOUND' );
    ok( defined( $status->payload ) );
    is( ref( $status->payload ), 'ARRAY' );
    is( scalar( @{ $status->payload } ), 1, "interval count is 1" );
    is( ref( $status->payload->[0] ), 'HASH' );
    is( $status->payload->[0]->{'long_desc'}, $ian_interval_long_desc );
    is( $status->payload->[0]->{'iid'}, $ian_iid );

    note( "let $user use GET interval/nick/:nick/:ts/:psqlint to list it" );
    $status = req( $test, 200, $user, 'GET', "interval/nick/active/1958-01-01/1 year" );
    is( $status->level, 'OK' );
    is( $status->code, 'DISPATCH_RECORDS_FOUND' );
    ok( defined( $status->payload ) );
    is( ref( $status->payload ), 'ARRAY' );
    is( scalar( @{ $status->payload } ), 1, "interval count is 1" );
    is( ref( $status->payload->[0] ), 'HASH' );
    is( $status->payload->[0]->{'long_desc'}, $ian_interval_long_desc );
    is( $status->payload->[0]->{'iid'}, $ian_iid );
}

note( "let active try to GET interval/nick/:nick/:tsrange on another user\'s intervals" );
$status = req( $test, 403, 'active', 'GET', "interval/nick/inactive/[ 1958-01-01, 1958-12-31 )" );
is( $status->level, 'ERR' );
is( $status->code, 'DISPATCH_KEEP_TO_YOURSELF' );

foreach my $user ( qw( inactive demo ) ) {
    note( "let $user try GET interval/nick/:nick/:tsrange and get 403" );
    req( $test, 403, $user, 'GET', "interval/nick/active/[ 1958-01-01, 1958-12-31 )" );
}

note( 'delete the testing interval so it doesn\'t cause trouble later' );
$status = req( $test, 200, 'root', 'DELETE', "interval/iid/$ian_iid" );
ok( $status->ok );


note( '=============================' );
note( '"interval/self/:tsrange" resource' );
note( '"lock/self/:tsrange" resource' );
note( '=============================' );

foreach my $il ( qw( interval lock ) ) {

    note( "looping: il == $il" );

    $base = "$il/self";
    docu_check($test, "$base/:tsrange");
    
    note( 'GET' );
    note( 'demo is not allowed to see any intervals (even his own)' );
    req( $test, 403, 'demo', 'GET', "$base/[,)" );

    note( '- active has one interval in 2014 and one lock in 2013' );
    $status = req( $test, 200, 'active', 'GET',
        "$base/[2013-01-01 00:00, 2014-12-31 24:00)" );
    is( $status->level, 'OK' );
    is( $status->code, 'DISPATCH_RECORDS_FOUND' );
    is( $status->{'count'}, 1 );
    
    note( 'tsranges that fail validations clause' );
    foreach my $tsr ( @failing_tsranges ) {
        foreach my $user ( qw( demo inactive active root ) ) {
            req( $test, 400, $user, 'GET', "$base/$tsr" );
        }
    }
    
    note( 'PUT, POST' );
    foreach my $method ( qw( PUT POST ) ) {
        note( 'Testing method: $method' );
        foreach my $user ( 'demo', 'root', 'WAMBLE owdkmdf 5**' ) {
            req( $test, 405, $user, $method, "$base/[,)" );
        }
    }

    #note( 'DELETE' );
    #foreach my $user ( 'demo', 'root', 'WAMBLE owdkmdf 5**' ) {
    #    req( $test, 403, $user, 'DELETE', "$base/2/[,)" );
    #}
}
    
note( 'delete the testing interval' );
$status = req( $test, 200, 'root', 'DELETE', "/interval/iid/$test_iid" );
is( $status->level, 'OK' );
is( $status->code, 'DOCHAZKA_CUD_OK' );

note( 'delete the testing lock' );
$status = req( $test, 200, 'root', 'DELETE', "/lock/lid/$test_lid" );
is( $status->level, 'OK' );
is( $status->code, 'DOCHAZKA_CUD_OK' );


note( '=============================' );
note( '"interval/summary/eid/:eid/:tsrange" resource' );
note( '=============================' );

$base = "interval/summary/eid";
docu_check($test, "$base/:eid/:tsrange");

note( 'PUT, POST, DELETE -> 405' );
foreach my $method ( qw( PUT POST DELETE ) ) {
    foreach my $user ( qw( demo inactive active root ) ) {
        req( $test, 405, $user, $method, "$base/1/[,)" );
    }
}

note( "GET interval summary" );
$status = req( $test, 200, 'active', 'GET', "$base/$eid_active/[1980-01-01,1980-1-31)" );
is( $status->level, 'OK' );
is_deeply( $status->payload, {
           '1980-01-15' => {},
           '1980-01-11' => {},
           '1980-01-30' => {},
           '1980-01-08' => {},
           '1980-01-22' => {},
           '1980-01-02' => {},
           '1980-01-17' => {},
           '1980-01-26' => {
                             'weekend' => 1
                           },
           '1980-01-19' => {
                             'weekend' => 1
                           },
           '1980-01-18' => {},
           '1980-01-09' => {},
           '1980-01-13' => {
                             'weekend' => 1
                           },
           '1980-01-25' => {},
           '1980-01-27' => {
                             'weekend' => 1
                           },
           '1980-01-01' => {
                             'holiday' => 1
                           },
           '1980-01-29' => {},
           '1980-01-04' => {},
           '1980-01-21' => {},
           '1980-01-06' => {
                             'weekend' => 1
                           },
           '1980-01-05' => {
                             'weekend' => 1
                           },
           '1980-01-03' => {},
           '1980-01-14' => {},
           '1980-01-07' => {},
           '1980-01-10' => {},
           '1980-01-20' => {
                             'weekend' => 1
                           },
           '1980-01-12' => {
                             'weekend' => 1
                           },
           '1980-01-16' => {},
           '1980-01-24' => {},
           '1980-01-23' => {},
           '1980-01-28' => {}
        } );

$status = req( $test, 201, 'root', 'POST', 'interval/new', <<"EOH" );
{ "eid" : $eid_active, "aid" : $aid_of_work, "intvl" : "[1980-1-1 08:00, 1980-1-1 12:00)" }
EOH
ok( $status->ok );
is( $status->code, 'DOCHAZKA_CUD_OK' );
is( $status->{count}, 1 );

$status = req( $test, 200, 'active', 'GET', "$base/$eid_active/[1980-01-01,1980-1-31)" );
is( $status->level, 'OK' );
is_deeply( $status->payload, {
           '1980-01-15' => {},
           '1980-01-11' => {},
           '1980-01-30' => {},
           '1980-01-08' => {},
           '1980-01-22' => {},
           '1980-01-02' => {},
           '1980-01-17' => {},
           '1980-01-26' => {
                             'weekend' => 1
                           },
           '1980-01-19' => {
                             'weekend' => 1
                           },
           '1980-01-18' => {},
           '1980-01-09' => {},
           '1980-01-13' => {
                             'weekend' => 1
                           },
           '1980-01-25' => {},
           '1980-01-27' => {
                             'weekend' => 1
                           },
           '1980-01-01' => {
                             'WORK' => 4,
                             'holiday' => 1
                           },
           '1980-01-29' => {},
           '1980-01-04' => {},
           '1980-01-21' => {},
           '1980-01-06' => {
                             'weekend' => 1
                           },
           '1980-01-05' => {
                             'weekend' => 1
                           },
           '1980-01-03' => {},
           '1980-01-14' => {},
           '1980-01-07' => {},
           '1980-01-10' => {},
           '1980-01-20' => {
                             'weekend' => 1
                           },
           '1980-01-12' => {
                             'weekend' => 1
                           },
           '1980-01-16' => {},
           '1980-01-24' => {},
           '1980-01-23' => {},
           '1980-01-28' => {}
        } );

note( 'tear down' );
$status = delete_all_attendance_data();
BAIL_OUT(0) unless $status->ok;

done_testing;
