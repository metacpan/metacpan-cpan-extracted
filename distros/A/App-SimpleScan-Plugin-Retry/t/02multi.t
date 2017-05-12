use Test::More;
use Test::Differences;

my $simple_scan = `which simple_scan`;
chomp $simple_scan;

my %test_pairs = (
  "multi.in" => <<EOS,
use Test::More tests=>1;
use Test::WWW::Simple;
use strict;

mech->agent_alias('Windows IE 6');
mech->retry("5");
page_like "http://perl.org/",
          qr/Perl/,
          qq(branding [http://perl.org/] [/Perl/ should match]);
mech->retry("3");

EOS
);

plan tests=>(int keys %test_pairs);

for my $test_input (keys %test_pairs) {
  my $cmd = qq(perl -Iblib/lib $simple_scan --gen<t/$test_input);
  my $results = `$cmd`;
  eq_or_diff $results, $test_pairs{$test_input}, "expected output";
}
