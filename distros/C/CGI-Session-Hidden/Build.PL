#!/usr/bin/perl -w

use strict;

use Module::Build;

my $build_pkg = eval { require Apache::TestMB } ?
                    'Apache::TestMB' : 'Module::Build';

my $build = $build_pkg->new
  ( module_name => 'CGI::Session::Hidden',
    license => 'perl',
    dist_author        => 'Mattia Barbon <mbarbon@cpan.org>',
    requires => { 'perl'           => '5.6.0',
                  'CGI::Session'   => '1.23',
                  'Module::Build'  => '0.2607',
                  'Test::More'     => '0.48',
                  'if'             => '0.03',
                  },
    create_makefile_pl => 'traditional',
    );

$build->create_build_script;
