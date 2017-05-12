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

# $Id: 01-config.t,v 1.5 2006/12/28 18:30:24 ajk Exp $

# Tests for creating and manipulating Authen::Krb5::Admin::Principal
# objects

use strict;
use Test;

BEGIN { plan test => 11 }

use Authen::Krb5::Admin qw(:constants);

my $c = Authen::Krb5::Admin::Config->new;
ok $c;

$c->admin_server('example.com');
ok $c->admin_server, 'example.com';
ok $c->mask & KADM5_CONFIG_ADMIN_SERVER;

$c->kadmind_port(1);
ok $c->kadmind_port, 1;
ok $c->mask & KADM5_CONFIG_KADMIND_PORT;

$c->kpasswd_port(2);
ok $c->kpasswd_port, 2;
ok $c->mask & KADM5_CONFIG_KPASSWD_PORT;

my $do_not_have_profile = eval { KADM5_CONFIG_PROFILE }
                        ? '' : 'Skip unless KADM5_CONFIG_PROFILE is defined';
unless ($do_not_have_profile) {
    $c->profile('/tmp/krb5.conf');
}
skip $do_not_have_profile, eval { $c->profile() eq '/tmp/krb5.conf' };
skip $do_not_have_profile, eval { $c->mask & KADM5_CONFIG_PROFILE   };

$c->realm('PERL.TEST');
ok $c->realm, 'PERL.TEST';
ok $c->mask & KADM5_CONFIG_REALM;
