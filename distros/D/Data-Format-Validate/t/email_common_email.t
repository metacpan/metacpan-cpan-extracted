#!/usr/bin/perl
use 5.008;
use strict;
use warnings;

use Test::Simple tests => 15;
use Data::Format::Validate::Email 'looks_like_common_email';

ok(looks_like_common_email 'israel.batista@univem.edu.br');
ok(looks_like_common_email 'israel.batista42@univem.edu.br');

ok(not looks_like_common_email 'israel.@univem.edu.br');
ok(not looks_like_common_email 'israel.batistaunivem.edu.br');
ok(not looks_like_common_email '!$%@&[.B471374@*")..$$#!+=.-');
ok(not looks_like_common_email '!srael.batista@un!vem.edu.br');
ok(not looks_like_common_email 'i%rael.bati%ta@univem.edu.br');
ok(not looks_like_common_email 'isra&l.batista@univ&m.&du.br');
ok(not looks_like_common_email 'israel[batista]@univem.edu.br');
ok(not looks_like_common_email 'israel. batista@univem.edu.br');
ok(not looks_like_common_email 'israel.batista@univem. edu.br');
ok(not looks_like_common_email 'israel.batista@univem..edu.br');
ok(not looks_like_common_email 'israel..batista@univem.edu.br');
ok(not looks_like_common_email 'israel.batista@@univem.edu.br');
ok(not looks_like_common_email 'israel.batista@univem.edu.brasilia');
