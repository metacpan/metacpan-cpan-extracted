#!perl -w

use strict;
use Test qw(plan ok);
plan tests => 6;

use Data::Dump qw(dump);
use Symbol qw(gensym);

ok(dump(*STDIN), "*main::STDIN");
ok(dump(\*STDIN), "\\*main::STDIN");
ok(dump(gensym()), "do {\n  require Symbol;\n  Symbol::gensym();\n}");

$a = [];
${*foo}[1] = $a;
${*foo}{bar} = 2;
ok(dump(\*foo, $a) . "\n", <<'EOT');
do {
  my $a = \*main::foo;
  *{$a} = [undef, []];
  *{$a} = { bar => 2 };
  ($a, *{$a}{ARRAY}[1]);
}
EOT

my $s = gensym();
bless $s, 'Data::Dump::Test';
${*$s}{ddt_domain}  = 2;
${*$s}{ddt_proto}   = 6;
${*$s}{ddt_type}    = 1;
${*$s}{ddt_timeout} = 5;
$s = dump($s);
print "$s\n";
ok($s =~ /my \$a = bless\(Symbol::gensym\(\), "Data::Dump::Test"\);/);
ok($s =~ /\s+ddt_timeout\s+=> 5/m);
