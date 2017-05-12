#!perl
use warnings;
use strict;

use inc::Module::Install;

name            q{CatalystX-Imports};
license         q{perl};
author          q{Robert "phaylon" Sedlacek <rs@474.at>};
all_from        q{lib/CatalystX/Imports.pm};

requires        q{Carp::Clan},                  0;
requires        q{Filter::EOF},                 '0.02';
requires        q{Class::MOP},                  0;
requires        q{List::MoreUtils},             '0.19';
requires        q{Scalar::Util},                '1.19';
requires        q{Catalyst::Runtime},           '5.80002';
requires        q{Data::Alias},                 '0.08';
requires        q{Class::C3},                   '0.20';
requires        q{Sub::Name},                   '0.04';

test_requires   q{Test::More},                                  '0.62';
test_requires   q{FindBin},                                     0;
test_requires   q{Catalyst::Test},                              0;
test_requires   q{Test::WWW::Mechanize::Catalyst},              0;
test_requires   q{HTTP::Request},                               0;
test_requires   q{Catalyst::Plugin::Session},                   0;
test_requires   q{Catalyst::Plugin::Session::State::Cookie},    0;
test_requires   q{Catalyst::Plugin::Session::Store::FastMmap},  0;

auto_provides;
WriteAll;

package MY;

sub postamble {
    my $make_test = q{PERL_DL_NONLAZY=1 $(FULLPERLRUN) "-MExtUtils::Command::MM" "-e" "test_harness($(TEST_VERBOSE), 'inc', '$(INST_LIB)', '$(INST_ARCHLIB)')" $(TEST_FILES)};

    return <<"EOM"
testcover: pm_to_blib
\t-HARNESS_PERL_SWITCHES=-MDevel::Cover $make_test
\tcover
EOM
}
