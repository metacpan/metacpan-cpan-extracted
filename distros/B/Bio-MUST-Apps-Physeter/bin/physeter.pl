#!/usr/bin/env perl
# PODNAME: physeter.pl
# ABSTRACT: Taxonomic parser for BLAST reports
# CONTRIBUTOR: Valerian LUPO <valerian.lupo@doct.uliege.be>
# CONTRIBUTOR: Mick VAN VLIERBERGHE <mvanvlierberghe@doct.uliege.be>
# CONTRIBUTOR: Luc CORNET <luc.cornet@uliege.be>

use Modern::Perl '2011';
use autodie;

use Smart::Comments '###';

use Getopt::Euclid qw(:vars);

use File::Basename;
use File::Find::Rule;
use File::Slurp;
use Path::Class 'file';
use POSIX qw(ceil);
use List::AllUtils qw(apply sum count_by shuffle);
use Tie::IxHash;

use Bio::MUST::Core;
use aliased 'Bio::MUST::Core::Ali';
use aliased 'Bio::MUST::Core::Taxonomy';
use Bio::FastParsers;
use aliased 'Bio::FastParsers::Blast::Table';


die <<'EOT' if $ARGV_tax_min_hits > $ARGV_tax_max_hits;
--tax-max-hits must be greater or equal to --tax-min-hits; aborting!
EOT

# build taxonomy object
my $tax = Taxonomy->new_from_cache(tax_dir => $ARGV_taxdir);

# TODO: fix this (make it optional?)
# build labeler
my $labeler = $tax->tax_labeler_from_list($ARGV_taxon_list);

# k-folds method
my $subsets;
if ($ARGV_kfold) {
    srand($ARGV_kfold_seed) if $ARGV_kfold_seed;
    $subsets = split_db($ARGV_kfold);
}

my $seq_n;      # improve this
my @results;

FILE:
for my $infile (@ARGV_infiles) {

    ### Processing: $infile
    my ($basename) = fileparse($infile, qr{\.[^.]*}xms);

    # try to fetch expected taxon from CLI...
    my $query_org = q{};
    my $exp_tax = $ARGV_expected_taxon;

    unless ($ARGV_auto_detect) {
        # ... otherwise determine it (and query org) from infile basename
        unless ($exp_tax) {
            # TODO: allow for a regex to capture GCA number
            my @taxonomy = $tax->get_taxonomy($basename);
            $query_org = $taxonomy[-1];
            $exp_tax = $labeler->classify(
                \@taxonomy, { greedy => $ARGV_greedy_taxa }
            );
        }

        # skip infiles with undetermined expected taxon
        unless ($exp_tax) {
            warn <<"EOT";
Warning: cannot determine expected taxon for organism; skipping infile!
Check <infiles> basename ($basename) or --taxon-list ($ARGV_taxon_list) content.
EOT
            next FILE;
        }
    }

    # determine number of seqs
    my $fasfile = file($ARGV_fasta_dir, "$basename.fasta");
    $seq_n = Ali->instant_count($fasfile);

    unless ($ARGV_kfold) {
        # read BLAST report infile and compute LCAs
        my $lca_for = parse_report($infile, $query_org);

        # determine expected taxon from BLAST infile
        $exp_tax = auto_detect($lca_for) if $ARGV_auto_detect;

        # create kraken report if asked to do so
        if ($ARGV_kraken) {
            my $outfile = "$basename-kraken.tsv";
            store_kraken($outfile, $lca_for);
        }

        # create anvio report if asked to do so
        if ($ARGV_anvio) {
            my $outfile = "$basename-anvio.tsv";
            store_anvio($outfile, $lca_for);
        }

        # create krona report if asked to do so
        # TODO: account for unclassified?
        if ($ARGV_krona) {
            my $outfile = "$basename-krona.tsv";
            store_krona($outfile, $lca_for);
        }

        # create a LCA report if asked to do so
        if ($ARGV_lca) {
            my $outfile = "$basename-lca.tsv";
            store_lca($outfile, $lca_for);
        }

        format_results($lca_for, $basename, $exp_tax);
    }

    if ($ARGV_kfold) {

		# read BLAST report infile in kfold mode
        my @kfold_lcas = map {
            parse_report($infile, $query_org, $_)
        } @{$subsets};

        # TODO: try to refactor to avoid code redundancy here
        if ($ARGV_auto_detect) {
            # determine expected taxon from BLAST infile
            my @exp_taxs = map { auto_detect($_) } @kfold_lcas;
            my $len = @kfold_lcas;
            format_results( $kfold_lcas[$_], $basename, $exp_taxs[$_] )
                for 0..$len-1;
        }
        else {
            format_results( $_, $basename, $exp_tax )
                for @kfold_lcas;
        }
    }
}

