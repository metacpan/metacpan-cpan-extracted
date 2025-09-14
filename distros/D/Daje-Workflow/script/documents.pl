#!/usr/bin/perl
use FindBin;
BEGIN { unshift @INC, "$FindBin::Bin/../lib" }

use v5.40;
use Moo;
use MooX::Options;
use Cwd;
use Mojo::Pg;
use Daje::Workflow::Database;
use Daje::Workflow::Loader;
use Daje::Workflow;

use feature 'say';
use feature 'signatures';

use namespace::clean -except => [qw/_options_data _options_config/];

sub run_workflow() {

    my $pg = Mojo::Pg->new()->dsn(
        "dbi:Pg:dbname=Workflowtest;host=database;port=54321;user=test;password=test"
    );

    my $migrations;
    push @{$migrations}, {class => 'Daje::Workflow::Database', name => 'workflow', migration => 3};
    push @{$migrations}, {class => 'Daje::Workflow::FileChanged::Database::DB', name => 'file_changed', migration => 1};

    Daje::Workflow::Database->new(
        pg          => $pg,
        migrations  => $migrations,
    )->migrate();

    my $loader = Daje::Workflow::Loader->new(
        path => '/home/jan/Project/Daje-Workflow-Workflows/Workflows',
        type => 'workflow',
    );
    $loader->load();

    my $context->{context}->{template}->{data_section} = "login";
    $context->{context}->{template}->{source} = "Daje::Document::Template::Mail::Login";
    $context->{context}->{data}->{name} = "Jan Eskilsson";
    $context->{context}->{data}->{title} = "Authenticate";
    $context->{context}->{data}->{id} = 123456;

    my $workflow = Daje::Workflow->new(
        pg            => $pg,
        loader        => $loader->loader,
        workflow_name => 'document_builder',
        workflow_pkey => '0',
        context       => $context,
    );

    $workflow->process("build_document");
    say $workflow->error->error if $workflow->error->has_error() ;
}

run_workflow();