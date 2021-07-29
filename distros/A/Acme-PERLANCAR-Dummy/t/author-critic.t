#!perl

BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    print qq{1..0 # SKIP these tests are for testing by the author\n};
    exit
  }
}


use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::Perl::Critic::Subset 3.001.005

use Test::Perl::Critic (-profile => "") x!! -e "";

my $filenames = ['lib/Acme/PERLANCAR/Dummy.pm','lib/Acme/PERLANCAR/Dummy/DistZilla/InsertCommandOutput.pm','lib/Acme/PERLANCAR/Dummy/MetaCPAN/HTML.pm','lib/Acme/PERLANCAR/Dummy/ModuleFeatures/Declarer1.pm','lib/Acme/PERLANCAR/Dummy/ModuleFeatures/Declarer2.pm','lib/Acme/PERLANCAR/Dummy/ModuleFeatures/Declarer_PythonTrove.pm','lib/Acme/PERLANCAR/Dummy/ModuleFeatures/Module1.pm','lib/Acme/PERLANCAR/Dummy/ModuleFeatures/Module1/_ModuleFeatures.pm','lib/Acme/PERLANCAR/Dummy/POD/LinkToSection.pm'];
unless ($filenames && @$filenames) {
    $filenames = -d "blib" ? ["blib"] : ["lib"];
}

all_critic_ok(@$filenames);
