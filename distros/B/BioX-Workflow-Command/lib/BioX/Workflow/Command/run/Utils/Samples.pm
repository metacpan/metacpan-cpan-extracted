package BioX::Workflow::Command::run::Utils::Samples;

use MooseX::App::Role;
use namespace::autoclean;

with 'BioX::Workflow::Command::run::Rules::Directives::Sample';
with 'BioX::Workflow::Command::run::Rules::Rules';

use File::Find::Rule;
use File::Basename;
use File::Glob;
use List::Util qw(uniq);

use Storable qw(dclone);
use Path::Tiny;

=head1 BioX::Workflow::Command::run::Utils::Samples

=head2 Variables


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

sub get_samples {
    my $self = shift;

    #Stupid resample
    $self->get_global_keys;

    my $exists = $self->check_sample_exist;
    return if $exists;

    #We need to evaluate the global_dirs incase the indir has a var
    #But we don't keep it around, because that would be madness
    my $attr = dclone( $self->global_attr );
    if ( $attr->indir =~ m/\{\$/ ) {
        $attr->walk_process_data( $self->global_keys );
    }

    my $text = $self->get_sample_rule;
    $self->find_sample_glob( $attr, $text );
    $self->find_sample_file_find_rule( $attr, $text );

    if ( $self->has_no_samples ) {
        $self->app_log->warn('No samples were found!');
        $self->app_log->warn(
            "Indir: " . $attr->indir . "\tSearch: " . $text . "\n" );
    }

    $self->remove_excluded_samples;
    $self->write_sample_meta;
}

sub remove_excluded_samples {
    my $self = shift;

    return unless $self->has_samples;
    return unless $self->has_exclude_samples;

    my %sample_hash = ();
    map { $sample_hash{$_} = 1 } @{ $self->samples };

    foreach my $sample ( $self->all_exclude_samples ) {
        delete $sample_hash{$sample};
    }

    my @new_samples = keys %sample_hash;
    @new_samples = sort(@new_samples);
    $self->samples( \@new_samples );
}

sub find_sample_glob {
    my $self = shift;
    my $attr = shift;
    my $text = shift;

    return if $self->has_samples;
    return unless $attr->has_sample_glob;

    my @sample_files = glob( $attr->sample_glob );
    if ( !@sample_files ) {
        $self->app_log->warn( "No samples were found with the glob pattern '"
              . $attr->sample_glob
              . "'" );
        return;
    }

    @sample_files = sort(@sample_files);
    $self->sample_files( \@sample_files ) if @sample_files;

    my @basename = map { $self->match_samples( $_, $text ) } @sample_files;
    if (@basename) {
        @basename = uniq(@basename);
        @basename = sort(@basename);
        $self->samples( \@basename );
    }

    $self->global_attr->samples( dclone( $self->samples ) );
    $self->global_attr->sample_files( dclone( $self->sample_files ) );
}

sub get_sample_rule {
    my $self = shift;
    my $text;

    #Backwards compatibility
    #For both file_rule and sample_rule
    if ( $self->first_index_global_keys( sub { $_ eq 'file_rule' } ) != -1 ) {
        $text = $self->global_attr->sample_rule;
    }
    elsif (
        $self->first_index_global_keys( sub { $_ eq 'sample_rule' } ) != -1 )
    {
        $text = $self->global_attr->sample_rule;
    }
    else {
        $text = $self->sample_rule;
    }
}

sub find_sample_file_find_rule {
    my $self = shift;
    my $attr = shift;
    my $text = shift;

    return if $self->has_samples;

    my ( @whole, @basename, @sample_files, $find_sample_bydir );

    $find_sample_bydir = 0;

    if ( $attr->find_sample_bydir ) {
        @whole = find(
            directory => name     => qr/$text/,
            maxdepth  => $attr->maxdepth,
            in        => $attr->indir,
            extras    => { follow => 1 },
        );

        if (@whole) {
            if ( $whole[0] eq $attr->indir ) {
                shift(@whole);
            }
        }
    }
    else {
        @whole = find(
            file     => name     => qr/$text/,
            maxdepth => $attr->maxdepth,
            extras   => { follow => 1 },
            in       => $attr->indir
        );
    }
    @basename = map { $self->match_samples( $_, $text ) } @whole;

    @sample_files = map { path($_)->absolute } @whole;
    @sample_files = sort(@sample_files);

    if (@basename) {
        @basename = uniq(@basename);
        @basename = sort(@basename);
        $self->samples( \@basename );
    }
    $self->sample_files( \@sample_files ) if @sample_files;

    $self->global_attr->samples( dclone( $self->samples ) );
}

sub check_sample_exist {
    my $self = shift;

    my $exists = 0;
    if ( $self->has_samples && !$self->resample ) {
        my (@samples) = $self->sorted_samples;
        $self->samples( \@samples );
        ## Fixes Issue #19
        $self->global_attr->samples( \@samples );
        $self->app_log->info('Samples passed in on command line.');
        $exists = 1;
    }
    elsif ( $self->global_attr->has_samples ) {
        my (@samples) = @{ $self->global_attr->samples };
        @samples = sort(@samples);
        $self->samples( \@samples );
        $self->app_log->info('Samples were defined in the global key.');
        $exists = 1;
    }

    $self->write_sample_meta if $exists;
    return $exists;
}

=head2 match_samples

Match samples based on regex written in sample_rule

=cut

sub match_samples {
    my $self = shift;
    my $file = shift;
    my $text = shift;

    if ( $text =~ m/\(/ ) {
        my @tmp = fileparse($file);
        my ($m) = $tmp[0] =~ qr/$text/;

        return $m;
    }
    else {
        my @tmp = fileparse($file);
        return $tmp[0];
    }
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
