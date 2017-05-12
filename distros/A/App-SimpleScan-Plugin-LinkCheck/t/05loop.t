use Test::More;
use Test::Differences;
use File::Temp qw(tempfile);

$ENV{HARNESS_PERL_SWITCHES} = '' unless defined $ENV{HARNESS_PERL_SWITCHES};

$simple_scan = `which simple_scan`;
if (!$simple_scan){
  plan skip_all => 'simple_scan unavailable';
}
else {
  plan tests =>1;
  chomp $simple_scan;
}

($fh, $filename) = tempfile;
print $fh <<CMDS;
%%site python ruby cpan
%%has_link 'CPAN sites' == 2
%%no_link 'Python'
http://<site>.org /CPAN/ TY Got the <site> site
CMDS
close $fh;

@output = `$^X $ENV{HARNESS_PERL_SWITCHES} -Iblib/lib $simple_scan 2>/dev/null <$filename`;
$expected = <<EOS;
1..9
ok 1 - Got the cpan site [http://cpan.org] [/CPAN/ should match] # TODO Doesn't match now but should later
ok 2 - 'Python' link count == 0
ok 3 - 'CPAN sites' link count == 2
not ok 4 - Got the python site [http://python.org] [/CPAN/ should match] # TODO Doesn't match now but should later
ok 5 - 'Python' link count == 0
not ok 6 - 'CPAN sites' link count == 2
not ok 7 - Got the ruby site [http://ruby.org] [/CPAN/ should match] # TODO Doesn't match now but should later
ok 8 - 'Python' link count == 0
not ok 9 - 'CPAN sites' link count == 2
EOS
eq_or_diff(join("",@output), $expected, "output matches");
unlink $filename;
