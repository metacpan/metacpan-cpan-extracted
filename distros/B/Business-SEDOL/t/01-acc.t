#!/usr/bin/perl -w

use strict;
use Business::SEDOL;
use Test;

BEGIN { plan tests => 7 }

my $s = Business::SEDOL->new();
ok($s->sedol, undef);
{ local $ = 0; ok($s->series, ''); }
ok($s->sedol('0123457'), '0123457');
ok($s->sedol, '0123457');
ok($s->series, '0');

$s = Business::SEDOL->new('7060858');
ok($s->sedol, '7060858');
ok($s->series, '7');

__END__