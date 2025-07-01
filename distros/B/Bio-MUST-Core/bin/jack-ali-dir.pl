#!/usr/bin/env perl
# PODNAME: jack-ali-dir.pl
# ABSTRACT: Jackknife a directory of ALI files

use Modern::Perl '2011';
use autodie;

use Getopt::Euclid qw(:vars);
use Smart::Comments;

use File::Find::Rule;
use List::AllUtils qw(shuffle);
use Path::Class qw(file dir);
use POSIX;

use Bio::MUST::Core;
use Bio::MUST::Core::Constants qw(:dirs);
use aliased 'Bio::MUST::Core::Ali';
use aliased 'Bio::MUST::Core::SeqMask';

# TODO: output FASTA or p80 files?

for my $indir (@ARGV_indirs) {

    ### Processing: $indir
    my @infiles = File::Find::Rule
        ->file()
        ->maxdepth(1)
        ->name( $SUFFICES_FOR{Ali} )
        ->in($indir)
    ;

    # create output directory named after input directory and settings
    my $dirname = dir($indir)->basename
        . "-jack-$ARGV_replicates-$ARGV_width"
        . ($ARGV_del_const ? '-dc' : q{})
    ;
    my $dir = dir($dirname)->relative;
    $dir->mkpath();

    # setup replicate numbering format
    my $field = ceil( log($ARGV_replicates) / log(10) );

    # build replicates
    for my $rep (0..$ARGV_replicates-1) {
        my @pool = shuffle @infiles;

        my @alis;
        my $width = 0;

        ALI:
        while (my $infile = shift @pool) {
            my $ali = Ali->load($infile);

            # optionally delete constant sites
            if ($ARGV_del_const) {
                my $mask = SeqMask->variable_mask($ali);
                $ali->apply_mask($mask);
            }

            # cumulate Ali files while total width is lower than target width
            push @alis, $ali;
            $width += $ali->width;

            last ALI if $width >= $ARGV_width;
        }

        my $subdirname = sprintf 'replicate-%0*d', $field, $rep;
        ### REP dir: "$subdirname has $width sites"
        warn "Not enough ALI files to reach the target width!\n"
            if $width < $ARGV_width;

        # create subdirectory for replicate
        my $subdir = dir($dirname, $subdirname)->relative;
        $subdir->mkpath();

        # write Ali files to new subdirectory
        # Note: we don't use a mere copy to honour the --del-const option
        $_->store( file($subdir, $_->file->basename) ) for @alis;
    }
}

__END__

=pod

=head1 NAME

jack-ali-dir.pl - Jackknife a directory of ALI files

=head1 VERSION

version 0.251810

=head1 USAGE

    jack-ali-dir.pl <indirs> [optional arguments]

=head1 REQUIRED ARGUMENTS

=over

=item <indirs>

Path to input directories containing ALI files [repeatable argument].

=for Euclid: indirs.type: string
    repeatable

=back

=head1 OPTIONAL ARGUMENTS

=over

=item --rep[licates]=<n>

Number of jackknife replicates [default: 100].

=for Euclid: n.type: int >= 0
        n.default: 100

=item --width=<n>

Number of positions to be included in each replicate [default: 100000]. This
actually specifies a lower bound on replicate width. For each replicate, this
script will randomly add ALI files until their combined width reaches becomes
greater than this value. To ignore constant positions in the tally, use the
C<--del-const> option below.

=for Euclid: n.type: int >= 0
        n.default: 100000

=item --del-const

Delete constant sites just as the C<-dc> option of PhyloBayes [default: no].

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
