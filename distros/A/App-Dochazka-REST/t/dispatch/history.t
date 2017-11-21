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
# test history (priv/sched) resources:
# - since all the history dispatch logic is shared, most of the tests
#   for 'priv/history/...' and 'schedule/history/...' resources are either
#   identical or very similar, so it makes sense to test them as a unit
#

#!perl
use 5.012;
use strict;
use warnings;

#use App::CELL::Test::LogToFile;
use App::CELL qw( $meta $site );
use App::Dochazka::REST::Model::Privhistory;
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

note( 'define delete_history_recs() subroutine' );
note( 'this has to be defined after initialization because it uses $test' );
sub delete_history_recs {
    my ( $base, $set ) = @_;
    my $prop = ( $base =~ m/^priv/ ) 
        ? 'phid'
        : 'shid'; 
    my $resource = ( $base =~ m/^priv/ ) 
        ? '/priv/history/phid/'
        : '/schedule/history/shid/';
    foreach my $rec ( @$set ) {
        #diag( "$base deleting " . Dumper $rec );
        my $status = req( $test, 200, 'root', 'DELETE', $resource . $rec->{$prop} );
        is( $status->level, 'OK' );
        is( $status->code, 'DOCHAZKA_CUD_OK' );
    }
}

my $j;
my $res;


note( 'give root a schedule history of sorts' );
my $ts_sid = create_testing_schedule( $test );
my $status = req( $test, 201, 'root', 'POST', 'schedule/history/nick/root',
    '{ "effective":"1892-01-01 00:00", "sid":' . $ts_sid . ' }' );
is( $status->level, 'OK' );
is( $status->code, 'DOCHAZKA_CUD_OK' );
ok( exists $status->{payload} );
ok( defined $status->payload );
ok( exists $status->payload->{'shid'} );
ok( defined $status->payload->{'shid'} );
ok( $status->payload->{'shid'} > 0 );
my $root_shid = $status->payload->{'shid'};

my $base;


note( '=============================' );
note( '"{priv,schedule}/history/self/?:tsrange" resource' );
note( '=============================' );

foreach $base ( 'priv/history/self', 'schedule/history/self' ) {
    note( "testing $base" );

    note( 'docu_check()' );
    docu_check($test, "$base/?:tsrange");

    note( 'GET' );
    
    note( '403 fail as demo' );
    req( $test, 403, 'demo', 'GET', $base );
    
    note( 'succeed as root' );
    $status = req( $test, 200, 'root', 'GET', $base );
    is( $status->level, 'OK' );
    is( $status->code, "DISPATCH_RECORDS_FOUND" );
    ok( defined $status->payload );
    ok( exists $status->payload->{'eid'} );
    is( $status->payload->{'eid'}, $site->DOCHAZKA_EID_OF_ROOT );
    ok( exists $status->payload->{'history'} );
    is( scalar @{ $status->payload->{'history'} }, 1 );
    is( $status->payload->{'history'}->[0]->{'eid'}, $site->DOCHAZKA_EID_OF_ROOT );
    ok( exists $status->payload->{'history'}->[0]->{'effective'} );

    note( 'demo 403 with a valid tsrange' );
    req( $test, 403, 'demo', 'GET', "$base/[,)" );
    $status = req( $test, 200, 'root', 'GET', "$base/[,)" );
    is( $status->level, 'OK' );
    is( $status->code, "DISPATCH_RECORDS_FOUND" );
    ok( defined $status->payload );
    ok( exists $status->payload->{'eid'} );
    is( $status->payload->{'eid'}, $site->DOCHAZKA_EID_OF_ROOT );
    ok( exists $status->payload->{'history'} );
    is( scalar @{ $status->payload->{'history'} }, 1 );
    is( $status->payload->{'history'}->[0]->{'eid'}, $site->DOCHAZKA_EID_OF_ROOT );
    ok( exists $status->payload->{'history'}->[0]->{'effective'} );
    
    note( 'a number of invalid tsranges' );
    foreach my $inv_tsr (
        '0',
        'whinger',
        '[,',
    ) {
        req( $test, 400, 'root', 'GET', "$base/$inv_tsr" );
    }
    dbi_err( $test, 500, 'root', 'GET', "$base/[,sdf)", undef, qr/invalid input syntax for type timestamp/ );
    dbi_err( $test, 500, 'root', 'GET', "$base/[\"2014-01-01 00:00\",\"2013-01-01 00:00\")", undef, 
        qr/range lower bound must be less than or equal to range upper bound/ );

    note( 'PUT, POST, DELETE' );
    req( $test, 405, 'demo', 'PUT', $base );
    req( $test, 405, 'demo', 'POST', $base );
    req( $test, 405, 'demo', 'DELETE', $base );
    req( $test, 405, 'demo', 'PUT', "$base/[,)" );
    req( $test, 405, 'demo', 'POST', "$base/[,)" );
    req( $test, 405, 'demo', 'DELETE', "$base/[,)" );
}