# store default report
store_results($ARGV_outfile, \@results);

# functions

sub split_db {
    my $infile = shift;

    # TODO: use slurp method from Path::Class to avoid another module
    # TODO: slightly revise naming (e.g. no plural for @shuffle)
    my @taxids = read_file($infile, chomp => 1);
    my @shuffle = shuffle @taxids;
    my $sub_size = ceil( @shuffle / 10 );

    my @subsets;
    while (@shuffle) {
        push @subsets, [ splice @shuffle, 0, $sub_size ];
    }

    return \@subsets;
}

sub parse_report {
    my $infile    = shift;
    my $query_org = shift;
    my $taxids    = shift // ();

    # setup boolean filter for current database subset (if any)
	my %unwanted = map { $_ => 1 } @{$taxids};

    my $report = Table->new( file => $infile );

    tie my %lca_for, 'Tie::IxHash';

    my $curr_query = q{};
    my $best_score;
    my @relatives;

    my $method = 'next_hit';

    HIT:
    while (my $hit = $report->$method) {

        # at each new query...
        if ($hit->query_id ne $curr_query) {

            # store query LCA if enough relatives
            # TODO: make Taxonomy:: class for collections of lineages
            if (@relatives >= $ARGV_tax_min_hits) {
                $lca_for{$curr_query} = {
                    taxon => scalar $tax->compute_lca(
                        $ARGV_tax_min_lca_freq, @relatives),
                    rel_n => scalar @relatives,
                };
            }

            # prepare analysis of new query
            $curr_query = q{};
            $best_score = undef;
            @relatives = ();

            $method = 'next_hit';
        }

        # skip extra (unused) relatives
        if (@relatives >= $ARGV_tax_max_hits) {
            $method = 'next_query';
            next HIT;
        }

        # skip weak hits (classical mode)
        next HIT if $hit->hsp_length       < $ARGV_tax_min_len;
        next HIT if $hit->percent_identity < $ARGV_tax_min_ident;
        next HIT if $hit->bit_score        < $ARGV_tax_min_score;

        # fetch hit taxonomy and org
        # optimized code (requires taxon_id|accession seq_ids)
        my $taxon_id = ( split m{\|}xms, $hit->hit_id )[0];

        # k-folds mode (skip hits from current database subset)
        next HIT if $ARGV_kfold && $unwanted{$taxon_id};

        my @taxonomy = $tax->get_taxonomy($taxon_id);
        # regular code (more general)
#       my @taxonomy = $tax->get_taxonomy_from_seq_id( $hit->hit_id );
        my $hit_org = $taxonomy[-1];

        # skip self hits (corresponding to query_org)
        next HIT if $hit_org eq $query_org;

        # skip weak hits (MEGAN-like mode)
        $best_score //= $hit->bit_score;
        next HIT if $hit->bit_score < $ARGV_tax_score_mul * $best_score;

        # retain hit taxonomy as relative
        $curr_query = $hit->query_id;
        push @relatives, \@taxonomy;
    }

    # store last query LCA if enough relatives
    if ($curr_query && @relatives >= $ARGV_tax_min_hits) {
        $lca_for{$curr_query} = {
            taxon => scalar $tax->compute_lca(
                $ARGV_tax_min_lca_freq, @relatives),
            rel_n => scalar @relatives,
        };
    }

    return \%lca_for;
}

sub auto_detect {
    my $lca_for = shift;

    # TODO: implement and compare the opposite approach where we first label
    # then determine the exp_tax...

    # count LCA lineage occurrences (i.e., sort | uniq -c)
    my %count_for = count_by { join q{;}, @{ $_->{taxon} } } values %{$lca_for};

    # compute LCA proportions
    my @taxa = sort {
        $count_for{$b} <=> $count_for{$a}
    } keys %count_for;

    my $exp_tax = $labeler->classify(
        $taxa[0], { greedy => $ARGV_greedy_taxa }
    );

    return $exp_tax;
}

