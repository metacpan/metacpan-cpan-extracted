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
# tests for shared_process_quals() function in App::Dochazka::REST::Shared
#

#!perl
use 5.012;
use strict;
use warnings;

#use App::CELL::Test::LogToFile;
use App::Dochazka::REST::Shared qw( shared_process_quals );
use App::Dochazka::REST::Test;
use Data::Dumper;
use Test::More;
use Test::Warnings;

note( 'initialize unit' );
initialize_regression_test();

my $status = shared_process_quals( '' );
is( $status->level, "OK" );
is( $status->payload, undef );

note( 'try passing a bunch of malformed strings' );
my @str = (
    'sadf',
    'nick=bubba,sadf',
    'norna_stena,nick=bubba',
    '    nick=bubba , eid =   5234343343344',
    '    nick=bubba?? , eid =   52',
    '    nick=-_bubba',
    '  month=2015412',
    ',,nick=bubba,month=201406,',
    ',nick=bubba,month=201406,',
);
foreach my $str ( @str ) {
    $status = shared_process_quals( $str );
    is( $status->level, "ERR" );
    is( $status->code, "DOCHAZKA_MALFORMED_400" );
    is( $status->payload, undef );
}

$status = shared_process_quals( 'nick=bubba' );
is( $status->level, "OK" );
is( $status->code, 'DISPATCH_PROCESSED_QUALIFIERS' );
is_deeply( $status->payload, { 'nick' => 'bubba' } );

$status = shared_process_quals( '    nick=bubba , eid =   52' );
is( $status->level, "OK" );
is( $status->code, 'DISPATCH_PROCESSED_QUALIFIERS' );
is_deeply( $status->payload, { 
    'nick' => 'bubba',
    'eid' => 52,
} );

$status = shared_process_quals( '    nick=bubba , month=6, eid =   52' );
is( $status->level, "OK" );
is( $status->code, 'DISPATCH_PROCESSED_QUALIFIERS' );
is_deeply( $status->payload, { 
    'nick' => 'bubba',
    'eid' => 52,
    'month' => 6,
} );

$status = shared_process_quals( 'nick=bubba,month=201406,' );
is( $status->level, "OK" );
is( $status->code, 'DISPATCH_PROCESSED_QUALIFIERS' );
is_deeply( $status->payload, { 
    'nick' => 'bubba',
    'month' => 201406,
} );

$status = shared_process_quals( 'nick=bubba,month=201406,,,,,,,,,,,,,,,,,,,,,' );
is( $status->level, "OK" );
is( $status->code, 'DISPATCH_PROCESSED_QUALIFIERS' );
is_deeply( $status->payload, { 
    'nick' => 'bubba',
    'month' => 201406,
} );

done_testing;
