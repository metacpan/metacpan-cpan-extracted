package BioX::Workflow::Command::run::Utils::WriteMeta;

use strict;
use warnings FATAL => 'all';
use MooseX::App::Role;
use namespace::autoclean;

use YAML;
use File::Slurp;

=head1 BioX::Workflow::Command::run::Utils::WriteMeta;

Debug information containing metadata per rule.

Useful for tracking the evolution of an analysis

=head2 Variables

=head3 comment_char

Default comment char is '#'.

=cut

option 'comment_char' => (
    is      => 'rw',
    isa     => 'Str',
    default => '#',
);

=head3 verbose

Output some more things

=cut

option 'verbose' => (
    is        => 'rw',
    isa       => 'Bool',
    default   => 1,
    clearer   => 'clear_verbose',
    predicate => 'has_verbose',
);

=head2 Subroutines

=cut

=head3 print_opts

Get the command line opts and config data - print those to cached workflow and
our workflow file.

=cut

sub print_opts {
    my $self = shift;

    my $cmd_opts    = $self->print_cmd_line_opts;
    my $config_data = $self->print_config_data;

    write_file( $self->cached_workflow, $cmd_opts );
    write_file( $self->cached_workflow, { append => 1 }, $config_data );
    write_file(
        $self->cached_workflow,
        { append => 1 },
        Dump( $self->workflow_data )
    );

    my $now = DateTime->now();
    $self->fh->say("#!/usr/bin/env bash\n\n");

    $self->fh->print($cmd_opts);
    $self->fh->say($config_data);
}

=head3 write_workflow_meta

Write out the global variables in the start, and the ending variables in the end

=cut

sub write_workflow_meta {
    my $self = shift;
    my $type = shift;

    return unless $self->verbose;

    $self->write_workflow_meta_start if $type eq 'start';
    $self->write_workflow_meta_end   if $type eq 'end';
}

sub write_workflow_meta_start {
    my $self = shift;
    $self->fh->say("$self->{comment_char}\n");
    $self->fh->say("$self->{comment_char} Starting Workflow\n");
    $self->fh->say("$self->{comment_char}");
    $self->fh->say("$self->{comment_char}");

    $self->fh->say("$self->{comment_char} Samples:");
    $self->fh->say(
        "$self->{comment_char} \t" . join( ', ', @{ $self->samples } ) );
    $self->fh->say("$self->{comment_char}");
    $self->fh->say("$self->{comment_char}");

    $self->fh->say("$self->{comment_char} Global Variables:");

    foreach my $k ( $self->all_global_keys ) {
        next unless $k;
        my $v = $self->global_attr->$k;
        $self->fh->print( $self->write_pretty_meta( $k, $v ) );
    }
    $self->fh->say("$self->{comment_char}");
}

sub write_workflow_meta_end {
    my $self = shift;
    $self->fh->say("$self->{comment_char}");
    $self->fh->say("$self->{comment_char} Ending Workflow");
    $self->fh->say("$self->{comment_char}");
}

=head2 write_rule_meta

=cut

sub write_rule_meta {
    my $self = shift;
    my $meta = shift;

    my @meta_text = ();

    push( @meta_text, "\n$self->{comment_char}" );

    if ( $meta eq "after_meta" ) {

        push( @meta_text, "$self->{comment_char} Ending $self->{key}" );
    }

    push( @meta_text, "$self->{comment_char}\n" );

    return \@meta_text unless $meta eq "before_meta";

    push( @meta_text, "$self->{comment_char}" );
    push( @meta_text, "$self->{comment_char} Starting $self->{rule_name}" );
    push( @meta_text, "$self->{comment_char}" );

    return \@meta_text unless $self->verbose;

    push( @meta_text, "\n\n$self->{comment_char}" );

    push( @meta_text, "$self->{comment_char} Variables" );

    push( @meta_text,
        "$self->{comment_char} Indir: " . $self->local_attr->indir );

    push( @meta_text,
        "$self->{comment_char} Outdir: " . $self->local_attr->outdir );

    if ( exists $self->local_rule->{ $self->rule_name }->{local} ) {

        push( @meta_text, "$self->{comment_char}" );

        push( @meta_text, "$self->{comment_char} Local Variables:\n#" );

        foreach my $k ( $self->all_local_rule_keys ) {
            my ($v) = $self->local_attr->$k;

            push( @meta_text, $self->write_pretty_meta( $k, $v ) );
        }
    }

    my $t = $self->write_sample_meta if $self->resample;
    push( @meta_text, $t ) if $t;

    $self->write_hpc_meta;

    push( @meta_text, "$self->{comment_char}\n" );

    push( @meta_text, "$self->{comment_char}" );
    my @tmp_before_meta = split( "\n", $self->local_attr->before_meta );

    map { push( @meta_text, $self->decide_comment( trim($_) ) ) }
      @tmp_before_meta;

    push( @meta_text, "$self->{comment_char}\n" );

    return \@meta_text;
}

=head3 decide_comment

In order to keep backwards compatibility with beforemeta
If the before_meta starts with a #, don't add another one

=cut

sub decide_comment {
    my $self         = shift;
    my $current      = shift;
    my $comment_char = $self->comment_char;

    if ( $current =~ m/^$comment_char/ ) {
        return $current;
    }
    else {
        return $self->comment_char . $current;
    }

}

sub trim {
    my $text = shift;

    $text =~ s/^\s+|\s+$//g;
    return $text;
}

=head3 write_hpc_meta

=cut

