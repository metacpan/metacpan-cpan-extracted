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
# test employee resources
#

#!perl
use 5.012;
use strict;
use warnings;
use utf8;

#use App::CELL::Test::LogToFile;
use App::CELL qw( $log $meta $site );
use App::Dochazka::REST::ConnBank qw( $dbix_conn );
use App::Dochazka::REST::Test;
use Data::Dumper;
use JSON;
use Plack::Test;
use Test::JSON;
use Test::More;
use Test::Warnings;

note( 'initialize, connect to database, and set up a testing plan' );
my $app = initialize_regression_test();

note( 'check a random site param' );
ok( $site->DOCHAZKA_DBUSER );

note( 'instantiate Plack::Test object' );
my $test = Plack::Test->create( $app );
isa_ok( $test, 'Plack::Test::MockHTTP' );

my $res;


note( '=============================' );
note( '"employee/count/?:priv" resource' );
note( '=============================' );
my $base = 'employee/count';
docu_check( $test, "$base/?:priv" );

note( "GET $base/?:priv" );
note( '- fail 403 as demo' );
my $status = req( $test, 403, 'demo', 'GET', $base );

note( 'succeed as root' );
$status = req( $test, 200, 'root', 'GET', $base );
is( $status->level, 'OK', "GET $base 2" );
is( $status->code, 'DISPATCH_COUNT_EMPLOYEES', "GET $base 3" );

note( 'demonstrate that :priv parameter is case-insensitive' );
foreach my $priv ( qw( passerby PASSERBY paSsERby inactive
    INACTIVE inAcTive active ACTIVE actIVe admin ADMIN AdmiN
) ) {
    #diag( "$base/$priv" );
    $status = req( $test, 200, 'root', 'GET', "$base/$priv" );
    is( $status->level, "OK", "GET $base/:priv 2" );
    if( $status->code ne 'DISPATCH_COUNT_EMPLOYEES' ) {
        diag( Dumper $status );
        BAIL_OUT(0);
    }
    is( $status->code, 'DISPATCH_COUNT_EMPLOYEES', "GET $base/:priv 3" );
    ok( defined $status->payload, "GET $base/:priv 4" );
    ok( exists $status->payload->{'priv'}, "GET $base/:priv 5" );
    is( $status->payload->{'priv'}, lc $priv, "GET $base/:priv 6" );
    ok( exists $status->payload->{'count'}, "GET $base/:priv 7" );
    #
    req( $test, 403, 'demo', 'GET', "$base/$priv" );
}

note( 'demonstrate that invalid values of :priv are not accepted' );
foreach my $priv (
    '*pimpled teenager*',
    'nanaan',
    '%^%#$#',
#    'Žluťoucký kǔň',
    '      dfdf fifty-five sixty-five',
    'passerbies',
    '///adfd/asdf/asdf',
) {
    req( $test, 400, 'root', 'GET', "$base/$priv" );
    req( $test, 400, 'demo', 'GET', "$base/$priv" );
}

note( "PUT, POST, DELETE $base" );

note( 'fail 405 as demo, active, root, WOMBAT' );
$status = req( $test, 405, 'demo', 'PUT', $base );
$status = req( $test, 405, 'active', 'PUT', $base );
$status = req( $test, 405, 'WOMBAT', 'PUT', $base );
$status = req( $test, 405, 'root', 'PUT', $base );
$status = req( $test, 405, 'demo', 'POST', $base );
$status = req( $test, 405, 'active', 'POST', $base );
$status = req( $test, 405, 'root', 'POST', $base );
$status = req( $test, 405, 'demo', 'DELETE', $base );
$status = req( $test, 405, 'active', 'DELETE', $base );
$status = req( $test, 405, 'root', 'DELETE', $base );

$base .= '/admin';

note( "PUT, POST, DELETE $base" );

note( 'fail 405 for demo, active, root' );
$status = req( $test, 405, 'demo', 'PUT', $base );
$status = req( $test, 405, 'active', 'PUT', $base );
$status = req( $test, 405, 'root', 'PUT', $base );
$status = req( $test, 405, 'demo', 'POST', $base );
$status = req( $test, 405, 'active', 'POST', $base );
$status = req( $test, 405, 'root', 'POST', $base );
$status = req( $test, 405, 'demo', 'DELETE', $base );
$status = req( $test, 405, 'active', 'DELETE', $base );
$status = req( $test, 405, 'root', 'DELETE', $base );


note( '=============================' );
note( '"employee/self" resource' );
note( '=============================' );

my $ts_eid_inactive = create_inactive_employee( $test );
my $ts_eid_active = create_active_employee( $test );

foreach my $base ( "employee/self" ) {
    docu_check($test, $base);
    
    note( "looping GET $base" );
    $status = req( $test, 200, 'demo', 'GET', $base );
    is( $status->level, 'OK' );
    is( $status->code, 'DISPATCH_EMPLOYEE_SELF', "GET $base 3" );
    ok( defined $status->payload, "GET $base 4" );
    is_deeply( $status->payload, {
        'eid' => 2,
        'sec_id' => undef,
        'nick' => 'demo',
        'fullname' => 'Demo Employee',
        'email' => 'demo@dochazka.site',
        'supervisor' => undef,
        'sync' => 0,
    }, "GET $base 5");
    #
    $status = req( $test, 200, 'root', 'GET', $base );
    is( $status->level, 'OK' );
    is( $status->code, 'DISPATCH_EMPLOYEE_SELF', "GET $base 8" );
    ok( defined $status->payload, "GET $base 9" );
    is_deeply( $status->payload, {
        'eid' => 1,
        'sec_id' => undef,
        'nick' => 'root',
        'fullname' => 'Root Immutable',
        'email' => 'root@site.org',
        'supervisor' => undef,
        'remark' => 'dbinit',
        'sync' => 0,
    }, "GET $base 10" );
    
    note( "looping: PUT $base" );
    $status = req( $test, 405, 'demo', 'PUT', $base );
    $status = req( $test, 405, 'active', 'PUT', $base );
    $status = req( $test, 405, 'root', 'PUT', $base );
    
    note( "looping: POST $base" );
    note( "- default configuration is that 'active' and 'inactive' can modify" );
    note( '  their own passhash and salt fields; demo should *not* be ' );
    note( ' authorized to do this' );

    req( $test, 403, 'demo', 'POST', $base, '{ "password":"saltine" }' );
    foreach my $user ( "active", "inactive" ) {
        #
        #diag( "$user $base " . '{ "password" : "saltine" }' );
        $status = req( $test, 200, $user, 'POST', $base, '{ "password" : "saltine" }' );
        if ( $status->not_ok ) {
            diag( Dumper $status );
            BAIL_OUT(0);
        }
        is( $status->level, 'OK' );
        is( $status->code, 'DOCHAZKA_CUD_OK' ); 
        
        note( '- use root to change it back, otherwise the user won\'t be able' );
        note( '  to log in and next tests will fail' );
        $status = req( $test, 200, 'root', 'PUT', "employee/nick/$user", "{ \"password\" : \"$user\" }" );
        is( $status->level, 'OK' );
        is( $status->code, 'DOCHAZKA_CUD_OK' ); 
        
        note( '- legal but bogus JSON in body' );
        $status = req( $test, 200, $user, 'POST', $base, 0 );
        is( $status->level, 'OK' );
        is( $status->code, 'DISPATCH_UPDATE_NO_CHANGE_OK' ); 
        
        note( "- 'salt' is a permitted field, but 'inactive'/$user employees" );
        note( "  should not, for example, be allowed to change 'nick'" );
        req( $test, 403, $user, 'POST', $base, '{ "nick": "wanger" }' );
    }
    
    note( 'root can theoretically update any field, but certain fields of its own' );
    note( 'profile are immutable' );
    $status = req( $test, 200, 'root', 'POST', $base, '{ "email": "root@rotoroot.com" }' );
    is( $status->level, 'OK' );
    is( $status->code, 'DOCHAZKA_CUD_OK' );
    
    $status = req( $test, 200, 'root', 'POST', $base, '{ "email": "root@site.org" }' );
    is( $status->level, 'OK' );
    is( $status->code, 'DOCHAZKA_CUD_OK' );
   
    dbi_err( $test, 500, 'root', 'POST', $base, '{ "nick": "aaaaazz" }', qr/root employee is immutable/ );
    

    note( "DELETE $base" );
    $status = req( $test, 405, 'demo', 'DELETE', $base );
    $status = req( $test, 405, 'active', 'DELETE', $base );
    $status = req( $test, 405, 'root', 'DELETE', $base );
}


