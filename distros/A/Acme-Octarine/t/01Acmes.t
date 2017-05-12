#!/usr/bin/perl -w

use strict;
use Test::More tests => 5;

use Acme::Octarine;

cmp_ok (scalar (@Acme::Octarine::Acmes), '>', 3,
	"There should be >3 Acme modules");

my $fail = 0;
foreach (@Acme::Octarine::Acmes) {
  $fail++ unless /^Acme::[A-Za-z_0-9:]+\z/;
}
is ($fail, 0, "And all should /^Acme::/");

foreach (0..2) {
  my $module = Acme::Octarine::random_acme_module;
  like ($module, qr/^Acme::/,
	"random_acme_module should return Acme:: modules");
}
