#!/usr/bin/perl
use FindBin;
BEGIN { unshift @INC, "$FindBin::Bin/../lib" }

use v5.40;
use Moo;
use MooX::Options;
use Cwd;

use feature 'say';
use feature 'signatures';
use Daje::Workflow::Database;
use Daje::Workflow::Loader;
use Daje::Workflow;
use Mojo::Pg;

use namespace::clean -except => [qw/_options_data _options_config/];

sub run_workflow() {
    my $pg = Mojo::Pg->new()->dsn(
        "dbi:Pg:dbname=Workflowtest;host=database;port=54321;user=test;password=test"
    );
    Daje::Workflow::Database->new(
        pg => $pg
    )->migrate();

    my $loader = Daje::Workflow::Loader->new(
        path => '/home/jan/Project/Daje-Workflow-Loader/conf/'
    );
    $loader->load();
    my $context->{context}->{sql_path} = '/home/jan/Project/SyntaxSorcery/Tools/Generate/conf/generate_sql.ini';
    $context->{context}->{perl_path} = '/home/jan/Project/SyntaxSorcery/Tools/Generate/conf/generate_perl.ini';
    my $workflow = Daje::Workflow->new(
        pg            => $pg,
        loader        => $loader,
        workflow_name => 'generate',
        workflow_pkey => '0',
        context       => $context,
    );
    $workflow->process("sql");
    say $workflow->error->error if $workflow->error->has_error() ;

}

run_workflow();

1;
