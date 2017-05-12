package BioX::Workflow;

use 5.008_005;
our $VERSION = '1.10';

use Moose;

use File::Path qw(make_path remove_tree);
use Cwd qw(abs_path getcwd);
use Data::Dumper;
use List::Compare;
use YAML::XS 'LoadFile';
use Config::Any;

use Data::Dumper;
use Class::Load ':all';
use IO::File;
use Interpolation E => 'eval';
use Text::Template qw(fill_in_file fill_in_string);
use Data::Pairs;
use Storable qw(dclone);
use MooseX::Types::Path::Tiny qw/Path Paths AbsPath/;

extends 'BioX::Wrapper';

with 'BioX::Workflow::Samples';
with 'BioX::Workflow::Debug';
with 'BioX::Workflow::SpecialVars';
with 'BioX::Workflow::StructureOutput';
with 'BioX::Workflow::WriteMeta';
with 'BioX::Workflow::Rules';

with 'MooseX::Getopt::Usage';
with 'MooseX::Getopt::Usage::Role::Man';
with 'MooseX::SimpleConfig';
with 'MooseX::Object::Pluggable';

use MooseX::FileAttribute;

# For pretty man pages!

$ENV{TERM} = 'xterm-256color';

=encoding utf-7

=head1 NAME

BioX::Workflow - A very opinionated template based workflow writer.

=head1 SYNOPSIS

Most of the functionality can be accessed through the biox-workflow.pl script.

    biox-workflow.pl --workflow /path/to/workflow.yml

This module was written with Bioinformatics workflows in mind, but should be extensible to any sort of workflow or pipeline.

=head1 Usage

Please check out the full Usage Docs at L<BioX::Workflow::Usage>

Alternately, check out the github pages at L<http://jerowe.github.io/BioX-Workflow-Docs/showcase.html>. This format may be easier to read.

=head1 In Code Documenation

You shouldn't really need to look here unless you have some reason to do some serious hacking.

=head2 Attributes

Moose attributes. Technically any of these can be changed, but may break everything.

=head3 comment_char

This should really be in BioX::Wrapper

=cut

has '+comment_char' => (
    predicate => 'has_comment_char',
    clearer   => 'clear_comment_char',
);

=head3 workflow

Path to workflow workflow. This must be a YAML file.

=cut

has_file 'workflow' => (
    is            => 'rw',
    required      => 1,
    must_exist    => 1,
    documentation => q{Your configuration workflow file.},
);

=head3 rule_based

This is the default. The outer loop are the rules, not the samples

=cut

has 'rule_based' => (
    is      => 'rw',
    isa     => 'Bool',
    default => 1,
);

=head3 sample_based

Default Value. The outer loop is samples, not rules. Must be set in your global values or on the command line --sample_based 1

If you ever have resample: 1 in your config you should NOT set this value to true!

=cut

has 'sample_based' => (
    is      => 'rw',
    isa     => 'Bool',
    default => 0,
);

=head2 stash

This isn't ever used in the code. Its just there incase you want to persist objects across rules

It uses Moose::Meta::Attribute::Native::Trait::Hash and supports all the methods.

        set_stash     => 'set',
        get_stash     => 'get',
        has_no_stash => 'is_empty',
        num_stashs    => 'count',
        delete_stash  => 'delete',
        stash_pairs   => 'kv',

=cut

has 'stash' => (
    is      => 'rw',
    isa     => 'HashRef',
    traits  => ['Hash'],
    default => sub { {} },
    handles => {
        set_stash    => 'set',
        get_stash    => 'get',
        has_no_stash => 'is_empty',
        num_stashs   => 'count',
        delete_stash => 'delete',
        stash_pairs  => 'kv',
    },
);

=head2 plugins

Load plugins as an opt

=cut

has 'plugins' => (
    is      => 'rw',
    isa     => 'ArrayRef',
    default => sub { [] },
);

=head3 No GetOpt Here

=cut

has 'yaml' => (
    traits => ['NoGetopt'],
    is     => 'rw',
);

=head3 attr

attributes read in from runtime

=cut

has 'attr' => (
    traits => ['NoGetopt'],
    is     => 'rw',
    isa    => 'Data::Pairs',
);

=head3 global_attr

Attributes defined in the global section of the yaml file

=cut

