#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

use Mojo::Pg;
use Daje::Workflow::Database;;


sub migrate() {
    my $devtest = 0;

    if ($devtest == 1) {
        my $pg = Mojo::Pg->new()->dsn(
            "dbi:Pg:dbname=Workflowtest;host=database;port=54321;user=test;password=test"
        );
        my $database = Daje::Workflow::Database->new(
            pg => $pg,
        );
        $database->migrate();
    }

    return 1;
}

ok(migrate() ==1);

done_testing();