note( '===========================================' );
note( '"{priv,schedule}/history/eid/:eid" resource' );
note( '===========================================' );

foreach $base ( "priv/history/eid", "schedule/history/eid" ) {
    note( "testing $base" );

    note( "docu_check()" );
    docu_check($test, "$base/:eid");

    note( 'GET' );

    note( 'GET history of EID 1 (root)' );

    note( 'fail 403 as demo' );
    req( $test, 403, 'demo', 'GET', $base . '/' . $site->DOCHAZKA_EID_OF_ROOT );

    note( 'succeed as root' );
    $status = req( $test, 200, 'root', 'GET', $base . '/' . $site->DOCHAZKA_EID_OF_ROOT );
    is( $status->level, 'OK' );
    is( $status->code, "DISPATCH_RECORDS_FOUND" );
    ok( defined $status->payload );
    if ( ! exists( $status->payload->{'eid'} ) ) {
        diag( Dumper $status );
        BAIL_OUT(0);
    }
    ok( exists $status->payload->{'eid'} );

    note( 'returned EID should be same as the one we asked for' );
    if ( $status->payload->{'eid'} != $site->DOCHAZKA_EID_OF_ROOT ) {
        diag( Dumper $status );
        BAIL_OUT(0);
    }
    is( $status->payload->{'eid'}, $site->DOCHAZKA_EID_OF_ROOT );
    ok( exists $status->payload->{'history'} );
    is( scalar @{ $status->payload->{'history'} }, 1 );
    is( $status->payload->{'history'}->[0]->{'eid'}, $site->DOCHAZKA_EID_OF_ROOT );
    ok( exists $status->payload->{'history'}->[0]->{'effective'} );

    note( 'get history of non-existent EID' );

    note( 'fail 403 as demo' );
    req( $test, 403, 'demo', 'GET', "$base/4534" );

    note( '"succeed" (404) as root' );
    req( $test, 404, 'root', 'GET', "$base/4534" );

    note( 'GET history of various invalid EIDs' );
    foreach my $inv_eid ( 'asas', '!*!*', 'A long list of useless words followed by lots of spaces                                           \\,', '3.1415926', '; drop database dochazka-test;' ) {
        foreach my $user ( qw( demo root ) ) {
            req( $test, 400, 'demo', 'GET', "$base/$inv_eid" );
        }
    }

    foreach my $inv_eid ( '0', '-1' ) {
        # - as demo
        req( $test, 403, 'demo', 'GET', "$base/$inv_eid" );
        # - as root
        req( $test, 404, 'root', 'GET', "$base/$inv_eid" );
    }

    foreach my $inv_eid ( '3443/plus/several/bogus/levels/of/subresources' ) {
        # - as demo (entire resource is invalid, so ACL check is not reached)
        req( $test, 400, 'demo', 'GET', "$base/$inv_eid" );
        # - as root
        req( $test, 400, 'root', 'GET', "$base/$inv_eid" );
    }

    note( 'PUT' );
    req( $test, 405, 'demo', 'PUT', "$base/2" );
    req( $test, 405, 'active', 'PUT', "$base/2" );
    req( $test, 405, 'root', 'PUT', "$base/2" );
    
    note( 'POST' );

    note( 'dates before 1892-01-01 will not make it through the trigger' );
    foreach my $ts ( 
        '1869-04-28 19:15',
        '1891-01-01 00:00',
        '1891-12-31 23:55',
        '1000-01-01 00:05',
        '1500-12-20',
    ) {
        $j = ( $base =~ m/^priv/ )
            ? "{ \"effective\":\"$ts\", \"priv\":\"inactive\" }"
            : "{ \"effective\":\"$ts\", \"sid\":$ts_sid }";
        dbi_err( $test, 500, 'root', 'POST', "$base/2", 
            $j,
            qr/No dates earlier than 1892-01-01 please/
        );
    }

    note( 'we will be inserting a bunch of records so push them onto an array' );
    note( 'for easy deletion later' );
    my @history_recs_to_delete;
    # - be nice
    $j = ( $base =~ m/^priv/ )
        ? '{ "effective":"1969-04-28 19:15", "priv":"inactive" }'
        : '{ "effective":"1969-04-28 19:15", "sid":' . $ts_sid . ' }';

    req( $test, 403, 'demo', 'POST', "$base/2", $j );
    $status = req( $test, 201, 'root', 'POST', "$base/2", $j );
    if ( $status->not_ok ) {
        diag( $status->code . ' ' . $status->text );
    }
    is( $status->level, 'OK' );
    my $pho = $status->payload;
    my $prop = ( $base =~ m/^priv/ ) ? 'phid' : 'shid';
    ok( exists $pho->{$prop}, "$prop exists in payload after POST $base/2" );
    ok( defined $pho->{$prop}, "$prop defined in payload after POST $base/2" );
    push @history_recs_to_delete, { eid => $pho->{eid}, $prop => $pho->{$prop} };

    note( 'be pathological' );
    $j = '{ "effective":"1979-05-24", "horse" : "E-Or" }';
    req( $test, 403, 'demo', 'POST', "$base/2", $j );
    req( $test, 400, 'root', 'POST', "$base/2", $j );

    note( 'addition of privlevel makes the above request less pathological' );
    $j = ( $base =~ m/^priv/ )
        ? '{ "effective":"1979-05-24", "horse" : "E-Or", "priv" : "admin" }'
        : '{ "effective":"1979-05-24", "horse" : "E-Or", "sid" : ' . $ts_sid . ' }';
    req( $test, 403, 'demo', 'POST', "$base/2", $j );
    $status = req( $test, 201, 'root', 'POST', "$base/2", $j );
    is( $status->level, 'OK' );
    $pho = $status->payload;
    push @history_recs_to_delete, { eid => $pho->{eid}, $prop => $pho->{$prop} };

    if ( $base =~ m/^priv/ ) {
        # check if demo really is an admin
        $status = req( $test, 200, 'demo', 'GET', "employee/self/full" );
        is( $status->level, 'OK' );
        is( $status->code, 'DISPATCH_EMPLOYEE_PROFILE_FULL' );
        ok( exists $status->{'payload'} );
        ok( exists $status->payload->{'priv'} );
        is( $status->payload->{'priv'}, 'admin' );
    }

    note( 'DELETE' );
    req( $test, 405, 'demo', 'DELETE', "$base/2" );
    req( $test, 405, 'active', 'DELETE', "$base/2" );
    req( $test, 405, 'root', 'DELETE', "$base/2" );
    
    note( 'teardown: we have some records queued for deletion' );
    delete_history_recs( $base, \@history_recs_to_delete );
    @history_recs_to_delete = ();
}

