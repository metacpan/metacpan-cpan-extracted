use Test::More tests=>4;
use Test::Differences;

my $have_cache_plugin;
my $no;

BEGIN {
  unless (eval "require App::SimpleScan::Plugin::Cache; 1") {
    $have_cache_plugin = "";
    $no = "no_cache";
  }
  else {
    $have_cache_plugin = "mech()->";
    $no = "nocache";
  }
}

$ENV{HARNESS_PERL_SWITCHES} = "" unless defined $ENV{HARNESS_PERL_SWITCHES};

my @output = `echo "%%cache" |$^X $ENV{HARNESS_PERL_SWITCHES} -Iblib/lib bin/simple_scan --gen`;
ok((scalar @output), "got output");
my $expected = <<EOS;
use Test::More tests=>0;
use Test::WWW::Simple;
use strict;

mech->agent_alias('Windows IE 6');
${have_cache_plugin}cache();

EOS
eq_or_diff(join("",@output), $expected, "output matches");

@output = `echo "%%nocache" |$^X $ENV{HARNESS_PERL_SWITCHES} -Iblib/lib bin/simple_scan --gen`;
ok((scalar @output), "got output");
$expected = <<EOS;
use Test::More tests=>0;
use Test::WWW::Simple;
use strict;

mech->agent_alias('Windows IE 6');
${have_cache_plugin}$no();

EOS
eq_or_diff(join("",@output), $expected, "output matches");


