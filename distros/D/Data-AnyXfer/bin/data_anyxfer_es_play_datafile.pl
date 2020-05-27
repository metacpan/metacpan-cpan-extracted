#!/usr/bin/env perl

use v5.16.3;
use strict;
use warnings;

use Carp;
use Path::Class qw//;
use Getopt::Long::Descriptive;
use Class::Load ();

use Data::AnyXfer::Elastic::Importer;
use Data::AnyXfer::Elastic::Import::DataFile;

=head1 NAME

data_anyxfer_es_play_datafile.pl

=head1 USAGE

    data_anyxfer_es_play_datafile.pl --silo private_data --index my_index-2015 --alias my_index /tmp/example.datafile

=head1 DESCRIPTION

This script is useful for manually playing a datafile to a index. A custom name
can be given to overwrite the default defined. Additionally a alias can also
be assigned ( aliases defined in the datafile will not be assigned ).

=cut

my ( $opt, $usage ) = describe_options(
    'data_anyxfer_es_play_datafile.pl %c %o <file>    ',
    [],
    ['play a datafile'],
    [],
    [   'run-on-host=s',
        'optional: execute subtasks from the specified remote host'
    ],
    [   'with-port=s',
        'optional: the remote (ssh) port use with the -run-on-host option'
    ],
    [   'as-user=s',
        'optional: a remote user to use with the -run-on-host option'
    ],
    [   'with-identity-file=s',
        'optional: an identity file to use with the -run-on-host option'
    ],
    [   'with-index-info-class=s',
        'optional: an index info class to dynamically load and apply '
            . 'instead of individual options'
    ],
    [ 'silo=s',        'optional: overwrites silo defined in datafile' ],
    [ 'single-node=s', 'optional: play datafile to specific host' ],
    [ 'index=s',       'optional: overwrites name defined in datafile' ],
    [ 'alias=s',       'optional: apply an alias to the index' ],
    [   'bulk-max-count=s',
        'optional: change the maximum bulk size for the es client',
        { default => 1000 }
    ],
    [   'wait-count-timeout=s',
        'optional: change the timeout for new documents to appear in the index',
        { default => 60 }
    ],
    [ 'delete-before-create|D', 'delete the index if it already exists' ],
    [ 'dry-run',                "print what it will do" ],
    [ 'verbose|v',              'print useful stuff' ],
    [ 'help|h',                 'print usage message' ],
);

if ( $opt->help ) {
    say $usage->text;
    exit(0);
}



# read the datafile in and create an instance
if ( $opt->dry_run || $opt->verbose ) {
    say 'Reading datafile: ' . $ARGV[0];
}

my $datafile =    #
    Data::AnyXfer::Elastic::Import::DataFile->read(
    file => Path::Class::file( $ARGV[0] ) );


# Do we need to load a class to provide index information?
if ( my $class_name = $opt->with_index_info_class ) {

    # try to load the class dynamically
    if ( Class::Load::try_load_class($class_name) ) {
        my $index_info = $class_name->new;

        # extract index info and add it to the current datafile
        for (qw/index type mappings es235_mappings settings warmers aliases silo alias/) {
            my $value = $index_info->$_;
            $datafile->$_($value) if $value;
        }
    }
}

# re-define overwrites
$datafile->silo( $opt->silo );
$datafile->index( $opt->index );
$datafile->alias( $opt->alias );
$datafile->aliases( $opt->alias ? { $opt->alias => {} } : undef );


# make sure that we have a silo to play to
croak 'Silo is required' unless $datafile->silo;


# create an array of node arrays based on the silo or
# single node override
my @nodes
    = $opt->single_node
    ? [ $opt->single_node ]
    : Data::AnyXfer::Elastic::ServerList->get_silo_nodes(
    $datafile->silo );


if ( $opt->dry_run || $opt->verbose ) {

    # returns an array of connection nodes
    say 'Playing to nodes: ' . ( join ', ', map { @{$_} } @nodes );
    say 'Playing to index: ' . $datafile->index;
    say 'Assigning alias: ' . ( $datafile->alias || 'N/A' );
}

# importer code does not support a dry-run option
exit(0) if $opt->dry_run;


my @clients
    = map { Data::AnyXfer::Elastic->build_client( nodes => $_ ) }
    @nodes;


# setup remote args if a run-on-host value was supplid=ed
my @remote_args = ();
if ( my $remote_host = $opt->run_on_host ) {
    push @remote_args, remote_host => $remote_host;

    if ( my $identity_file = $opt->with_identity_file ) {
        push @remote_args, identity_file => $identity_file;
    }
    if ( my $remote_port = $opt->with_port ) {
        push @remote_args, remote_port => $remote_port;
    }
    if ( my $remote_user = $opt->as_user ) {
        push @remote_args, remote_user => $remote_user;
    }
}

# create an importer and deploy the datafile

my $bulk_max_count = $opt->bulk_max_count;

my @clients_args = ();
if ( $opt->single_node ) {
    push @clients_args, clients => \@clients;
}

my $importer = Data::AnyXfer::Elastic::Importer->new(
    delete_before_create => $opt->delete_before_create,
    bulk_max_count       => $bulk_max_count,
    wait_count_timeout   => $opt->wait_count_timeout,

    logger => Data::AnyXfer::Elastic::Logger->new(
        screen => $opt->verbose ? 1 : 0,
        file => 0,
    ),
    @clients_args,
    @remote_args,
);

eval { $importer->deploy( datafile => $datafile ); };

if ($@) {

    $bulk_max_count ||= 'default';

    carp sprintf 'An error was received which looks to be a timeout.'
        . 'Perhaps your bulk_max_count (current: %s) '
        . 'needs to be lowered?', $bulk_max_count
        if $@ =~ /Timeout/;

    # croak as normal
    croak $@;

}

1;
