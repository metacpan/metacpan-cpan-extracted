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
  plan tests =>12;
  chomp $simple_scan;
}

$delete_me = build_input(<<EOS);
%%has_link
http://cpan.org/ /CPAN/ Y CPAN is there
EOS

@output = `$^X $ENV{HARNESS_PERL_SWITCHES} -Iblib/lib $simple_scan --gen < $delete_me`;
ok((scalar @output), "got output");

$expected = <<EOS;
use Test::More tests=>2;
use Test::WWW::Simple;
use strict;

mech->agent_alias('Windows IE 6');
fail "No arguments for %%has_link";
page_like "http://cpan.org/",
          qr/CPAN/,
          qq(CPAN is there [http://cpan.org/] [/CPAN/ should match]);

EOS

eq_or_diff(join("",@output), $expected, "output matches");
unlink $delete_me;

#########################################

$delete_me = build_input(<<EOS);
%%has_link "CPAN sites"
http://cpan.org/ /CPAN/ Y CPAN is there
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
          qq(CPAN is there [http://cpan.org/] [/CPAN/ should match]);
cmp_ok scalar \@{[mech()->find_all_links(text=>qq(CPAN sites))]}, qq(>), qq(0), "'CPAN sites' link count > 0";

EOS

eq_or_diff(join("",@output), $expected, "output matches");
unlink $delete_me;

########################################

$delete_me = build_input(<<EOS);
%%has_link "CPAN sites" >
http://cpan.org/ /CPAN/ Y CPAN is there
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
          qq(CPAN is there [http://cpan.org/] [/CPAN/ should match]);
fail "Missing count";

EOS

eq_or_diff(join("",@output), $expected, "output matches");
unlink $delete_me;

########################################

$delete_me = build_input(<<EOS);
%%has_link "CPAN sites" glorm
http://cpan.org/ /CPAN/ Y CPAN is there
EOS

@output = `$^X $ENV{HARNESS_PERL_SWITCHES} -Iblib/lib $simple_scan --gen < $delete_me`;
ok((scalar @output), "got output");

$expected = <<EOS;
use Test::More tests=>3;
use Test::WWW::Simple;
use strict;

mech->agent_alias('Windows IE 6');
page_like "http://cpan.org/",
          qr/CPAN/,
          qq(CPAN is there [http://cpan.org/] [/CPAN/ should match]);
fail "glorm is not a legal comparison operator (use < > <= >= == !=)";
fail "Missing count";

EOS

eq_or_diff(join("",@output), $expected, "output matches");
unlink $delete_me;

########################################

$delete_me = build_input(<<EOS);
%%has_link "CPAN sites" glorm splat
http://cpan.org/ /CPAN/ Y CPAN is there
EOS

@output = `$^X $ENV{HARNESS_PERL_SWITCHES} -Iblib/lib $simple_scan --gen < $delete_me`;
ok((scalar @output), "got output");

$expected = <<EOS;
use Test::More tests=>3;
use Test::WWW::Simple;
use strict;

mech->agent_alias('Windows IE 6');
page_like "http://cpan.org/",
          qr/CPAN/,
          qq(CPAN is there [http://cpan.org/] [/CPAN/ should match]);
fail "glorm is not a legal comparison operator (use < > <= >= == !=)";
fail "splat doesn't look like a legal number to me";

EOS

eq_or_diff(join("",@output), $expected, "output matches");
unlink $delete_me;

########################################

$delete_me = build_input(<<EOS);
%%has_link "CPAN sites" > 1
http://cpan.org/ /CPAN/ Y CPAN is there
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
          qq(CPAN is there [http://cpan.org/] [/CPAN/ should match]);
cmp_ok scalar \@{[mech()->find_all_links(text=>qq(CPAN sites))]}, qq(>), qq(1), "'CPAN sites' link count > 1";

EOS
eq_or_diff(join("",@output), $expected, "output matches");
unlink $delete_me;

exit 0;

($fh, $filename) = tempfile;
print $fh <<CMDS;
http://cpan.org /CPAN/ Y Got the site
%%has_link 'CPAN sites' == 2
%%no_link 'Python'
CMDS
close $fh;

@output = `$^X $ENV{HARNESS_PERL_SWITCHES} -Iblib/lib $simple_scan <$filename`;
$expected = <<EOS;
1..3
ok 1 - Got the site [http://cpan.org] [/CPAN/ should match]
ok 2 - 'CPAN sites' link count == 2
ok 3 - 'Python' link count == 0
EOS
eq_or_diff(join("",@output), $expected, "output matches");
