#!/usr/bin/perl
use v5.42;
use strict;
use warnings FATAL => 'all';

use feature 'say';
use feature 'signatures';

use Daje::Tools::Mail::Manager;
use Daje::Workflow::Errors::Error;
use Mojo::Pg;

sub send_mail() {

    my $pg = Mojo::Pg->new()->dsn(
        "dbi:Pg:dbname=sentinel;host=192.168.1.124;port=5432;user=sentinel;password=PV58nova64"
    );

    my $manager = Daje::Tools::Mail::Manager->new(
        db    => $pg->db,
        error => Daje::Workflow::Errors::Error->new(),
    );
    try {
        $manager->verify_simple('jan@daje.work', '1234');
    } catch ($e) {
        say $e;
    }
}

send_mail();