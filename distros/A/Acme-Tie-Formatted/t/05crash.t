use Test::More tests=>3;

BEGIN {
  use_ok qw(Acme::Tie::Formatted);
}

my $expected;
my $result;

eval { $format{""} = "zorch" };
ok $@, "died as expected";
like $@, qr/You can only use %format by accessing it/, "right message";
