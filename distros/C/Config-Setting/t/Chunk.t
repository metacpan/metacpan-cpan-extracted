# Copyright (C) 2004 by Dominic Mitchell. All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
# 
# THIS SOFTWARE IS PROVIDED BY AUTHOR AND CONTRIBUTORS ``AS IS'' AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED.  IN NO EVENT SHALL AUTHOR OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
# OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
# LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
# OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
# SUCH DAMAGE.

# @(#) $Id: Chunk.t 542 2005-02-22 08:19:24Z dom $

use strict;
use Test::More tests => 27;

use_ok( 'Config::Setting::Chunk' );

my $chunk = Config::Setting::Chunk->new;
isa_ok( $chunk, 'Config::Setting::Chunk' );
can_ok(
        $chunk,
        qw( add_section sections has_section section_keys ),
        qw( set_item get_item get to_string )
);

test_add_section();
test_set_item();
test_to_string();
test_get();
test_section_keys();
test_has_section();
test_autovivification_prevention();

sub test_add_section {
        my $chunk = Config::Setting::Chunk->new;
        is_deeply( [ $chunk->sections ], [], 'sections() empty' );
        is( $chunk->add_section( 'foo' ), undef, 'add_section() retval' );
        is_deeply( [ $chunk->sections ], ['foo'], 'sections() one' );
        is( $chunk->add_section( 'bar' ), undef, 'add_section() retval' );
        is( $chunk->add_section( 'baz' ), undef, 'add_section() retval' );
        is_deeply( [ $chunk->sections ], [qw(foo bar baz)],
                'sections() three' );
}

sub test_set_item {
        my $chunk = Config::Setting::Chunk->new;
        is( $chunk->get_item( 'foo', 'bar' ),
                undef, 'get_item() no such section' );
        $chunk->add_section( 'foo' );
        is( $chunk->get_item( 'foo', 'bar' ), undef, 'get_item() no such key' );
        is( $chunk->set_item( 'foo', 'bar', 42 ), undef, 'set_item() retval' );
        is( $chunk->get_item( 'foo', 'bar' ), 42, 'get_item() success' );
}

sub test_to_string {
        my $chunk = Config::Setting::Chunk->new;
        is( $chunk->to_string, "", 'to_string()' );
        $chunk->add_section( 'foo' );
        is( $chunk->to_string, "[foo]\n\n", 'to_string() one secthead' );
        $chunk->set_item( 'foo', 'bar', 42 );
        is( $chunk->to_string, "[foo]\nbar=42\n\n", 'to_string() one section' );
}

sub test_get {
        my $chunk = Config::Setting::Chunk->new;

        # This also tests that set_item() automatically adds sections.
        $chunk->set_item( 'sect1', 'key1', 'val1' );
        $chunk->set_item( 'sect1', 'key2', 'val2' );
        $chunk->set_item( 'sect2', 'key1', 'val3' );
        $chunk->set_item( 'sect2', 'key3', 'val4' );
        is( $chunk->get( 'key1' ), 'val1', 'get()' );
        is( $chunk->get( 'key3' ), 'val4', 'get()' );
}

sub test_section_keys {
        my $chunk = Config::Setting::Chunk->new;
        $chunk->set_item( foo => bar => 42 );
        $chunk->set_item( foo => baz => 43 );
        $chunk->set_item( quux => boink => 47 );
        is_deeply(
                [ $chunk->section_keys( 'foo' ) ],
                [qw(bar baz)],
                'section_keys() foo',
        );
        is_deeply(
                [ $chunk->section_keys( 'quux' ) ],
                ['boink'],
                'section_keys() quux',
        );
        is_deeply(
                [ $chunk->section_keys( 'notpresent' ) ],
                [],
                'section_keys() notpresent',
        );
}

sub test_has_section {
        my $chunk = Config::Setting::Chunk->new;
        $chunk->set_item( foo => bar => 42 );
        ok( $chunk->has_section( 'foo' ), 'has_section(foo)' );
        ok( !$chunk->has_section( 'notpresent' ), 'has_section(notpresent)' );
}

# Sometimes Perl will automatically create hashes for you.  We don't
# want that to happen.
sub test_autovivification_prevention {
        my $chunk = Config::Setting::Chunk->new;
        is( $chunk->section_keys( 'fish' ), undef, 'no section fish' );
        ok( !$chunk->has_section( 'fish' ), 'still no section fish' );
        is( $chunk->get_item( 'ping', 'pong' ), undef, 'no item ping/pong' );
        ok( !$chunk->has_section( 'ping' ), 'still no section ping' );
}

# vim: set ai et sw=8 syntax=perl :
