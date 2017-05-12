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
# + truncate_to
#

#!perl
use 5.012;
use strict;
use warnings;

use App::Dochazka::CLI::Util qw( truncate_to );
use Data::Dumper;
use Test::Fatal;
use Test::More;
use Test::Warnings;

note( 'truncate_to with undef' );
is( truncate_to( undef ), undef, 'truncate_to undef returns undef 1' );
is( truncate_to( undef, 0 ), undef, 'truncate_to undef returns undef 2' );

note( 'truncate_to with empty string' );
is( truncate_to( '' ), '', 'truncate_to empty string returns empty string 1' );
is( truncate_to( '', 0 ), '', 'truncate_to empty string returns empty string 2' );

note( 'truncate_to with length parameter equal to length of string' );
is( truncate_to( 'a', 1 ), 'a' );
is( truncate_to( 'abc123', 6 ), 'abc123' );
is( truncate_to( '1234567890123456789012345678901', 31 ), '1234567890123456789012345678901' );
is( truncate_to( '12345678901234567890123456789012' ), '12345678901234567890123456789012', 
    'No parameter - length defaults to 32');

note( 'truncate_to with max length parameter one less than length of string' );
is( truncate_to( 'a', 0 ), '' );
is( truncate_to( 'abc123', 5 ), 'abc12...' );
is( truncate_to( '1234567890123456789012345678901', 30 ), '123456789012345678901234567890...' );

note( 'truncate_to with max length two less than length of string' );
is( truncate_to( 'ab', 0 ), '' );
is( truncate_to( 'abc123', 4 ), 'abc1...' );
is( truncate_to( '1234567890123456789012345678901', 29 ), '12345678901234567890123456789...' );

note( 'do weird things' );
like( 
    exception { truncate_to( undef, {} ); }, 
    qr/which is not one of the allowed types: scalar/,
    'cause an exception'
);
like( 
    exception { truncate_to( undef, -1 ); }, 
    qr/did not pass the 'greater than or equal to zero' callback/,
    'cause an exception'
);

done_testing;
