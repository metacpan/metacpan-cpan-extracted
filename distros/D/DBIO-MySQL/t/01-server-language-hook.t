use strict;
use warnings;
use Test::More;

# WHY IT MATTERS. DBIO_TEST_SERVER_LANGUAGE puts the live suite's server
# sessions into German or French, to find a test that reads an English server
# text. The switch works through a module that the harness loads into every test
# process (.proverc, which only `prove` reads). A run that goes another way --
# `make test`, `dzil test`, `perl t/x.t` -- loads nothing, the sessions stay
# English, and the run would report green without having tested the language.
# All test processes of a run are started the same way, so this one tells for
# the others: with the switch set and the module not loaded, the run is red.
# The module is deliberately not loaded here.

plan skip_all => 'DBIO_TEST_SERVER_LANGUAGE is not set'
  unless defined $ENV{DBIO_TEST_SERVER_LANGUAGE} && length $ENV{DBIO_TEST_SERVER_LANGUAGE};

my $language = $ENV{DBIO_TEST_SERVER_LANGUAGE};

ok $INC{'DBIOMySQLTestLanguage.pm'},
  "DBIO_TEST_SERVER_LANGUAGE=$language: the harness loaded the language hook into this test process"
  or diag <<"HINT";
DBIO_TEST_SERVER_LANGUAGE is set, but the language hook is not loaded: the server
sessions of this run stay English. Run the suite through prove from the root of
the distribution, which reads .proverc:

  DBIO_TEST_SERVER_LANGUAGE=$language prove -lr t/

For a single file without prove:

  DBIO_TEST_SERVER_LANGUAGE=$language perl -Ilib -It/lib -MDBIOMySQLTestLanguage t/<file>.t
HINT

no warnings "once";
is $DBIOMySQLTestLanguage::ACTIVE, ({ de => 'de_DE', fr => 'fr_FR' }->{$language}),
  '... and it is active in this language'
  if $INC{'DBIOMySQLTestLanguage.pm'};

done_testing;
