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
# test for various 'schedule' related bugs 
#

#!perl
use 5.012;
use strict;
use warnings;

#use App::CELL::Test::LogToFile;
use App::CELL qw( $meta $site );
use App::Dochazka::Common qw( $today );
use App::Dochazka::REST::ConnBank qw( $dbix_conn );
use App::Dochazka::REST::Model::Schedule;
use App::Dochazka::REST::Test;
use Data::Dumper;
use JSON;
use Plack::Test;
use Test::More;
use Test::Warnings;


note( "initialize, connect to database, and set up a testing plan" );
my $app = initialize_regression_test();

note( "instantiate Plack::Test object");
my $test = Plack::Test->create( $app );

note( 'a bug where the insert method in App::Dochazka::REST::Model::Schedule' );
note( 'was returning DOCHAZKA_CUD_OK (which was undesirable)' );
my $intvls = { "schedule" => [
    "[$today 12:30, $today 16:30)",
    "[$today 08:00, $today 12:00)",
] };
my $intvls_json = JSON->new->utf8->canonical(1)->encode( $intvls );
my $status = req( $test, 201, 'root', 'POST', 'schedule/new', $intvls_json );
isnt( $status->code, 'DOCHAZKA_CUD_OK' );

my $pl = $status->payload;
my $furry = App::Dochazka::REST::Model::Schedule->spawn( %$pl );
$furry->scode( 'FURRY' );
is( $furry->scode, 'FURRY' );

note( 'update the schedule record and see that FURRY gets stored in the database' );
$intvls->{'scode'} = $furry->scode;
$intvls_json = JSON->new->utf8->canonical(1)->encode( $intvls );
$status = req( $test, 201, 'root', 'POST', 'schedule/new', $intvls_json );
is( $status->payload->{'scode'}, 'FURRY' );
is( $status->payload->{'sid'}, $furry->sid );

note( "use 'POST schedule/new' with the same schedue but a different scode" );
note( "(a corner case) -> the desired result is for the new scode to be" );
note( "ignored and the existing one to be returned" );
$intvls->{'scode'} = 'SOME DIFFERENT VALUE THAT WILL BE IGNORED';
$intvls_json = JSON->new->utf8->canonical(1)->encode( $intvls );
$status = req( $test, 201, 'root', 'POST', 'schedule/new', $intvls_json );
is( $status->level, 'OK' );
is( $status->code, 'DISPATCH_SCHEDULE_EXISTS' );
is( $status->payload->{'scode'}, 'FURRY' );
is( $status->payload->{'sid'}, $furry->sid );

note( "tear down" );
$status = delete_all_attendance_data();
BAIL_OUT(0) unless $status->ok;

done_testing;
