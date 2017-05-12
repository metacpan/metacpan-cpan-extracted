use Test::More;
use Test::Differences;

my $simple_scan = `which simple_scan`;
chomp $simple_scan;

system "rm -rf t/run_*" unless $ENV{DEBUG};

my %counts = (
  'snaponrun.in' => 2,
  'snaperrorrun.in' => 1,
);

my %test_pairs = (
  "snaponrun.in" => <<EOS,
1..2
not ok 1 - branding [http://cpan.org/] [/Python/ should match]
#   Failed test 'branding [http://cpan.org/] [/Python/ should match]'
#   in ... at line XX.
#          got: "<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Trans"...
#       length: ...
#     doesn't match '(?-xism:Python)'
# See snapshot t/run_xxx-xxx-xx-xx-xx-xx-xxxx/frame_xxx-xxx-xx-xx-xx-xx-xxxx-x.html
ok 2 - branding [http://perl.org/] [/Perl/ should match]
# See snapshot t/run_xxx-xxx-xx-xx-xx-xx-xxxx/frame_xxx-xxx-xx-xx-xx-xx-xxxx-x.html
# Looks like you failed 1 test of 2.
EOS
  "snaperrorrun.in" => <<EOS,
1..2
ok 1 - branding [http://perl.org/] [/Perl/ should match]
not ok 2 - branding [http://perl.org/] [/Python/ should match]
#   Failed test 'branding [http://perl.org/] [/Python/ should match]'
#   in ... at line XX.
#          got: "\\x{0a}<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Tran"...
#       length: ...
#     doesn't match '(?-xism:Python)'
# See snapshot t/run_xxx-xxx-xx-xx-xx-xx-xxxx/frame_xxx-xxx-xx-xx-xx-xx-xxxx-x.html
# Looks like you failed 1 test of 2.
EOS
);

plan tests=>(int keys %test_pairs)+(3*int keys %counts);

for my $test_input (keys %test_pairs) {
  system "rm -rf t/run_*" unless $ENV{DEBUG};
  my $cmd = qq(perl -Iblib/lib $simple_scan 2>&1 <t/$test_input);
  my $results = `$cmd`;

  $results =~ s/\n\n/\n/g;
  $results =~ s|in .*? at line|in ... at line|;
  $results =~ s|in ... at line \d+|in ... at line XX|;
  $results =~ s|length: \d+|length: ...|;
  $results =~ s|(run_).*?(/frame_).*?(.html)|${1}xxx-xxx-xx-xx-xx-xx-xxxx${2}xxx-xxx-xx-xx-xx-xx-xxxx-x${3}|gsm;

  eq_or_diff $results, $test_pairs{$test_input}, "expected output";

  for my $which (qw(debug frame content)) {
    my @files = glob("t/run_*/$which*.html");
    unless (is int(@files), $counts{$test_input}, "proper number of $which files for $test_input") {
      diag "@files";
    }
  }
  system "rm -rf t/run_*" unless $ENV{DEBUG};
}