note( '=============================' );
note( '"employee/self/full" resource' );
note( '=============================' );

$base = "employee/self";
my $resource = "$base/full";
docu_check( $test, $resource );

foreach my $originator ( 'demo', 'inactive', 'active', 'root' ) {

    my $uri;
    if ( $base eq 'employee/nick' ) {
        $uri = "employee/nick/$originator/full";
    } elsif ( $base eq 'employee/self' ) {
        $uri = 'employee/self/full';
    } else {
        diag( "Bad loop!" );
        BAIL_OUT(0);
    }

    $status = req( $test, 200, $originator, 'GET', $uri );
    is( $status->level, 'OK' );
    is( $status->code, 'DISPATCH_EMPLOYEE_PROFILE_FULL' );
    ok( defined $status->payload );
    ok( exists $status->payload->{'emp'} );
    ok( exists $status->payload->{'has_reports'} );
    ok( exists $status->payload->{'priv'} );
    ok( exists $status->payload->{'privhistory'} );
    ok( exists $status->payload->{'schedule'} );
    ok( exists $status->payload->{'schedhistory'} );
    is( $status->payload->{'emp'}->{'nick'}, $originator );
    if ( $originator eq 'demo' ) {
        is( $status->payload->{'priv'}, 'passerby' );
        is( $status->payload->{'privhistory'}, undef );
    } elsif ( $originator eq 'inactive' ) {
        is( $status->payload->{'priv'}, 'inactive' );
        is( ref( $status->payload->{'privhistory'} ), 'HASH' );
        ok( exists $status->payload->{'privhistory'}->{'phid'} );
    } elsif ( $originator eq 'active' ) {
        is( $status->payload->{'priv'}, 'active' );
        is( ref( $status->payload->{'privhistory'} ), 'HASH' );
        ok( exists $status->payload->{'privhistory'}->{'phid'} );
    } elsif ( $originator eq 'root' ) {
        is( $status->payload->{'priv'}, 'admin' );
        is( ref( $status->payload->{'privhistory'} ), 'HASH' );
        ok( exists $status->payload->{'privhistory'}->{'phid'} );
    } else {
        diag( "bad \$originator ($originator) in test loop" );
        BAIL_OUT(0);
    }
    is( $status->payload->{'schedule'}, undef );
    is( $status->payload->{'schedhistory'}, undef );

    note( "PUT, POST, DELETE $resource" );
    $status = req( $test, 405, $originator, 'PUT', $uri );
    $status = req( $test, 405, $originator, 'POST', $uri );
    $status = req( $test, 405, $originator, 'DELETE', $uri );

}

    
note( '=============================' );
note( '"employee/eid/:eid/full" resource' );
note( '"employee/nick/:nick/full" resource' );
note( '=============================' );

map { docu_check( $test, $_ ); } 
    ( 'employee/eid/:eid/full', 'employee/nick/:nick/full' );

my %eid_map = (
    'demo' => $site->DOCHAZKA_EID_OF_DEMO,
    'inactive' => $ts_eid_inactive,
    'active' => $ts_eid_active,
    'root' => $site->DOCHAZKA_EID_OF_ROOT,
);

foreach my $nick ( 'demo', 'inactive' ) {
    my $eid = $eid_map{$nick};
    foreach my $uri ( "employee/eid/$eid/full", "employee/nick/$nick/full" ) {
        note( "$nick tries and fails to use $uri resource" );
        req( $test, 403, $nick, 'GET', $uri );
        req( $test, 405, $nick, 'PUT', $uri );
        req( $test, 405, $nick, 'POST', $uri );
        req( $test, 405, $nick, 'DELETE', $uri );
    }
}

foreach my $nick ( 'demo', 'inactive', 'active' ) {
    foreach my $uri ( "employee/eid/1/full", "employee/nick/root/full" ) {
        note( "$nick tries and fails to use $uri resource" );
        req( $test, 403, $nick, 'GET', $uri );
        req( $test, 405, $nick, 'PUT', $uri );
        req( $test, 405, $nick, 'POST', $uri );
        req( $test, 405, $nick, 'DELETE', $uri );
    }
}

sub _employee_full_success {
    my ( $originator, $nick, $uri ) = @_;

    note( "$nick tries and succeeds to use $uri resource" );
    $status = req( $test, 200, $originator, 'GET', $uri );
    is( $status->level, 'OK' );
    is( $status->code, 'DISPATCH_EMPLOYEE_PROFILE_FULL' );
    ok( defined $status->payload );
    ok( exists $status->payload->{'emp'} );
    ok( exists $status->payload->{'priv'} );
    ok( exists $status->payload->{'privhistory'} );
    ok( exists $status->payload->{'schedule'} );
    ok( exists $status->payload->{'schedhistory'} );
    is( $status->payload->{'emp'}->{'nick'}, $nick );
    if ( $nick eq 'demo' ) {
        is( $status->payload->{'priv'}, 'passerby' );
        is( $status->payload->{'privhistory'}, undef );
    } elsif ( $nick eq 'inactive' ) {
        is( $status->payload->{'priv'}, 'inactive' );
        is( ref( $status->payload->{'privhistory'} ), 'HASH' );
        ok( exists $status->payload->{'privhistory'}->{'phid'} );
    } elsif ( $nick eq 'active' ) {
        is( $status->payload->{'priv'}, 'active' );
        is( ref( $status->payload->{'privhistory'} ), 'HASH' );
        ok( exists $status->payload->{'privhistory'}->{'phid'} );
    } elsif ( $nick eq 'root' ) {
        is( $status->payload->{'priv'}, 'admin' );
        is( ref( $status->payload->{'privhistory'} ), 'HASH' );
        ok( exists $status->payload->{'privhistory'}->{'phid'} );
    } else {
        diag( "bad \$nick ($nick) in test loop" );
        BAIL_OUT(0);
    }
    is( $status->payload->{'schedule'}, undef );
    is( $status->payload->{'schedhistory'}, undef );
}

foreach my $nick ( 'active', 'root' ) {
    my $eid = $eid_map{$nick};
    foreach my $uri ( "employee/eid/$eid/full", "employee/nick/$nick/full" ) {

        _employee_full_success( $nick, $nick, $uri );

        note( "PUT, POST, DELETE $resource" );
        req( $test, 405, $nick, 'PUT', $uri );
        req( $test, 405, $nick, 'POST', $uri );
        req( $test, 405, $nick, 'DELETE', $uri );
    }
}

foreach my $uri ( "employee/eid/$ts_eid_inactive/full", "employee/nick/inactive/full" ) {
    _employee_full_success( 'root', 'inactive', $uri );
}


note( '=============================' );
note( '"employee/eid" resource' );
note( '=============================' );
$base = "employee/eid";

note( "docu_check on $base" );
docu_check($test, "employee/eid");

note( "GET, PUT: $base" );
req( $test, 405, 'demo', 'GET', $base );
req( $test, 405, 'active', 'GET', $base );
req( $test, 405, 'root', 'GET', $base );
req( $test, 405, 'demo', 'PUT', $base );
req( $test, 405, 'active', 'PUT', $base );
req( $test, 405, 'root', 'PUT', $base );