sub tabulate_lcas {
    my $lca_for = shift;
    my $exp_tax = shift;

    my $self_n    = 0;
    my $foreign_n = 0;
    my $unknown_n = 0;

    my %count_for;

    # tabulate LCAs
    while ( my ($query_id, $lca) = each %{$lca_for} ) {

        # label LCA
        my $got_tax = $labeler->classify(
            $lca->{taxon}, { greedy => $ARGV_greedy_taxa }
        );

        # update counts based on LCA label
        unless ($got_tax)                  { $unknown_n++ }
        elsif  ($got_tax eq $exp_tax)      {    $self_n++ }
        else                               { $foreign_n++;
                                             $count_for{$got_tax}++;
        }
    }

    # compute class proportions
    # TODO: decide on a data structure to include all this
    my $self_p    = sprintf "%.2f", 100 * $self_n    / $seq_n;
    my $foreign_p = sprintf "%.2f", 100 * $foreign_n / $seq_n;
    my $unknown_p = sprintf "%.2f", 100 * $unknown_n / $seq_n;
    my $unclass_p = sprintf "%.2f", 100 - ($self_p + $foreign_p + $unknown_p);

    # compute LCA proportions
    my @taxa = sort {
        $count_for{$b} <=> $count_for{$a} || $a cmp $b
    } keys %count_for;
    my @details = map {
        sprintf "%s=%.2f", $_, 100 * $count_for{$_} / $seq_n
    } @taxa;

    my $result = join "\t", $self_p, $foreign_p, $unknown_p, $unclass_p,
        join q{,}, @details;

    return $result;
}

sub format_results {
	my $lca_for  = shift;
	my $basename = shift;
	my $exp_tax  = shift;

    # compute mean number of relatives used for LCA inference
    my @rel_counts = map { $_->{rel_n} } values %{$lca_for};
    my $rel_mean
        = @rel_counts ? sprintf "%.2f", sum(@rel_counts) / @rel_counts : 'NA';

    # format default report line
    # TODO: better specify this format
    push @results, join "\t", $basename, $exp_tax,
       tabulate_lcas($lca_for, $exp_tax), $rel_mean;

    return;
}

sub store_results {
    my $outfile = shift;
    my $results = shift;

    open my $out, '>', $outfile;
    say {$out} join "\n", @{$results};

    return;
}

# TODO: improve and move to BMC::Taxonomy
sub store_lca {
    my $outfile = shift;
    my $lca_for = shift;

    open my $out, '>', $outfile;

    say {$out} '# ' . join "\t", qw(query_id rel_n lca_lineage);
    while ( my ($query_id, $lca) = each %{$lca_for} ) {
        say {$out} join "\t",
            $query_id, $lca->{rel_n}, join q{; }, @{ $lca->{taxon} };
    }

    return;
}

