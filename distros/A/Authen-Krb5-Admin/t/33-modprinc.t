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

# $Id: 33-modprinc.t,v 1.12 2006/12/28 18:30:24 ajk Exp $

# Tests for modifying principals

use strict;
use Test;

BEGIN { plan test => 29 }

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

my $ap = Authen::Krb5::Admin::Principal->new;
ok $ap;

$ap->attributes(KRB5_KDB_DISALLOW_ALL_TIX);
ok $ap->attributes, KRB5_KDB_DISALLOW_ALL_TIX;
ok $ap->mask & KADM5_ATTRIBUTES;

$ap->kvno(5);
ok $ap->kvno, 5;
ok $ap->mask & KADM5_KVNO;

$ap->max_life(6);
ok $ap->max_life, 6;
ok $ap->mask & KADM5_MAX_LIFE;

$ap->max_renewable_life(7);
ok $ap->max_renewable_life, 7;
ok $ap->mask & KADM5_MAX_RLIFE;

$ap->policy_clear;
ok !defined $ap->policy;
ok $ap->mask & KADM5_POLICY_CLR;

# set expire time to zero so cpw test will work later

$ap->princ_expire_time(0);
ok $ap->princ_expire_time, 0;
ok $ap->mask & KADM5_PRINC_EXPIRE_TIME;

$ap->principal($p);
ok(($ap->principal->data)[0], ($p->data)[0]);
ok $ap->mask & KADM5_PRINCIPAL;

$ap->pw_expiration(1021993140);
ok $ap->pw_expiration, 1021993140;
ok $ap->mask & KADM5_PW_EXPIRATION;

ok $handle->modify_principal($ap), 1, Authen::Krb5::Admin::error;

$ap = $handle->get_principal($p);
ok $ap;

ok $ap->attributes, KRB5_KDB_DISALLOW_ALL_TIX;
ok $ap->kvno, 5;
ok $ap->max_life, 6;
ok $ap->max_renewable_life, 7;
ok !defined $ap->policy;
ok $ap->princ_expire_time, 0;
ok(($ap->principal->data)[0], ($p->data)[0]);
ok $ap->pw_expiration, 1021993140;
