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
# test the timestamp_delta_minus() and timestamp_delta_plus() functions
#

#!perl
use 5.012;
use strict;
use warnings;

#use App::CELL::Test::LogToFile;
use App::CELL qw( $meta $site );
use Data::Dumper;
use App::Dochazka::REST::ConnBank qw( $dbix_conn );
use App::Dochazka::REST::Model::Shared qw( timestamp_delta_minus timestamp_delta_plus );
use App::Dochazka::REST::Test;
use Test::More;
use Test::Warnings;


note( 'initialize, connect to database, and set up a testing plan' );
initialize_regression_test();

note( 'subtract two days from 2015-01-3' );
my $status = timestamp_delta_minus( $dbix_conn, '2015-01-3', '2 days' );
is( $status->level, 'OK' );
like( $status->payload, qr/^2015-01-01 00:00:00/ );

note( 'add two days to 2015-01-3' );
$status = timestamp_delta_plus( $dbix_conn, '2015-01-3', '2 days' );
is( $status->level, 'OK' );
like( $status->payload, qr/^2015-01-05 00:00:00/ );

note( 'add 1 week to 1957-1-3 19:57' );
$status = timestamp_delta_plus( $dbix_conn, '1957-1-3 19:57', '1 week 5 hours 3 seconds' );
is( $status->level, 'OK' );
like( $status->payload, qr/^1957-01-11 00:57:03/ );

note( 'add 1 month to 2964-02-01' );
$status = timestamp_delta_plus( $dbix_conn, '2964-02-01', '1 month' );
is( $status->level, 'OK' );
like( $status->payload, qr/^2964-03-01 00:00:00/ );

done_testing;
