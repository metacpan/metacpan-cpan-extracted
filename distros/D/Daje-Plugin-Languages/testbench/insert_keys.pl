#!/usr/bin/perl
use v5.42;
use strict;
use warnings FATAL => 'all';

use feature 'say';
use feature 'signatures';

use Daje::Plugin::Languages::Languages;
use Daje::Workflow::Errors::Error;
use Mojo::Pg;

sub insert_keys() {

    my $pg = Mojo::Pg->new()->dsn(
        "dbi:Pg:dbname=sentinel;host=192.168.1.124;port=5432;user=sentinel;password=PV58nova64"
    );

    my $manager = Daje::Plugin::Languages::Languages->new(
        db    => $pg->db,
    );
    try {
        $manager->language();
    } catch ($e) {
        say $e;
    }
}

insert_keys();