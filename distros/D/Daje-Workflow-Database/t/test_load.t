#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

use Mojo::Pg;
use Daje::Workflow::Database;;

sub load() {
    my $pg = Mojo::Pg->new()->dsn(
        "dbi:Pg:dbname=Workflowtest;host=database;port=54321;user=test;password=test"
    );

    # my $database = Daje::Workflow::Database->new(
    #     pg => $pg,
    #     db => $pg->db,
    # );

 return 1;
}

ok(load() ==1);

done_testing();

