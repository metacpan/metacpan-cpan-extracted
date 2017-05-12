#!perl -w

use strict;
use Test qw(plan ok);

plan tests => 2;

use Data::Dump::Perl6 qw(dump_perl6);

my $a = 42;
bless \$a, "Foo";

ok(nl(dump_perl6($a)), <<'EOT');
do {
  my $a = 42;
  Foo.bless(content => $a);
  $a;
}
EOT

ok(dump_perl6(\$a), q{Foo.bless(content => 42)});

sub nl {
    $_[0] . "\n";
}
