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

# @(#) $Id: 02simple.t 550 2005-02-22 13:03:53Z dom $

use strict;
use Test::More tests => 7;

# Override the default file layout, by sub classing.
{
        package TestSetting;

        use Config::Setting::FileProvider;

        use base qw( Config::Setting );

        sub provider {
                my $self = shift;
                return Config::Setting::FileProvider->new(
                        Env   => "TEST_SETTINGS_INI",
                        Paths => [ "t/test.ini" ],
                );
        }
}

# Test 1: Can we subclass ok?
my $stg = TestSetting->new;
isa_ok( $stg, 'TestSetting' );
ok( $stg->is_configured, 'is_configured()' );

#---------------------------------------------------------------------

my @expected_sections = ( 'settings', 'other stuff' );
my @sections          = $stg->sections();
is_deeply( \@expected_sections, \@sections, "Correct list of sections");

my @expected_keys = sort qw(foo baz Ivor combined);
my @keys          = sort $stg->keylist('settings');
is_deeply( \@expected_keys, \@keys, "Correct list of keys" );

my $v = $stg->get("settings", "baz");
is( $v, "quux", "'baz' key has correct value" );

$v = $stg->get("settings", "foo");
is( $v, "bar, The Engine", "'bar' key has correct value" );

$v = $stg->get("settings", "combined");
is( $v, "bar, The Engine quux ", "'combined' key has the right value");

# vim: set ai et sw=8 syntax=perl :
