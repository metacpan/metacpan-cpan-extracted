use Test::More;
use Test::Differences;

my $simple_scan = `which simple_scan`;
chomp $simple_scan;

system "rm -rf t/run_*" unless $ENV{DEBUG};

my %counts = (
  'snaponrun_leader.in' => 2,
  'snaperrorrun_leader.in' => 1,
);

my %test_pairs = (
  "snaponrun_leader.in" => <<EOS,
1..2
not ok 1 - branding [http://cpan.org/] [/Python/ should match]
#   Failed test 'branding [http://cpan.org/] [/Python/ should match]'
#   in ... at line XX.
#          got: "<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Trans"...
#       length: ...
#     doesn't match '(?-xism:Python)'
# See snapshot http://somewhere.com/run_xxx-xxx-xx-xx-xx-xx-xxxx/frame_xxx-xxx-xx-xx-xx-xx-xxxx-x.html
ok 2 - branding [http://perl.org/] [/Perl/ should match]
# See snapshot http://somewhere.com/run_xxx-xxx-xx-xx-xx-xx-xxxx/frame_xxx-xxx-xx-xx-xx-xx-xxxx-x.html
# Looks like you failed 1 test of 2.
EOS
  "snaperrorrun_leader.in" => <<EOS,
1..2
ok 1 - branding [http://perl.org/] [/Perl/ should match]
not ok 2 - branding [http://perl.org/] [/Python/ should match]
#   Failed test 'branding [http://perl.org/] [/Python/ should match]'
#   in ... at line XX.
#          got: "\\x{0a}<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Tran"...
#       length: ...
#     doesn't match '(?-xism:Python)'
# See snapshot http://somewhere.com/run_xxx-xxx-xx-xx-xx-xx-xxxx/frame_xxx-xxx-xx-xx-xx-xx-xxxx-x.html
# Looks like you failed 1 test of 2.
EOS
);

my %test_pairs_2 = (
  "-snap_dir t -snap_prefix 'http://someplace.com'" => <<EOS,
1..1
ok 1 - branding [http://perl.org/] [/Perl/ should match]
# See snapshot http://someplace.com/run_xxx-xxx-xx-xx-xx-xx-xxxx/frame_xxx-xxx-xx-xx-xx-xx-xxxx-x.html
EOS
  "--snap_dir /nonexistent -snap_prefix 'http://someplace.com'" => <<EOS,
1..1
Couldn't create directory /nonexistent/run_xxx-xxx-xx-xx-xx-xx-xxxx: mkdir /nonexistent: Permission denied at ...
EOS
  "-snap_dir t -snap_prefix 'http://someplace.com/'" => <<EOS,
1..1
ok 1 - branding [http://perl.org/] [/Perl/ should match]
# See snapshot http://someplace.com/run_xxx-xxx-xx-xx-xx-xx-xxxx/frame_xxx-xxx-xx-xx-xx-xx-xxxx-x.html
EOS
  "--snap_dir /nonexistent -snap_prefix 'http://someplace.com/'" => <<EOS,
1..1
Couldn't create directory /nonexistent/run_xxx-xxx-xx-xx-xx-xx-xxxx: mkdir /nonexistent: Permission denied at ...
EOS
);

plan tests=>(int keys %test_pairs) + (int keys %test_pairs_2);

for my $test_input (keys %test_pairs) {
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
  }
  system "rm -rf t/run_*" unless $ENV{DEBUG};
}

for my $test_input (keys %test_pairs_2) {
  my $cmd = qq(perl -Iblib/lib $simple_scan $test_input 2>&1 <t/testsnap.in);
  my $results = `$cmd`;
  $results =~ s/run_...-...-..-..-..-..-....:/run_xxx-xxx-xx-xx-xx-xx-xxxx:/ms;
  $results =~ s/(Permission denied at).*$/$1 ...\n/ms;
  $results =~ s|(run_).*?(/frame_).*?(.html)|${1}xxx-xxx-xx-xx-xx-xx-xxxx${2}xxx-xxx-xx-xx-xx-xx-xxxx-x${3}|gsm;
  eq_or_diff $results, $test_pairs_2{$test_input}, "expected output";
  if ($test_input eq "-snap_dir t") {
    for my $which (qw(content debug frame)) {
      my @file = glob("t/run*/${which}*.html");
      ok -e $file[0], "$which file exists";
      ok -s $file[0], "$which file has content";
    }
  }
  system "rm -rf t/run_*" unless $ENV{DEBUG};
}
