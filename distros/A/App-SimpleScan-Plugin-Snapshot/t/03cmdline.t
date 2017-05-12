use Test::More;
use Test::Differences;

my $simple_scan = `which simple_scan`;
chomp $simple_scan;

my %test_pairs = (
  "-snap_dir /tmp" => <<EOS,
use Test::More tests=>1;
use Test::WWW::Simple;
use strict;

my \@accent;
mech->snapshots_to("/tmp");
mech->agent_alias('Windows IE 6');
page_like "http://perl.org/",
          qr/Perl/,
          qq(branding [http://perl.org/] [/Perl/ should match]);

EOS
  "--snap_dir /nonexistent" => <<EOS,
use Test::More tests=>1;
use Test::WWW::Simple;
use strict;

my \@accent;
mech->snapshots_to("/nonexistent");
mech->agent_alias('Windows IE 6');
page_like "http://perl.org/",
          qr/Perl/,
          qq(branding [http://perl.org/] [/Perl/ should match]);

EOS
);

plan tests=>(int keys %test_pairs);

for my $test_input (keys %test_pairs) {
  my $cmd = qq(perl -Iblib/lib $simple_scan --gen $test_input <t/neither.in);
  my $results = `$cmd`;
  eq_or_diff $results, $test_pairs{$test_input}, "expected output";
}
