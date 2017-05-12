package BioX::Workflow::StructureOutput;

use Moose::Role;

=head1 BioX::Workflow::StructureOutput

BioX::Workflow does the best it can to create an easy to parse directory structure.

Options are either files or directories, and for the most part can output looks like:

    #Global indir - our raw data
    data/raw
    #Global outdir  - our processed/analyzed data
    data/processed
            rule1
            rule2

    Or if by_sample_outdir
    data/processed
            Sample1/rule1
            Sample1/rule2

=head2 Variables

=head3 coerce_paths

Coerce relative path directories in variables: indir, outdir, and other variables ending in _dir to full path names

=cut

has 'coerce_paths' => (
    is        => 'rw',
    isa       => 'Bool',
    default   => 1,
    predicate => 'has_coerce_paths',
);

=head3 min

Print the workflow as 2 files.

    #run-workflow.sh
    export SAMPLE=sampleN && ./run_things

Instead of each sample having its own command, have sample exported as an environmental variable.

This option is probably less ideal when working on an HPC cluster.

=cut

has 'min' => (
    is      => 'rw',
    isa     => 'Bool',
    default => 0,
);

=head2 Subroutines

=cut

sub write_min_files {
    my ($self) = shift;

    open( my $fh, '>', 'run-workflow.sh' )
        or die print "Could not open file $!\n";

    print $fh "#!/bin/bash\n\n";

    my $cwd = getcwd();
    foreach my $sample ( @{ $self->samples } ) {
        print $fh <<EOF;
export SAMPLE=$sample && ./workflow.sh
EOF
    }

    close $fh;

    chmod 0777, 'run-workflow.sh';

    $self->samples( ["\${SAMPLE}"] );
}

=head3 process_by_sample_outdir

Make sure indir/outdirs are named appropriated for samples when using by

=cut

sub process_by_sample_outdir {
    my $self   = shift;
    my $sample = shift;

    my ( $tt, $key );
    $tt  = $self->outdir;
    $key = $self->key;
    $tt =~ s/$key/$sample\/$key/;
    $self->outdir($tt);
    $self->make_outdir;
    $self->attr->set( 'outdir' => $self->outdir );

    $tt = $self->indir;
    if ( $tt =~ m/\{\$self/ ) {
        $tt = "$tt/{\$sample}";
        $self->indir($tt);
    }
    elsif ( $self->has_pkey ) {
        $key = $self->pkey;
        $tt =~ s/$key/$sample\/$key/;
        $self->indir($tt);
    }
    else {
        $tt = "$tt/$sample";
        $self->indir($tt);
    }
    $self->attr->set( 'indir' => $self->indir );
}

1;
