#!/usr/bin/perl
use 5.008;
use strict;
use warnings;

use Module::Build;

my $builder = Module::Build->new(
    module_name => q/Data::Format::Validate/,
    license => q/MIT/,
    dist_author => q/Israel Costa <israel.batista@univem.edu.br>/,
    dist_abstract => q/Perl module to validate data/,
    create_makefile_pl => 0,
    create_readme => 0,
    requires => {
        q/Carp/ => q/1.3.8/
    },
    build_requires => {
        q/Test::Simple/ => q/1.302136/
    }
);

$builder->create_build_script;