note( "POST: $base" );

note( "create a 'mrfu' employee" );
my $mrfu = create_bare_employee( { nick => 'mrfu', password => 'mrfu' } );
my $eid_of_mrfu = $mrfu->eid;

# these tests break when 'email' is added to DOCHAZKA_PROFILE_EDITABLE_FIELDS
## - give Mr. Fu an email address
##req( $test, 403, 'demo', 'POST', $base, '{ "eid": ' . $mrfu->eid . ', "email" : "shake it" }' );
# 
##is( $mrfu->nick, 'mrfu' );
##req( $test, 403, 'mrfu', 'POST', $base, '{ "eid": ' . $mrfu->eid . ', "email" : "shake it" }' );
# fails because mrfu is a passerby

note( "make mrfu an inactive" );
$status = req( $test, 201, 'root', 'POST', "priv/history/eid/" . $mrfu->eid, <<"EOH" );
{ "priv" : "inactive", "effective" : "2004-01-01" }
EOH
is( $status->level, "OK", 'POST employee/eid 3' );
is( $status->code, "DOCHAZKA_CUD_OK", 'POST employee/eid 3' );
ok( exists $status->payload->{'phid'} );
my $mrfu_phid = $status->payload->{'phid'};

# these tests break when 'email' is added to DOCHAZKA_PROFILE_EDITABLE_FIELDS
## - try the operation again - it still fails because inactives can not change their email
##req( $test, 403, 'mrfu', 'POST', $base, '{ "eid": ' . $mrfu->eid . ', "email" : "shake it" }' );

note( "inactive mrfu can change his password" );
$status = req( $test, 200, 'mrfu', 'POST', $base, '{ "eid": ' . $mrfu->eid . ', "password" : "shake it" }' );
is( $status->level, "OK", 'POST employee/eid 3' );
is( $status->code, 'DOCHAZKA_CUD_OK', 'POST employee/eid 4' );

note( "but now mrfu cannot log in, because req assumes password is 'mrfu'" );
req( $test, 401, 'mrfu', 'GET', 'employee/nick/mrfu' );

note( "so, use root powers to change the password back" );
$eid_of_mrfu = $mrfu->eid;
$status = req( $test, 200, 'root', 'POST', $base, <<"EOH" );
{ "eid" : $eid_of_mrfu, "password" : "mrfu" }
EOH
is( $status->level, "OK", 'POST employee/eid 3' );
is( $status->code, "DOCHAZKA_CUD_OK", 'POST employee/eid 3' );

note( "and now mrfu can log in" );
$status = req( $test, 200, 'mrfu', 'GET', 'employee/nick/mrfu' );
is( $status->level, "OK", 'POST employee/eid 3' );
is( $status->payload->{'remark'}, undef );
is( $status->payload->{'sec_id'}, undef );
is( $status->payload->{'nick'}, 'mrfu' );
is( $status->payload->{'email'}, undef );
is( $status->payload->{'fullname'}, undef );

note( "attempt by demo to update mrfu to a different nick" );
#diag("--- POST employee/eid (update with different nick)");
req( $test, 403, 'demo', 'POST', $base, '{ "eid": ' . $mrfu->eid . ', "nick" : "mrsfu" , "fullname":"Dragoness" }' );

note( "use root power to update mrfu to a different nick" ); 
$status = req( $test, 200, 'root', 'POST', $base, '{ "eid": ' . $mrfu->eid . ', "nick" : "mrsfu" , "fullname":"Dragoness" }' );
is( $status->level, 'OK', 'POST employee/eid 8' );
is( $status->code, 'DOCHAZKA_CUD_OK', 'POST employee/eid 9' );
my $mrsfu = App::Dochazka::REST::Model::Employee->spawn( %{ $status->payload } );
my $mrsfuprime = App::Dochazka::REST::Model::Employee->spawn( eid => $mrfu->eid,
    nick => 'mrsfu', fullname => 'Dragoness' );
is( $mrsfu->eid, $mrsfuprime->eid, 'POST employee/eid 10' );
is( $mrsfu->nick, $mrsfuprime->nick, 'POST employee/eid 10' );
is( $mrsfu->fullname, $mrsfuprime->fullname, 'POST employee/eid 10' );
is( $mrsfu->email, $mrsfuprime->email, 'POST employee/eid 10' );
is( $mrsfu->remark, $mrsfuprime->remark, 'POST employee/eid 10' );

note( "attempt as demo and root to update Mr./Mrs. Fu to a non-existent EID" );
#diag("--- POST employee/eid (non-existent EID)");
req( $test, 403, 'demo', 'POST', $base, '{ "eid" : 5442' );
req( $test, 400, 'root', 'POST', $base, '{ "eid" : 5442' );
req( $test, 403, 'demo', 'POST', $base, '{ "eid" : 5442 }' );
req( $test, 404, 'root', 'POST', $base, '{ "eid" : 5442 }' );
req( $test, 404, 'root', 'POST', $base, '{ "eid": 534, "nick": "mrfu", "fullname":"Lizard Scale" }' );

note( 'missing EID' );
req( $test, 400, 'root', 'POST', $base, '{ "long-john": "silber" }' );

note( 'incorrigibly attempt to update totally bogus and invalid EIDs' );
req( $test, 400, 'root', 'POST', $base, '{ "eid" : }' );
req( $test, 400, 'root', 'POST', $base, '{ "eid" : jj }' );
$status = req( $test, 500, 'root', 'POST', $base, '{ "eid" : "jj" }' );
like( $status->text, qr/invalid input syntax for integer/ );

note( 'and give it a bogus parameter (on update, bogus parameters cause REST to' );
note( 'return 200 status code with DISPATCH_UPDATE_NO_CHANGE_OK; on insert, they are ignored)' );
$status = req( $test, 200, 'root', 'POST', $base, '{ "eid" : 2, "bogus" : "json" }' ); 
is( $status->level, "OK", "POST $base with bogus property in body 1" );
is( $status->code, 'DISPATCH_UPDATE_NO_CHANGE_OK', "POST $base with bogus property in body 2" );

note( 'update to existing nick' );
dbi_err( $test, 500, 'root', 'POST', $base, 
    '{ "eid": ' . $mrfu->eid . ', "nick" : "root" , "fullname":"Tom Wang" }',
    qr/Key \(nick\)=\(root\) already exists/ );

note( 'update nick to null' );
dbi_err( $test, 500, 'root', 'POST', $base, 
    '{ "eid": ' . $mrfu->eid . ', "nick" : null  }',
    qr/null value in column "nick" violates not-null constraint/ );

note( 'inactive and active users get a little piece of the action, too:' );
note( 'they can operate on themselves (certain fields), but not on, e.g., Mr. Fu' );
foreach my $user ( qw( demo inactive active ) ) {
    req( $test, 403, $user, 'POST', $base, <<"EOH" );
{ "eid" : $eid_of_mrfu, "passhash" : "HAHAHAHA" }
EOH
}
foreach my $user ( qw( demo inactive active ) ) {
    $status = req( $test, 200, 'root', 'GET', "employee/nick/$user" );
    is( $status->level, 'OK' );
    is( $status->code, 'DISPATCH_EMPLOYEE_FOUND' );
    is( ref( $status->payload ), 'HASH' );
    my $eid = $status->payload->{'eid'};
    req( $test, 403, $user, 'POST', $base, <<"EOH" );
{ "eid" : $eid, "nick" : "tHE gREAT fABULATOR" }
EOH
}
foreach my $user ( qw( inactive active ) ) {
    $status = req( $test, 200, 'root', 'GET', "employee/nick/$user" );
    is( $status->level, 'OK' );
    is( $status->code, 'DISPATCH_EMPLOYEE_FOUND' );
    is( ref( $status->payload ), 'HASH' );
    my $eid = $status->payload->{'eid'};
    $status = req( $test, 200, $user, 'POST', $base, <<"EOH" );
{ "eid" : $eid, "password" : "tHE gREAT fABULATOR" }
EOH
    is( $status->level, 'OK' );
    is( $status->code, 'DOCHAZKA_CUD_OK' );
    
    note( "$user can no longer log in because Test.pm expects password to be same as $user" );
    req( $test, 401, $user, 'GET', "employee/nick/$user" );
    
    note( "use root power to change $user\'s password back to $user" );
    $status = req( $test, 200, 'root', 'POST', $base, <<"EOH" );
{ "eid" : $eid, "password" : "$user" }
EOH
    is( $status->level, 'OK' );
    is( $status->code, 'DOCHAZKA_CUD_OK' );
}



