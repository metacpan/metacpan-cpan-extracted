#!/usr/bin/env perl

use Modern::Perl '2011';
use autodie;
use Smart::Comments '###';

use File::Basename;
use File::Find::Rule;
use Path::Class 'file';
use Getopt::Euclid qw(:vars);
use List::Util qw(sum);

use Bio::MUST::Core;
use aliased 'Bio::MUST::Core::Taxonomy';
use aliased 'Bio::MUST::Core::Ali';
use aliased 'Bio::MUST::Core::SeqId';
use Bio::FastParsers;
use aliased 'Bio::FastParsers::Blast::Table';

# build taxonomy object
my $tax = Taxonomy->new_from_cache(tax_dir => $ARGV_taxdir);

# build classifier
my $classifier = $tax->tax_labeler_from_list($ARGV_contam_list);

my @contam_results;

FILE:
for my $infile (@ARGV_infiles) {
	### processing : $infile
	my ($basename) = fileparse($infile, qr{\.[^.]*}xms);
	my $got_tax;
	my $current_org;

	unless ($ARGV_taxa){
		# define organism for future skip on self-hit
		my @taxonomy = $tax->get_taxonomy($basename);
		my $lineage = join '; ', @taxonomy;
		$current_org = pop @taxonomy;
		$got_tax = $classifier->classify($lineage, @_);

		# skip if unknown assembly
		warn "Cannot fetch taxonomy for $basename"
			unless $current_org;
		next FILE
			unless $current_org;
	}

	$got_tax = $ARGV_taxa
		if $ARGV_taxa;

	my $fasta = file($ARGV_fasta_dir, "$basename" . '.fasta');

	# load fasta file and get number of sequences
	my $ali = Ali->load($fasta);
	my $seq_n = $ali->height;

	# read blastx report file and compute lca
	my ($lca_for, $rel_mean) = fetch_hit($infile, $current_org);

	# create a LCA report if specified
	if ($ARGV_lca){
		my $lcafile = "$basename.lca";
		store_lca($lcafile, $lca_for);
	}

	# get contam statistics
	my $result = count_contam($lca_for, $got_tax, $seq_n);

	push @contam_results, "$basename\t$got_tax\t$result\t$rel_mean";
}

# store result in outfile and outfile-stat
store_result($ARGV_outfile, \@contam_results);

# functions

sub fetch_hit{
	my $infile = shift;
	my $current_org	= shift;

	my $report = Table->new( file => $infile );

	my %lca_for;
	my @rel_counts;

	my $curr_query;
	my $best_score;
	my @relatives;

	HIT:
	while (my $hit = $report->next_hit) {

		if ($curr_query && $curr_query ne $hit->query_id) {
			unless (@relatives < $ARGV_tax_min_hits) {
				# compute lca
				$lca_for{$curr_query} = _get_lca(\@relatives);
				push @rel_counts, scalar @relatives;
			}

			$curr_query = undef;
			$best_score = undef;
			@relatives = ();
		}
        ### x: scalar @relatives

		next HIT unless @relatives < $ARGV_tax_max_hits;

		# ... classic or best-hit mode
		next HIT if $hit->hsp_length < $ARGV_tax_min_len;
		next HIT if $hit->percent_identity < $ARGV_tax_min_ident;

		# catch taxon id from hit id
		my $taxon_id = SeqId->new( full_id => $hit->hit_id )->taxon_id;

		# skip on self hit
		unless ($ARGV_taxa){
			next HIT if _skip_self($taxon_id, $current_org);
		}

		# Note: contrary to ref_score_mul the best_score never changes
		$best_score //= $hit->bit_score;

		# ... MEGAN-like mode (and top_score needed for one-on-one)
		next HIT if $hit->bit_score < $ARGV_tax_score_mul * $best_score;

		# hit accumulation
		$curr_query = $hit->query_id;
		push @relatives, $taxon_id;
	}

	if ($curr_query) {
		# compute lca
		$lca_for{$curr_query} = _get_lca(\@relatives);
		push @rel_counts, scalar @relatives;
	}

	my $rel_mean = sprintf ( "%.2f", List::AllUtils::sum(@rel_counts)/@rel_counts );
	### $rel_mean

	return (\%lca_for, $rel_mean);
}

sub _skip_self {
	my $taxon_id = shift;
	my $current_org = shift;

	my @taxonomy = $tax->get_taxonomy($taxon_id);
	my $org = pop @taxonomy;

	return $org eq $current_org;
}

sub _get_lca {
	my $relatives = shift;

	my $common_tax = $tax->compute_lca( map { $_ . '|1' } @{$relatives} );
	my $lineage = join '; ', @{$common_tax};

	return $lineage;
}

