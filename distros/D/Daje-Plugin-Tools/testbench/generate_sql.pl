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
use Daje::Workflow::Activities::Tools::Generate::SQL;
use Daje::Workflow::Database::Model;
use Daje::Workflow::Errors::Error;

use namespace::clean -except => [qw/_options_data _options_config/];

sub genereate_sql() {

    my $pg = Mojo::Pg->new()->dsn(
        "dbi:Pg:dbname=Toolstest;host=database;port=54321;user=test;password=test"
    );

    my $model = Daje::Workflow::Database::Model->new(db => $pg->db);

    my $context->{context}->{payload}->{tools_projects_pkey} = 8;
    my $generate = Daje::Workflow::Activities::Tools::Generate::SQL->new(
        db      => $pg->db,
        context => $context,
        model   => $model,
        error   => Daje::Workflow::Errors::Error->new(),
    );


    try {
        $generate->generate_sql();
    } catch ($e) {
        say $e;
    };

}

genereate_sql();