note( '===========================================' );
note( '"{priv,schedule}/history/eid/:eid/:tsrange" resource' );
note( '===========================================' );

foreach $base ( "priv/history/eid", "schedule/history/eid" ) {
    note( "testing $base" );

    note( 'docu_check()' );
    docu_check($test, "$base/:eid/:tsrange");

    note( 'GET' );

    note( 'fail 403 as demo' );
    req( $test, 403, 'demo', 'GET', $base. '/' . $site->DOCHAZKA_EID_OF_ROOT . 
        '/[1891-12-30, 1892-01-02)' );

    note( 'root employee, with tsrange, records found' );
    note( "GET $base" . '/' . $site->DOCHAZKA_EID_OF_ROOT . 
        '/[1891-12-30, 1892-01-02)' );
    $status = req( $test, 200, 'root', 'GET', $base. '/' . $site->DOCHAZKA_EID_OF_ROOT . 
        '/[1891-12-30, 1892-01-02)' );
    is( $status->level, 'OK' );
    is( $status->code, "DISPATCH_RECORDS_FOUND" );
    ok( defined $status->payload );
    ok( exists $status->payload->{'eid'} );
    is( $status->payload->{'eid'}, $site->DOCHAZKA_EID_OF_ROOT );
    ok( exists $status->payload->{'history'} );
    is( scalar @{ $status->payload->{'history'} }, 1 );
    is( $status->payload->{'history'}->[0]->{'eid'}, $site->DOCHAZKA_EID_OF_ROOT );
    ok( exists $status->payload->{'history'}->[0]->{'effective'} );

    my $uri = $base . '/' .  $site->DOCHAZKA_EID_OF_ROOT .
              '/[1999-12-31 23:59, 2000-01-01 00:01)';

    note( 'fail 403 as demo' );
    req( $test, 403, 'demo', 'GET', $uri );

    note( '"succeed" (404) as root' );
    req( $test, 404, 'root', 'GET', $uri );

    note( 'non-existent EID');
    my $tsr = '[1999-12-31 23:59, 2000-01-01 00:01)';
    req( $test, 403, 'demo', 'GET', "$base/4534/$tsr" );
    req( $test, 404, 'root', 'GET', "$base/4534/$tsr" );

    note( 'invalid EID (caught by Path::Router validations)' );
    foreach my $user ( qw( demo root ) ) {
        req( $test, 400, $user, 'GET', "$base/asas/$tsr" );
    }
    
    note( 'PUT, POST, DELETE' );
    foreach my $user ( qw( demo root ) ) {
        foreach my $method ( qw( PUT POST DELETE ) ) {
            req( $test, 405, $user, $method, "$base/23/[,)" );
        }
    }
}


