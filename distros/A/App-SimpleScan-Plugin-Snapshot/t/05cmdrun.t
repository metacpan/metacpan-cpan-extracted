use Test::More;
use Test::Differences;

my $simple_scan = `which simple_scan`;
chomp $simple_scan;

system "rm -rf t/run_*" unless $ENV{DEBUG};

my %test_pairs = (
  "-snap_dir t" => <<EOS,
1..1
ok 1 - branding [http://perl.org/] [/Perl/ should match]
# See snapshot t/run_xxx-xxx-xx-xx-xx-xx-xxxx/frame_xxx-xxx-xx-xx-xx-xx-xxxx-x.html
EOS
  "--snap_dir /nonexistent" => <<EOS,
1..1
Couldn't create directory /nonexistent/run_xxx-xxx-xx-xx-xx-xx-xxxx: mkdir /nonexistent: Permission denied at ...
EOS
);

plan tests=>(int keys %test_pairs) + 6;

for my $test_input (keys %test_pairs) {
  my $cmd = qq(perl -Iblib/lib $simple_scan $test_input 2>&1 <t/testsnap.in);
  my $results = `$cmd`;
  $results =~ s/run_...-...-..-..-..-..-....:/run_xxx-xxx-xx-xx-xx-xx-xxxx:/ms;
  $results =~ s/(Permission denied at).*$/$1 ...\n/ms;
  $results =~ s|(run_).*?(/frame_).*?(.html)|${1}xxx-xxx-xx-xx-xx-xx-xxxx${2}xxx-xxx-xx-xx-xx-xx-xxxx-x${3}|gsm;
  eq_or_diff $results, $test_pairs{$test_input}, "expected output";
  if ($test_input eq "-snap_dir t") {
    for my $which (qw(content debug frame)) {
      my @file = glob("t/run*/${which}*.html");
      ok -e $file[0], "$which file exists";
      ok -s $file[0], "$which file has content";
    }
  }
}
system "rm -rf t/run_*" unless $ENV{DEBUG};
