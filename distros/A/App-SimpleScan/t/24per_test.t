#!/usr/local/bin/perl
use Test::More tests=>2;
use Test::Differences;

$ENV{HARNESS_PERL_SWITCHES} = "" unless defined $ENV{HARNESS_PERL_SWITCHES};

@output = `$^X -It bin/simple_scan --gen <examples/ss_country.in`;
@expected = map {"$_\n"} split /\n/,<<EOF;
use Test::More tests=>4;
use Test::WWW::Simple;
use strict;

use Test::Demo;
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

EOF
push @expected, "\n";
eq_or_diff(\@output, \@expected, "uninserted output as expected");

@output = `$^X -It bin/simple_scan --test_expand --gen <examples/ss_country.in`;
@expected = map {"$_\n"} split /\n/,<<EOF;
use Test::More tests=>4;
use Test::WWW::Simple;
use strict;

use Test::Demo;
# Adding test expansion comment
mech->agent_alias('Windows IE 6');
page_like "http://au.yahoo.com/",
          qr/yahoo/,
          qq(Yahoo should be there (au) [http://au.yahoo.com/] [/yahoo/ should match]);
# per-test comment
page_like "http://es.yahoo.com/",
          qr/yahoo/,
          qq(Yahoo should be there (es) [http://es.yahoo.com/] [/yahoo/ should match]);
# per-test comment
page_like "http://de.yahoo.com/",
          qr/yahoo/,
          qq(Yahoo should be there (de) [http://de.yahoo.com/] [/yahoo/ should match]);
# per-test comment
page_like "http://asia.yahoo.com/",
          qr/yahoo/,
          qq(Yahoo should be there (asia) [http://asia.yahoo.com/] [/yahoo/ should match]);
# per-test comment

EOF
push @expected, "\n";
eq_or_diff(\@output, \@expected, "inserted output as expected");