note( '===========================================' );
note( '"{priv,schedule}/history/eid/:eid/:ts" resource' );
note( '===========================================' );

foreach my $prop ( "priv", "schedule" ) {
    my $base = "$prop/history/eid";
    note( "testing $base/:eid/:ts" );

    note( 'docu_check()' );
    docu_check($test, "$base/:eid/:ts");

    note( 'GET' );

    note( 'fail 403 as demo' );
    req( $test, 403, 'demo', 'GET', $base. '/' . $site->DOCHAZKA_EID_OF_ROOT . 
        '/1891-12-30' );

    note( 'root employee, record found' );
    note( "GET $base" . '/' . $site->DOCHAZKA_EID_OF_ROOT . 
        '/1892-01-01 00:00' );
    $status = req( $test, 200, 'root', 'GET', $base. '/' . $site->DOCHAZKA_EID_OF_ROOT . 
        '/1892-01-01 00:00' );
    is( $status->level, 'OK' );
    is( $status->code, "DISPATCH_RECORDS_FOUND" );
    ok( defined $status->payload );
    ok( exists $status->payload->{'eid'} );
    is( $status->payload->{'eid'}, $site->DOCHAZKA_EID_OF_ROOT );
    if ( $prop eq 'priv' ) {
        ok( exists $status->payload->{'phid'} );
    } elsif ( $prop eq 'schedule' ) {
        ok( exists $status->payload->{'shid'} );
    } else {
        diag( "A very bad thing happened" );
        BAIL_OUT(0);
    }
    ok( exists $status->payload->{'effective'} );

    my $uri = $base . '/' .  $site->DOCHAZKA_EID_OF_ROOT .
              '/"1891-12-31 23:59:59"';

    note( 'fail 403 as demo' );
    req( $test, 403, 'demo', 'GET', $uri );

    note( '"succeed" (404) as root' );
    req( $test, 404, 'root', 'GET', $uri );

    note( 'non-existent EID');
    my $ts = '\'2015-01-06 14:55\'';
    req( $test, 403, 'demo', 'GET', "$base/4534/$ts" );
    req( $test, 404, 'root', 'GET', "$base/4534/$ts" );

    note( 'invalid EID (caught by Path::Router validations)' );
    foreach my $user ( qw( demo root ) ) {
        req( $test, 400, $user, 'GET', "$base/asas/$ts" );
    }

    note( 'PUT, POST, DELETE' );
    foreach my $user ( qw( demo root ) ) {
        foreach my $method ( qw( PUT POST DELETE ) ) {
            req( $test, 405, $user, $method, "$base/23/1966-09-28 00:00" );
        }
    }
}


