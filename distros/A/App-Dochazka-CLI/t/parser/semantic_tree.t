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
# semantic tree tests

#!perl
use 5.012;
use strict;
use warnings;

use App::Dochazka::CLI::Parser qw( generate_semantic_tree );
use Data::Dumper;
use Test::More;
use Test::Warnings;

my ( $dm, $tree );

$dm = {
    'GET' => undef,
};
$tree = generate_semantic_tree( $dm );
is_deeply( $tree, {
    'GET' => {},
} );

$dm = {
    'GET' => undef,
    'GET ACTIVITY' => undef,
};
$tree = generate_semantic_tree( $dm );
is_deeply( $tree, {
    'GET' => {
        'ACTIVITY' => {},
    },
} );

$dm = {
    'GET' => undef,
    'GET ACTIVITY' => undef,
    'BIG BAD WOLF' => undef,
    'BIG BAD PONY' => undef,
};
$tree = generate_semantic_tree( $dm );
is_deeply( $tree, {
    'GET' => {
        'ACTIVITY' => {},
    },
    'BIG' => {
        'BAD' => {
            'PONY' => {},
            'WOLF' => {},
        },
    },
} );

# Taking, for example, a dispatch map consisting of the following two commands:
# 
#     ABE BABEL CAROL
#     DALE EARL JENSEN PARLOR
#     DALE TWIT
# 
# The semantic tree would be:
# 
#     (root)
#     |
#     +-----------+
#     |           |
#     ABE        DALE
#     |           |
#     |           +------+
#     |           |      |
#     BABEL      EARL   TWIT
#     |           |
#     CAROL      JENSEN
#                 |
#                PARLOR
#

$dm = {
    'ABE BABEL CAROL' => {},
    'DALE EARL JENSEN PARLOR' => {},
    'DALE TWIT' => {},
};
$tree = generate_semantic_tree( $dm );
is_deeply( $tree, {
    'ABE' => {
        'BABEL' => {
            'CAROL' => {},
        },
    },
    'DALE' => {
        'EARL' => {
            'JENSEN' => {
                'PARLOR' => {},
            },
        },
        'TWIT' => {},
    },
} );

done_testing;
