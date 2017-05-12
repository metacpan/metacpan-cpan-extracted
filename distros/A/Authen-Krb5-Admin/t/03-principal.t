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

# $Id: 03-principal.t,v 1.3 2002/10/09 16:36:35 ajk Exp $

# Tests for creating and manipulating Authen::Krb5::Admin::Principal
# objects

use strict;
use Test;

BEGIN { plan test => 39 }

use Authen::Krb5;
use Authen::Krb5::Admin qw(:constants);

my $ap = Authen::Krb5::Admin::Principal->new;
ok $ap;

Authen::Krb5::init_context;
Authen::Krb5::init_ets;

my $p = Authen::Krb5::parse_name($ENV{PERL_KADM5_TEST_NAME});
ok $p;
ok(($p->data)[0], $ENV{PERL_KADM5_TEST_NAME});

$ap->attributes(KRB5_KDB_DISALLOW_TGT_BASED);
ok $ap->attributes, KRB5_KDB_DISALLOW_TGT_BASED;
ok $ap->mask & KADM5_ATTRIBUTES;

$ap->aux_attributes(KADM5_POLICY);
ok $ap->aux_attributes, KADM5_POLICY;
ok !($ap->mask & KADM5_AUX_ATTRIBUTES);

$ap->fail_auth_count(1);
ok $ap->fail_auth_count, 1;
ok $ap->mask & KADM5_FAIL_AUTH_COUNT;

$ap->kvno(2);
ok $ap->kvno, 2;
ok $ap->mask & KADM5_KVNO;

$ap->last_failed(1021987120);
ok $ap->last_failed, 1021987120;
ok !($ap->mask & KADM5_LAST_FAILED);

$ap->last_pwd_change(1021987175);
ok $ap->last_pwd_change, 1021987175;
ok !($ap->mask & KADM5_LAST_PWD_CHANGE);

$ap->last_success(1021987204);
ok $ap->last_success, 1021987204;
ok !($ap->mask & KADM5_LAST_FAILED);

$ap->mask(KADM5_PRINCIPAL_NORMAL_MASK);
ok $ap->mask, KADM5_PRINCIPAL_NORMAL_MASK;

$ap->mask(0);
ok $ap->mask, 0;

$ap->max_life(3);
ok $ap->max_life, 3;
ok $ap->mask & KADM5_MAX_LIFE;

$ap->max_renewable_life(4);
ok $ap->max_renewable_life, 4;
ok $ap->mask & KADM5_MAX_RLIFE;

$ap->mkvno(5);
ok $ap->mkvno, 5;
ok !($ap->mask & KADM5_MKVNO);

$ap->mod_date(1021987450);
ok $ap->mod_date, 1021987450;
ok !($ap->mask & KADM5_MOD_TIME);

$ap->mod_name($p);
ok(($ap->mod_name->data)[0], ($p->data)[0]);
ok !($ap->mask & KADM5_MOD_NAME);

$ap->policy('default');
ok $ap->policy, 'default';
ok $ap->mask & KADM5_POLICY;

$ap->policy_clear;
ok !defined $ap->policy;
ok $ap->mask & KADM5_POLICY_CLR;

$ap->princ_expire_time(1021908731);
ok $ap->princ_expire_time, 1021908731;
ok $ap->mask & KADM5_PRINC_EXPIRE_TIME;

$ap->principal($p);
ok $ap->principal->realm, $p->realm;
ok $ap->mask & KADM5_PRINCIPAL;

$ap->pw_expiration(1021908826);
ok $ap->pw_expiration, 1021908826;
ok $ap->mask & KADM5_PW_EXPIRATION;
