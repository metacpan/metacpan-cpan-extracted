use Test::More tests=>2;

BEGIN {
  use_ok qw(Acme::Tie::Formatted);
}

my $expected;
my $result;

$result = $format{16, 1, 255, 4184, "%04x"};
is $result, "0010 0001 00ff 1058", "basic format";
