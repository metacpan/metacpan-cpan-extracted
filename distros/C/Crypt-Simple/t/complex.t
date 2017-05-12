#!/usr/bin/perl -w
use strict;
use Test;

plan tests => 2;

use Crypt::Simple;

my $r = bless {foo=>'bar'}, "thingie";
my $e = encrypt($r);
my $r2 = decrypt($e);
ok($r->isa("thingie"));
ok($r->{foo} eq 'bar');
