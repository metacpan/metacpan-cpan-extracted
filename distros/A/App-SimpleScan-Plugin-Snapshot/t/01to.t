use Test::More;
use Test::Differences;

my $simple_scan = `which simple_scan`;
chomp $simple_scan;

my %test_pairs = (
  "%%snap_dir /nonexistent" => <<EOS,
use Test::More tests=>0;
use Test::WWW::Simple;
use strict;

my \@accent;
mech->agent_alias('Windows IE 6');
mech->snapshots_to("/nonexistent");

EOS
  "%%snap_dir ." => <<EOS,
use Test::More tests=>0;
use Test::WWW::Simple;
use strict;

my \@accent;
mech->agent_alias('Windows IE 6');
mech->snapshots_to(".");

EOS
);

plan tests=>(int keys %test_pairs);

for my $test_input (keys %test_pairs) {
  my $cmd = qq(echo "$test_input" | perl -Iblib/lib $simple_scan --gen);
  my $results = `$cmd`;
  eq_or_diff $results, $test_pairs{$test_input}, "expected output";
}
