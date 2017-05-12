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

# $Id: 20-addpol.t,v 1.6 2006/12/28 18:30:24 ajk Exp $

# Tests for adding policies

use strict;
use Test;

BEGIN { plan test => 15 }

use Authen::Krb5;
use Authen::Krb5::Admin qw(:constants);

Authen::Krb5::init_context;
Authen::Krb5::init_ets;

my $handle =
    Authen::Krb5::Admin->init_with_creds($ENV{PERL_KADM5_PRINCIPAL},
    Authen::Krb5::cc_resolve($ENV{PERL_KADM5_TEST_CACHE}));
ok $handle or warn Authen::Krb5::Admin::error;

my $p = Authen::Krb5::Admin::Policy->new;
ok $p;

$p->name($ENV{PERL_KADM5_TEST_NAME});
ok $p->name, $ENV{PERL_KADM5_TEST_NAME};
ok $p->mask & KADM5_POLICY;

$p->pw_history_num(1);
ok $p->pw_history_num, 1;
ok $p->mask & KADM5_PW_HISTORY_NUM;

$p->pw_max_life(10);
ok $p->pw_max_life, 10;
ok $p->mask & KADM5_PW_MAX_LIFE;

$p->pw_min_classes(3);
ok $p->pw_min_classes, 3;
ok $p->mask & KADM5_PW_MIN_CLASSES;

$p->pw_min_length(4);
ok $p->pw_min_length, 4;
ok $p->mask & KADM5_PW_MIN_LENGTH;

$p->pw_min_life(5);
ok $p->pw_min_life, 5;
ok $p->mask & KADM5_PW_MIN_LIFE;

ok $handle->create_policy($p) or warn Authen::Krb5::Admin::error;
