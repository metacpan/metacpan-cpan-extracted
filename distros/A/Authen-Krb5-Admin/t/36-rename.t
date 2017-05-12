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

# $Id: 36-rename.t,v 1.5 2006/12/28 18:30:24 ajk Exp $

# Tests for renaming principals

use strict;
use Test;

BEGIN { plan test => 6 }

use Authen::Krb5;
use Authen::Krb5::Admin qw(:constants);

Authen::Krb5::init_context;
Authen::Krb5::init_ets;

my $handle =
    Authen::Krb5::Admin->init_with_creds($ENV{PERL_KADM5_PRINCIPAL},
    Authen::Krb5::cc_resolve($ENV{PERL_KADM5_TEST_CACHE}));
ok $handle or warn Authen::Krb5::Admin::error;

my $p1 = Authen::Krb5::parse_name($ENV{PERL_KADM5_TEST_NAME});
ok $p1 or warn Authen::Krb5::error;

my $ap1 = $handle->get_principal($p1, KADM5_KEY_DATA);
ok $ap1 or warn Authen::Krb5::Admin::error;

my $cannot_rename = 1;
foreach ($ap1->key_data) {
	$cannot_rename = 0;
	if ($_->ver == 1 || $_->salt_type == KRB5_KDB_SALTTYPE_NORMAL) {
		$cannot_rename =
		    'renaming not tested: salt type does not support renaming';
		last;
	}
}

my $p2 = Authen::Krb5::parse_name($ENV{PERL_KADM5_TEST_NAME_2});
ok $p2 or warn Authen::Krb5::error;

my $status = $handle->rename_principal($p1, $p2);
if ($cannot_rename) {
	ok !$status or
	    warn 'should not be able to rename principals with this salt type';
} else {
	ok $status or warn Authen::Krb5::Admin::error;
}

skip $cannot_rename, $handle->rename_principal($p2, $p1)
    or warn Authen::Krb5::Admin::error;