note( "teardown: delete the testing user mrfu" );

note( "first, delete his privhistory entry" );
$status = req( $test, 200, 'root', 'DELETE', "priv/history/phid/$mrfu_phid" );
ok( $status->ok );

note( "then, delete the employee" );
delete_bare_employee( $eid_of_mrfu );

note( "DELETE $base" );
req( $test, 405, 'demo', 'DELETE', $base );
req( $test, 405, 'active', 'DELETE', $base );
req( $test, 405, 'root', 'DELETE', $base );


note( '=============================' );
note( '"employee/eid/:eid" resource' );
note( '=============================' );
$base = 'employee/eid';
docu_check($test, "$base/:eid");

my @invalid_eids = (
    '342j',
    '**12',
    'fenestre',
    '1234/123/124/',
);

note( "GET $base/:eid" );

note( "normal usage: get employee with nick [0], eid [2], fullname [3] as employee" );
note( "with nick [1]" );
foreach my $params (
    [ 'root', 'root', $site->DOCHAZKA_EID_OF_ROOT, 'Root Immutable' ],
    [ 'demo', 'root', 2, 'Demo Employee' ],
    [ 'active', 'root', $ts_eid_active, undef ],
    [ 'active', 'active', $ts_eid_active, undef ],
    [ 'inactive', 'root', $ts_eid_inactive, undef ],
) {
    $status = req( $test, 200, $params->[1], 'GET', "$base/" . $params->[2] );
    is( $status->level, 'OK' );
    is( $status->code, 'DISPATCH_EMPLOYEE_FOUND' );
    ok( defined $status->payload );
    ok( exists $status->payload->{'eid'} );
    is( $status->payload->{'eid'}, $params->[2] );
    ok( exists $status->payload->{'nick'} );
    is( $status->payload->{'nick'}, $params->[0] );
    ok( exists $status->payload->{'fullname'} );
    is( $status->payload->{'fullname'}, $params->[3] );
}

note( "GET $base/2 as demo" );
req( $test, 200, 'demo', 'GET', "$base/2" );
is( $status->level, 'OK' );
is( $status->code, 'DISPATCH_EMPLOYEE_FOUND' );

note( "GET $base/53432 as root" );
req( $test, 404, 'root', 'GET', "$base/53432" );

note( "GET $base/53432 as demo" );
req( $test, 403, 'demo', 'GET', "$base/53432" );

note( 'invalid EIDs caught by Path::Router validations clause' );
foreach my $eid ( @invalid_eids ) {
    foreach my $user ( qw( root demo ) ) {
        req( $test, 400, $user, 'GET', "$base/$eid" );
    }
}

note( 'as demonstrated above, an active employee can see his own profile using this' );
note( 'resource -- demonstrate it again' );
$status = req( $test, 200, 'active', 'GET', "$base/$ts_eid_active" );
is( $status->level, 'OK' );
is( $status->code, 'DISPATCH_EMPLOYEE_FOUND' );

note( 'an \'inactive\' employee can do the same' );
$status = req( $test, 200, 'inactive', 'GET', "$base/$ts_eid_inactive" );
is( $status->level, 'OK' );
is( $status->code, 'DISPATCH_EMPLOYEE_FOUND' );

note( 'and, indeed, demo as well' );
req( $test, 200, 'demo', 'GET', "$base/2" );  # EID 2 is 'demo'
is( $status->level, 'OK' );
is( $status->code, 'DISPATCH_EMPLOYEE_FOUND' );

note( 'unknown user gets 401' );
req( $test, 401, 'unknown', 'GET', "$base/2" );  # EID 2 is 'demo'

note( 'non-administrators cannot use this resource to look at other employees' );
foreach my $user ( qw( active inactive demo ) ) {
    my $status = req( $test, 403, $user, 'GET', "$base/1" );
}

note( "PUT $base/:eid" );

note( "create a testing employee 'brotherchen'" );
my $emp = create_bare_employee( {
    nick => 'brotherchen',
    email => 'goodbrother@orient.cn',
    fullname => 'Good Brother Chen',
} );
my $eid_of_brchen = $emp->{eid};
is( $eid_of_brchen, $emp->eid );

note( "insufficient priv" );
req( $test, 403, 'demo', 'PUT', "$base/$eid_of_brchen",
    '{ "eid": ' . $eid_of_brchen . ', "fullname":"Chen Update Again" }' );

note( "be nice" );
req( $test, 403, 'demo', 'PUT', "$base/$eid_of_brchen",
    '{ "fullname":"Chen Update Again", "salt":"tasty" }' );
$status = req( $test, 200, 'root', 'PUT', "$base/$eid_of_brchen",
    '{ "fullname":"Chen Update Again", "salt":"tasty" }' );
is( $status->level, 'OK' );
is( $status->code, 'DOCHAZKA_CUD_OK' );
my $brchen = App::Dochazka::REST::Model::Employee->spawn( %{ $status->payload } );
is( $brchen->eid, $eid_of_brchen );
my $brchenprime = App::Dochazka::REST::Model::Employee->spawn( eid => $eid_of_brchen,
    nick => 'brotherchen', email => 'goodbrother@orient.cn', fullname =>
    'Chen Update Again', salt => 'tasty', sync => 0 );
is_deeply( $brchen, $brchenprime );

note( "provide invalid EID in request body -> it will be ignored" );
$status = req( $test, 200, 'root', 'PUT', "$base/$eid_of_brchen",
    '{ "eid": 99999, "fullname":"Chen Update Again 2" }' );
is( $status->level, 'OK' );
is( $status->code, 'DOCHAZKA_CUD_OK' );
$brchen = App::Dochazka::REST::Model::Employee->spawn( %{ $status->payload } );
isnt( $brchen->eid, 99999 );
is( $brchen->eid, $eid_of_brchen );
$brchenprime = App::Dochazka::REST::Model::Employee->spawn( eid => $eid_of_brchen,
    nick => 'brotherchen', email => 'goodbrother@orient.cn', fullname =>
    'Chen Update Again 2', salt => 'tasty', sync => 0 );
is_deeply( $brchen, $brchenprime );

note( 'change the nick' );
req( $test, 403, 'demo', 'PUT', "$base/$eid_of_brchen", '{' );
req( $test, 400, 'root', 'PUT', "$base/$eid_of_brchen", '{' );
req( $test, 403, 'demo', 'PUT', "$base/$eid_of_brchen", '{ "nick": "mrfu", "fullname":"Lizard Scale" }' );
$status = req( $test, 200, 'root', 'PUT', "$base/$eid_of_brchen",
    '{ "nick": "mrfu", "fullname":"Lizard Scale", "email":"mrfu@dragon.cn" }' );
is( $status->level, 'OK' );
is( $status->code, 'DOCHAZKA_CUD_OK' );
$mrfu = App::Dochazka::REST::Model::Employee->spawn( %{ $status->payload } );
isnt( $mrfu->nick, 'brotherchen' );
is( $mrfu->nick, 'mrfu' );
my $mrfuprime = App::Dochazka::REST::Model::Employee->spawn( eid => $eid_of_brchen,
    nick => 'mrfu', fullname => 'Lizard Scale', email => 'mrfu@dragon.cn',
    salt => 'tasty', sync => 0 );
