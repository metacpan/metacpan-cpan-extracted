use Test::More tests=>1;
use Test::Differences;
my $input;
my $expected = <<EOS;
use Test::More tests=>6;
use Test::WWW::Simple;
use strict;

mech->agent_alias('Windows IE 6');
page_like "http://sample.org/bar",
          qr/freen/,
          qq(Should substitute both [http://sample.org/bar] [/freen/ should match]);
page_like "http://sample.org/bar",
          qr/glonk/,
          qq(Should substitute both [http://sample.org/bar] [/glonk/ should match]);
page_like "http://sample.org/baz",
          qr/freen/,
          qq(Should substitute both [http://sample.org/baz] [/freen/ should match]);
page_like "http://sample.org/baz",
          qr/glonk/,
          qq(Should substitute both [http://sample.org/baz] [/glonk/ should match]);
page_like "http://sample.org/<foo>",
          qr/freen/,
          qq(zorch but not foo [http://sample.org/<foo>] [/freen/ should match]);
page_like "http://sample.org/<foo>",
          qr/glonk/,
          qq(zorch but not foo [http://sample.org/<foo>] [/glonk/ should match]);

EOS
my @expected = map {"$_\n"} (split /\n/, $expected);
push @expected, "\n";

eval "use App::SimpleScan::Plugin::Vars";
if ($@) {
  # No "vars" support installed
  $input = "examples/forget2.in";
}
else {
  # No "vars" support installed
  $input = "examples/forget1.in";
}

$ENV{PERL5LIB} = "blib/lib";
@output = `simple_scan --gen <$input`;

eq_or_diff \@output, \@expected, "expected output";
