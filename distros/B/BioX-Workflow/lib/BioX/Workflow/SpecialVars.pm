package BioX::Workflow::SpecialVars;

use Cwd qw(abs_path getcwd);
use File::Path qw(make_path remove_tree);

use MooseX::Types::Path::Tiny qw/Path Paths AbsPath/;
use Moose::Role;

=head1 BioX::Workflow::SpecialVars

Variables that BioX::Workflow treats as special.

Directories - indir, outdir are looped. The indir of one rule is the outdir of the previous rule

Files - INPUT, OUTPUT are also looped. The INPUT of one rule is the OUTPUT of the previous.

INPUT and OUTPUT are used by the L<BioX::Workflow::Plugin::Drake> and L<BioX::Workflow::Plugin::FileEixsts> plugins.

=head2 Variables

=head3 auto_name

Auto_name - Create outdirectory based on rulename

global:
    - outdir: /home/user/workflow/processed
rule:
    normalize:
        process:
            dostuff {$self->indir}/{$sample}.in >> {$self->outdir}/$sample.out
    analyse:
        process:
            dostuff {$self->indir}/{$sample}.in >> {$self->outdir}/$sample.out

Would create your directory structure /home/user/workflow/processed/normalize (if it doesn't exist)

In addition each indir is the outdir of the previous rule

The indir of analyse (though not specified) is normalize.

=cut

has 'auto_name' => (
    traits  => ['Bool'],
    is      => 'rw',
    isa     => 'Bool',
    default => 1,
    predicate => 'has_auto_name',
    handles   => {
        enforce_struct       => 'set',
        clear_enforce_struct => 'unset',
        clear_auto_name      => 'unset',
    },
);

=head3 auto_input

This is similar to the auto_name function in the BioX::Workflow.
Instead this says each INPUT should be the previous OUTPUT.

=cut

has 'auto_input' => (
    is        => 'rw',
    isa       => 'Bool',
    default   => 1,
    clearer   => 'clear_auto_input',
    predicate => 'has_auto_input',
);

=head3 create_outdir

=cut

has 'create_outdir' => (
    is        => 'rw',
    isa       => 'Bool',
    predicate => 'has_create_outdir',
    clearer   => 'clear_create_outdir',
    documentation =>
        q(Create the outdir. You may want to turn this off if doing a rule that doesn't write anything, such as checking if files exist),
    default => 1,
);

=head3 indir outdir

The initial indir is where samples are found

All output is written relative to the outdir

=cut

has 'indir' => (
    is            => 'rw',
    isa           => AbsPath,
    coerce        => 1,
    default       => sub { getcwd(); },
    predicate     => 'has_indir',
    clearer       => 'clear_indir',
    documentation => q(Directory to look for samples),
);

has 'outdir' => (
    is            => 'rw',
    isa           => AbsPath,
    coerce        => 1,
    default       => sub { getcwd(); },
    predicate     => 'has_outdir',
    clearer       => 'clear_outdir',
    documentation => q(Output directories for rules and processes),
);


=head3 INPUT OUTPUT

Special variables that can have input/output

These variables are also used in L<BioX::Workflow::Plugin::Drake>

=cut

has 'OUTPUT' => (
    is        => 'rw',
    isa       => 'Str|Undef',
    predicate => 'has_OUTPUT',
    clearer   => 'clear_OUTPUT',
    documentation =>
        q(At the end of each process the OUTPUT becomes
    the INPUT.)
);

has 'INPUT' => (
    is            => 'rw',
    isa           => 'Str|Undef',
    predicate     => 'has_INPUT',
    clearer       => 'clear_INPUT',
    documentation => q(See $OUTPUT)
);

=head2 Subroutines

=head3 OUTPUT_to_INPUT

If we are using auto_input chain INPUT/OUTPUT

=cut

sub OUTPUT_to_INPUT {
    my $self = shift;

    #Change the output to input
    if ( $self->auto_input && $self->local_attr->exists('OUTPUT') ) {
        my ( $tmp, $indir, $outdir ) = (
            $self->local_attr->get_values('OUTPUT'),
            $self->indir, $self->outdir
        );
        $tmp =~ s/{\$self->outdir}/{\$self->indir}/g;
        $self->INPUT($tmp);

        #This is not the best way of doing this....
        $self->global_attr->set( INPUT => $self->INPUT );
    }
    else {
        $self->clear_OUTPUT();
    }
}

=head3 make_outdir

Set initial indir and outdir

=cut

sub make_outdir {
    my ($self) = @_;

    return unless $self->create_outdir;

    if ( $self->{outdir} =~ m/\{\$/ ) {
        return;
    }
    make_path( $self->outdir ) if !-d $self->outdir;
}

=head2 reset_special_vars

For each sample the process is interpolated

    {$sample}.csv -> Sample_A.csv

We need to set it back to the original for the following rule

=cut

sub reset_special_vars {
    my $self = shift;

    $self->INPUT( $self->local_attr->get_values('INPUT') )
        if $self->local_attr->exists('INPUT');
    $self->OUTPUT( $self->local_attr->get_values('OUTPUT') )
        if $self->local_attr->exists('OUTPUT');

    $self->indir( $self->local_attr->get_values('indir') )
        if $self->local_attr->exists('indir');
    $self->outdir( $self->local_attr->get_values('outdir') )
        if $self->local_attr->exists('outdir');
}

1;