has 'global_attr' => (
    traits  => ['NoGetopt'],
    is      => 'rw',
    isa     => 'Data::Pairs',
    lazy    => 1,
    default => sub {
        my $self = shift;

        my $n = Data::Pairs->new(
            [   { resample         => $self->resample },
                { wait             => $self->wait },
                { auto_input       => $self->auto_input },
                { coerce_paths     => $self->coerce_paths },
                { auto_name        => $self->auto_name },
                { indir            => $self->indir },
                { outdir           => $self->outdir },
                { min              => $self->min },
                { override_process => $self->override_process },
                { rule_based       => $self->rule_based },
                { verbose          => $self->verbose },
                { create_outdir    => $self->create_outdir },
            ]
        );
        return $n;
    }
);

=head3 local_attr

Attributes defined in the rules->rulename->local section of the yaml file

=cut

has 'local_attr' => (
    traits => ['NoGetopt'],
    is     => 'rw',
    isa    => 'Data::Pairs',
);

=head3 local_rule

=cut

has 'local_rule' => (
    traits => ['NoGetopt'],
    is     => 'rw',
    isa    => 'HashRef'
);

=head3 process

Our bash string

    bowtie2 -p 12 -I {$sample}.fastq -O {$sample}.bam

=cut

has 'process' => (
    traits => ['NoGetopt'],
    is     => 'rw',
    isa    => 'Str',
);

=head3 key

Name of the rule

=cut

has 'key' => (
    traits => ['NoGetopt'],
    is     => 'rw',
    isa    => 'Str',
);

=head3 pkey

Name of the previous rule

=cut

has 'pkey' => (
    traits    => ['NoGetopt'],
    is        => 'rw',
    isa       => 'Str|Undef',
    predicate => 'has_pkey'
);

=head2 Subroutines

Subroutines can also be overriden and/or extended in the usual Moose fashion.

=head3 run

Starting point.

=cut

sub run {
    my ($self) = shift;

    print "#!/bin/bash\n\n";

    $self->print_opts;

    $self->init_things;

    $self->write_workflow_meta('start');

    $self->write_pipeline;

    $self->write_workflow_meta('end');
}

=head3 init_things

Load the workflow, additional classes, and plugins

Initialize the global_attr, make the global outdir, and find samples

=cut

sub init_things {
    my $self = shift;

    $self->key('global');

    $self->workflow_load;
    $self->class_load;
    $self->plugin_load;

    #Darn you data pairs and your shallow copies!
    $self->init_global_attr;

    $self->make_outdir;
    $self->get_samples;

    $self->save_env;
}

=head2 workflow_load

use Config::Any to load configuration files - yaml, json, etc

=cut

sub workflow_load {
    my $self = shift;

    my $cfg = Config::Any->load_files(
        { files => [ $self->workflow ], use_ext => 1 } );

    for (@$cfg) {
        my ( $filename, $config ) = %$_;
        $self->yaml($config);
    }
}

=head3 plugin_load

Load plugins defined in yaml or on command line with --plugins with MooseX::Object::Pluggable

=cut

sub plugin_load {
    my ($self) = shift;

    my $plugins = [];
    if ( $self->yaml->{plugins} ) {
        $plugins = $self->yaml->{plugins};
    }
    elsif ( $self->plugins ) {
        $plugins = $self->plugins;
    }
    else {
        return;
    }

    foreach my $m (@$plugins) {
        $self->load_plugin($m);
    }
}

=head3 class_load

Load classes defined in yaml with Class::Load

=cut

sub class_load {
    my ($self) = shift;

    return unless $self->yaml->{use};

    my $modules = $self->yaml->{use};

    foreach my $m (@$modules) {
        load_class($m);
    }
}

=head3 make_template

Make the template for interpolating strings

=cut

sub make_template {
    my ( $self, $input ) = @_;

    my $template = Text::Template->new(
        TYPE   => 'STRING',
        SOURCE => "$E{$input}",
    );

    #SOURCE => "$input",
    return $template;
}

=head2 init_global_attr

Add our global key from config file to the global_attr, and then to attr

Deprecated: set_global_yaml

=cut

sub init_global_attr {
    my $self = shift;

    return unless exists $self->yaml->{global};

    my $aref = $self->yaml->{global};
    for my $a (@$aref) {
        while ( my ( $key, $value ) = each( %{$a} ) ) {
            $self->global_attr->set( $key => $value );
        }
    }

    $self->attr( dclone( $self->global_attr ) );
    $self->create_attr;
}

=head3 create_attr

Add attributes to $self-> namespace

=cut

