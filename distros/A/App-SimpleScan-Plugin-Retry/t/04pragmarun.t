use Test::More;
use Test::Differences;

my $simple_scan = `which simple_scan`;
chomp $simple_scan;

my %test_pairs = (
  "retryonrun.in" => <<EOS,
1..2
not ok 1 - branding [http://cpan.org/] [/Python/ should match]
#   Failed test 'branding [http://cpan.org/] [/Python/ should match]'
#   in ... at line XX.
#          got: "<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Trans"...
#       length: ...
#     doesn't match '(?-xism:Python)'
ok 2 - branding [http://perl.org/] [/Perl/ should match]
# Looks like you failed 1 test of 2.
EOS
);

plan tests=>(int keys %test_pairs);

for my $test_input (keys %test_pairs) {
  my $cmd = qq(perl -Iblib/lib $simple_scan 2>&1 <t/$test_input);
  my $results = `$cmd`;

  $results =~ s/\n\n/\n/g;
  $results =~ s|in .*? at line|in ... at line|;
  $results =~ s|in ... at line \d+|in ... at line XX|;
  $results =~ s|length: \d+|length: ...|;

  eq_or_diff $results, $test_pairs{$test_input}, "expected output";
}