is_deeply( $mrfu, $mrfuprime );
$eid_of_mrfu = $mrfu->eid;
is( $eid_of_mrfu, $eid_of_brchen );

note( 'provide non-existent EID' );
req( $test, 403, 'demo', 'PUT', "$base/5633", '{' );
req( $test, 404, 'root', 'PUT', "$base/5633", '{' );
req( $test, 403, 'demo', 'PUT', "$base/5633",
    '{ "nick": "mrfu", "fullname":"Lizard Scale" }' );
req( $test, 404, 'root', 'PUT', "$base/5633",
    '{ "eid": 534, "nick": "mrfu", "fullname":"Lizard Scale" }' );

note( 'with valid JSON that is not what we are expecting' );
req( $test, 400, 'root', 'PUT', "$base/2", 0 );

note( 'another kind of bogus JSON' );
$status = req( $test, 200, 'root', 'PUT', "$base/2", '{ "legal" : "json" }' );
is( $status->level, 'OK' );
is( $status->code, 'DISPATCH_UPDATE_NO_CHANGE_OK' ); 

note( 'invalid EIDs caught by Path::Router validations clause' );
foreach my $eid ( @invalid_eids ) {
    foreach my $user ( qw( root demo ) ) {
        req( $test, 400, $user, 'PUT', "$base/$eid" );
    }
}

note( 'inactive and active users get a little piece of the action, too:' );
note( 'they can operate on themselves (certain fields), but not on, e.g., Mr. Fu' );
foreach my $user ( qw( demo inactive active ) ) {
    req( $test, 403, $user, 'PUT', "$base/$eid_of_mrfu", <<"EOH" );
{ "passhash" : "HAHAHAHA" }
EOH
}
foreach my $user ( qw( demo inactive active ) ) {
    $status = req( $test, 200, 'root', 'GET', "employee/nick/$user" );
    is( $status->level, 'OK' );
    is( $status->code, 'DISPATCH_EMPLOYEE_FOUND' );
    is( ref( $status->payload ), 'HASH' );
    my $eid = $status->payload->{'eid'};
    req( $test, 403, $user, 'PUT', "$base/$eid", <<"EOH" );
{ "nick" : "tHE gREAT fABULATOR" }
EOH
}
foreach my $user ( qw( inactive active ) ) {
    $status = req( $test, 200, 'root', 'GET', "employee/nick/$user" );
    is( $status->level, 'OK' );
    is( $status->code, 'DISPATCH_EMPLOYEE_FOUND' );
    is( ref( $status->payload ), 'HASH' );
    my $eid = $status->payload->{'eid'};
    $status = req( $test, 200, $user, 'PUT', "$base/$eid", <<"EOH" );
{ "password" : "tHE gREAT fABULATOR" }
EOH
    is( $status->level, 'OK' );
    is( $status->code, 'DOCHAZKA_CUD_OK' );
    
    note( "so far so good, but now we can\'t log in because Test.pm assumes password is $user" );
    req( $test, 401, $user, 'GET', "$base/$eid" );
    
    note( 'change it back' );
    $status = req( $test, 200, 'root', 'PUT', "$base/$eid", "{ \"password\" : \"$user\" }" );
    is( $status->level, 'OK' );
    is( $status->code, 'DOCHAZKA_CUD_OK' );
    
    note( 'working again' );
    $status = req( $test, 200, 'root', 'GET', "employee/nick/$user" );
    is( $status->level, 'OK' );
    is( $status->code, 'DISPATCH_EMPLOYEE_FOUND' );
    is( ref( $status->payload ), 'HASH' );
}

note( 'delete the \'brotherchen\' testing user' );
delete_bare_employee( $eid_of_brchen );

note( "POST $base/:eid" );
req( $test, 405, 'demo', 'POST', "$base/2" );
req( $test, 405, 'active', 'POST', "$base/2" );
req( $test, 405, 'root', 'POST', "$base/2" );

note( "DELETE $base/:eid" );

note( 'create a "cannon fodder" employee' );
my $cf = create_bare_employee( { nick => 'cannonfodder' } );
my $eid_of_cf = $cf->eid;

note( 'employee/eid/:eid - delete cannonfodder' );
req( $test, 403, 'demo', 'DELETE', "$base/$eid_of_cf" );
req( $test, 403, 'active', 'DELETE', "$base/$eid_of_cf" ); 
req( $test, 401, 'unknown', 'DELETE', "$base/$eid_of_cf" ); # 401 because 'unknown' doesn't exist
$status = req( $test, 200, 'root', 'DELETE', "$base/$eid_of_cf" );
is( $status->level, 'OK' );
is( $status->code, 'DOCHAZKA_CUD_OK' );

note( 'attempt to get cannonfodder - not there anymore' );
req( $test, 403, 'demo', 'GET', "$base/$eid_of_cf" );
req( $test, 404, 'root', 'GET', "$base/$eid_of_cf" );

note( 'create another "cannon fodder" employee' );
$cf = create_bare_employee( { nick => 'cannonfodder' } );
ok( $cf->eid > $eid_of_cf ); # EID will have incremented
$eid_of_cf = $cf->eid;

note( 'delete the sucker' );
req( $test, 403, 'demo', 'DELETE', '/employee/nick/cannonfodder' );
$status = req( $test, 200, 'root', 'DELETE', '/employee/nick/cannonfodder' );
is( $status->level, 'OK' );
is( $status->code, 'DOCHAZKA_CUD_OK' );

note( 'attempt to get cannonfodder - not there anymore' );
req( $test, 403, 'demo', 'GET',  "$base/$eid_of_cf" );
req( $test, 404, 'root', 'GET',  "$base/$eid_of_cf" );

note( 'attempt to delete "root the immutable" (won\'t work)' );
dbi_err( $test, 500, 'root', 'DELETE', "$base/1", undef, qr/immutable/i );

note( 'invalid EIDs caught by Path::Router validations clause' );
foreach my $eid ( @invalid_eids ) {
    foreach my $user ( qw( root demo ) ) {
        req( $test, 400, $user, 'GET', "$base/$eid" );
    }
}


note( '=============================' );
note( '"employee/eid/:eid/minimal" resource' );
note( '=============================' );
$base = 'employee/eid';
docu_check($test, "$base/:eid/minimal");

note( 'root attempt to get non-existent EID (minimal)' );
req( $test, 404, 'root', 'GET', "$base/53432/minimal" );

note( 'demo attempt to get non-existent EID (minimal)' );
req( $test, 403, 'demo', 'GET', "$base/53432/minimal" );

note( 'demo attempt to get existent EID (minimal)' );
note( 'DOCHAZKA_EMPLOYEE_MINIMAL_FIELDS is ' . Dumper( $site->DOCHAZKA_EMPLOYEE_MINIMAL_FIELDS ) );
req( $test, 403, 'demo', 'GET', "$base/" . $site->DOCHAZKA_EID_OF_ROOT . "/minimal" );

note( 'root get active (minimal)' );
$status = req( $test, 200, 'root', 'GET', "$base/$ts_eid_active/minimal" );
is( $status->level, 'OK' );
is( $status->code, 'DOCHAZKA_EMPLOYEE_MINIMAL' );
ok( $status->payload );
is( ref( $status->payload ), 'HASH' );
ok( $status->payload->{'nick'} );
is( $status->payload->{'nick'}, 'active' );
is( $status->payload->{'eid'}, $ts_eid_active );
is( join( '', sort( keys( %{ $status->payload } ) ) ),
    join( '', sort( @{ $site->DOCHAZKA_EMPLOYEE_MINIMAL_FIELDS } ) ) );

note( '=============================' );
note( '"employee/eid/:eid/team" resource' );
note( '=============================' );
$base = "employee/eid";
docu_check($test, "$base/:eid/team" );

note( 'FIXME: NO TESTS!!!' );


