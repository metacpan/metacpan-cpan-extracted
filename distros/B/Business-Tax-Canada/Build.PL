#!/usr/bin/perl -w

use Module::Build;

Module::Build->new(
    module_name => 'Business::Tax::Canada',
    dist_abstract => q{Calculates Canadian GST/PST/HST},
    dist_author => 'Steve Simms <steve@deefs.net>',
    license => 'perl',
    create_readme => 1,
    meta_merge => {
        resources => {
            repository => 'https://bitbucket.org/ssimms/business-tax-canada',
        },
    },
)->create_build_script();
