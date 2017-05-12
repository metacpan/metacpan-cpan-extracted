#!/usr/bin/env perl

use File::Spec;
use maint::Maker;

all_from 'lib/App/local/lib/helper.pm';

requires 'FindBin';
requires 'File::Spec';
requires 'local::lib';
requires 'Getopt::Long';
requires 'Config';

build_requires 'File::Spec';
test_requires 'Test::More' => '0.94';

tests_recursive;

my $local_lib_helper_script =
  File::Spec->catdir('script','local-lib-helper');

install_script $local_lib_helper_script;

postamble <<"EOP";
install :: install_local_lib_helper

install_local_lib_helper :
\t\$(PERL) $local_lib_helper_script @ARGV

EOP

