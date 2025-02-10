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
use Daje::Workflow::Errors::Error;

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
        path => '/home/jan/Project/Daje-Workflow-Workflows/Generate',
        type => 'workflow',
    );
    $loader->load();
    my $context->{context}->{sql_path} = '/home/jan/Project/SyntaxSorcery/Tools/Generate/conf/generate_sql.ini';
    $context->{context}->{perl_path} = '/home/jan/Project/SyntaxSorcery/Tools/Generate/conf/generate_perl.ini';
    $context->{context}->{source_dir} = '/home/jan/Project/Daje-Schema/Users/';
    $context->{context}->{sql_target_dir} = '/home/jan/Project/SyntaxSorcery/Tools/Generate/Sql/';
    $context->{context}->{data_dir} = '/home/jan/Project/SyntaxSorcery/Tools/Generate/schema/';
    $context->{context}->{target_dir} = '/home/jan/Project/SyntaxSorcery/Tools/Generate/schema/';
    $context->{context}->{dbconn} = "dbi:Pg:dbname=DB;host=database;port=54321;user=test;password=test";


    $context->{context}->{schema_dir}="/home/jan/Project/Daje-Database/schema/";
    $context->{context}->{perl}->{name_space_dir}="/home/jan/Project/Daje-Database/lib/Daje/Database/Model/Super/";
    $context->{context}->{perl}->{view_name_space_dir}="/home/jan/Project/Daje-Database/lib/Daje/Database/View/Super/";
    $context->{context}->{perl}->{base_space_dir}="/home/jan/Project/Daje-Database/lib/Daje/Database/Model/Super/Common/";
    $context->{context}->{perl}->{interface_space_dir}="/home/jan/Project/Daje-Database/lib/Daje/Database/Model/";
    $context->{context}->{perl}->{view_interface_space_dir}="/home/jan/Project/Daje-Database/lib/Daje/Database/View/";

    $context->{context}->{perl}->{name_space}="Daje::Database::Model::Super::";
    $context->{context}->{perl}->{view_name_space}="Daje::Database::View::Super::";
    $context->{context}->{perl}->{base_name_space}="Daje::Database::Model::Super::Common::";
    $context->{context}->{perl}->{name_interface}="Daje::Database::Model::";
    $context->{context}->{perl}->{view_name_interface}="Daje::Database::View::";

    # my $context;
    my $workflow = Daje::Workflow->new(
        pg            => $pg,
        loader        => $loader,
        workflow_name => 'generate',
        workflow_pkey => '4',
        context       => $context,
    );
    # changed_files
    # generate_sql
    # save_sql_file
    # generate_schema
    # save_schema_file
    # generate_perl generatePerl
    # save_perl_file
    $workflow->process("save_perl_file");
    say $workflow->error->error if $workflow->error->has_error() ;

}

run_workflow();

1;
