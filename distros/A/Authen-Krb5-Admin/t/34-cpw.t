#!/usr/bin/perl -w

# Copyright (c) 2002 Andrew J. Korty
# All rights reserved.
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
# THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
# OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
# LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
# OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
# SUCH DAMAGE.

# $Id: 34-cpw.t,v 1.11 2008/01/30 13:07:11 ajk Exp $

# Tests for changing passwords

use strict;
use Test;

BEGIN { plan test => 8 }

use Authen::Krb5;
use Authen::Krb5::Admin qw(:constants);

Authen::Krb5::init_context;
Authen::Krb5::init_ets;

my $handle =
    Authen::Krb5::Admin->init_with_creds($ENV{PERL_KADM5_PRINCIPAL},
    Authen::Krb5::cc_resolve($ENV{PERL_KADM5_TEST_CACHE}));
ok $handle or warn Authen::Krb5::Admin::error;

my $p = Authen::Krb5::parse_name($ENV{PERL_KADM5_TEST_NAME});
ok $p;

my $s = Authen::Krb5::parse_name('krbtgt/' . $p->realm);
ok $p;

my $pw = join '', map { chr rand(255) + 1 } 1..256;

ok $handle->chpass_principal($p, $pw), 1, Authen::Krb5::Admin::error;

my $ap = $handle->get_principal($p);
ok $ap;

# Authen::Krb5 1.7 get_in_tkt_with_password segfaults with MIT 1.6.3
my $mit_version = `krb5-config --version 2>/dev/null` || '';
if ($Authen::Krb5::VERSION eq '1.7'
    && $mit_version =~ /release 1\.6\./) {
    foreach (1..3) {
        skip 'MIT / Authen::Krb5 incompatibility';
    }
}

else {
    $ap->attributes($ap->attributes & ~KRB5_KDB_DISALLOW_ALL_TIX);
    ok $handle->modify_principal($ap), 1, Authen::Krb5::Admin::error;

    ok Authen::Krb5::get_in_tkt_with_password($p, $s, $pw, undef)
       or warn Authen::Krb5::error;

    $ap->attributes($ap->attributes & KRB5_KDB_DISALLOW_ALL_TIX);
    ok $handle->modify_principal($ap), 1, Authen::Krb5::Admin::error;
}
