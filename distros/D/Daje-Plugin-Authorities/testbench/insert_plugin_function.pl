#!/usr/bin/perl
use FindBin;
BEGIN { unshift @INC, "$FindBin::Bin/../lib" }

use v5.42;
use Moo;
use MooX::Options;
use Cwd;
use Mojo::Pg;

use feature 'say';
use feature 'signatures';
use Daje::Plugin::Authorities::Authorities;;

use namespace::clean -except => [qw/_options_data _options_config/];

sub genereate_angular() {

    my $pg = Mojo::Pg->new()->dsn(
        "dbi:Pg:dbname=sentinel;host=192.168.1.124;port=5432;user=sentinel;password=PV58nova64"
    );

    try {
        Daje::Plugin::Authorities::Authorities->new(
            db => $pg->db
        )->authorize();
    } catch ($e) {
        say $e;
    };

}

genereate_angular();
