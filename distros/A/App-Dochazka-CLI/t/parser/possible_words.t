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
# possible_words tests

#!perl
use 5.012;
use strict;
use warnings;

use App::Dochazka::CLI::Parser qw( possible_words $semantic_tree );
use Data::Dumper;
use Test::More;
use Test::Warnings;

my ( $ts, $pw );


$semantic_tree = {
    'GET' => {},
};
$ts = [ 'GET' ];
$pw = [ sort @{ possible_words( $ts ) } ];
is_deeply( $pw, [], 'GET' );


$semantic_tree = {
    'GETFOOBAR' => {
        'FOO' => {},
        'BAR' => {},
    },
};
$ts = [ 'GETFOOBAR' ];
$pw = [ sort @{ possible_words( $ts ) } ];
is_deeply( $pw, [ 'BAR', 'FOO' ], 'GETFOOBAR' );


$semantic_tree = {
    'GET' => {
        'FOO' => {},
        'BAR' => {},
    },
    'POST' => {},
};
$ts = [ 'GET', 'FOO' ];
$pw = [ sort @{ possible_words( $ts ) } ];
is_deeply( $pw, [], 'GET FOO' );
$ts = [ 'POST' ];
$pw = [ sort @{ possible_words( $ts ) } ];
is_deeply( $pw, [], 'POST' );
$ts = [];
$pw = [ sort @{ possible_words( $ts ) } ];
is_deeply( $pw, [ 'GET', 'POST' ], 'Empty token stack' );
$ts = [ 'FOOBAR' ];
$pw = [ sort @{ possible_words( $ts ) } ];
is_deeply( $pw, [], 'FOOBAR' );

$semantic_tree = {
    ONE => {
        TWO => {
            THREE => {
                FOUR => {
                    FIVE => {},
                    JAZZ => { _DIZZY => {} },
                },
            },
        },
    },
};
$ts = [ qw( ONE TWO THREE ) ];
$pw = [ sort @{ possible_words( $ts ) } ];
is_deeply( $pw, [ 'FOUR' ], 'ONE TWO THREE' );
$ts = [ qw( ONE TWO THREE FOUR ) ];
$pw = [ sort @{ possible_words( $ts ) } ];
is_deeply( $pw, [ 'FIVE', 'JAZZ' ], 'ONE TWO THREE FOUR' );
$ts = [ qw( ONE TWO THREE FOUR JAZZ ) ];
$pw = [ sort @{ possible_words( $ts ) } ];
is_deeply( $pw, [ '_DIZZY' ], 'ONE TWO THREE FOUR JAZZ' );


done_testing;