note( '===========================================' );
note( '"{priv,schedule}/history/eid/:eid/now" resource' );
note( '===========================================' );

foreach my $prop ( "priv", "schedule" ) {
    my $base = "$prop/history/eid";
    note( "testing $base/:eid/now" );

    note( 'docu_check()' );
    docu_check($test, "$base/:eid/now");

    note( 'GET' );

    note( 'fail 403 as demo' );
    req( $test, 403, 'demo', 'GET', $base. '/' . $site->DOCHAZKA_EID_OF_ROOT . 
        '/now' );

    note( 'root employee, record found' );
    note( "GET $base" . '/' . $site->DOCHAZKA_EID_OF_ROOT . '/now' );
    $status = req( $test, 200, 'root', 'GET', $base. '/' . $site->DOCHAZKA_EID_OF_ROOT . 
        '/now' );
    is( $status->level, 'OK' );
    is( $status->code, "DISPATCH_RECORDS_FOUND" );
    ok( defined $status->payload );
    ok( exists $status->payload->{'eid'} );
    is( $status->payload->{'eid'}, $site->DOCHAZKA_EID_OF_ROOT );
    if ( $prop eq 'priv' ) {
        ok( exists $status->payload->{'phid'} );
    } elsif ( $prop eq 'schedule' ) {
        ok( exists $status->payload->{'shid'} );
    } else {
        diag( "A very bad thing happened" );
        BAIL_OUT(0);
    }
    ok( exists $status->payload->{'effective'} );

    my $uri = $base . '/' .  $site->DOCHAZKA_EID_OF_ROOT . '/now';

    note( 'fail 403 as demo' );
    req( $test, 403, 'demo', 'GET', $uri );

    $uri = $base . '/' .  $site->DOCHAZKA_EID_OF_DEMO . '/now';

    note( '"succeed" (404) as root' );
    req( $test, 404, 'root', 'GET', $uri );

    note( 'non-existent EID');
    my $ts = '\'2015-01-06 14:55\'';
    req( $test, 403, 'demo', 'GET', "$base/4534/now" );
    req( $test, 404, 'root', 'GET', "$base/4534/now" );

    note( 'invalid EID (caught by Path::Router validations)' );
    foreach my $user ( qw( demo root ) ) {
        req( $test, 400, $user, 'GET', "$base/asas/now" );
    }

    note( 'PUT, POST, DELETE' );
    foreach my $user ( qw( demo root ) ) {
        foreach my $method ( qw( PUT POST DELETE ) ) {
            req( $test, 405, $user, $method, "$base/23/now" );
        }
    }
}


