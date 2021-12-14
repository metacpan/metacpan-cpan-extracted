#!/usr/bin/env perl
# PODNAME: prune-outliers.pl
# ABSTRACT: Identify and discard outliers based on all-versus-all BLAST searches
# CONTRIBUTOR: Amandine BERTRAND <amandine.bertrand@doct.uliege.be>
# CONTRIBUTOR: Loic MEUNIER <loic.meunier@doct.uliege.be>

use Modern::Perl '2011';
use autodie;

use File::Basename;
use File::Find::Rule;
use Getopt::Euclid qw(:vars);
use Path::Class qw(dir file);
use Smart::Comments;

use Bio::MUST::Core;
use Bio::MUST::Core::Constants qw(:dirs);
use Bio::MUST::Drivers;

use aliased 'Bio::MUST::Core::Ali';
use aliased 'Bio::MUST::Core::IdList';

my $qr_class = 'Bio::MUST::Core::Ali::Temporary';
my $db_class = 'Bio::MUST::Drivers::Blast::Database';
my $db_tmp_class = 'Bio::MUST::Drivers::Blast::Database::Temporary';

for my $indir (@ARGV_indirs) {

    ### Processing: $indir
    my @infiles = File::Find::Rule
        ->file()
        ->name( $SUFFICES_FOR{Ali} )
        ->in($indir);

    for my $infile (@infiles) {
        ### Processing: $infile

        # BLASTP/N all versus all
        my $db = $db_tmp_class->new( seqs => file($infile) );

        # Note: this is a special case where query and database are identical
        # (but autodetection won't work because query is just a filename)
        my $query = $db->filename;
        my $pgm   = $db->type eq 'nucl' ? 'blastn' : 'blastp';

        my $parser = $db->$pgm($query, {
            -evalue => $ARGV_evalue,
            -outfmt => 6,
            $db->type eq 'nucl' ? ( -task => 'blastn' ) : ()
        } );

        # parsing
        my %count_for;
        while ( my $hit = $parser->next_hit ) {
            my $query_id = $db->long_id_for( $hit->query_id );
            $count_for{$query_id}++;
        }

        my $outdir = dir($indir)->basename . '-pruned';

        for (my $t = $ARGV_min_ident; $t <= $ARGV_max_ident; $t += 0.1) {

            my @ids
                = grep { ($count_for{$_} / keys %count_for) >= $t }
                  grep {  $count_for{$_} >= $ARGV_min_hits } keys %count_for
            ;

            ### threshold: $t . ' - ' . scalar @ids . ' seqs kept out of ' . scalar keys %count_for

            my $ali = Ali->load($infile);
            $ali->dont_guess if $ARGV_noguessing;

            my $list = IdList->new( ids => \@ids );
            my $new_ali = $list->filtered_ali($ali);

            # create output dirs named after input dir and identity threshold
            my $subdir = dir( $outdir, $t )->relative;
            $subdir->mkpath();

            # store Ali in corresponding dir
            my ($filename) = fileparse($infile);
            my $outfile = file($subdir, $filename)->stringify;
            $new_ali->store($outfile);
        }
    }

}

__END__

=pod

=head1 NAME

prune-outliers.pl - Identify and discard outliers based on all-versus-all BLAST searches

=head1 VERSION

version 0.213470

=head1 USAGE

	prune-outliers.pl <indirs> [options]

=head1 REQUIRED ARGUMENTS

=over

=item <indirs>

Path to input directories containing ALI (or FASTA) files [repeatable argument].

=for Euclid: indirs.type: string
    repeatable

=back

=head1 OPTIONS

=over

=item --evalue=<n>

evalue threshold for a hit to be considered during the all-versus-all BLAST
searches [default: n.default].

=for Euclid: n.type: num
    n.default: 1e-10

=item --min-ident=<n> | --min_ident=<n>

Minimal identity value used for selecting sequences that match at least this
proportion in the all-versus-all BLAST searches [default: n.default]. An output
dir will be created by step of 0.1 between the min threshold and max threshold.

=for Euclid: n.type: num
    n.default: 0.3

=item --max-ident=<n> | --max_ident=<n>

Maximum percent value used for selecting sequences that match at least this
proportion in the all versus all BLAST searches [default: n.default]. An output
dir will be created by step of 0.1 between the min threshold and max threshold.

=for Euclid: n.type: num
    n.default: 0.8

=item --min-hits=<n> | --min_hits=<n>

Minimum number of hits in the all-versus-all BLAST searches required for a
sequence to be retained in the output file [default: n.default].

=for Euclid: n.type: num
    n.default: 10

=item --[no]guessing

[Don't] guess whether sequences are aligned or not [default: yes].

=item --version

=item --usage

=item --help

=item --man

Print the usual program information

=back

=head1 AUTHOR

Denis BAURAIN <denis.baurain@uliege.be>

=head1 CONTRIBUTORS

=for stopwords Amandine BERTRAND Loic MEUNIER

=over 4

=item *

Amandine BERTRAND <amandine.bertrand@doct.uliege.be>

=item *

Loic MEUNIER <loic.meunier@doct.uliege.be>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by University of Liege / Unit of Eukaryotic Phylogenomics / Denis BAURAIN.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
