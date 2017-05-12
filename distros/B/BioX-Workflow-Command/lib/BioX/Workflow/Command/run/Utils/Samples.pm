package BioX::Workflow::Command::run::Utils::Samples;

use MooseX::App::Role;
use File::Find::Rule;
use File::Basename;
use List::Uniq ':all';
use Data::Walk;

use Storable qw(dclone);
use MooseX::Types::Path::Tiny qw/Path Paths AbsPath AbsFile/;
use Path::Tiny;

=head1 BioX::Workflow::Command::run::Utils::Samples

=head2 Variables

=head3 resample

Boolean value get new samples based on indir/sample_rule or no

Samples are found at the beginning of the workflow, based on the global indir variable and the file_find.

Chances are you don't want to set resample to true. These files probably won't exist outside of the indirectory until the pipeline is run.

One example of doing so, shown in the gemini.yml in the examples directory, is looking for uncompressed files, .vcf extension, compressing them, and
then resampling based on the .vcf.gz extension.

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
    is  => 'rw',
    isa => 'ArrayRef',
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

Our samples to process. They are either found through sample_rule, or passed as command line opts

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
q{Supply samples on the command line as --samples sample1 --samples sample2, or find through sample_rule.}
);

=head3 sample

Each time we get the sample we set it.

=cut

has 'sample' => (
    is        => 'rw',
    isa       => 'Str',
    required  => 0,
    default   => '',
    predicate => 'has_sample',
);

=head2 Subroutines

=head3 get_samples

Get basename of the files. Can add optional rules.

sample.vcf.gz and sample.vcf would be sample if the sample_rule is (.vcf)$|(.vcf.gz)$

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

##TODO Add files

sub get_samples {
    my $self = shift;
    my ( @whole, @basename, $find_sample_bydir, $text, $attr );

    #Stupid resample
    $self->get_global_keys;

    if ( $self->has_samples && !$self->resample ) {
        my (@samples) = $self->sorted_samples;
        $self->samples( \@samples );
        return;
    }

    #We need to evaluate the global_dirs incase the indir has a var
    #But we don't keep it around, because that would be madness
    #TODO Fix this we should process these the same way we process rule names
    $attr       = dclone( $self->global_attr );
    $DB::single = 2;
    if ( $attr->indir =~ m/\{\$self/ ) {
        $attr->walk_process_data( $self->global_keys );
    }

    if ( $self->global_attr->can('sample_rule') ) {
        $text = $self->global_attr->sample_rule;
    }
    else {
        $text = $self->sample_rule;
    }

    $find_sample_bydir = 0;

    if ( $attr->find_sample_bydir ) {
        @whole = find(
            directory => name     => qr/$text/,
            maxdepth  => 1,
            in        => $attr->indir,
            extras    => { follow => 1 },
        );

        if (@whole) {
            if ( $whole[0] eq $attr->indir ) {
                shift(@whole);
            }

            #File find puts directory we are looking in, not just subdirs
            @basename = map { basename($_) } @whole;
            @basename = sort(@basename);
        }
    }
    else {
        @whole = find(
            file     => name     => qr/$text/,
            maxdepth => 1,
            extras   => { follow => 1 },
            in       => $attr->indir
        );

        @basename = map { $self->match_samples( $_, $text ) } @whole;
        @basename = uniq(@basename);
        @basename = sort(@basename);
    }

    my @sample_files = map { path($_)->absolute } @whole;
    @sample_files = sort(@sample_files);

    #Throw error if sample don't exist
    $self->samples( \@basename )          if @basename;
    $self->sample_files( \@sample_files ) if @sample_files;

    $self->global_attr->samples( dclone( $self->samples ) );

    if ( $self->has_no_samples ) {
        $self->app_log->warn('No samples were found!');
        $self->app_log->warn(
            "Indir: " . $attr->indir . "\tSearch: " . $text . "\n" );
    }

    $self->write_sample_meta;
}

=head2 match_samples

Match samples based on regex written in sample_rule

=cut

sub match_samples {
    my $self = shift;
    my $file = shift;
    my $text = shift;

    my @tmp = fileparse($_);
    my ($m) = $tmp[0] =~ qr/$text/;

    return $m;
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
}

1;
