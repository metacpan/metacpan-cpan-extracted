#!/usr/bin/perl

use strict;
use warnings;
use Test::Most;

use App::Prove::Plugin::TraceUse;


cmp_deeply(
           App::Prove::Plugin::TraceUse::_parse_build_pl ,
           {
            'Test::More' => 0,
            'version'    => 0,
            'App::Prove' => '3.15',
            'Test::Perl::Critic'  => '1.02',
            'Test::Pod::Coverage' => '1.08',
            'Test::Most'          => '0.25',
            'Set::Object'         => '1.26',
            'Test::Pod'           => '1.45',
            'File::Slurp'         => '9999.19',
            'Tree::Simple'        => '1.18',
            'Devel::TraceUse'     => 0,
           }
           , "found own Build.pl and it parses"
          );

cmp_deeply(
           App::Prove::Plugin::TraceUse::_parse_build_pl("Build.PL") ,
           {
            'Test::More' => 0,
            'version'    => 0,
            'App::Prove' => '3.15',
            'Test::Perl::Critic'  => '1.02',
            'Test::Pod::Coverage' => '1.08',
            'Test::Most'          => '0.25',
            'Set::Object'         => '1.26',
            'Test::Pod'           => '1.45',
            'File::Slurp'         => '9999.19',
            'Tree::Simple'        => '1.18',
            'Devel::TraceUse'     => 0,
           }
           , "own Build.pl parses when pointed to"
          );

cmp_deeply(
           App::Prove::Plugin::TraceUse::_parse_build_pl("t/testdata/Build_with_bad_version.PL") ,
           {
            'Test::More' => 0,
            'version'    => 0,
            'App::Prove' => '3.15',
            'Test::Perl::Critic'  => '1.02',
            'Test::Pod::Coverage' => '1.08',
            'Test::Most'          => '0.25',
            'Set::Object'         => '1.26',
            'Test::Pod'           => '1.45',
#            'File::Slurp'         => '9999.19', # These two modules have bad version strings
#            'Tree::Simple'        => '1.18', # in test file
           }, "bad versions removed"
          );


done_testing();
