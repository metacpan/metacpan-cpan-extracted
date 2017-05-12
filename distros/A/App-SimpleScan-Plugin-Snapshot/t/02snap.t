use Test::More;
use Test::Differences;

my $simple_scan = `which simple_scan`;
chomp $simple_scan;

my %test_pairs = (
  "snapon.in" => <<EOS,
use Test::More tests=>1;
use Test::WWW::Simple;
use strict;

my \@accent;
mech->agent_alias('Windows IE 6');
page_like "http://perl.org/",
          qr/Perl/,
          qq(branding [http://perl.org/] [/Perl/ should match]);
diag "See snapshot " . mech->snapshot( qq(branding<br>http://perl.org/<br>Perl Y) );

EOS
  "snaperror.in" => <<EOS,
use Test::More tests=>1;
use Test::WWW::Simple;
use strict;

my \@accent;
mech->agent_alias('Windows IE 6');
page_like "http://perl.org/",
          qr/Perl/,
          qq(branding [http://perl.org/] [/Perl/ should match]);
if (!last_test->{ok}) {
  diag "See snapshot " . mech->snapshot( qq(branding<br>http://perl.org/<br>Perl Y) );
}

EOS
);

plan tests=>(int keys %test_pairs);

for my $test_input (keys %test_pairs) {
  my $cmd = qq(perl -Iblib/lib $simple_scan --gen<t/$test_input);
  my $results = `$cmd`;
  eq_or_diff $results, $test_pairs{$test_input}, "expected output";
}