note( '=============================' );
note( '"employee/list/?:priv" resource' );
note( '=============================' );
$base = "employee/list";
docu_check($test, "employee/list/?:priv");

note( 'GET employee/list/?:priv' );
req( $test, 403, 'demo', 'GET', $base );
$status = req( $test, 200, 'root', 'GET', $base );
test_employee_list( $status, [ 'active', 'demo', 'inactive', 'root' ] );
$status = req( $test, 200, 'root', 'GET', "$base/admin" );
test_employee_list( $status, [ 'root' ] );
$status = req( $test, 200, 'root', 'GET', "$base/active" );
test_employee_list( $status, [ 'active' ] );
$status = req( $test, 200, 'root', 'GET', "$base/inactive" );
test_employee_list( $status, [ 'inactive' ] );
$status = req( $test, 200, 'root', 'GET', "$base/passerby" );
test_employee_list( $status, [ 'demo' ] );

note( 'PUT, POST, DELETE employee/list/?:priv' );
req( $test, 405, 'demo', 'PUT', $base );
req( $test, 405, 'root', 'PUT', $base );
req( $test, 405, 'demo', 'POST', $base );
req( $test, 405, 'root', 'POST', $base );
req( $test, 405, 'demo', 'DELETE', $base );
req( $test, 405, 'root', 'DELETE', $base );


note( "=============================" );
note( '"employee/nick" resource' );
note( "=============================" );
$base = "employee/nick";
docu_check($test, "employee/nick");

note( 'GET, PUT employee/nick' );
req( $test, 405, 'demo', 'GET', $base );
req( $test, 405, 'root', 'GET', $base );
req( $test, 405, 'demo', 'PUT', $base );
req( $test, 405, 'root', 'PUT', $base );

note( 'POST employee/nick' );

note( 'create a \'mrfu\' employee' );
$mrfu = create_bare_employee( { nick => 'mrfu' } );
my $nick_of_mrfu = $mrfu->nick;
$eid_of_mrfu = $mrfu->eid;

note( 'give Mr. Fu an email address' );
my $j = '{ "nick": "' . $nick_of_mrfu . '", "email" : "mrsfu@dragon.cn" }';
req( $test, 403, 'demo', 'POST', $base, $j );

$status = req( $test, 200, 'root', 'POST', $base, $j );
is( $status->level, "OK" );
is( $status->code, 'DOCHAZKA_CUD_OK' );
is( $status->payload->{'email'}, 'mrsfu@dragon.cn' );

note( "non-existent nick (insert new employee)" );
req( $test, 403, 'demo', 'POST', $base, '{ "nick" : 5442' );
req( $test, 400, 'root', 'POST', $base, '{ "nick" : 5442' );
req( $test, 403, 'demo', 'POST', $base, '{ "nick" : 5442 }' );

note( 'attempt to insert new employee with bogus "eid" value' );
$status = req( $test, 200, 'root', 'POST', $base,
    '{ "eid": 534, "nick": "mrfutra", "fullname":"Rovnou do futer" }' );
is( $status->level, 'OK' );
is( $status->code, 'DOCHAZKA_CUD_OK' );
is( $status->payload->{'nick'}, 'mrfutra' );
is( $status->payload->{'fullname'}, 'Rovnou do futer' );
isnt( $status->payload->{'eid'}, 534 );
my $eid_of_mrfutra = $status->payload->{'eid'};

note( 'bogus property' );
$status = req( $test, 400, 'root', 'POST', $base, '{ "Nick" : "foobar" }' );

note( 'cleanup: delete the testing users' );
delete_bare_employee( $eid_of_mrfu );
delete_bare_employee( $eid_of_mrfutra );

note( 'add a new employee with nick in request body' );
req( $test, 403, 'demo', 'POST', $base, '{' );
req( $test, 400, 'root', 'POST', $base, '{' );
req( $test, 403, 'demo', 'POST', $base, 
    '{ "nick":"mrfu", "fullname":"Dragon Scale" }' );
$status = req( $test, 200, 'root', 'POST', $base, 
    '{ "nick":"mrfu", "fullname":"Dragon Scale", "email":"mrfu@dragon.cn" }' );
is( $status->level, 'OK' );
is( $status->code, 'DOCHAZKA_CUD_OK' );
$mrfu = App::Dochazka::REST::Model::Employee->spawn( %{ $status->payload } );
$mrfuprime = App::Dochazka::REST::Model::Employee->spawn( eid => $mrfu->eid, 
    nick => 'mrfu', fullname => 'Dragon Scale', email => 'mrfu@dragon.cn', 
    sync => 0 );
is_deeply( $mrfu, $mrfuprime );
$eid_of_mrfu = $mrfu->eid;

note( "POST valid, yet bogus JSON (bogus property will be ignored and wombat employee inserted)" );
$status = req( $test, 200, 'root', 'POST', $base, 
    '{ "nick" : "wombat", "bogus" : "json" }' );
is( $status->level, 'OK' );
is( $status->code, 'DOCHAZKA_CUD_OK' );
my $eid_of_wombat = $status->payload->{'eid'};

note( 'GET employee/nick/wombat' );
$status = req( $test, 200, 'root', 'GET', '/employee/nick/wombat' );
is( $status->level, 'OK' );
is( $status->code, 'DISPATCH_EMPLOYEE_FOUND' );
my $wombat_emp = App::Dochazka::REST::Model::Employee->spawn( $status->payload );

note( 'POST with valid, yet bogus JSON -- wombat exists, so this is an update' );
note( 'operation, but after the bogus property is filtered out there is no work to do' );
$status = req( $test, 200, 'root', 'POST', $base, 
    '{ "nick" : "wombat", "bogus" : "json" }' );
is( $status->level, 'OK' );
is( $status->code, 'DISPATCH_UPDATE_NO_CHANGE_OK' );

note( 'cleanup: delete wombat employee' ); 
delete_bare_employee( $eid_of_wombat );

note( "update existing employee" );
req( $test, 403, 'demo', 'POST', $base, 
    '{ "nick":"mrfu", "fullname":"Dragon Scale Update", "email" : "scale@dragon.org" }' );
$status = req( $test, 200, 'root', 'POST', $base, 
    '{ "nick":"mrfu", "fullname":"Dragon Scale Update", "email" : "scale@dragon.org" }' );
is( $status->level, "OK" );
is( $status->code, 'DOCHAZKA_CUD_OK' );
$mrfu = App::Dochazka::REST::Model::Employee->spawn( %{ $status->payload } );
$mrfuprime = App::Dochazka::REST::Model::Employee->spawn( eid => $eid_of_mrfu,
    nick => 'mrfu', fullname => 'Dragon Scale Update', email => 'scale@dragon.org',
    sync => 0 );
is_deeply( $mrfu, $mrfuprime );

note( 'create a bogus user with a bogus property' );
$status = req( $test, 200, 'root', 'POST', $base, 
    '{ "nick":"bogus", "wago":"svorka", "fullname":"bogus user" }' );
is( $status->level, "OK" );
is( $status->code, 'DOCHAZKA_CUD_OK' );
my $eid_of_bogus = $status->payload->{'eid'};

note( 'delete testing employees' );
map { delete_bare_employee( $_ ); } ( $eid_of_mrfu, $eid_of_bogus );

note( "DELETE employee/nick" );
req( $test, 405, 'demo', 'DELETE', $base );
req( $test, 405, 'root', 'DELETE', $base );


note( '=============================' );
note( '"employee/nick/:nick" resource' );
note( '=============================' );
$base = "employee/nick";
docu_check($test, "employee/nick/:nick");

note( 'GET employee/nick/:nick' );

