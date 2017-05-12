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
# test genreport resources
#

#!perl
use 5.012;
use strict;
use warnings;

#use App::CELL::Test::LogToFile;
use App::CELL qw( $log $meta $site );
use App::Dochazka::REST::ConnBank qw( $dbix_conn );
use App::Dochazka::REST::Test;
use Data::Dumper;
use JSON;
use Plack::Test;
use Test::More;
use Test::Warnings;

note( 'initialize, connect to database, and set up a testing plan' );
my $app = initialize_regression_test();

note( 'instantiate Plack::Test object' );
my $test = Plack::Test->create( $app );


note( '=============================' );
note( '"genreport" resource' );
note( '=============================' );
my $base = 'genreport';
docu_check($test, $base);

note( "POST on $base" );

note( "sample/local_time.mc" );
req( $test, 403, 'demo', 'POST', $base, '{ "path":"sample/local_time.mc" }' );
my $status = req( $test, 200, 'root', 'POST', $base, '{ "path":"sample/local_time.mc" }' );
is( $status->level, 'OK' );
like( $status->payload, qr/Hello! The local time is / );

note( "/sample/local_time.mc" );
$status = req( $test, 200, 'root', 'POST', $base, '{ "path":"/sample/local_time.mc" }' );
is( $status->level, 'OK' );
like( $status->payload, qr/Hello! The local time is / );

note( "sample/site_param.mc expected use" );
$status = req( $test, 200, 'root', 'POST', $base, <<EOS );
{ "path":"/sample/site_param.mc", "parameters":{ "param":"DOCHAZKA_STATE_DIR" } }
EOS
is( $status->level, 'OK' );
like( $status->payload, qr{site_param_name = 'DOCHAZKA_STATE_DIR'.*site_param_value = '/var/lib/dochazka-rest'}s );

note( "sample/site_param.mc error path missing mandatory parameter I" );
$status = req( $test, 400, 'root', 'POST', $base, '{ "path":"/sample/site_param.mc" }' );
like( $status->text, qr/Mandatory parameter 'param' missing in call to App::Dochazka::REST::Dispatch::handler_genreport/ );

note( "sample/site_param.mc error path missing mandatory parameter II" );
$status = req( $test, 400, 'root', 'POST', $base, <<'EOS' );
{ "path":"/sample/site_param.mc", "parameters":{} }
EOS
like( $status->text, qr/Mandatory parameter 'param' missing in call to App::Dochazka::REST::Dispatch::handler_genreport/ );

note( "sample/site_param.mc error path with additional (illegal) parameter" );
$status = req( $test, 400, 'root', 'POST', $base, <<'EOS' );
{ "path" : "/sample/site_param.mc", "parameters":{ "hooligan" : "Not supposed to be here" } }
EOS
like( $status->text, qr/The following parameter was passed in the call to App::Dochazka::REST::Dispatch::handler_genreport but was not listed in the validation options: hooligan/ );

done_testing;
