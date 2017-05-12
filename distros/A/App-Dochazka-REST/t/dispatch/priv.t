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
# test priv (non-history) resources
#

#!perl
use 5.012;
use strict;
use warnings;

#use App::CELL::Test::LogToFile;
use App::CELL qw( $meta $site );
use App::Dochazka::REST;
use App::Dochazka::REST::Model::Privhistory;
use App::Dochazka::REST::Test;
use Data::Dumper;
use JSON;
use Plack::Test;
use Test::JSON;
use Test::More;
use Test::Warnings;


note( "initialize, connect to database, and set up a testing plan" );
my $app = initialize_regression_test();

note( "instantiate Plack::Test object");
my $test = Plack::Test->create( $app );

note( 'define delete_ph_recs() function after initialization because it uses \$test' );
sub delete_ph_recs {
    my ( $set ) = @_;
    foreach my $rec ( @$set ) {
        my $status = req( $test, 200, 'root', 'DELETE', "/priv/history/phid/" . $rec->{phid} );
        is( $status->level, 'OK' );
        is( $status->code, 'DOCHAZKA_CUD_OK' );
    }
}

my $res;


note( '=============================' );
note( '"priv/self/?:ts" resource' );
note( '=============================' );
my $base = "priv/self";
docu_check($test, "$base/?:ts");

note( 'GET' );

note( "GET $base as demo" );
my $status = req( $test, 200, 'demo', 'GET', $base );
is( $status->level, 'OK' );
is( $status->code, "DISPATCH_EMPLOYEE_PRIV" );
ok( defined $status->payload );
ok( exists $status->payload->{'priv'} );
is( $status->payload->{'priv'}, 'passerby' );

note( "GET $base as root" );
$status = req( $test, 200, 'root', 'GET', $base );
is( $status->level, 'OK' );
is( $status->code, "DISPATCH_EMPLOYEE_PRIV" );
ok( defined $status->payload );
ok( exists $status->payload->{'priv'} );
is( $status->payload->{'priv'}, 'admin' );

note( "GET $base/1000-12-31 23:59 as root" );
$status = req( $test, 200, 'root', 'GET', "$base/1000-12-31 23:59" );
is( $status->level, 'OK' );
is( $status->code, "DISPATCH_EMPLOYEE_PRIV_AS_AT" );
is_deeply( $status->payload, {
    timestamp => "1000-12-31 23:59",
    nick => "root",
    priv => "passerby",
    eid => "1"
} );

note( "GET $base/1892-01-01 00:01 as root" );
$status = req( $test, 200, 'root', 'GET', "$base/1892-01-01 00:01" );
is( $status->level, 'OK' );
is( $status->code, "DISPATCH_EMPLOYEE_PRIV_AS_AT" );
is_deeply( $status->payload, {
    timestamp => "1892-01-01 00:01",
    nick => "root",
    priv => "admin",
    eid => "1"
} );

note( 'PUT, POST, DELETE -> 405' );
foreach my $base ( '/priv/self', '/priv/self/1892-01-01' ) {
    req( $test, 405, 'demo', 'PUT', $base );
    req( $test, 405, 'demo', 'POST', $base );
    req( $test, 405, 'demo', 'DELETE', $base );
    #
    req( $test, 405, 'root', 'PUT', $base );
    req( $test, 405, 'root', 'POST', $base );
    req( $test, 405, 'root', 'DELETE', $base );
}


note( '===========================================' );
note( '"priv/eid/:eid/?:ts" resource' );
note( '===========================================' );
$base = "priv/eid";
docu_check($test, "$base/:eid/?:ts");

note( 'GET' );

note( "GET $base/1 as demo" );
req( $test, 403, 'demo', 'GET', "$base/1" );

note( "GET $base/1 as root" );
$status = req( $test, 200, 'root', 'GET', "$base/1" );
is( $status->level, 'OK' );
is( $status->code, "DISPATCH_EMPLOYEE_PRIV" );
ok( defined $status->payload );
is_deeply( $status->payload, {
    "priv" => "admin",
    "eid" => "1",
    "nick" => "root"
});

note( '- as root, with timestamp (before 1892 A.D. root was a passerby)' );
$status = req( $test, 200, 'root', 'GET', "$base/1/1891-12-31 23:59" );
is( $status->level, 'OK' );
is( $status->code, "DISPATCH_EMPLOYEE_PRIV_AS_AT" );
is_deeply( $status->payload, {
    timestamp => "1891-12-31 23:59",
    nick => "root",
    priv => "passerby",
    eid => "1"
} );

note( '- as root, with timestamp (root became an admin on 1892-01-01 at 00:00)' );
$status = req( $test, 200, 'root', 'GET', "$base/1/1892-01-01 00:01" );
is( $status->level, 'OK' );
is( $status->code, "DISPATCH_EMPLOYEE_PRIV_AS_AT" );
is_deeply( $status->payload, {
    timestamp => "1892-01-01 00:01",
    nick => "root",
    priv => "admin",
    eid => "1"
} );

note( 'PUT, POST, DELETE -> 405' );
foreach my $base ( '/priv/eid/1', '/priv/eid/1/1892-01-01' ) {
    req( $test, 405, 'demo', 'PUT', $base );
    req( $test, 405, 'demo', 'POST', $base );
    req( $test, 405, 'demo', 'DELETE', $base );
    #
    req( $test, 405, 'root', 'PUT', $base );
    req( $test, 405, 'root', 'POST', $base );
    req( $test, 405, 'root', 'DELETE', $base );
}


note( '===========================================' );
note( '"priv/nick/:nick/?:ts" resource' );
note( '===========================================' );
$base = "priv/nick";
docu_check($test, "$base/:nick/?:ts");

note( 'GET' );
req( $test, 403, 'demo', 'GET', "$base/root" );
$status = req( $test, 200, 'root', 'GET', "$base/root" );
is( $status->level, 'OK' );
is( $status->code, "DISPATCH_EMPLOYEE_PRIV" );
ok( defined $status->payload );
is_deeply( $status->payload, {
    "priv" => "admin",
    "eid" => "1",
    "nick" => "root"
});

note( '- as root, with timestamp (before 1892 A.D. root was a passerby)' );
$status = req( $test, 200, 'root', 'GET', "$base/root/1891-12-31 23:59" );
is( $status->level, 'OK' );
is( $status->code, "DISPATCH_EMPLOYEE_PRIV_AS_AT" );
is_deeply( $status->payload, {
    timestamp => "1891-12-31 23:59",
    nick => "root",
    priv => "passerby",
    eid => "1"
} );

note( '- as root, with timestamp (root became an admin on 1892-01-01 at 00:00)' );
$status = req( $test, 200, 'root', 'GET', "$base/root/1892-01-01 00:01" );
is( $status->level, 'OK' );
is( $status->code, "DISPATCH_EMPLOYEE_PRIV_AS_AT" );
is_deeply( $status->payload, {
    timestamp => "1892-01-01 00:01",
    nick => "root",
    priv => "admin",
    eid => "1"
} );

note( 'PUT, POST, DELETE -> 405' );
foreach my $user ( qw( demo root ) ) {
    foreach my $method ( qw( PUT POST DELETE ) ) {
        foreach my $uri ( "$base/root", "$base/root/1892-01-01" ) {
            req( $test, 405, $user, $method, $uri );
        }
    }
}

note( 'tear down' );
$status = delete_all_attendance_data();
BAIL_OUT(0) unless $status->ok;

done_testing;
