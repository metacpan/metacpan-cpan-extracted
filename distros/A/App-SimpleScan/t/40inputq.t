use Test::More tests=>7;
use Test::Differences;

BEGIN {
  use_ok qw(App::SimpleScan);
  use_ok qw(App::SimpleScan::TestSpec);
  push @INC, "t";
}

my $ss = new App::SimpleScan;
ok $ss->can('plugins'), "plugins method available";
isa_ok [$ss->plugins()],"ARRAY", "plugin list";
is  1, ( grep { /TestNextLine/ } $ss->plugins() ), "test plugin there";

ok scalar @{ $ss->next_line_callbacks }, "plugin installed callback";

$ENV{HARNESS_PERL_SWITCHES} = "" unless defined $ENV{HARNESS_PERL_SWITCHES};

@output = `$^X $ENV{HARNESS_PERL_SWITCHES} -Mlib='t' -Iblib/lib bin/simple_scan -gen -test_nextline <examples/ss_escaped.in 2>&1`;
@expected = map {"$_\n"} split /\n/,<<EOF;
use Test::More tests=>1;
use Test::WWW::Simple;
use strict;

use Test::Demo;
mech->agent_alias('Windows IE 6');
# next line plugin called 1 time
page_like "http://yahoo.com",
          qr/\\d+/,
          qq(digits [http://yahoo.com] [/\\\\d+/ should match]);
# next line plugin called 2 times
EOF
push @expected,"\n";

eq_or_diff(\@output, \@expected, "working output as expected");
