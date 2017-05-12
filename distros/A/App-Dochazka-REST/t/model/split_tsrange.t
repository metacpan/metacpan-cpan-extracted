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
# tests of the split_tsrange() frunction

#!perl
use 5.012;
use strict;
use warnings;

#use App::CELL::Test::LogToFile;
use App::CELL qw( $meta $site );
use Data::Dumper;
use DBI;
use App::Dochazka::REST::ConnBank qw( $dbix_conn );
use App::Dochazka::REST::Model::Shared qw( split_tsrange );
use App::Dochazka::REST::Test;
use Test::Fatal;
use Test::More;
use Test::Warnings;

sub test_is_ok {
    my ( $status ) = @_;
    is( $status->level, 'OK' );
    is( $status->code, 'DISPATCH_RECORDS_FOUND' );
}

note( 'initialize, connect to database, and set up a testing plan' );
initialize_regression_test();

note( 'split a legal tsrange' );
my $status = split_tsrange( $dbix_conn, '[ 2015-01-1, 2015-02-1 )' );
test_is_ok( $status ); 
like( $status->payload->[0], qr/2015-01-01 00:00:00/ );
like( $status->payload->[1], qr/2015-02-01 00:00:00/ );

note( 'split boring tsrange' );
$status = split_tsrange( $dbix_conn, '[ 1957-01-01 00:00, 1957-01-02 00:00 )' );
test_is_ok( $status );
like( $status->payload->[0], qr/1957-01-01 00:00:00/ );
like( $status->payload->[1], qr/1957-01-02 00:00:00/ );

note( 'split a less boring tsrange' );
$status = split_tsrange( $dbix_conn, '( 2000-1-9, 2100-12-1 ]' );
test_is_ok( $status );
like( $status->payload->[0], qr/2000-01-09 00:00:00/ );
like( $status->payload->[1], qr/2100-12-01 00:00:00/ );

note( 'split a seemingly illegal tsrange' );
$status = split_tsrange( $dbix_conn, '( 1979-4-002 1:1, 1980-4-11 1:2 )' );
test_is_ok( $status );
like( $status->payload->[0], qr/1979-04-02 01:01:00/ );
like( $status->payload->[1], qr/1980-04-11 01:02:00/ );

note( 'split another borderline legal tsrange' );
$status = split_tsrange( $dbix_conn, '( "April 2, 1979" 1:1, "April 11, 1980" 1:2 )' );
test_is_ok( $status );
like( $status->payload->[0], qr/1979-04-02 01:01:00/ );
like( $status->payload->[1], qr/1980-04-11 01:02:00/ );

note( 'split an illegal tsrange' );
$status = split_tsrange( $dbix_conn, '( "April 002, 1979" 1:1, "April 11th, 1980" 1:2 )' );
is( $status->level, 'ERR' );
is( $status->code, 'DOCHAZKA_DBI_ERR' );

note( 'split a half-undefined tsrange (1)' );
$status = split_tsrange( $dbix_conn, '(1979-4-02, )' );
is( $status->level, 'ERR' );
is( $status->code, 'DOCHAZKA_DBI_ERR' );

note( 'split a half-undefined tsrange (2)' );
$status = split_tsrange( $dbix_conn, '(1979-4-02,)' );
is( $status->level, 'ERR' );
is( $status->code, 'DOCHAZKA_UNBOUNDED_TSRANGE' );

note( 'split a half-undefined tsrange (3)' );
$status = split_tsrange( $dbix_conn, '( , 1979-4-02 )' );
is( $status->level, 'ERR' );
is( $status->code, 'DOCHAZKA_DBI_ERR' );

note( 'split a half-undefined tsrange (4)' );
$status = split_tsrange( $dbix_conn, '(,1979-4-02)' );
is( $status->level, 'ERR' );
is( $status->code, 'DOCHAZKA_UNBOUNDED_TSRANGE' );

note( 'split a half-undefined tsrange (5)' );
$status = split_tsrange( $dbix_conn, '[ 1979-4-02,  ]' );
is( $status->level, 'ERR' );
is( $status->code, 'DOCHAZKA_DBI_ERR' );

note( 'split a half-undefined tsrange (6)' );
$status = split_tsrange( $dbix_conn, '[ 1979-4-02,]' );
is( $status->level, 'ERR' );
is( $status->code, 'DOCHAZKA_UNBOUNDED_TSRANGE' );

note( 'split a half-undefined tsrange (7)' );
$status = split_tsrange( $dbix_conn, '[ , 1979-4-02 ]' );
is( $status->level, 'ERR' );
is( $status->code, 'DOCHAZKA_DBI_ERR' );

note( 'split a half-undefined tsrange (8)' );
$status = split_tsrange( $dbix_conn, '[,1979-4-02]' );
is( $status->level, 'ERR' );
is( $status->code, 'DOCHAZKA_UNBOUNDED_TSRANGE' );

note( 'split several completely undefined tsranges' );
my @non_ranges = ( 
    '[,]',
    '[ , ]',
    '[,)',
    '[, )',
    '(,]',
    '( ,]',
    '(,)',
    '( , )',
    '[infinity,]',
    '[ ,infinity ]',
    '[,infinity)',
    '[infinity, )',
    '(,infinity]',
    '( infinity ,infinity]',
    '(infinity,)',
    '( ,infinity )',
    "[,2014-07-14 17:00)",
    "[ ,2014-07-14 17:00)",
    "[2014-07-14 17:15,)",
    "[2014-07-14 17:15, )",
    "[ infinity,2014-07-14 17:00)",
    "[2014-07-14 17:15,infinity)",
);
foreach my $non_range ( @non_ranges ) {
    $status = split_tsrange( $dbix_conn, '[,]' );
    is( $status->level, 'ERR' );
    is( $status->code, 'DOCHAZKA_UNBOUNDED_TSRANGE' );
}

note( 'attempt to split_tsrange bogus tsranges individually' );
my $bogus = [
        "[)",
        "(2014-07-34 09:00, 2014-07-14 17:05)",
        "[2014-07-14 09:00, 2014-07-14 25:05]",
        "( 2014-07-34 09:00, 2014-07-14 17:05)",
        "[2014-07-14 09:00, 2014-07-14 25:05 ]",
    ];
map {
        $status = split_tsrange( $dbix_conn, $_ );
        #diag( $status->level . ' ' . $status->text );
        is( $status->level, 'ERR' ); 
    } @$bogus;

done_testing;
