use Test::More;
use Test::Differences;
use File::Temp qw(tempfile);
eval "use App::SimpleScan::Plugin::Snapshot";
if ($@) {
  plan skip_all => 'No snapshot plugin installed';
}

$ENV{HARNESS_PERL_SWITCHES} = '' unless defined $ENV{HARNESS_PERL_SWITCHES};

$simple_scan = `which simple_scan`;
if (!$simple_scan){
  plan skip_all => 'simple_scan unavailable';
}
else {
  plan tests =>4;
  chomp $simple_scan;
}

sub build_input {
  my($fh, $filename) = tempfile();
  print $fh @_;
  close $fh;
  return $filename;
}

#########################################

$delete_me = build_input(<<EOS);
%%has_link "CPAN sites"
http://cpan.org/ /CPAN/ Y CPAN is there
EOS

@output = `$^X $ENV{HARNESS_PERL_SWITCHES} -Iblib/lib $simple_scan --snapshot error --gen < $delete_me`;
ok((scalar @output), "got output");

$expected = <<EOS;
use Test::More tests=>2;
use Test::WWW::Simple;
use strict;

mech->agent_alias('Windows IE 6');
page_like "http://cpan.org/",
          qr/CPAN/,
          qq(CPAN is there [http://cpan.org/] [/CPAN/ should match]);
if (!last_test->{ok}) {
  diag "See snapshot " . mech->snapshot( qq(CPAN is there<br>http://cpan.org/<br>CPAN Y) );
}
cmp_ok scalar \@{[mech()->find_all_links(text=>qq(CPAN sites))]}, qq(>), qq(0), "'CPAN sites' link count > 0";
if (!last_test->{ok}) {
  diag "See snapshot " . mech->snapshot( qq('CPAN sites' link count > 0<br>http://cpan.org/<br>CPAN Y) );
}

EOS

eq_or_diff(join("",@output), $expected, "output matches");
unlink $delete_me;

########################################

$delete_me = build_input(<<EOS);
%%has_link "CPAN sites" > 1
http://cpan.org/ /CPAN/ Y CPAN is there
EOS

@output = `$^X $ENV{HARNESS_PERL_SWITCHES} -Iblib/lib $simple_scan --snapshot error --gen < $delete_me`;
ok((scalar @output), "got output");

$expected = <<EOS;
use Test::More tests=>2;
use Test::WWW::Simple;
use strict;

mech->agent_alias('Windows IE 6');
page_like "http://cpan.org/",
          qr/CPAN/,
          qq(CPAN is there [http://cpan.org/] [/CPAN/ should match]);
if (!last_test->{ok}) {
  diag "See snapshot " . mech->snapshot( qq(CPAN is there<br>http://cpan.org/<br>CPAN Y) );
}
cmp_ok scalar \@{[mech()->find_all_links(text=>qq(CPAN sites))]}, qq(>), qq(1), "'CPAN sites' link count > 1";
if (!last_test->{ok}) {
  diag "See snapshot " . mech->snapshot( qq('CPAN sites' link count > 1<br>http://cpan.org/<br>CPAN Y) );
}

EOS
eq_or_diff(join("",@output), $expected, "output matches");
unlink $delete_me;

exit 0;
