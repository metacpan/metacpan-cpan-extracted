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

# $Id: 31-getprinc.t,v 1.6 2006/12/28 18:30:24 ajk Exp $

# Tests for retrieving principals

use strict;
use Test;

BEGIN { plan test => 18 }

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

my $adminp = Authen::Krb5::parse_name($ENV{PERL_KADM5_PRINCIPAL});
ok $adminp;

my $ap = $handle->get_principal($p,
    KADM5_PRINCIPAL_NORMAL_MASK | KADM5_KEY_DATA);
ok $ap;

ok $ap->attributes, KRB5_KDB_DISALLOW_ALL_TIX | KRB5_KDB_DISALLOW_TGT_BASED;
ok $ap->aux_attributes, KADM5_POLICY;
ok $ap->kvno, 2;
ok $ap->max_life, 3;
ok $ap->max_renewable_life, 4;
ok(($ap->mod_name->data)[0], ($adminp->data)[0]);
ok $ap->policy, $ENV{PERL_KADM5_TEST_NAME};
ok $ap->princ_expire_time, 1021908731;
ok(($ap->principal->data)[0], ($p->data)[0]);
ok $ap->pw_expiration, 1021908826;

my @keys = $ap->key_data;
ok @keys;
ok $keys[0] && $keys[0]->ver;
ok $keys[0] && $keys[0]->kvno;
ok $keys[0] && $keys[0]->enc_type;
