#!/usr/bin/env perl

use common::sense;
use File::Temp;
use Chouette;

my $chouette = Chouette->new({
    config_defaults => {
        var_dir => File::Temp::tempdir(CLEANUP => 1),
        listen => '9876',
    },

    routes => {
        '/' => {
            GET => sub {
                my $c = shift;
                die $c->respond({ hello => 'world!' });
            },
        },
    },
});

$chouette->run;