note( 'nick: root' );
$status = req( $test, 200, 'root', 'GET', "$base/root" );
is( $status->level, "OK" );
is( $status->code, 'DISPATCH_EMPLOYEE_FOUND' );
ok( defined $status->payload );
ok( exists $status->payload->{'eid'} );
is( $status->payload->{'eid'}, $site->DOCHAZKA_EID_OF_ROOT );
ok( exists $status->payload->{'nick'} );
is( $status->payload->{'nick'}, 'root' );
ok( exists $status->payload->{'fullname'} );
is( $status->payload->{'fullname'}, 'Root Immutable' );

note( 'nick: demo' );
$status = req( $test, 200, 'root', 'GET', "$base/demo" );
is( $status->level, "OK" );
is( $status->code, 'DISPATCH_EMPLOYEE_FOUND' );
ok( defined $status->payload );
ok( exists $status->payload->{'eid'} );
is( $status->payload->{'eid'}, 2 );
ok( exists $status->payload->{'nick'} );
is( $status->payload->{'nick'}, 'demo' );
ok( exists $status->payload->{'fullname'} );
is( $status->payload->{'fullname'}, 'Demo Employee' );

note( "GET $base/demo" );
req( $test, 200, 'demo', 'GET', "$base/demo" );
is( $status->level, "OK" );
is( $status->code, 'DISPATCH_EMPLOYEE_FOUND' );

note( "GET $base/nick/{various bogus nicks}" );
req( $test, 404, 'root', 'GET', "$base/53432" );
req( $test, 403, 'demo', 'GET', "$base/53432" );
req( $test, 404, 'root', 'GET', "$base/heathledger" );

# this one triggers "wide character in print" warnings
#req( $test, 404, 'root', 'GET', "$base/" . uri_escape_utf8('/employee/nick//////áěěoěščqwšáščšýš..-...-...-..-.00') );

note( 'single-character nicks' );
$status = req( $test, 404, 'root', 'GET', "$base/4" );


note( "PUT employee/nick/:nick" );

note( 'demo cannot PUT no matter what' );
req( $test, 403, 'demo', 'PUT', "$base/mrsfu", '{' );

note( 'root can PUT, but JSON entity is invalid' );
req( $test, 400, 'root', 'PUT', "$base/mrsfu", '{' );

note( 'demo cannot PUT no matter what' );
req( $test, 403, 'demo', 'PUT', "$base/mrsfu", 
    '{ "fullname":"Dragonness" }' );

note( 'insert happy path' );
$status = req( $test, 200, 'root', 'PUT', "$base/mrsfu", 
    '{ "fullname":"Dragonness" }' );
is( $status->level, 'OK' );
is( $status->code, 'DOCHAZKA_CUD_OK' );
$mrsfu = App::Dochazka::REST::Model::Employee->spawn( %{ $status->payload } );
$mrsfuprime = App::Dochazka::REST::Model::Employee->spawn( eid => $mrsfu->eid, 
    nick => 'mrsfu', fullname => 'Dragonness', sync => 0 );
is_deeply( $mrsfu, $mrsfuprime );
my $eid_of_mrsfu = $mrsfu->eid;

note( 'insert pathological paths' );

note( 'provide conflicting \'nick\' property in the content body' );
req( $test, 403, 'demo', 'PUT', "$base/hapless", '{' );
req( $test, 400, 'root', 'PUT', "$base/hapless", '{' );
req( $test, 403, 'demo', 'PUT', "$base/hapless", 
    '{ "nick":"INVALID", "fullname":"Anders Chen" }' );
$status = req( $test, 200, 'root', 'PUT', "$base/hapless", 
    '{ "nick":"INVALID", "fullname":"Anders Chen" }' );
is( $status->level, 'OK' );
is( $status->code, 'DOCHAZKA_CUD_OK' );
my $hapless = App::Dochazka::REST::Model::Employee->spawn( %{ $status->payload } );
isnt( $hapless->nick, 'INVALID' );
is( $hapless->nick, 'hapless' );
my $haplessprime = App::Dochazka::REST::Model::Employee->spawn( eid => $hapless->eid, 
    nick => 'hapless', fullname => 'Anders Chen', sync => 0 );
is_deeply( $hapless, $haplessprime );
my $eid_of_hapless = $hapless->eid;

note( "update happy path" );
$status = req( $test, 200, 'root', 'PUT', "$base/hapless", 
    '{ "fullname":"Chen Update", "salt":"none, please" }' );
is( $status->level, 'OK' );
is( $status->code, 'DOCHAZKA_CUD_OK' );
$hapless = App::Dochazka::REST::Model::Employee->spawn( %{ $status->payload } );
is( $hapless->nick, "hapless" );
is( $hapless->fullname, "Chen Update" );
is( $hapless->salt, "none, please" );
$haplessprime = App::Dochazka::REST::Model::Employee->spawn( eid => $eid_of_hapless,
    nick => 'hapless', fullname => 'Chen Update', salt => "none, please",
    sync => 0 );
is_deeply( $hapless, $haplessprime );

note( "update: change salt to null" );
$status = req( $test, 200, 'root', 'PUT', "$base/hapless", 
    '{ "fullname":"Chen Update", "salt":null }' );
is( $status->level, 'OK' );
is( $status->code, 'DOCHAZKA_CUD_OK' );
$hapless = App::Dochazka::REST::Model::Employee->spawn( %{ $status->payload } );
is( $hapless->nick, "hapless" );
is( $hapless->fullname, "Chen Update" );
is( $hapless->salt, undef );
$haplessprime = App::Dochazka::REST::Model::Employee->spawn( eid => $eid_of_hapless,
    nick => 'hapless', fullname => 'Chen Update', sync => 0 );
is_deeply( $hapless, $haplessprime );

note( "update: pathological paths" );

note( 'attempt to set a bogus EID' );
$status = req( $test, 200, 'root', 'PUT', "$base/hapless",
    '{ "eid": 534, "fullname":"Good Brother Chen", "salt":"" }' );
is( $status->level, 'OK' );
is( $status->code, 'DOCHAZKA_CUD_OK' );
$hapless = App::Dochazka::REST::Model::Employee->spawn( %{ $status->payload } );
is( $hapless->fullname, "Good Brother Chen" );
is( $hapless->eid, $eid_of_hapless );
isnt( $hapless->eid, 534 );
$haplessprime = App::Dochazka::REST::Model::Employee->spawn( eid => $eid_of_hapless,
    nick => 'hapless', fullname => 'Good Brother Chen', salt => '', sync => 0 );
is_deeply( $hapless, $haplessprime );

note( 'attempt to change nick to null' );
dbi_err( $test, 500, 'root', 'PUT', "$base/hapless",
    '{ "nick":null }', qr/violates not-null constraint/ );

note( 'feed it some random bogusness' );
$status = req( $test, 200, 'root', 'PUT', "$base/hapless", '{ "legal" : "json" }' );
is( $status->level, 'OK' );
is( $status->code, 'DISPATCH_UPDATE_NO_CHANGE_OK' ); 

note( 'inactive and active users can not change passwords of other users' );
foreach my $user ( qw( demo inactive active ) ) {
    foreach my $target ( qw( mrsfu hapless ) ) {
        req( $test, 403, $user, 'PUT', "$base/$target", <<"EOH" );
{ "passhash" : "HAHAHAHA" }
EOH
    }
}

note( 'clean up testing employees' );
delete_bare_employee( $eid_of_mrsfu );
delete_bare_employee( $eid_of_hapless );

note( 'POST employee/nick:nick' );
req( $test, 405, 'demo', 'POST', "$base/root" );
req( $test, 405, 'root', 'POST', "$base/root" );

note( 'DELETE employee/nick/:nick' );

note( 'create a "cannon fodder" employee' );
$cf = create_bare_employee( { nick => 'cannonfodder' } );
ok( $cf->eid > 1 );
$eid_of_cf = $cf->eid;

note( 'get cannonfodder - no problem' );
$status = req( $test, 200, 'root', 'GET', "$base/cannonfodder" );
is( $status->level, 'OK' );
is( $status->code, 'DISPATCH_EMPLOYEE_FOUND' );

