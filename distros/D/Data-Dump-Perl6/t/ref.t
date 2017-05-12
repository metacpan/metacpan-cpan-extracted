#!perl -w

use strict;
use Test qw(plan ok);

plan tests => 2;

use Data::Dump::Perl6 qw(dump_perl6);

my $n = \\1;
ok(nl(dump_perl6($n)), <<'EOT');
1
EOT

my $sv = [];
my $s = \'test';

my %h = (
    c => (bless \$sv, "foo"),
    b => (bless \$sv, "foo"),
    a => $sv,
    d => $sv,
    e => (bless \$s, "foo"),
);

$h{z} = ${$h{c}};
$h{x} = ${$h{e}};

#print STDERR dump_perl6(\%h);

ok(nl(dump_perl6(\%h)), <<'EOT');
do {
  my $a = {
    a => [],
    b => foo.bless(content => Any),
    c => Any,
    d => Any,
    e => foo.bless(content => "test"),
    x => Any,
    z => Any,
  };
  $a<b>.content = $a<a>;
  $a<c> = $a<b>;
  $a<d> = $a<a>;
  $a<x> = $a<e>.content;
  $a<z> = $a<a>;
  $a;
}
EOT

sub nl { shift(@_) . "\n" }
