#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

use Mojo::Pg;
use Daje::Workflow::Database;;

sub load_existing() {
    my $pg = Mojo::Pg->new()->dsn(
        "dbi:Pg:dbname=Workflowtest;host=database;port=54321;user=test;password=test"
    );
    my $context->{path} = "";
    my $wfl_data->{action} = "GenerateSQL";

    my $db = $pg->db;
    my $tx = $db->begin();
    my $database = Daje::Workflow::Database->new(
        pg            => $pg,
        db            => $db,
        workflow      => 'testflow',
        workflow_pkey => 15,
        context       => $context,
        wfl_data      => $wfl_data,
    );

    $database->start();
    $tx->commit();

    return 1;
}

sub load_first_time() {
    my $pg = Mojo::Pg->new()->dsn(
        "dbi:Pg:dbname=Workflowtest;host=database;port=54321;user=test;password=test"
    );
    my $context->{path};
    my $wfl_data->{action} = "GenerateSQL";

    my $db = $pg->db;
    my $tx = $db->begin();
    my $database = Daje::Workflow::Database->new(
        pg            => $pg,
        db            => $db,
        workflow      => 'testflow',
        workflow_pkey => 0,
        context       => $context,
        wfl_data      => $wfl_data,
    );

    $database->start();
    $tx->commit();

    return 1;
}
ok(load_existing() ==1);
ok(load_first_time() ==1);

done_testing();

