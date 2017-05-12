#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 2;
use File::Spec;

use Test::Differences (qw( eq_or_diff ));

use YAML::XS (qw( LoadFile ));

use App::Sky::Config::Validate;

package main;

{
    my $config = LoadFile(
        File::Spec->catfile(
            File::Spec->curdir(),
            qw(t data sample-configs shlomif1 config.yaml)
        )
    );

    my $validator = App::Sky::Config::Validate->new(
        {
            config => $config,
        }
    );

    # TEST
    ok ($validator, 'Validator was initialised.');

    $validator->is_valid();

    # TEST
    ok (1, 'Reached here');
}
