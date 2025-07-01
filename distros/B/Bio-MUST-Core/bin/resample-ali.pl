#!/usr/bin/env perl
# PODNAME: resample-ali.pl
# ABSTRACT: Resample ALI files using (variable length) bootstrap or jackknife

use Modern::Perl '2011';
use autodie;

use File::Basename;
use Getopt::Euclid qw(:vars);
use Path::Class qw(dir file);
use POSIX;
use Smart::Comments;

use Bio::MUST::Core;
use Bio::MUST::Core::Utils qw(change_suffix append_suffix);
use aliased 'Bio::MUST::Core::Ali';
use aliased 'Bio::MUST::Core::SeqMask::Weights';


# setup resampling method
my $method = $ARGV_resampling . '_masks';

# setup replicate numbering format
my $field = ceil( log($ARGV_replicates) / log(10) );

for my $infile (@ARGV_infiles) {

    ### Processing: $infile
    my $ali = Ali->load($infile);

    # create output directory named after input file and resampling mode
    my $outdir = append_suffix(
        change_suffix($infile, q{}), "-$ARGV_resampling"
    );

    for my $width (@ARGV_width) {

        # create output subdirectory named after width
        my $subdir = dir( $outdir, 'width-' . $width )->relative;
        ### REPDIR: $subdir->stringify
        $subdir->mkpath();

        # generate resampling masks for Ali
        my @masks = Weights->$method(
            $ali, { 'rep' => $ARGV_replicates, 'width' => $width }
        );

        # apply masks to generate pseudo-replicates
        for my $rep (0..$ARGV_replicates-1) {
            my $new_ali = $masks[$rep]->filtered_ali($ali);
            my $filename = sprintf 'replicate-%0*d.ali', $field, $rep;
            ### REP file: $filename
            my $outfile = file($subdir, $filename);
            $new_ali->store($outfile);
        }
    }
}

__END__

=pod

=head1 NAME

resample-ali.pl - Resample ALI files using (variable length) bootstrap or jackknife

=head1 VERSION

version 0.251810

=head1 USAGE

    resample-ali.pl <infiles> [optional arguments]

=head1 REQUIRED ARGUMENTS

=over

=item <infiles>

Path to input ALI files [repeatable argument].

=for Euclid: infiles.type: readable
    repeatable

=back

=head1 OPTIONAL ARGUMENTS

=over

=item --resampling=<mode>

Mode of resampling to perform on the ALI [default: bootstrap]. The following
modes are available: bootstrap and jackknife.

=for Euclid: mode.type:       string, mode eq 'bootstrap' || mode eq 'jackknife'
    mode.type.error: <mode> must be one of bootstrap or jackknife (not mode)
    mode.default:    'bootstrap'

=item --rep[licates]=<n>

Number of pseudo-replicates [default: 100].

=for Euclid: n.type: int >= 0
        n.default: 100

=item --width=<n>...

Number of positions to be included in each pseudo-replicate [default: 1]. When
specified as a fraction between 0 and 1 (included), it is interpreted as
relative to the width of the ALI. Thus 10000 would mean 10,000 sites whereas
0.5 would mean half the width of the ALI. Hence, the default is to generate
pseudo-replicates of the same width as the ALI. Multiple values can be
provided if they are whitespace-separated.

=for Euclid: n.type: number
        n.default: [ 1 ]

=item --version

=item --usage

=item --help

=item --man

Print the usual program information

=back

=head1 AUTHOR

Denis BAURAIN <denis.baurain@uliege.be>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by University of Liege / Unit of Eukaryotic Phylogenomics / Denis BAURAIN.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