note( 'DELETE "employee/nick/:nick" with nick cannonfodder' );
req( $test, 403, 'demo', 'DELETE', $base . "/" . $cf->nick );
$status = req( $test, 200, 'root', 'DELETE', $base . "/" . $cf->nick );
is( $status->level, 'OK' );
is( $status->code, 'DOCHAZKA_CUD_OK' );

note( 'attempt to get cannonfodder - not there anymore' );
req( $test, 404, 'root', 'GET', "$base/cannonfodder" );

note( 'attempt to get in a different way' );
$status = App::Dochazka::REST::Model::Employee->load_by_nick( $dbix_conn, 'cannonfodder' );
is( $status->level, 'NOTICE' );
is( $status->code, 'DISPATCH_NO_RECORDS_FOUND' );

note( 'create another "cannon fodder" employee' );
$cf = create_bare_employee( { nick => 'cannonfodder' } );
ok( $cf->eid > $eid_of_cf ); # EID will have incremented
$eid_of_cf = $cf->eid;

note( 'get cannonfodder - again, no problem' );
$status = req( $test, 200, 'root', 'GET', "$base/cannonfodder" );
is( $status->level, 'OK' );
is( $status->code, 'DISPATCH_EMPLOYEE_FOUND' );

note( 'delete with a typo (non-existent nick)' );
req( $test, 403, 'demo', 'DELETE', "$base/cannonfoddertypo" );
req( $test, 404, 'root', 'DELETE', "$base/cannonfoddertypo" );

note( 'attempt to get cannonfodder - still there' );
$status = req( $test, 200, 'root', 'GET', "$base/cannonfodder" );
is( $status->level, 'OK' );
is( $status->code, 'DISPATCH_EMPLOYEE_FOUND' );

note( 'tear down testing employee' );
delete_bare_employee( $eid_of_cf );

note( 'attempt to delete \'root the immutable\' (won\'t work)' );
dbi_err( $test, 500, 'root', 'DELETE', "$base/root", undef, qr/immutable/i );


note( '=============================' );
note( '"employee/nick/:nick/minimal" resource' );
note( '=============================' );
$base = 'employee/nick';
docu_check($test, "$base/:nick/minimal");

note( 'root attempt to get non-existent nick (minimal)' );
req( $test, 404, 'root', 'GET', "$base/53432/minimal" );

note( 'demo attempt to get non-existent nick (minimal)' );
req( $test, 403, 'demo', 'GET', "$base/53432/minimal" );

note( 'demo attempt to get existent nick (minimal)' );
req( $test, 403, 'demo', 'GET', "$base/root/minimal" );

note( 'root get active (minimal)' );
$status = req( $test, 200, 'root', 'GET', "$base/active/minimal" );
is( $status->level, 'OK' );
is( $status->code, 'DOCHAZKA_EMPLOYEE_MINIMAL' );
ok( $status->payload );
is( ref( $status->payload ), 'HASH' );
ok( $status->payload->{'nick'} );
is( $status->payload->{'nick'}, 'active' );
is( $status->payload->{'eid'}, $ts_eid_active );
is( join( '', sort( keys( %{ $status->payload } ) ) ),
    join( '', sort( @{ $site->DOCHAZKA_EMPLOYEE_MINIMAL_FIELDS } ) ) );


note( '=============================' );
note( '"employee/nick/:nick/team" resource' );
note( '=============================' );
$base = "employee/nick";
docu_check($test, "$base/:nick/team" );

note( 'FIXME: NO TESTS!!!' );


note( '=============================' );
note( '"employee/search/nick/:key" resource' );
note( '=============================' );
$base = "employee/search/nick";
docu_check($test, "$base/:key");
# 
# - with wildcard == 'ro%'
$status = req( $test, 200, 'root', 'GET', "$base/ro%" );
is( $status->level, "OK" );
is( $status->code, 'DISPATCH_RECORDS_FOUND' );
ok( defined $status->payload );
is( ref( $status->payload ), 'ARRAY' );
is( scalar( @{ $status->payload } ), 1 );
is( $status->payload->[0]->{'nick'}, 'root' );
#ok( exists $status->payload->{'count'} );
#ok( exists $status->payload->{'search_key'} );
#ok( exists $status->payload->{'result_set'} );
#ok( ref( $status->payload->{'result_set'} ) eq 'ARRAY' );
#is( $status->payload->{'result_set'}->[0]->{'nick'}, 'root' );

note( '=============================' );
note( '"employee/sec_id/:sec_id" resource' );
note( '=============================' );
$base = "employee/sec_id";
docu_check($test, "$base/:sec_id");

note( "give 'inactive' employee a sec_id" );
$status = req( $test, 200, 'root', 'PUT', "employee/nick/inactive",
    '{ "sec_id" : 1024 }' );
is( $status->level, "OK" );
is( $status->code, 'DOCHAZKA_CUD_OK' );

note( 'read it back' );
$status = req( $test, 200, 'root', 'GET', "employee/nick/inactive" ); 
is( $status->level, "OK" );
is( $status->code, 'DISPATCH_EMPLOYEE_FOUND' );
is( $status->payload->{'sec_id'}, 1024 );
my $mustr = $status->payload;

note( 'GET employee/sec_id/1024' );
$status = req( $test, 200, 'root', 'GET', "employee/sec_id/1024" ); 
is( $status->level, "OK" );
is( $status->code, 'DISPATCH_EMPLOYEE_FOUND' );
is_deeply( $status->payload, $mustr );


note( '=============================' );
note( '"employee/sec_id/:sec_id/minimal" resource' );
note( '=============================' );
$base = 'employee/sec_id';
docu_check($test, "$base/:sec_id/minimal");

note( 'root attempt to get non-existent sec_id (minimal)' );
req( $test, 404, 'root', 'GET', "$base/53432/minimal" );

note( 'demo attempt to get non-existent sec_id (minimal)' );
req( $test, 403, 'demo', 'GET', "$base/53432/minimal" );

note( 'set root\'s sec_id to be foobar' );
my $eid_of_root = $site->DOCHAZKA_EID_OF_ROOT;
$status = req( $test, 200, 'root', 'POST', 'employee/eid', <<"EOS" );
{ "eid" : $eid_of_root, "sec_id" : "foobar" }
EOS
is( $status->level, 'OK' );
is( $status->code, 'DOCHAZKA_CUD_OK' );

note( 'demo attempt to get existent sec_id (minimal)' );
req( $test, 403, 'demo', 'GET', "$base/foobar/minimal" );

note( 'root get itself (minimal)' );
$status = req( $test, 200, 'root', 'GET', "$base/foobar/minimal" );
is( $status->level, 'OK' );
is( $status->code, 'DOCHAZKA_EMPLOYEE_MINIMAL' );
ok( $status->payload );
is( ref( $status->payload ), 'HASH' );
ok( $status->payload->{'nick'} );
is( $status->payload->{'nick'}, 'root' );
is( $status->payload->{'eid'}, $eid_of_root );
is( join( '', sort( keys( %{ $status->payload } ) ) ),
    join( '', sort( @{ $site->DOCHAZKA_EMPLOYEE_MINIMAL_FIELDS } ) ) );

note( 'set root\'s sec_id back to undef' );
$status = req( $test, 200, 'root', 'POST', 'employee/eid', <<"EOS" );
{ "eid" : $eid_of_root, "sec_id" : null }
EOS
is( $status->level, 'OK' );
is( $status->code, 'DOCHAZKA_CUD_OK' );



note( '=============================' );
note( '"employee/team" resource' );
note( '=============================' );
$base = "employee/team";
docu_check($test, "$base");

note( 'FIXME: NO TESTS!!!' );

note( 'tear down' );
$status = delete_all_attendance_data();
BAIL_OUT(0) unless $status->ok;

done_testing;
