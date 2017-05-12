package BioX::Workflow::Samples;

use File::Find::Rule;
use File::Basename;
use List::Uniq ':all';

use Moose::Role;

=head1 BioX::Workflow::Samples

All the options for samples are here.

=head2 Variables

=head3 resample

Boolean value get new samples based on indir/file_rule or no

Samples are found at the beginning of the workflow, based on the global indir variable and the file_find.

Chances are you don't want to set resample to true. These files probably won't exist outside of the indirectory until the pipeline is run.

One example of doing so, shown in the gemini.yml in the examples directory, is looking for uncompressed files, .vcf extension, compressing them, and
then resampling based on the .vcf.gz extension.

=cut

has 'resample' => (
    traits    => ['NoGetopt'],
    is        => 'rw',
    isa       => 'Bool',
    default   => 0,
    predicate => 'has_resample',
    clearer   => 'clear_resample',
);

=head3 infiles

Infiles to be processed

=cut

has 'infiles' => (
    traits => ['NoGetopt'],
    is     => 'rw',
    isa    => 'ArrayRef',
);

=head2 find_by_dir

Use this option when you sample names are by directory
The default is to find samples by filename

    /SAMPLE1
        SAMPLE1_r1.fastq.gz
        SAMPLE1_r2.fastq.gz
    /SAMPLE2
        SAMPLE2_r1.fastq.gz
        SAMPLE2_r2.fastq.gz

=cut

has 'find_by_dir' => (
    is            => 'rw',
    isa           => 'Bool',
    default       => 0,
    documentation => q{Use this option when you sample names are directories},
    predicate     => 'has_find_by_dir',
    clearer       => 'clear_find_by_dir',
);

=head2 by_sample_outdir

    outdir/
    /outdir/SAMPLE1
        /rule1
        /rule2
        /rule3
    /outdir/SAMPLE2
        /rule1
        /rule2
        /rule3

Instead of

    /outdir
        /rule1
        /rule2

=cut

has 'by_sample_outdir' => (
    is            => 'rw',
    isa           => 'Bool',
    default       => 0,
    documentation => q{When you want your output by sample},
    clearer       => 'clear_by_sample_outdir',
    predicate     => 'has_by_sample_outdir',
);

=head3 samples

Our samples to process. They are either found through file_rule, or passed as command line opts

=cut

has 'samples' => (
    traits   => ['Array'],
    is       => 'rw',
    isa      => 'ArrayRef',
    default  => sub { [] },
    required => 0,
    handles  => {
        all_samples    => 'elements',
        add_sample     => 'push',
        map_samples    => 'map',
        filter_samples => 'grep',
        find_sample    => 'first',
        get_sample     => 'get',
        join_samples   => 'join',
        count_samples  => 'count',
        has_samples    => 'count',
        has_no_samples => 'is_empty',
        sorted_samples => 'sort',
    },
    documentation =>
        q{Supply samples on the command line as --samples sample1 --samples sample2, or find through file_rule.}
);

=head3 sample

Each time we get the sample we set it.

=cut

has 'sample'=> (
    traits => ['NoGetopt'],
    is => 'rw',
    isa => 'Str',
    required => 0,
    default => '',
);

=head3 file_rule

Rule to find files/samples

=cut

has 'file_rule' => (
    is        => 'rw',
    isa       => 'Str',
    default   => sub { return "(.*)"; },
    clearer   => 'clear_file_rule',
    predicate => 'has_file_rule',
);

=head2 Subroutines

=head3 get_samples

Get basename of the files. Can add optional rules.

sample.vcf.gz and sample.vcf would be sample if the file_rule is (.vcf)$|(.vcf.gz)$

Also gets the full path to infiles

Instead of doing

    foreach my $sample (@$self->samples){
        dostuff
    }

Could have

    foreach my $infile (@$self->infiles){
        dostuff
    }

=cut

sub get_samples {
    my ($self) = shift;
    my ( @whole, @basename, $text );

    if ( $self->has_samples && !$self->resample ) {
        my (@samples) = $self->sorted_samples;
        $self->samples( \@samples );
        return;
    }

    $text = $self->file_rule;

    if ( $self->find_by_dir ) {
        @whole = find(
            directory => name => qr/$text/,
            maxdepth  => 1,
            in        => $self->indir
        );

        #File find puts directory we are looking in, not just subdirs
        @basename = grep { $_ != basename( $self->{indir} ) } @basename;
        @basename = map  { basename($_) } @whole;
        @basename = sort(@basename);
    }
    else {
        @whole = find(
            file     => name => qr/$text/,
            maxdepth => 1,
            in       => $self->indir
        );

        @basename = map { $self->match_samples( $_, $text ) } @whole;
        @basename = uniq(@basename);
        @basename = sort(@basename);
    }

    $self->samples( \@basename );
    $self->infiles( \@whole );

    $self->write_sample_meta;
}

=head2 write_sample_meta

Write the meta for samples

=cut

sub write_sample_meta {
    my $self = shift;

    return unless $self->verbose;

    print "$self->{comment_char}\n";
    print "$self->{comment_char} Samples: ",
        join( ", ", @{ $self->samples } ) . "\n";
    print "$self->{comment_char}\n";

}


=head2 match_samples

Match samples based on regex written in file_rule

=cut

sub match_samples {
    my $self = shift;
    my $file = shift;
    my $text = shift;

    my @tmp = fileparse($_);
    my ($m) = $tmp[0] =~ qr/$text/;

    return $m;
}
1;
