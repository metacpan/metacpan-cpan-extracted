#!/usr/bin/perl
use 5.008;
use strict;
use warnings;

use Test::Simple tests => 5;
use Data::Format::Validate::Email 'looks_like_any_email';

ok(looks_like_any_email 'israel.batista@univem.edu.br');
ok(looks_like_any_email '!$%@&[.B471374@*")..$$#!+=.-');

ok(not looks_like_any_email 'israel.batistaunivem.edu.br');
ok(not looks_like_any_email 'israel. batista@univem.edu.br');
ok(not looks_like_any_email 'israel.batista@univ em.edu.br');