# TODO: move to BMC::Taxonomy
sub store_anvio {
    my $outfile = shift;
    my $lca_for = shift;

    open my $out, '>', $outfile;
    my @ranks = qw(superkingdom phylum class order family genus species);
    say {$out} join "\t", 'gene_callers_id', map { "t_$_" } @ranks;

    while ( my ($query_id, $lca) = each %{$lca_for} ) {
        my $taxon_id = $tax->get_taxid_from_taxonomy( $lca->{taxon} );
        my @taxa = $tax->get_taxa_from_taxid($taxon_id, @ranks);
        say {$out} join "\t", $query_id, apply { s/undef//xms } @taxa;
    }

    return;
}

# TODO: move to BMC::Taxonomy
# TODO: check how to avoid OTUsamples2krona.sh (different format then)
sub store_krona {
    my $outfile = shift;
    my $lca_for = shift;

    open my $out, '>', $outfile;
    say {$out} join "\t", qw(sample lineage);

    my %count_for = count_by { join q{;}, @{ $_->{taxon} } } values %{$lca_for};

    for my $lineage (sort keys %count_for) {
        my $count = $count_for{$lineage};
        $lineage =~ s/\s/_/xmsg;
        say {$out} join "\t", $count, $lineage;
    }

    return;
}

# TODO: move to BMC::Taxonomy
sub store_kraken {
    my $outfile = shift;
    my $lca_for = shift;

# 4. A rank code, indicating (U)nclassified, (R)oot, (D)omain, (K)ingdom,
#    (P)hylum, (C)lass, (O)rder, (F)amily, (G)enus, or (S)pecies.
#    Taxa that are not at any of these 10 ranks have a rank code that is
#    formed by using the rank code of the closest ancestor rank with
#    a number indicating the distance from that rank.  E.g., "G2" is a
#    rank code indicating a taxon is between genus and species and the
#    grandparent taxon is at the genus rank.

    open my $out, '>', $outfile;

    # count LCA lineage occurrences (i.e., sort | uniq -c)
    my %count_for = count_by { join q{;}, @{ $_->{taxon} } } values %{$lca_for};

    # compute unclassified number
    my $unclass_n = $seq_n - sum values %count_for;

    # generate kraken-like rank_codes
    my %code_for = map {
        $_ eq 'domain' ? 'superkingdom' : $_ => uc substr($_, 0, 1)
    } qw(unclassified root domain kingdom phylum class order family genus species);

    # setup two main levels of taxonomic tree
    my %tree = (
        unclassified => {
            taxon_id  => 0,
            rank_code => $code_for{unclassified},
            coverage  => $unclass_n,
            count     => $unclass_n,
            # no children for unclassified
        },
        root => {
            taxon_id  => 1,
            rank_code => $code_for{root},
            coverage  => 0,
            count     => 0,
            children  => {},
        },
    );

    # break all LCA lineages down into decorated taxonomic tree
    for my $lineage (reverse sort keys %count_for) {
        my $count = $count_for{$lineage};

        # fetch taxonomy with ranks from lineage
        my $taxon_id = $tax->get_taxid_from_taxonomy($lineage);
        my @taxonomy = $tax->get_taxonomy_with_levels($taxon_id);

        # start count propagation with tree root
        # Note: could we get root count different from zero?
        $tree{root}{coverage} += $count;

        # setup lineage break-down into taxa
        my $tree_ref = $tree{root}{children};
        my $curr_rank_code = $code_for{root};
        my @taxa;           # to keep track of partial lineage

        while (my $taxon = shift @taxonomy) {

            # extract next taxon and rank
            my ($taxon, $rank) = @{$taxon};
            push @taxa, $taxon;

            # create taxon entry (if not yet existing)
            unless ($tree_ref->{$taxon}{taxon_id}) {

                # fetch taxon_id for taxon (using partial lineage as fall-back)
                $tree_ref->{$taxon}{taxon_id}
                    = $tax->get_taxid_from_taxonomy( \@taxa );

                # recode rank (= kraken-like rank_code)
                my $rank_code = $code_for{$rank};           # try standard rank
                $rank_code //= length($curr_rank_code) == 1      # or incr last
                    ? $curr_rank_code . '1' : ++$curr_rank_code; # rank (from 1)
                $tree_ref->{$taxon}{rank_code} = $rank_code;

                # setup count (this avoids tracking undef later)
                $tree_ref->{$taxon}{count} = 0;
            }

            # propagate count to taxon (= kraken-like coverage)
            $tree_ref->{$taxon}{coverage} += $count;

            # setup children entry if lineage not yet exausted
            # ... and remember rank_code (in case next taxon has no rank)
            if (@taxonomy) {
                $curr_rank_code = $tree_ref->{$taxon}{rank_code};
                $tree_ref->{$taxon}{children} //= {};
                $tree_ref = $tree_ref->{$taxon}{children};
            }

            # otherwise cumulate count for taxon (= kraken-like count)
            else {
                $tree_ref->{$taxon}{count} += $count;
            }
        }
    }

    # output taxonomic tree recursively
    _dump_tree_level( $out, 0, $_, $tree{$_} ) for qw(unclassified root);

    return;
}

sub _dump_tree_level {
    my ($out, $depth, $taxon, $tree_ref) = @_;

    say {$out} join "\t",
        (sprintf "%5.2f", 100.0 * $tree_ref->{coverage} / $seq_n),
        $tree_ref->{coverage},
        $tree_ref->{count},
        $tree_ref->{rank_code},
        $tree_ref->{taxon_id},
        q{ } x ($depth * 2) . $taxon
    ;

    my $children_for = $tree_ref->{children};
    return unless $children_for;

    my @children = sort {
        $children_for->{$b}{coverage} <=> $children_for->{$a}{coverage}
    } keys %{$children_for};

    _dump_tree_level( $out, $depth+1, $_, $children_for->{$_} ) for @children;

    return;
}

__END__

=pod

=head1 NAME

physeter.pl - Taxonomic parser for BLAST reports

=head1 VERSION

version 0.202960

=head1 USAGE

                                              |||||\\\\\\\\\\\\\\\\\|||
                                         ||\\\\||||                |||\\\||
                                    ||\\\|||                            |\\\
                                 |\\\|        ||||||              ||\\\\\\@@@\|       |||||
       @                      |\\\|        |\\\\\\\\\\\||       \\\\@@@@@@@@@@@\\  |\\||||\\|
      \@@|               \|||\\|    \|   |\\\|        |\\\\    \\@@@@@@@@@@@@@@@@\\\       |\\
       \@@@\|            \\||\      |\| \\\             |\\\\\\|\@@@@@@@@@@@@@@@@@@|         \\|
       \@@@@@\|         |\||\|        \\\\     ||\\\\\\\\\\@@@\\@@@@@@@@@@@@@@@@@@@\    |\\\\\\\\\\
      \@@@@@@@@\       \\||           |\\\|   \\\|      @@@@@\\@@@@@@@@@@@@@@@@@@@@@|  |\\   |\\
     \@@@@@@@@@@\|                    \\||\\\\\|   @@@@@@\\\\\@@@@@@@@@@@@@@@@@@@@@\   \\     \\|
     \\@@@@@@@@@@@@@@\\               \\|      @@@@@@@@\\\@@@@@@@@@@@@@@@@@@@@@@@@\\  |\\      \\
  \\@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@\\@@@@@@@@@@@@@\\@@@@@@@@@@@@@@@@@@@@@@@@\\||\\\\     |\\|
  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@|@@@@@@@@@@@@\\@@@@@@@@@@@@@| |@@@@@\\\\|||\\\\      |\\|
 |@@@@@@@@\\| |\\@@@@@@@@@@@@@@@@@@@@\\@@@@@@@@@@@@\@@@@@@@@@|@@@@@@@@\\||||@@@@@@@\     \\
 \@@@@@\\|       \\@@@@@@@@@@@@@@@@@\\@@@@@@@@@@@@@@@@@@@@@@@\|@@@@@@\\\\\\\@@@@@\      \\
\@@@\\|            \\@@@@@@@@@@@@@@\\@@@@@@@@@@@@@@@@@@@@@@@@\\@@@@@\||\||||\|          \\
                     \\@@@@@@@@@@@\\@@@@@@@@@@@@@@@@@@@@@@@@@@\\\@\\\|\\|||\             \
                       |\@@@@@@@\\\@@@@@@@@@@@@@@@@@@@@@@@@@@@\\|| |\|\|||\|
                          |@@@\\\@@@@@@@@@@@@@@@@@@@@@@@@\\\\      |\|\||\|
                       |\\\\\\\||@@@@@@@@@@@@@@@@@@@@@\|  |\|       \|\||\
                     |\\\\||                    \@@@\|   |\|        \|\|\
                                                |@@\   |\\        |\\\\\\|
                                                \@     \|         \||\\||\
                                                      |\          |\|\||\
                                                                   |\\\|
                                                                    \\

    physeter.pl <infiles> --outfile=<file> --taxdir=<dir> --taxon-list=<file> \
        [optional arguments]

=head1 REQUIRED ARGUMENTS

=over

=item <infiles>

Path to input BLAST report files [repeatable argument].

Report files must be named <assembly_accession.blastx> unless the organism does
not have an assembly accession. In the latter case, use the C<--exp-tax> option
to provide the expected taxonomy of the organism.

=for Euclid: infiles.type: readable
    repeatable

=item --outfile=<file>

Path to output file.

=for Euclid: file.type: writable

=for Euclid: file.type: readable

=item --taxdir=<dir>

Path to local mirror of the NCBI Taxonomy database.

=for Euclid: dir.type: string

=item --taxon-list=<file>

List of taxa to consider when looking for foreign sequences. This labeler file
is used throughout the program to truncate LCA lineages at specific taxonomic
levels (which can vary from one lineage to the other).

=back

=head1 OPTIONS

=over

=item --fasta-dir=<dir>

Path to the directory holding the FASTA query files [default: dir.default].
FASTA files must have the same basenames as BLAST infiles.

=for Euclid: dir.type: readable
    dir.default: './'

=item --exp[ected]-tax[on]=<string>

Organism taxon [default: automatic]. Use this option when the organism does not
have an assembly accession. The specified taxon must be in the file provided
with the C<--taxon-list> option.

=for Euclid: string.type: string

=item --auto-detect

Determine organism taxon based on BLAST infile [default: no].

=item --greedy-taxa

Enable greedy behavior when interpreting the ambiguous taxa provided in the
required argument C<--taxon-list> [default: no].

=item --tax-min-ident=<n>

Minimum identity percentage to consider a hit when computing a LCA [default:
n.default].

=for Euclid: n.type: +number
    n.default: 0

=item --tax-min-len=<n>

Minimum alignment length to consider a hit when computing a LCA [default:
n.default].

=for Euclid: n.type: +integer
    n.default: 0

=item --tax-min-score=<n>

Minimum bit score to consider a hit when computing a LCA [default: n.default].

=for Euclid: n.type: +integer
    n.default: 80

=item --tax-score-mul=<n>

Bit score reduction allowed when accumulating hits for LCA inference (MEGAN-like
algorithm) [default: n.default].

=for Euclid: n.type: +number
    n.default: 0.95

=item --tax-min-hits=<n>

Minimum number of hits to use when computing LCAs [default: n.default]. Must
be lower or equal to the next optional argument (C<--tax-max-hits>).

=for Euclid: n.type: 0+integer
    n.default: 1

=item --tax-max-hits=<n>

Maximum number of hits to use when computing LCAs [default: n.default]. Must
be greater or equal to the previous optional argument (C<--tax-min-hits>).

=for Euclid: n.type: 0+integer
    n.default: 1

=item --tax-min-lca-freq=<n>

Minimum frequency for the common taxon when computing LCA [default: n.default].
When specified and lower than 1.0, the LCA inference algorithm returns the
lowest taxon that is found in at least this fraction of lineages (instead of
returning the lowest taxon found in all lineages).

=for Euclid: n.type: 0+number
    n.default: 1.0

=item --kraken

Write KRAKEN-like report file [default: no].

=item --anvio

Write ANVIO-like report file [default: no].

=item --krona

Write KRONA-compatible report file [default: no].

=item --lca

Write LCA report file (including the lineage of each query) [default: no].

=item --kfold=<file>

Enable the k-fold mode [default: no]. The provided file must contain the list of
the NCBI GCA/GCF accessions of all the genomes composing the complete reference
database (one accession per line).

=item --kfold-seed=<n>

Seed for the random number generator [default: none]. Use this to obtain
predictable subsets of the database in k-fold mode.

=for Euclid: n.type: integer

=for Euclid: file.type: readable

=item --version

=item --usage

=item --help

=item --man

Print the usual program information

=back

=head1 COLOPHON

C<physeter.pl> is based on the script originally developed by Luc CORNET and
Denis BAURAIN for the article Cornet, L., et al. (2018). "Consensus assessment
of the contamination level of publicly available cyanobacterial genomes." PLoS
One 13(7): e0200323. [L<PubMed|https://pubmed.ncbi.nlm.nih.gov/30044797/>]. The
code was first completely rewritten by Valerian LUPO to use the C<Bio::MUST>
modules and then further reviewed and refactored by D. BAURAIN. Mick VAN
VLIERBERGHE greatly contributed to the taxonomic methods offered by C<Bio::MUST>
modules.

=head1 AUTHOR

Denis BAURAIN <denis.baurain@uliege.be>

=head1 CONTRIBUTORS

=for stopwords Valerian LUPO Mick VAN VLIERBERGHE Luc CORNET

=over 4

=item *

Valerian LUPO <valerian.lupo@doct.uliege.be>

=item *

Mick VAN VLIERBERGHE <mvanvlierberghe@doct.uliege.be>

=item *

Luc CORNET <luc.cornet@uliege.be>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by University of Liege / Unit of Eukaryotic Phylogenomics / Denis BAURAIN.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
