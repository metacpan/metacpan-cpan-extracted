use Test::More tests=>4;
use Test::Differences;
$ENV{HARNESS_PERL_SWITCHES} = "" unless defined $ENV{HARNESS_PERL_SWITCHES};

my %runs = (
  qq(echo "http://perl.org/ /python/ TY later..." | $^X $ENV{HARNESS_PERL_SWITCHES} -Iblib/lib bin/simple_scan 2>&1) => <<EOS,
1..1
not ok 1 - later... [http://perl.org/] [/python/ should match] # TODO Doesn't match now but should later
#   Failed (TODO) test 'later... [http://perl.org/] [/python/ should match]'
#   in .../Test/WWW/Simple.pm at line ....
#          got: "...<!DOCTYPE html>"...
#       length: ****
#     doesn\'t match \'...python...\'

EOS
  qq(echo "http://perl.org/ /python/ SY later..." | $^X $ENV{HARNESS_PERL_SWITCHES} -Iblib/lib bin/simple_scan) => <<EOS,
1..1
ok 1 # skip Deliberately skipping test that should match
EOS
  qq(echo "http://perl.org/ /python/ SN later..." | $^X $ENV{HARNESS_PERL_SWITCHES} -Iblib/lib bin/simple_scan) => <<EOS,
1..1
ok 1 # skip Deliberately skipping test that shouldn't match
EOS
  qq(echo "http://perl.org/ /python/ TN later..." | $^X $ENV{HARNESS_PERL_SWITCHES} -Iblib/lib bin/simple_scan) => <<EOS,
1..1
ok 1 - later... [http://perl.org/] [/python/ shouldn't match] # TODO Matches now but shouldn't later
EOS
);

for my $cmd (keys %runs) {
  my @output = qx($cmd);
  for (@output) {
    s/length: \d+/length: ****/;
    s/got: ".*<!DOCTYPE html>.*/got: "...<!DOCTYPE html>".../;
    s|at .* line|in .../Test/WWW/Simple.pm line|;
    s/line .*/at line ..../;
    s/doesn't match .*python.*/doesn't match '...python...'/;
  }

  my @expected = map {"$_\n"} (split /\n/, $runs{$cmd});
  eq_or_diff \@output, \@expected, "good output";
}
