# ************************************************************************* 
# Copyright (c) 2014-2016, SUSE LLC
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
# Tests for Util.pm functions:
# + datelist_from_token
# + month_alpha_to_numeric
#

#!perl
use 5.012;
use strict;
use warnings;

#use App::CELL::Test::LogToFile;
use App::CELL qw( $log );
use App::Dochazka::CLI qw( $prompt_year $prompt_month );
use App::Dochazka::CLI::Util qw( datelist_from_token month_alpha_to_numeric );
use Data::Dumper;
use Test::Fatal;
use Test::More;
use Test::Warnings;

note( 'initialize logger' );
$log->init( ident => "dochazka-cli", debug_mode => 1 ); 

note( 'month_alpha_to_numeric()' );
my %test_months = (
    'prd' => undef,
    'Jan' => 1,
    'feb' => 2,
    'MAR' => 3,
    'aPril' => 4,
    'MAYFAIR' => 5,
    'June' => 6,
    'julYjuniper' => 7,
    'august' => 8,
    'sep' => 9,
    'oct' => 10,
    'november' => 11,
    'dec' => 12,
    'furt' => undef,
);
foreach my $test ( keys %test_months ) {
    my $result = month_alpha_to_numeric( $test );
    is( $test_months{$test}, $result );
}
is( month_alpha_to_numeric(), undef );

note( 'datelist_from_token() - legal prompt_month' );
$prompt_year = 1960;
my %tests = (
    1 => [ "5", [ "1960-01-05" ] ],
    2 => [ "5-6", [ "1960-02-05", "1960-02-06" ] ],
    3 => [ "10", [ "1960-03-10" ] ],
    4 => [ "9-10", [ "1960-04-09", "1960-04-10" ] ],
    5 => [ "10-13,5,5", [ "1960-05-10", "1960-05-11", "1960-05-12", "1960-05-13", "1960-05-05", "1960-05-05" ] ],
    6 => [ "5,6,10-13,2", [ "1960-06-05", "1960-06-06", "1960-06-10", "1960-06-11", "1960-06-12", "1960-06-13", "1960-06-02" ] ],
);
foreach my $test ( keys %tests ) {
    $prompt_month = $test;
    my $result = datelist_from_token( $tests{$test}->[0] );
    is_deeply( $tests{$test}->[1], $result );
}

note( 'datelist_from_token() - illegal prompt_month' );
%tests = (
    0 => [ "5,6,10-13,2", undef ],
    13 => [ "5,6,10-13,2", undef ],
);
foreach my $test ( keys %tests ) {
    $prompt_month = $test;
    like( exception { datelist_from_token( $tests{$test}->[0] ); },
          qr/ASSERT ohayoa9I/ );
}

done_testing;
