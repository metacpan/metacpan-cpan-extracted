use Test::More tests=>6;
use Test::Differences;
$ENV{HARNESS_PERL_SWITCHES} = "" unless defined $ENV{HARNESS_PERL_SWITCHES};

my %commands = (
  "$^X $ENV{HARNESS_PERL_SWITCHES} -Iblib/lib bin/simple_scan --gen <examples/ss_over_defer.in" => <<EOS,
use Test::More tests=>1;
use Test::WWW::Simple;
use strict;

mech->agent_alias('Windows IE 6');
page_like "http://sample.org/bar",
          qr/quux/,
          qq(substitution test [http://sample.org/bar] [/quux/ should match]);

EOS

  "$^X $ENV{HARNESS_PERL_SWITCHES} -Iblib/lib bin/simple_scan --gen --define foo=boing <examples/ss_over_defer.in" => <<EOS,
use Test::More tests=>1;
use Test::WWW::Simple;
use strict;

mech->agent_alias('Windows IE 6');
page_like "http://sample.org/bar",
          qr/quux/,
          qq(substitution test [http://sample.org/bar] [/quux/ should match]);

EOS
  "$^X $ENV{HARNESS_PERL_SWITCHES} -Iblib/lib bin/simple_scan --gen --defer --define foo=boing <examples/ss_over_defer.in" => <<EOS,
use Test::More tests=>1;
use Test::WWW::Simple;
use strict;

mech->agent_alias('Windows IE 6');
page_like "http://sample.org/bar",
          qr/quux/,
          qq(substitution test [http://sample.org/bar] [/quux/ should match]);

EOS
  "$^X $ENV{HARNESS_PERL_SWITCHES} -Iblib/lib bin/simple_scan --gen --over --define foo=boing --define bar=thud<examples/ss_over_defer.in" => <<EOS,
use Test::More tests=>1;
use Test::WWW::Simple;
use strict;

mech->agent_alias('Windows IE 6');
page_like "http://sample.org/boing",
          qr/quux/,
          qq(substitution test [http://sample.org/boing] [/quux/ should match]);

EOS
  "$^X $ENV{HARNESS_PERL_SWITCHES} -Iblib/lib bin/simple_scan --gen --over --define foo=boing --define baz=splat<examples/ss_over_defer.in" => <<EOS,
use Test::More tests=>1;
use Test::WWW::Simple;
use strict;

mech->agent_alias('Windows IE 6');
page_like "http://sample.org/boing",
          qr/splat/,
          qq(substitution test [http://sample.org/boing] [/splat/ should match]);

EOS
  "$^X $ENV{HARNESS_PERL_SWITCHES} -Iblib/lib bin/simple_scan --debug --gen --over --define foo=boing --define baz=splat<examples/ss_over_defer.in" => <<EOS,
use Test::More tests=>1;
use Test::WWW::Simple;
use strict;

mech->agent_alias('Windows IE 6');
diag "Substitution foo not altered to 'bar'";
diag "Substitution baz not altered to 'quux'";
page_like "http://sample.org/boing",
          qr/splat/,
          qq(substitution test [http://sample.org/boing] [/splat/ should match]);

EOS
);

foreach my $cmd (keys %commands) {
  my @expected = map {"$_\n"} split /\n/, $commands{$cmd};
  push @expected, "\n";
  eq_or_diff([qx($cmd)], \@expected, "expected output");
}
