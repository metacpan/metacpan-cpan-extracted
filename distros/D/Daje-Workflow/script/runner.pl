#!/usr/bin/perl
### # !/opt/ActivePerl-5.26/bin/perl
use v5.40;
use FindBin;
BEGIN { unshift @INC, "$FindBin::Bin/../lib" }

use Moo;
use MooX::Options;
use Data::Dumper;
use feature 'say';
use feature 'signatures';
use POSIX qw(strftime);
use Config::Tiny;
use Try::Tiny;
use Cwd;
use Log::Log4perl qw(:easy);
use Daje::Workflow::Config;
use Daje::Workflow::Database;
use Daje::Workflow::Loader;
use Daje::Workflow;
use Mojo::Pg;
use namespace::clean -except => [qw/_options_data _options_config/];

option 'config' => (
    is 			=> 'ro',
    required 	=> 1,
    format 		=> 's',
    doc 		=> 'Configuration file',
    default 	=> '/home/jan/Project/Daje-Workflow/conf/'
);

sub runner ($self) {
# orkflow.name
    my $config = Daje::Workflow::Config->new(
        path => $self->config
    )->load("users.json");

    my $pg = Mojo::Pg->new()->dsn(
        $config->param('dsn')
        # "dbi:Pg:dbname=Workflowtest;host=database;port=54321;user=test;password=test"
    );

    my $migrations = $config->param('migrations');
    # push @{$migrations}, {
    #     class => 'Daje::Workflow::Database', name => 'workflow', migration => 3
    # };
    # push @{$migrations}, {
    #     class => 'Daje::Workflow::FileChanged::Database::DB',
    #     name => 'file_changed',
    #     migration => 1
    # };

    Daje::Workflow::Database->new(
        pg          => $pg,
        migrations  => $migrations,
    )->migrate();


    my $loader = Daje::Workflow::Loader->new(
        path => $config->param('workflow.path'),
        type => $config->param('workflow.type'),
        #path => '/home/jan/Project/Daje-Workflow-Workflows/Workflows',
        #type => 'workflow',
    );
    $loader->load();

    my $context->{context} = $config->param('context');
    # my $workflow = Daje::Workflow->new(
    #     pg            => $pg,
    #     loader        => $loader->loader,
    #     workflow_name => $config->param('workflow.name'),
    #     workflow_pkey => '0',
    #     context       => $context,
    # );
    #
    # generate_sql
    # save_sql_file
    # generate_schema
    # save_schema_file
    # generate_perl
    # save_perl_file
    #
    # generatePerl
    #
    my $activities = $config->param('workflow.activities');
    my $length = scalar @{$activities};
    @$activities = sort {$a->{order} <=> $b->{order}} @$activities ;

    my $err = 1;
    my $workflow_pkey = 0;
    for(my $i = 0; $i < $length; $i++) {
        my $workflow = Daje::Workflow->new(
            pg            => $pg,
            loader        => $loader->loader,
            workflow_name => $config->param('workflow.name'),
            workflow_pkey => $workflow_pkey,
            context       => $context,
        );
        if($err == 1) {
            $workflow->process(@{$activities}[$i]->{activity});
            $workflow_pkey = $workflow->workflow_pkey();
            $err = !$workflow->error->has_error();
            say $workflow->error->error if $workflow->error->has_error();
        }
    }


}

main->new_with_options->runner();