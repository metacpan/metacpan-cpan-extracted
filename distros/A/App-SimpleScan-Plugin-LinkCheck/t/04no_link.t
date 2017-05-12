use Test::More;
use Test::Differences;
use File::Temp qw(tempfile);

$ENV{HARNESS_PERL_SWITCHES} = '' unless defined $ENV{HARNESS_PERL_SWITCHES};

sub build_input {
  my($fh, $filename) = tempfile();
  print $fh @_;
  close $fh;
  return $filename;
}

$simple_scan = `which simple_scan`;
if (!$simple_scan){
  plan skip_all => 'simple_scan unavailable';
}
else {
  plan tests =>6;
  chomp $simple_scan;
}

$delete_me = build_input(<<EOS);
%%no_link
http://cpan.org/ /CPAN/ Y Load page
EOS

@output = `$^X $ENV{HARNESS_PERL_SWITCHES} -Iblib/lib $simple_scan --gen < $delete_me`;
ok((scalar @output), "got output");

$expected = <<EOS;
use Test::More tests=>2;
use Test::WWW::Simple;
use strict;

mech->agent_alias('Windows IE 6');
fail "No arguments for %%no_link";
page_like "http://cpan.org/",
          qr/CPAN/,
          qq(Load page [http://cpan.org/] [/CPAN/ should match]);

EOS

eq_or_diff(join("",@output), $expected, "output matches");
unlink $delete_me;

###################################

$delete_me = build_input(<<EOS);
%%no_link Details
http://cpan.org/ /CPAN/ Y Load page
EOS

@output = `$^X $ENV{HARNESS_PERL_SWITCHES} -Iblib/lib $simple_scan --gen < $delete_me`;
ok((scalar @output), "got output");

$expected = <<EOS;
use Test::More tests=>2;
use Test::WWW::Simple;
use strict;

mech->agent_alias('Windows IE 6');
page_like "http://cpan.org/",
          qr/CPAN/,
          qq(Load page [http://cpan.org/] [/CPAN/ should match]);
cmp_ok scalar \@{[mech()->find_all_links(text=>qq(Details))]}, qq(==), qq(0), "'Details' link count == 0";

EOS

eq_or_diff(join("",@output), $expected, "output matches");
unlink $delete_me;

###################################

$delete_me = build_input(<<EOS);
%%no_link Details glorm splat
http://cpan.org/ /CPAN/ Y Load page
EOS

@output = `$^X $ENV{HARNESS_PERL_SWITCHES} -Iblib/lib $simple_scan --gen < $delete_me`;
ok((scalar @output), "got output");

$expected = <<EOS;
use Test::More tests=>2;
use Test::WWW::Simple;
use strict;

mech->agent_alias('Windows IE 6');
page_like "http://cpan.org/",
          qr/CPAN/,
          qq(Load page [http://cpan.org/] [/CPAN/ should match]);
cmp_ok scalar \@{[mech()->find_all_links(text=>qq(Details))]}, qq(==), qq(0), "'Details' link count == 0";

EOS

eq_or_diff(join("",@output), $expected, "output matches");
unlink $delete_me;
