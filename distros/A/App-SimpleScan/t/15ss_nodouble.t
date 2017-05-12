use Test::More tests=>2;
use Test::Differences;

$ENV{HARNESS_PERL_SWITCHES} = "" unless defined $ENV{HARNESS_PERL_SWITCHES};

@output = `$^X $ENV{HARNESS_PERL_SWITCHES} -Iblib/lib bin/simple_scan --gen <examples/ss_multisub.in`;
@expected = map {"$_\n"} split /\n/,<<EOF;
use Test::More tests=>4;
use Test::WWW::Simple;
use strict;

mech->agent_alias('Windows IE 6');
page_like "http://uk.staging.search.blork.com?zorch",
          qr/(?:Success)/,
          qq(uk. results [http://uk.staging.search.blork.com?zorch] [/(?:Success)/ should match]);
page_like "http://ca.staging.search.blork.com?zorch",
          qr/(?:Success)/,
          qq(ca. results [http://ca.staging.search.blork.com?zorch] [/(?:Success)/ should match]);
page_like "http://au.staging.search.blork.com?zorch",
          qr/(?:Success)/,
          qq(au. results [http://au.staging.search.blork.com?zorch] [/(?:Success)/ should match]);
page_like "http://in.staging.search.blork.com?zorch",
          qr/(?:Success)/,
          qq(in. results [http://in.staging.search.blork.com?zorch] [/(?:Success)/ should match]);

EOF
push @expected, "\n";
eq_or_diff(\@output, \@expected, "working output as expected");

my @output = `$^X $ENV{HARNESS_PERL_SWITCHES} -Iblib/lib bin/simple_scan --gen <examples/ss_nodouble.in`;
@expected = map {"$_\n"} split /\n/,<<EOF;
use Test::More tests=>5;
use Test::WWW::Simple;
use strict;

mech->agent_alias('Windows IE 6');
page_like "http://au.yahoo.com/",
          qr/yahoo/,
          qq(Yahoo should be there (au) [http://au.yahoo.com/] [/yahoo/ should match]);
page_like "http://es.yahoo.com/",
          qr/yahoo/,
          qq(Yahoo should be there (es) [http://es.yahoo.com/] [/yahoo/ should match]);
page_like "http://de.yahoo.com/",
          qr/yahoo/,
          qq(Yahoo should be there (de) [http://de.yahoo.com/] [/yahoo/ should match]);
page_like "http://asia.yahoo.com/",
          qr/yahoo/,
          qq(Yahoo should be there (asia) [http://asia.yahoo.com/] [/yahoo/ should match]);
page_like "http://search.yahoo.com",
          qr/yahoo/,
          qq(Yahoo should be there [http://search.yahoo.com] [/yahoo/ should match]);
EOF
push @expected, "\n";
eq_or_diff(\@output, \@expected, "working output as expected");
