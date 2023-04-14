#!/usr/bin/env perl
# AP-Client: CLI-based client / toolbox for ActivityPub
# Copyright © 2020-2023 AP-Client Authors <https://hacktivis.me/git/ap-client/>
# SPDX-License-Identifier: BSD-3-Clause
use strict;
use utf8;
use open ":std", ":encoding(UTF-8)";

use Test::More tests => 1;
use Test::Output;

use JSON;
use App::ActivityPubClient qw(print_object);

# Read whole files
undef $/;

open(USER_JSON, '<:raw', 't/pleroma_user.json') or die "$!";

my $object = decode_json(<USER_JSON>) or die "$!";

close(USER_JSON);

open(USER_TXT,  '<:encoding(UTF-8)', 't/pleroma_user.out')  or die "$!";

output_is(sub { print_object(1, $object) }, <USER_TXT>, '', 'Test printing pleroma user');

close(USER_TXT);
