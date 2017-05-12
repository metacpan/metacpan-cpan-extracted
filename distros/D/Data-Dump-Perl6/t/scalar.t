#!perl -w

use strict;
use Test qw(plan ok);

plan tests => 2;

use Data::Dump::Perl6 qw(dump_perl6);

my $a = 42;
my @a = (\$a);

my $d = dump_perl6($a, $a, \$a, \\$a, "$a", $a+0, \@a);

ok(nl($d), <<'EOT');
do {
  my $a = 42;
  ($a, $a, $a, $a, 42, 42, [$a]);
}
EOT

# not really a scalar test, but anyway
$a = [];
$d = dump_perl6(\$a, $a);

ok(nl($d), <<'EOT');
do {
  my $a = [];
  ($a, $a);
}
EOT

sub nl {
    $_[0] . "\n";
}