sub count_contam {
	my $lca_for = shift;
	my $got_tax = shift;
	my $seq_n = shift;

	my $condition = '^\bcellular\sorganisms\b|^\bBacteria\b|^\bArchaea\b';
	my $self_n    = 0;
	my $contam_n  = 0;
	my $unknown_n = 0;
	my %contam_for;

	while (my ($query_id, $lineage_lca) = each %$lca_for){

		my $exp_tax = $classifier->classify($lineage_lca, @_);
		# self count
		$self_n++ if $exp_tax eq $got_tax;

		unless ( $exp_tax eq $got_tax ){
			# unknown count
			$unknown_n++ if $exp_tax =~ m/$condition/xms;
			# contam count
			unless ($exp_tax =~ m/$condition/xms){
				$contam_n++;
				# contam detail
				$contam_for{$exp_tax}++;
			}
		}
	}

	# compute contam statistics
	my $self_p    = sprintf ("%.2f", 100 * $self_n    / $seq_n);
	my $contam_p  = sprintf ("%.2f", 100 * $contam_n  / $seq_n);
	my $unknown_p = sprintf ("%.2f", 100 * $unknown_n / $seq_n);
	my $unclass_p = sprintf ("%.2f", 100 * (($seq_n - $self_n - $contam_n - $unknown_n)/$seq_n));

	my @contam_d;
	for (keys %contam_for){
		my $line = $_ . '=' .  sprintf ("%.2f", 100 * $contam_for{$_} / $seq_n);
		push @contam_d, $line;
	}

	my $result = join "\t", $self_p, $contam_p, $unknown_p, $unclass_p, join ',', @contam_d;

	return $result;
}

sub store_lca {
        my $outfile = shift;
        my $lca_for = shift;

        open my $out, '>', $outfile;

        say {$out} join "\t", $_, $lca_for->{$_} for sort keys %$lca_for;
}

sub store_result {
	my $outfile = shift;
	my $results = shift;

	open my $out, '>', $outfile;

	say {$out} join "\n", @{$results};
}

#~ sub clean_fasta {
	#~ my $ali = shift;
	#~ my $contam_id = shift;
	#~ my $assembly = shift;

	#~ for my $seq ($ali->all_seqs){
		#~ for (@$contam_id){
			#~ $seq->_set_seq( $seq->seq =~ tr/ATUGCYRSWKMBDHVN/N/r ) if $seq->foreign_id eq $_;
		#~ }
	#~ }

	#~ $ali->store("$assembly-clean.fasta");
#~ }

__END__

=head1 NAME

Parse BLAST report and compute statistics on taxonomic affiliation.

=head1 USAGE

    blastx-taxonomic-parsing.pl <infiles> --outfile [optional arguments]

=head1 REQUIRED ARGUMENTS

=over

=item <infiles>

Path to input BLAST file [repeatable argument].
File must be structured like this if organism has assembly accession :
assembly_accession.blastx. Unless, use --taxa option.

=for Euclid:
    infiles.type: readable
    repeatable

=item --outfile=<string>

Path to output file.

=for Euclid:
        string.type: string

=head1 OPTIONS

=over

=item --taxdir=<string>

Path to local mirror of the NCBI Taxonomy database. [default: string.default].

=for Euclid:
    string.type: string
    string.default: '/media/vol1/databases/taxdump-20190309'

=item --contam-list=<string>

List of taxa to use to classify and compute stat [default: string.default].

=for Euclid:
    string.type: string
    string.default: 'contam-taxa.list'

=item --fasta-dir=<string>

Path to the fasta directory [default: string.default].
Fasta file must have same basename than infile.

=for Euclid:
    string.type: string
    string.default: './'

=item --taxa=<string>

Taxa of organism. Use this option if organism do not have an assembly accession.
Specified taxa must be in the --contam-list file.

=for Euclid:
	string.type: string

=item --tax-min-len=<string>

minmal length of alignment to be considered for define bistcore [default: string.default].

=for Euclid:
    string.type: string
    string.default: '0'

=item --tax-min-ident=<string>

minimal percentage of identity of alignment to be considered for define bistcore [default: string.default].

=for Euclid:
    string.type: string
    string.default: '0'

=item --tax-min-score=<string>

minimal bitscore value [default: string.default].

=for Euclid:
    string.type: string
    string.default: '80'

=item --tax-score-mul=<string>

minimal percentage of bitscore for a hit to be considered for LCA [default: string.default].

=for Euclid:
    string.type: string
    string.default: '0.95'

=item --tax-min-hits=<string>

minimal number of hit for a read to compute LCA [default: string.default].

=for Euclid:
    string.type: string
    string.default: '1'

=item --tax-max-hits=<string>

maximal number of hit for a read to compute LCA [default: string.default].

=for Euclid:
    string.type: string
    string.default: '1'

=item --lca

Write a .lca report file [default: no].

=item --cleaning-fasta

Clean fasta file [default: no].
