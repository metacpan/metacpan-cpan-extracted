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

# $Id: 30-addprinc.t,v 1.8 2006/12/28 18:30:24 ajk Exp $

# Tests for adding principles

use strict;
use Test;

BEGIN { plan test => 22 }

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

my @args = $ap->db_args('derp');
ok !@args;

@args = $ap->db_args;
#warn $_ for unpack 'C*', $args[0];
#warn $args[0];
ok $args[0] eq "derp";

$ap->attributes(KRB5_KDB_DISALLOW_ALL_TIX | KRB5_KDB_DISALLOW_TGT_BASED);
ok $ap->attributes, KRB5_KDB_DISALLOW_ALL_TIX | KRB5_KDB_DISALLOW_TGT_BASED;
ok $ap->mask & KADM5_ATTRIBUTES;

$ap->kvno(2);
ok $ap->kvno, 2;
ok $ap->mask & KADM5_KVNO;

$ap->max_life(3);
ok $ap->max_life, 3;
ok $ap->mask & KADM5_MAX_LIFE;

$ap->max_renewable_life(4);
ok $ap->max_renewable_life, 4;
ok $ap->mask & KADM5_MAX_RLIFE;

$ap->policy($ENV{PERL_KADM5_TEST_NAME});
ok $ap->policy, $ENV{PERL_KADM5_TEST_NAME};
ok $ap->mask & KADM5_POLICY;

$ap->princ_expire_time(1021908731);
ok $ap->princ_expire_time, 1021908731;
ok $ap->mask & KADM5_PRINC_EXPIRE_TIME;

$ap->principal($p);
ok $ap->principal->realm, $p->realm;
ok $ap->mask & KADM5_PRINCIPAL;

$ap->pw_expiration(1021908826);
ok $ap->pw_expiration, 1021908826;
ok $ap->mask & KADM5_PW_EXPIRATION;

# utf8 gets ya
ok $handle->create_principal($ap, join '', map { chr(rand(127) + 1) } 1..256)
    or warn Authen::Krb5::Admin::error;
