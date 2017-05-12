use Test::More tests=>2;

BEGIN {
  use_ok qw(Acme::Tie::Formatted);
}

my $expected;
my $result;

$result = $format{16, "%03x"};
is $result, "010", "basic format";
