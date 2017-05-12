#!perl -w
use strict;
use warnings;
use Test::More;

use Test::Spelling 0.11;

set_spell_cmd('aspell list');

add_stopwords( grep { defined $_ && length $_ } <DATA>);

all_pod_files_spelling_ok();

__DATA__
Kimball
rfc
uri
APIs
Sascha
URI
https
dhoss
behaviour
Doran
Kiefer
Kogman
Yuval
auth
username
Authorization
authorization
sess
init
ok
Corlett
