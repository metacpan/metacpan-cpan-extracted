use Test::More;
use Test::Differences;

my $simple_scan = `which simple_scan`;
chomp $simple_scan;

system "rm -rf t/run_*" unless $ENV{DEBUG};

my %test_pairs = (
  "-retry 0" => <<EOS,
1..1
ok 1 - branding [http://perl.org/] [/Perl/ should match]
EOS
  "-retry 3" => <<EOS,
1..1
ok 1 - branding [http://perl.org/] [/Perl/ should match]
EOS
);

plan tests=>(int keys %test_pairs);

for my $test_input (keys %test_pairs) {
  my $cmd = qq(perl -Iblib/lib $simple_scan $test_input 2>&1 <t/testretry.in);
  my $results = `$cmd`;
  eq_or_diff $results, $test_pairs{$test_input}, "expected output";
}
