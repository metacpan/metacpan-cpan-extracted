#!/usr/bin/perl

use strict;
use warnings;
use Test::Most;

use App::Prove::Plugin::TraceUse;

my @present_modules = qw
    /
        App::Prove
        Test::Perl::Critic
        Test::Pod::Coverage
        Test::Most
        Set::Object
        Test::Pod
        File::Slurp
        Tree::Simple
    /;

my @not_present_modules =
  qw/
        CGI
        Moose
        LWP::UserAgent
    /;

plan tests => $#present_modules +
  $#not_present_modules +
  2;

for (@present_modules) {
    ok( App::Prove::Plugin::TraceUse::_check_makefile_pl_for_module($_), "$_ found in Makefile.PL" );
}

for (@not_present_modules) {
    ok( !App::Prove::Plugin::TraceUse::_check_makefile_pl_for_module($_), "$_ not found in Makefile.PL" );
}

done_testing();