#===========================================
# "{priv,schedule}/history/nick/:nick" resource
#===========================================
foreach $base ( "priv/history/nick", "schedule/history/nick" ) {
    note( "testing $base" );

    note( 'docu_check()' );
    docu_check($test, "$base/:nick");

    note( 'GET' );
    note( 'root employee: fail 403 as demo' );
    req( $test, 403, 'demo', 'GET', "$base/root" );
    note( 'root employee: succeed as root' );
    $status = req( $test, 200, 'root', 'GET', "$base/root" );
    is( $status->level, 'OK' );
    is( $status->code, "DISPATCH_RECORDS_FOUND" );
    ok( defined $status->payload );
    ok( exists $status->payload->{'nick'} );
    is( $status->payload->{'nick'}, 'root' );
    ok( exists $status->payload->{'history'} );
    is( scalar @{ $status->payload->{'history'} }, 1 );
    is( $status->payload->{'history'}->[0]->{'eid'}, 1 );
    ok( exists $status->payload->{'history'}->[0]->{'effective'} );

    note( 'non-existent employee' );
    req( $test, 403, 'demo', 'GET', "$base/rotoroot" );
    req( $test, 404, 'root', 'GET', "$base/rotoroot" );
    
    note( 'PUT' );
    req( $test, 405, 'demo', 'PUT', "$base/asdf" );
    req( $test, 405, 'root', 'PUT', "$base/asdf" );
    
    note( "POST" );
    $j = ( $base =~ m/^priv/ ) 
        ? '{ "effective":"1969-04-27 9:45", "priv":"inactive" }'
        : '{ "effective":"1969-04-27 9:45", "sid":' . $ts_sid . ' }';
    req( $test, 403, 'demo', 'POST', "$base/demo", $j );
    $status = req( $test, 201, 'root', 'POST', "$base/demo", $j );
    if ( $status->not_ok ) {
        diag( $status->code . ' ' . $status->text );
    }
    is( $status->level, 'OK' );
    my $pho = $status->payload;
    my $prop = ( $base =~ m/^priv/ ) ? 'phid' : 'shid';
    push my @history_recs_to_delete, { nick => 'demo', $prop => $pho->{$prop} };
    
    note( 'DELETE' );
    req( $test, 405, 'demo', 'DELETE', "$base/madagascar" );
    req( $test, 405, 'active', 'DELETE', "$base/madagascar" );
    req( $test, 405, 'root', 'DELETE', "$base/madagascar" );
   
    note( 'teardown: we have some records queued for deletion' );
    delete_history_recs( $base, \@history_recs_to_delete );
    @history_recs_to_delete = ();
}


note( '===========================================' );
note( '"{priv,schedule}/history/nick/:nick/:tsrange" resource' );
note( '===========================================' );

foreach $base ( "priv/history/nick", "schedule/history/nick" ) {
    note( "testing $base" );

    note( 'docu_check()' );
    docu_check($test, "$base/:nick/:tsrange");

    note( 'GET' );

    note( 'GET root: fail 403 as demo' ); 
    req( $test, 403, 'demo', 'GET', "$base/root/[1891-12-30, 1892-01-02)" );
    note( 'GET root as root: employee, with tsrange, records found' );
    $status = req( $test, 200, 'root', 'GET', "$base/root/[1891-12-30, 1892-01-02)" );
    is( $status->level, 'OK' );
    is( $status->code, "DISPATCH_RECORDS_FOUND" );
    ok( defined $status->payload );
    ok( exists $status->payload->{'nick'} );
    is( $status->payload->{'nick'}, 'root' );
    ok( exists $status->payload->{'history'} );
    is( scalar @{ $status->payload->{'history'} }, 1 );
    is( $status->payload->{'history'}->[0]->{'eid'}, 1 );
    ok( exists $status->payload->{'history'}->[0]->{'effective'} );

    note( 'non-existent employee' );
    my $tsr = '[1891-12-30, 1892-01-02)';
    req( $test, 403, 'demo', 'GET', "$base/humphreybogart/$tsr" );
    req( $test, 404, 'root', 'GET', "$base/humphreybogart/$tsr" );

    note( 'root employee, with tsrange but no records found' );
    req( $test, 403, 'demo', 'GET', "$base/root/[1999-12-31 23:59, 2000-01-01 00:01)" );
    req( $test, 404, 'root', 'GET', "$base/root/[1999-12-31 23:59, 2000-01-01 00:01)" );
    
    note( 'PUT, POST, DELETE' );
    foreach my $user ( qw( demo root ) ) {
        foreach my $method ( qw( PUT POST DELETE ) ) {
            req( $test, 405, $user, $method, "$base/root/[1999-12-31 23:59, 2000-01-01 00:01)" );
        }
    }
}    


note( '===========================================' );
note( '"{priv,schedule}/history/phid/:phid" resource' );
note( '===========================================' );

