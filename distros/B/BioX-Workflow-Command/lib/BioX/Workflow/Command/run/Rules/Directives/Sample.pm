package BioX::Workflow::Command::run::Rules::Directives::Sample;

use MooseX::App::Role;
use namespace::autoclean;

use BioSAILs::Utils::Traits qw(ArrayRefOfStrs);
use MooseX::Types::Path::Tiny qw/Path Paths AbsPath AbsPaths AbsFile/;

=head3 sample_rule

Rule to find files/samples

=cut

has 'sample_rule' => (
    is        => 'rw',
    isa       => 'Str',
    default   => sub { return "(.*)"; },
    clearer   => 'clear_sample_rule',
    predicate => 'has_sample_rule',
);

=head3 maxdepth

Like find -max_depth

=cut

has 'maxdepth' => (
    is      => 'rw',
    default => 1
);

=head3 sample_glob

Alternately, instead of sample_rule use sample_glob to find files. Glob does not
differentiate between files and directories.

=cut

has 'sample_glob' => (
    is        => 'rw',
    isa       => 'Str',
    clearer   => 'clear_sample_glob',
    predicate => 'has_sample_glob',
);

=head2 find_sample_bydir

#Previous find_by_dir

Use this option when you sample names are by directory
The default is to find samples by filename

    /SAMPLE1
        SAMPLE1_r1.fastq.gz
        SAMPLE1_r2.fastq.gz
    /SAMPLE2
        SAMPLE2_r1.fastq.gz
        SAMPLE2_r2.fastq.gz

=cut

has 'find_sample_bydir' => (
    is            => 'rw',
    isa           => 'Bool',
    default       => 0,
    documentation => q{Use this option when you sample names are directories},
    predicate     => 'has_find_sample_bydir',
);

#Same thing - here for backwards compatibility

has 'find_by_dir' => (
    is            => 'rw',
    isa           => 'Bool',
    default       => 0,
    documentation => q{Use this option when you sample names are directories},
    predicate     => 'has_find_by_dir',
    trigger       => sub {
        my $self = shift;
        $self->find_sample_bydir( $self->find_by_dir );
    }
);

=head3 by_sample_outdir

No change - previously by sample outdir

Preface outdir with sample

Instead of

  outdir/
    rule1
    rule2

  outdir/
    Sample_01/
      rule1
      rule2

=cut

has 'by_sample_outdir' => (
    traits        => ['Bool'],
    is            => 'rw',
    isa           => 'Bool',
    default       => 0,
    documentation => q{Use this option when you sample names are directories},
    predicate     => 'has_by_sample_outdir',
    handles       => {
        clear_by_sample_outdir => 'unset',
    },
);

=head3 samples

This is our actual list of samples

=cut

option 'samples' => (
    traits    => ['Array'],
    is        => 'rw',
    isa       => 'ArrayRef',
    default   => sub { [] },
    required  => 0,
    cmd_split => qr/,/,
    handles   => {
        all_samples    => 'elements',
        has_samples    => 'count',
        has_no_samples => 'is_empty',
        sorted_samples => 'sort',
    },
    documentation =>
q{Supply samples on the command line as --samples sample1 --samples sample2, or find through sample_rule.}
);

option 'exclude_samples' => (
    traits    => ['Array'],
    is        => 'rw',
    isa       => 'ArrayRef',
    default   => sub { [] },
    required  => 0,
    cmd_split => qr/,/,
    handles   => {
        all_exclude_samples    => 'elements',
        has_exclude_samples    => 'count',
        has_no_exclude_samples => 'is_empty',
        sorted_exclude_samples => 'sort',
    },
    documentation =>
q{Exclude samples from analysis --exclude_samples sample1 --exclude_samples sample2}
);

has 'sample' => (
    is        => 'rw',
    isa       => 'Str',
    predicate => 'has_sample',
    clearer   => 'clear_sample',
    required  => 0,
);

=head3 resample

Boolean value get new samples based on indir/sample_rule or no

Samples are found at the beginning of the workflow, based on the global indir
variable and the file_find.

Chances are you don't want to set resample to true. These files probably won't
exist outside of the indirectory until the pipeline is run.

One example of doing so, shown in the gemini.yml in the examples directory, is
looking for uncompressed files, .vcf extension, compressing them, and then
resampling based on the .vcf.gz extension.

=cut

has 'resample' => (
    isa       => 'Bool',
    is        => 'rw',
    default   => 0,
    predicate => 'has_resample',
    clearer   => 'clear_resample',
);

=head3 sample_files

Infiles to be processed

=cut

has 'sample_files' => (
    is     => 'rw',
    isa    => AbsPaths,
    coerce => 1,
);

1;