sub create_attr {
    my ($self) = shift;

    my $meta = __PACKAGE__->meta;

    $meta->make_mutable;

    my %seen = ();

    for my $attr ( $meta->get_all_attributes ) {
        $seen{ $attr->name } = 1;
    }

    # Data Pairs is so much prettier
    my @keys = $self->attr->get_keys();

    foreach my $k (@keys) {
        my ($v) = $self->attr->get_values($k);

        if ( !exists $seen{$k} ) {
            if ( $k =~ m/_dir$/ ) {
                if ( $self->coerce_paths ) {
                    $meta->add_attribute(
                        $k => (
                            is        => 'rw',
                            isa       => AbsPath,
                            coerce    => 1,
                            predicate => "has_$k",
                            clearer   => "clear_$k"
                        )
                    );
                }
                else {
                    $meta->add_attribute(
                        $k => (
                            is        => 'rw',
                            isa       => AbsPath,
                            coerce    => 0,
                            predicate => "has_$k",
                            clearer   => "clear_$k"
                        )
                    );
                }
            }
            else {
                $meta->add_attribute(
                    $k => (
                        is        => 'rw',
                        predicate => "has_$k",
                        clearer   => "clear_$k"
                    )
                );
            }
        }
        $self->$k($v) if defined $v;
    }

    $meta->make_immutable;
}

=head3 eval_attr

Evaluate the keys for variables using Text::Template
{$sample} -> SampleA
{$self->indir} -> data/raw (or the indir of the rule)

If variables are themselves hashes/array refs, leave them alone

=cut

sub eval_attr {
    my $self   = shift;
    my $sample = shift;

    my @keys = $self->attr->get_keys();

    foreach my $k (@keys) {
        next unless $k;

        my ($v) = $self->attr->get_values($k);
        next unless $v;

        #If its an array or hash reference leave it alone
        if ( ref($v) eq 'ARRAY' || ref($v) eq 'HASH' ) {
            $self->$k($v);
            next;
        }

        #Otherwise its a string
        my $template = $self->make_template($v);
        my $text;
        if ($sample) {
            $text = $template->fill_in(
                HASH => { self => \$self, sample => $sample } );
        }
        else {
            $text = $template->fill_in( HASH => { self => \$self } );
        }

        $self->$k($text);
    }

    $self->make_outdir if $self->create_outdir;
}

=head2 clear_attr

After each rule is processe clear the $self->attr

=cut

sub clear_attr {
    my $self = shift;

    my @keys = $self->attr->get_keys();

    foreach my $k (@keys) {
        my ($v) = $self->attr->get_values($k);
        next unless $v;

        my $clear = "clear_$k";
        $self->$clear;
    }
}

sub write_pipeline {
    my ($self) = shift;

    #Min and Sample_Based Mode will break with --resample
    if ( $self->min ) {
        $self->write_min_files;
        $self->process_rules;
    }
    elsif ( $self->sample_based ) {

        #Store the samples
        my $sample_store = $self->samples;
        foreach my $sample (@$sample_store) {
            $self->samples( [$sample] );
            $self->process_rules;
        }
    }
    elsif ( $self->rule_based ) {
        $self->process_rules;
    }
    else {
        die print "Workflow must be rule based or sample based!\n";
    }
}

sub process_rules {
    my $self = shift;

    my $process;
    $process = $self->yaml->{rules};

    die print "Where are the rules?\n" unless $process;
    die unless ref($process) eq 'ARRAY';

    foreach my $p ( @{$process} ) {
        next unless $p;
        if ( $self->number_rules ) {
            my @keys   = keys %{$p};
            my $result = sprintf( "%04d", $self->counter_rules );
            my $newkey = $keys[0];
            $newkey = $result . '-' . $newkey;
            $p->{$newkey} = dclone( $p->{ $keys[0] } );
            delete $p->{ $keys[0] };
        }
        $self->local_rule($p);
        $self->dothings;
        $self->inc_counter_rules;
    }
}

sub dothings {
    my ($self) = shift;

    $self->check_keys;

    $self->init_process_vars;

    return if $self->check_rules;

    $self->process( $self->local_rule->{ $self->key }->{process} );

    $self->write_rule_meta('before_meta');

    $self->write_process();

    $self->write_rule_meta('after_meta');

    $self->clear_process_attr;

    $self->indir( $self->outdir . "/" . $self->pkey ) if $self->auto_name;
}

=head2 check_keys

There should be one key and one key only!

=cut

