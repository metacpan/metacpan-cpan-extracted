#!/usr/bin/perl

use strict;
use warnings;
use Test::Most;

use App::Prove::Plugin::TraceUse;


cmp_deeply(
           App::Prove::Plugin::TraceUse::_parse_makefile_pl ,
           {
            'App::Prove' => '3.15',
            'Test::Perl::Critic'  => '1.02',
            'Test::Pod::Coverage' => '1.08',
            'Test::Most'          => '0.25',
            'Set::Object'         => '1.26',
            'Test::Pod'           => '1.45',
            'File::Slurp'         => '9999.19',
            'Tree::Simple'        => '1.18',
            'Devel::TraceUse'     => 0,
           }, "found own Makefile.pl and it parses"
          );

cmp_deeply(
           App::Prove::Plugin::TraceUse::_parse_makefile_pl("Makefile.PL") ,
           {
            'App::Prove' => '3.15',
            'Test::Perl::Critic'  => '1.02',
            'Test::Pod::Coverage' => '1.08',
            'Test::Most'          => '0.25',
            'Set::Object'         => '1.26',
            'Test::Pod'           => '1.45',
            'File::Slurp'         => '9999.19',
            'Tree::Simple'        => '1.18',
            'Devel::TraceUse'     => 0,
           }, "own Makefile.pl parses when pointed to"
          );

cmp_deeply(
           App::Prove::Plugin::TraceUse::_parse_makefile_pl("t/testdata/Makefile_with_bad_version.PL") ,
           {
            'App::Prove' => '3.15',
            'Test::Perl::Critic'  => '1.02',
            'Test::Pod::Coverage' => '1.08',
            'Test::Most'          => '0.25',
            'Set::Object'         => '1.26',
            'Test::Pod'           => '1.45',
            # 'File::Slurp'         => '9999.19', # These two modules now have bad version formats
            # 'Tree::Simple'        => '1.18', # and should not be found
           }, "bad versions removed"
          );


done_testing();
