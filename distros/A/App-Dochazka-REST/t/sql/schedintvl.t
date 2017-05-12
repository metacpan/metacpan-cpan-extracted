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
# some tests to ensure/demonstrate that we can't enter bogus schedintvls
#

#!perl
use 5.012;
use strict;
use warnings;

#use App::CELL::Test::LogToFile;
use App::CELL qw( $meta $site );
use App::Dochazka::Common qw( $today );
use App::Dochazka::REST::ConnBank qw( $dbix_conn );
use App::Dochazka::REST::Test;
use Data::Dumper;
use Test::More;
use Test::Warnings;

my $illegal = qr/illegal attendance interval/;


note( "initialize, connect to database, and set up a testing plan" );
initialize_regression_test();

note( "get the next SSID" );
my ( $ssid ) = do_select_single( $dbix_conn, "SELECT nextval('scratch_sid_seq')" );
ok( $ssid ); # this doesn't tell us much, of course

note( "test NULL tsrange separately because it requires different SQL syntax" );
test_sql_failure( $dbix_conn, $illegal, <<"SQL" );
INSERT into schedintvls (ssid, intvl) VALUES ( $ssid, NULL::tstzrange )
SQL

note( "set up our hash where keys are intervals and values are regex quotes" );
my %int_map = (
    '[today,today)' => '',  # empty range
    '["1967-09-20 12:25","1967-09-20 12:25")' => '', # another empty range
    '[-infinity,today)' => '', # contains -infinity
    '[,-infinity)' => '', # contains -infinity
    '[today,infinity)' => '',  # contains infinity
    '[infinity,)' => '', # contains infinity
    '[,)' => '', # unbounded on both sides
    '[today,)' => '', # unbounded on one side
    '[,today)' => '', # unbounded on other side
    '("1967-09-20 00:00",today)' => '', # lower not inclusive
    '["1967-09-20 00:00",today]' => '', # upper inclusive
    '("1967-09-20 00:00",today]' => '', # lower not inclusive AND upper inclusive
);
foreach my $intvl ( keys( %int_map ) ) {
    $intvl = "'" . $intvl . "'" . "::tstzrange";
    test_sql_failure( $dbix_conn, $illegal, <<"SQL" );
INSERT into schedintvls (ssid, intvl) VALUES ( $ssid, $intvl )
SQL

}

done_testing;
