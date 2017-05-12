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
# + normalize_date
# + normalize_time
#

#!perl
use 5.012;
use strict;
use warnings;

use App::Dochazka::Common qw( $t $today $tomorrow $yesterday );
use App::Dochazka::CLI qw( $prompt_date $prompt_year $prompt_month $prompt_day );
use App::Dochazka::CLI::Util qw( 
    init_prompt
    normalize_date
    normalize_time
);
use Data::Dumper;
use Test::More;
use Test::Warnings;

my ( $rd, $nd, $rt, $nt ); 


#=================================
# normalize_date() tests
#=================================

note( 'normalize_date routine from Util.pm' );
note( 'Normalize a date entered by the user.' ); 

note( 'Initialize timepiece' );
ok( ! defined( $t ), "\$t not defined before timepiece initialization" );
init_prompt();
ok( defined( $t ), "\$t defined after timepiece initialization" );

like( $prompt_date, qr/\d{4,4}-\d{1,2}-\d{1,2}/, 'Prompt date resembles a date' );

note( 'Normalize the prompt date' );
my $normalized_prompt_date = normalize_date( $prompt_date );
is( normalize_date( undef ), $normalized_prompt_date, 
    'If no date is provided, the prompt date is returned 1' );
is( normalize_date(   ''  ), $normalized_prompt_date, 
    'If no date is provided, the prompt date is returned 2' );

$rd = '2014-01-01';
$nd = normalize_date( $rd );
is( $rd, $nd, "2014-01-01 is already normalized - no change" );

is( normalize_date( 'Admin barge' ), undef, "Admin barge is an invalid date" );

note( 'YY-MM-DD' );
$rd = '72-12-12';
$nd = normalize_date( $rd );
is( $nd, '2072-12-12', "$rd normalizes to current century" );

note( 'MM-DD' );
$rd = '12-12';
$nd = normalize_date( $rd );
is( $nd, $prompt_year . '-12-12', "$rd normalizes to prompt year" );

note( 'Trailing characters' );
$rd = '72-12-12 BLBA';
$nd = normalize_date( $rd );
is( $nd, undef, "Trailing characters in raw date are not tolerated 1" );

$rd = '12-12 *DSS(((';
$nd = normalize_date( $rd );
is( $nd, undef, "Trailing characters in raw date are not tolerated 2" );

note( 'any of the two-digit forms can be fulfilled by a single digit' );
$rd = '1955-2-12';
$nd = normalize_date( $rd );
is( $nd, '1955-02-12', "month gets leading zero 1" );

$rd = '2-12';
$nd = normalize_date( $rd );
is( $nd, $prompt_year . '-02-12', "month gets leading zero 2" );

$rd = '2-00';
$nd = normalize_date( $rd );
is( $nd, undef );

$rd = '1955-12-2';
$nd = normalize_date( $rd );
is( $nd, '1955-12-02', "day gets leading zero 1" );

$rd = '12-2';
$nd = normalize_date( $rd );
is( $nd, $prompt_year . '-12-02', "day gets leading zero 2" );

note( 'a single zero will not pass for a month or date' );
$rd = '1983-0-10';
$nd = normalize_date( $rd );
is( $nd, undef, "single zero as month does not fly" );

$rd = '12-0';
$nd = normalize_date( $rd );
is( $nd, undef, "single zero as day does not fly" );

note( 'three-digit month or date does not fly' );
$rd = '1983-999-10';
$nd = normalize_date( $rd );
is( $nd, undef, "three-digit month does not fly" );

$rd = '12-999';
$nd = normalize_date( $rd );
is( $nd, undef, "three-digit day does not fly" );

note( 'If only YY is given, it is converted into YYYY by appending two digits corresponding to the current century' ); 
$rd = '22-22-22';
$nd = normalize_date( $rd );
is( $nd, undef );

note( 'special date forms' );
note( 'The special date forms "TODAY", "TOMORROW", and "YESTERDAY" are recognized' );
$rd = "TODAY";
$nd = normalize_date( $rd );
is( $nd, "$today", "$rd is normalized to $today" );

$rd = "TOMORROW";
$nd = normalize_date( $rd );
is( $nd, "$tomorrow", "$rd is normalized to $tomorrow" );

$rd = "YESTERDAY 22:00";
$nd = normalize_date( $rd );
is( $nd, "$yesterday", "$rd is normalized to $yesterday" );

note( 'only the first three letters are significant' );
$rd = "todMUMBOJUMBO";
$nd = normalize_date( $rd );
is( $nd, "$today", "$rd converts to today\'s date" );

note( 'If no year is given, the current year is used.' );
$rd = "6-30";
$nd = normalize_date( $rd );
is( $nd, $prompt_year . "-06-30" );

note( 'Offsets are applied to prompt date' );
$prompt_date = '2014-04-24';
$rd = "-1";
$nd = normalize_date( $rd );
is( $nd, "2014-04-23" );

$prompt_date = '2014-04-01';
$rd = "-1";
$nd = normalize_date( $rd );
is( $nd, "2014-03-31" );


#=================================
# normalize_time() tests
#=================================

note( 'if seconds are given, they are left off' );
$rt = '00:00:00';
$nt = normalize_time( $rt );
is( $nt, '00:00', "seconds get left off 1" );

#$rt = '99:05:99';
#$nt = normalize_time( $rt );
#is( $nt, '99:05', "seconds get left off 2" );

#note( 'any of the two-digit forms can be fulfilled by a single digit' );
#note( 'and in the time part single zeroes are handled properly' );
#$rt = '1:0';
#$nt = normalize_time( $rt );
#is( $nt, '01:00', "single zeroes expand to double zeroes in hours and minutes" );

#$rt = '000:00';
#$nt = normalize_time( $rt );
#is( $nt, undef, "three-digit hours does not fly" );

#$rt = '12:999:00';
#$nt = normalize_time( $rt );
#is( $nt, undef, "three-digit minutes does not fly" );

#note( 'for example 6:4:9 is 6:04 a.m. and nine seconds' );
#$rt = '6:4:9';
#$nt = normalize_time( $rt );
#is( $nt, '06:04', "$rd is cryptic, but valid" );

done_testing;
