use Test::More;
use Test::Differences;

my $simple_scan = `which simple_scan`;
chomp $simple_scan;

my %test_pairs = (
  "%%retry 0" => <<EOS,
use Test::More tests=>0;
use Test::WWW::Simple;
use strict;

mech->agent_alias('Windows IE 6');
mech->retry("0");

EOS
  "%%retry 4.7" => <<EOS,
use Test::More tests=>0;
use Test::WWW::Simple;
use strict;

mech->agent_alias('Windows IE 6');
mech->retry("4");

EOS
  "%%retry zonk" => <<EOS,
use Test::More tests=>1;
use Test::WWW::Simple;
use strict;

mech->agent_alias('Windows IE 6');
fail "retry count 'zonk' is not a number";

EOS
  "%%retry 3" => <<EOS,
use Test::More tests=>0;
use Test::WWW::Simple;
use strict;

mech->agent_alias('Windows IE 6');
mech->retry("3");

EOS
);

plan tests=>(int keys %test_pairs);

for my $test_input (keys %test_pairs) {
  my $cmd = qq(echo "$test_input" | perl -Iblib/lib $simple_scan --gen);
  my $results = `$cmd`;
  eq_or_diff $results, $test_pairs{$test_input}, "expected output";
}
