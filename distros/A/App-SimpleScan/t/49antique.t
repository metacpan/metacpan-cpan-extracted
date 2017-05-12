use Test::More tests=>1;
use Test::Differences;
$ENV{HARNESS_PERL_SWITCHES} = "" unless defined $ENV{HARNESS_PERL_SWITCHES};

@output = `echo "http://>server</ /not run/ Y Old brackets"| $^X $ENV{HARNESS_PERL_SWITCHES} -Iblib/lib bin/simple_scan -gen -define server=zorch`;
@expected = (map {"$_\n"} (split /\n/,<<EOS));
use Test::More tests=>1;
use Test::WWW::Simple;
use strict;

mech->agent_alias('Windows IE 6');
page_like "http://zorch/",
          qr/not run/,
          qq(Old brackets [http://zorch/] [/not run/ should match]);
EOS
push @expected,"\n";
eq_or_diff [@output], [@expected], "got expected output";
