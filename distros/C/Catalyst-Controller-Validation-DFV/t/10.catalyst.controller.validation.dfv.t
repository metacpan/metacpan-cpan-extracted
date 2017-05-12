#!/usr/bin/env perl
# vim: ts=8 sts=4 et sw=4 sr sta
use strict;
use warnings;

use Test::More tests => 2;

use_ok('Catalyst::Controller::Validation::DFV');

can_ok('Catalyst::Controller::Validation::DFV',
    qw(
        new

        add_form_invalid
        form_check
        refill_form
    )
);