sub check_keys {
    my $self = shift;
    my @keys = keys %{ $self->local_rule };

    if ( $#keys > 0 ) {
        die print
            "We have a problem! There should only be one key. Please see the documentation!\n";
    }
    elsif ( !@keys ) {
        die print "There are no rules. Please see the documenation.\n";
    }
    else {
        $self->key( $keys[0] );
    }

    if ( !exists $self->local_rule->{ $self->key }->{process} ) {
        die print "There is no process key! Dying...\n";
    }
}

=head2 clear_process_attr

Clear the process attr

Deprecated: clear_process_vars

=cut

sub clear_process_attr {
    my $self = shift;

    $self->attr->clear;
    $self->local_attr->clear;

    $self->add_attr('global_attr');

    $self->eval_attr;
}

=head2 init_process_vars

Initialize the process vars

=cut

sub init_process_vars {
    my $self = shift;

    if ( $self->auto_name ) {
        $self->outdir( $self->outdir . "/" . $self->key );
        $self->make_outdir() unless $self->by_sample_outdir;
    }

    if ( exists $self->local_rule->{ $self->key }->{override_process}
        && $self->local_rule->{ $self->key }->{override_process} == 1 )
    {
        $self->override_process(1);
    }
    else {
        $self->override_process(0);
    }

    $self->local_attr( Data::Pairs->new( [] ) );
    if ( exists $self->local_rule->{ $self->key }->{local} ) {
        $self->local_attr(
            Data::Pairs->new(
                dclone( $self->local_rule->{ $self->key }->{local} )
            )
        );
    }

    #Make sure these aren't reset to global
    ##YAY FOR TESTS
    $self->local_attr->set( 'outdir' => $self->outdir )
        unless $self->local_attr->exists('outdir');
    $self->local_attr->set( 'indir' => $self->indir )
        unless $self->local_attr->exists('indir');

    $self->add_attr('local_attr');
    $self->create_attr;
    $self->get_samples if $self->resample;

    #Why did I have this in write rule meta?
    if ( $self->auto_input ) {
        $self->local_attr->set( 'OUTPUT' => $self->OUTPUT )
            if $self->has_OUTPUT;
        $self->local_attr->set(
            'INPUT' => $self->global_attr->get_values('INPUT') )
            if $self->global_attr->exists('INPUT');
    }
}

=head2 add_attr

Add the local attr onto the global attr

=cut

sub add_attr {
    my $self = shift;
    my $type = shift;

    my @keys = $self->$type->get_keys();

    foreach my $key (@keys) {
        next unless $key;

        my ($v) = $self->$type->get_values($key);
        $self->attr->set( $key => $v );
    }
}

sub write_process {
    my ($self) = @_;

    $self->save_env;

    if ( !$self->override_process ) {
        foreach my $sample ( @{ $self->samples } ) {
            $self->sample($sample);
            $self->process_by_sample_outdir($sample)
                if $self->by_sample_outdir;
            $self->eval_attr($sample);
            my $data = { self => \$self, sample => $sample };
            $self->process_template($data);
            $self->reset_special_vars;
        }
    }
    else {
        $self->eval_attr;
        my $data = { self => \$self };
        $self->process_template($data);
    }

    print "\nwait\n" if $self->wait;

    $self->OUTPUT_to_INPUT;

    $self->pkey( $self->key );
}

sub process_template {
    my ( $self, $data ) = @_;

    my $template = $self->make_template( $self->process );
    $template->fill_in( HASH => $data, OUTPUT => \*STDOUT );

    $DB::single = 2;
    $DB::single = 2;

    print "\n\n";
}

__PACKAGE__->meta->make_immutable;

1;

__END__


=head1 DESCRIPTION

BioX::Workflow - A very opinionated template based workflow writer.

=head1 AUTHOR

Jillian Rowe E<lt>jillian.e.rowe@gmail.comE<gt>

=head1 Acknowledgements

Before version 0.03

This module was originally developed at and for Weill Cornell Medical
College in Qatar within ITS Advanced Computing Team. With approval from
WCMC-Q, this information was generalized and put on github, for which
the authors would like to express their gratitude.

As of version 0.03:

This modules continuing development is supported
by NYU Abu Dhabi in the Center for Genomics and
Systems Biology. With approval from NYUAD, this
information was generalized and put on bitbucket,
for which the authors would like to express their
gratitude.


=head1 COPYRIGHT

Copyright 2015- Weill Cornell Medical College in Qatar

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