sub write_hpc_meta {
    my $self = shift;

    ##TODO Fix this for mixed data types
    ##TODO Just make them all a hash

    $self->local_attr->add_before_meta( ' ### HPC Directives' . "\n" );
    if ( ref( $self->local_attr->HPC ) eq 'HASH' ) {
        $self->write_hpc_hash_meta;
    }
    elsif ( ref( $self->local_attr->HPC ) eq 'ARRAY' ) {
        $self->write_hpc_array_meta;
    }

}

=head3 write_hpc_hash_meta

Write meta when HPC is a HashRef

If its a hash we can merge it

=cut

sub write_hpc_hash_meta {
    my $self = shift;

    my $jobname = '';
    if ( !exists $self->local_attr->HPC->{jobname} ) {
        $self->local_attr->add_before_meta(
            'HPC jobname=' . $self->rule_name . "\n" );
        $jobname = $self->rule_name;
    }
    else {
        $self->local_attr->add_before_meta(
            'HPC jobname=' . $self->local_attr->HPC->{jobname} . "\n" );
        $jobname = $self->local_attr->HPC->{jobname};
        delete $self->local_attr->HPC->{jobname};
    }

    $self->iter_hpc_hash( $self->local_attr->HPC );
    $self->local_attr->HPC->{jobname} = $jobname;
}

=head3 write_hpc_array_meta

Write meta when HPC is an ArrayRef

=cut

sub write_hpc_array_meta {
    my $self = shift;

    #First we look for keys to see if we get jobname

    my %lookup = ();

    if ( ref( $self->global_attr->HPC ) eq 'ARRAY' ) {
        %lookup =
          %{ $self->iter_hpc_array( $self->global_attr->HPC, \%lookup ) };
    }
    elsif ( ref( $self->global_attr->HPC ) eq 'HASH' ) {
        %lookup = %{ $self->global_attr->HPC };
    }

    %lookup = %{ $self->iter_hpc_array( $self->local_attr->HPC, \%lookup ) };

    if ( !exists $lookup{jobname} ) {
        $self->local_attr->add_before_meta(
            'HPC jobname=' . $self->rule_name . "\n" );
        unshift(
            @{ $self->local_attr->HPC },
            { 'jobname' => $self->rule_name }
        );
    }
    else {
        $self->local_attr->add_before_meta(
            'HPC jobname=' . $lookup{jobname} . "\n" );
        delete $lookup{jobname};
    }

    $self->iter_hpc_hash( \%lookup );
}

=head3 iter_hpc_array

=cut

sub iter_hpc_array {
    my $self   = shift;
    my $aref   = shift;
    my $lookup = shift;

    foreach my $href ( @{$aref} ) {
        if ( ref($href) eq 'HASH' ) {
            my @keys = keys %{$href};
            map { $lookup->{$_} = $href->{$_} } @keys;
        }
        else {
            $self->warn_hpc_meta;
            return;
        }
    }

    return $lookup;
}

=head3 iter_hpc_hash

=cut

sub iter_hpc_hash {
    my $self = shift;
    my $href = shift;

    #TODO Add in a lookup here that will check deps for any undeclared rules

    while ( my ( $k, $v ) = each %{$href} ) {
        if ( !ref($k) ) {
            $self->local_attr->add_before_meta( 'HPC ' . $k . '=' . $v . "\n" );
        }
        else {
            $self->warn_hpc_meta;
        }
    }
}

sub warn_hpc_meta {
    my $self = shift;

    my $hpc = <<EOF;
Key/Value:

 HPC:
     mem: 40GB
     walltime: '02:00:00'

List of Key/Value:
 HPC:
     - mem: 40GB
     - walltime: '02:00:00'
EOF
    $self->app_log->warn(
        'You are using an unsupported data structure for HPC.');
    $self->app_log->warn('HPC should be key/value or a list of key/value');
    $self->app_log->warn(
        'HPC data structure should look resemble the following:' . "\n"
          . $hpc );
}

=head3 write_sample_meta

Write the meta for samples

=cut

#TODO add this to app log

sub write_sample_meta {
    my $self = shift;

    return unless $self->verbose;
    my $meta_text = "";

    $meta_text .= "$self->{comment_char}\n";
    $meta_text .= "$self->{comment_char} Samples: "
      . join( ', ', @{ $self->samples } ) . "\n";
    $meta_text .= "$self->{comment_char}\n\n";

    $self->app_log->info(
        'Found samples: ' . join( ', ', @{ $self->samples } ) . "\n" );

    return $meta_text;
}

sub write_pretty_meta {
    my $self = shift;
    my $k    = shift;
    my $v    = shift;

    my $t = $self->get_pretty_value( $k, $v );
    if ( length($t) > 100 ) {
        return "$self->{comment_char}\t$k:\n" . $t . "\n";
    }
    my $comment_char = $self->comment_char;
    $t =~ s/#//;
    $t =~ s/\t//;
    return "$self->{comment_char}\t$k:\t" . $t . "\n";
}

sub get_pretty_value {
    my $self = shift;
    my $k    = shift;
    my $v    = shift;

    my $t   = '';
    my $ref = 0;
    if ( ref($v) ) {
        $ref = 1;
        $v   = Dump($v);
    }
    my %seen       = ();
    my @uniq_array = ();
    my @array      = split( "\n", $v );
    ##Get rid of the top '-----' line produced by the yaml dump
    shift(@array) if $ref;
    for ( my $x = 0 ; $x <= $#array ; $x++ ) {
        my $t = $self->comment_char . "\t\t" . $array[$x];
        next if $seen{$t};
        push( @uniq_array, $t );
        $seen{$t} = 1;
    }
    $v = join( "\n", @uniq_array );
    return $v;
}

1;