foreach $base ( "priv/history/phid", "schedule/history/shid" ) {
    my $prop = ( $base =~ m/^priv/ ) ? 'phid' : 'shid';
    note( "now testing the $base/:$prop resource" );
    docu_check($test, "$base/:$prop" );

    note( 'preparation' );
    my $tphid;
    if ( $base =~ m/^priv/ ) {
        note( 'priv-specific preparations' );
        
        note( 'check that demo is a passerby to start with' );
        $status = req( $test, 200, 'demo', 'GET', "priv/self" );
        is( $status->level, 'OK' );
        is( $status->payload->{'priv'}, "passerby" );
        
        note( 'make demo an "inactive" user as of 1977-04-27 15:30' );
        $status = req( $test, 201, 'root', 'POST', "priv/history/nick/demo", 
            '{ "effective":"1977-04-27 15:30", "priv":"inactive" }' );
        is( $status->level, 'OK' );
        is( $status->code, 'DOCHAZKA_CUD_OK' );
        # we use regex comparison in the next test because the exact string
        # returned depends on the timezone setting
        like( $status->payload->{'effective'}, qr/1977-04-27 15:30:00/ );
        is( $status->payload->{'priv'}, 'inactive' );
        is( $status->payload->{'remark'}, undef );
        is( $status->payload->{'eid'}, 2 );
        ok( $status->payload->{'phid'} );
        $tphid = $status->payload->{'phid'};
        
        note( 'check that demo is really inactive now' );
        $status = req( $test, 200, 'demo', 'GET', "priv/self" );
        is( $status->level, 'OK' );
        is( $status->payload->{'priv'}, "inactive" );
    } else {
        note( 'schedule-specific preparations' );

        note( 'give demo a schedule effective 1977-04-27 15:30' );
        $status = req( $test, 201, 'root', 'POST', 'schedule/history/nick/demo', 
            '{ "effective":"1977-04-27 15:30", "sid":' . $ts_sid . ' }' );
        is( $status->level, 'OK' );
        is( $status->code, 'DOCHAZKA_CUD_OK' );
        $tphid = $status->payload->{'shid'};
    }
    
    note( 'GET' );

    note( "GET $base/$tphid as root" );
    $status = req( $test, 200, 'root', 'GET', "$base/$tphid" );
    is( $status->level, 'OK' );
    is( $status->code, 'DISPATCH_HISTORY_RECORD_FOUND' );
    is( $status->payload->{'remark'}, undef );
    is( $status->payload->{ ( ( $base =~ m/^priv/ ) ? 'priv' : 'sid' ) },
        ( ( $base =~ m/^priv/ ) ? 'inactive' : $ts_sid ) );
    is( $status->payload->{'eid'}, 2 );
    is( $status->payload->{$prop}, $tphid );
    like( $status->payload->{'effective'}, qr/1977-04-27 15:30:00/ );
    
    note( 'PUT' );

    note( "PUT operations on $base/$tphid will fail with 405" );
    foreach my $user ( qw( demo root ) ) {
        req( $test, 405, $user, 'PUT', "$base/$tphid" );
    }
    
    note( 'POST' );

    note( "Update the history record inserted above" );
    $status = req( $test, 200, 'root', 'POST', "$base/$tphid", <<"EOS" );
{ "remark" : "I am foo!" }
EOS
    is( $status->level, 'OK' );
    is( $status->code, 'DOCHAZKA_CUD_OK' );
    ok( defined $status->payload );
    ok( exists $status->payload->{'remark'} );
    is( $status->payload->{'remark'}, 'I am foo!' );

    note( "Get the updated history record and check it just to be sure" );
    $status = req( $test, 200, 'root', 'GET', "$base/$tphid" );
    ok( $status->ok );
    is( $status->payload->{'remark'}, 'I am foo!' );

    note( 'DELETE' );

    note( 'delete the privhistory record we created earlier' );
    $status = req( $test, 200, 'root', 'DELETE', "$base/$tphid" );
    is( $status->level, "OK" );
    is( $status->code, 'DOCHAZKA_CUD_OK' );
    
    note( 'not there anymore' );
    req( $test, 404, 'root', 'GET', "$base/$tphid" );
    
    note( 'and demo is a passerby again' );
    $status = req( $test, 200, 'demo', 'GET', "priv/self" );
    is( $status->level, 'OK' );
    is( $status->payload->{'priv'}, "passerby" );
} 

note( 'tear down' );
$status = delete_all_attendance_data();
BAIL_OUT(0) unless $status->ok;

done_testing;
