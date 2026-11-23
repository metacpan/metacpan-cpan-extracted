# SYNOPSIS

    use Cn::Bioinf ':all';

    my $seqs = fasta2hash('proteome.fa.gz');        # { defline => sequence }
    my $one  = fasta2hash('proteome.fa', 'P12345'); # just that sequence
    hash2fasta_file($seqs, 'copy.fa');
    my $part = fasta_region('genome.fa', 'chr1:1000-2000');   # as samtools faidx

    # sequences as strings
    my $rc      = reverse_complement('ATGAAACTG');             # CAGTTTCAT
    my $protein = translate('ATGAAACTGTAA', to_stop => 1);     # MKL
    my $orfs    = find_orfs($one, table => 11, min_length => 100);
    my $hits    = motif_search($one, 'GRATYC', strand => 'both');
    my $gc      = gc_content($one);
    my $kmers   = kmer_count($one, 4);
    my $stats   = assembly_stats($seqs);                       # N50 and the rest
    my $pi      = isoelectric_point($protein);

    my $hits = get_best_alignment_hit('blast.json', 'bit_score');

    # the PDB structures that match a sequence, how well, and what kind they are
    my $pdb = pdb_search(seq => $one);
    print "$pdb->[0]{id} $pdb->[0]{pident}% $pdb->[0]{method} $pdb->[0]{resolution}\n";

    # one clustalo run: plot_msa keeps the guide tree, and plot_phylo draws it
    plot_msa(
    	fasta       => 'orthologs.fa',     # or { name => sequence }
    	filename    => 'msa.svg',          # .png, .pdf, ... too
    	'tree_file' => 'orthologs.newick',
    	title       => 'EF-3',
    );
    plot_phylo('tree_file' => 'orthologs.newick', 'output_file' => 'tree.svg', title => 'EF-3');

    # the alignment in the terminal, as Stats::LikeR's view shows a table, and as an SVG
    view_alignment('orthologs.fa', output_file => 'aln.svg', track => 'S.cerevisiae',
        color_residues => { 'S.cerevisiae' => { 3 => 'red', 8 => 'blue' } });

    # a polygenic score for each sample of a VCF, from a PGS Catalog scoring file
    my $scores = pgs_score(vcf => 'genome.vcf.gz', weights => 'PGS000138.txt.gz');

    # population genetics of a cohort's VCF, by PLINK 2
    my $pruned = ld_prune(vcf => 'cohort.vcf.gz');                 # { keep => [...], remove => [...] }
    my $pcs    = pca(vcf => 'cohort.vcf.gz', n => 4);              # { samples => { sample => [PC1 .. PC4] }, ... }
    my $fst    = fst(vcf => 'cohort.vcf.gz', populations => \%population_of);
    print $fst->{fst}{CEU}{YRI};
    my $hwe    = hardy_weinberg(vcf => 'cohort.vcf.gz');           # [ { chrom, pos, het, p, ... }, ... ]
    my $ld     = ld(vcf => 'cohort.vcf.gz', window_kb => 250);      # [ { a => {...}, b => {...}, r2 }, ... ]
    my $gwas   = gwas(vcf => 'cohort.vcf.gz', phenotypes => 'pheno.tsv', phenotype => 'height',
                      covariates => [qw(age sex)]);                # [ { beta, se, p, ... }, ... ]
    my $anc    = admixture(vcf => 'cohort.vcf.gz', k => 3);        # { samples => { sample => [3 fractions] }, ... }

    # each sample's sex, from its heterozygosity on X
    my $sex = sex_check(vcf => 'cohort.vcf.bz2'); # { sample => { sex => 'female', ... } }

    # whether two people are parent and child: 1 or 0
    my $is = parent(child => 'child.vcf.gz', parent => 'father.vcf.gz');

    # how every two people are related: father-son, brother-sister, ...
    my $kin = relatedness('mom.vcf.gz', 'dad.vcf.gz', 'kid.vcf.gz');
    print $kin->{'kid'}{'dad'}{category}; # by the sample names in the VCFs

    # how well a test VCF's calls agree with a truth VCF's, sample by sample
    my $conc = concordance(truth => 'NA12878.truth.vcf.gz', test => 'NA12878.run42.vcf.gz');
    print $conc->{'NA12878'}{metrics}{genotype_concordance};

    # each sample's ABO and RhD blood type, and the genotype behind each
    my $blood = blood_type(vcf => 'exome.vcf.gz');
    print "$blood->{'NA12878'}{type} ($blood->{'NA12878'}{abo}{genotype})\n"; # A+ (AO)

    # the 41 HIrisPlex-S markers, as the webtool's CSV wants them
    my $g = hirisplex_genotypes(vcf => 'genome.vcf.gz', file => 'hirisplexs.csv');

    # ... and a prediction from a multinomial logistic model you supply
    my $p = trait_predict(genotypes => $g, model => 'my_model.tsv');
    print $p->{'NA12878'}{eye}{call};

# DESCRIPTION

FASTA I/O in XS, with `samtools`'s index for fetching a part of a file; the
everyday operations on a sequence (its reverse complement, its translation
under any of NCBI's genetic codes, its open reading frames, GC content, k-mers,
motifs, molecular weight and isoelectric point, and an assembly's N50); BLAST
hit ranking, a search of the PDB's structures for a
sequence, and multiple-sequence-alignment plots and LaTeX tables; polygenic scores from a VCF and a PGS Catalog scoring file; a cohort's principal components, Fst between populations, Hardy-Weinberg tests, linkage disequilibrium and its pruning, and association tests (GWAS), by PLINK 2; admixture proportions; and, from VCFs, each sample's sex, whether two people are parent and child, how every two people are related, how well one VCF's calls agree with another's, each sample's ABO and RhD blood type, and the genotypes of the HIrisPlex-S eye, hair and skin colour panel, with a trait predictor for any multinomial logistic model you supply.

Nothing is exported by default; ask for functions by name or with `:all`.
Every function dies (via `Carp::croak`) on bad arguments, with a message that
starts with the name of the function that raised it, as in
`fasta2hash: couldn't find "four" in x.fa`. `pdb_search`, `pgs_score`, `pca`, `fst`, `hardy_weinberg`, `ld`, `ld_prune`, `gwas`, `admixture`, `sex_check`,
`parent`, `relatedness`, `concordance`, `blood_type`, `hirisplex_genotypes`, `trait_predict`, `plot_msa`, `plot_phylo` and `msa_quality_table`
take `name => value` pairs, not a hash ref; `view_alignment` takes the
alignment first, as a hash ref or a file name, and `name => value` pairs after
it.

## Alien::Bioinf

Clustal Omega, BLAST+, PLINK 2 and the Python that draws the plots come from
`Alien::Bioinf`, which installs them module-locally and never uses `PATH`. It
is recommended rather than required, because it can only be installed where
NCBI builds BLAST+ (Linux and macOS on x86\_64 and aarch64, and Windows on
x86\_64) and it needs the network; PLINK 2 has no build for Linux on aarch64,
so there it installs the rest. `fasta2hash`, `hash2fasta_file`,
`get_best_alignment_hit`, `sex_check`, `parent`, `relatedness`, `concordance`,
`hirisplex_genotypes` and `trait_predict` work without it; `pgs_score`, `plot_msa`,
`plot_phylo`, `msa_quality_table`, and `view_alignment` given
sequences that are not aligned, die saying that they need it. A CPAN client does not install a recommended module
unless asked, so install it first:

    cpanm Alien::Bioinf
    cpanm Cn::Bioinf

or, from a clone of [the repository](https://github.com/hhg7/Bioinf-Basic),
where it is `alien/Alien-Bioinf`:

    cpanm ./alien/Alien-Bioinf
    cpanm .

That downloads nothing it can reuse: archives are cached (`ALIEN_BIOINF_CACHE`,
default `~/.cache/alien-bioinf`), a clustalo or BLAST+ already on the machine at
the newest version is copied instead (`ALIEN_BIOINF_CLUSTALO`,
`ALIEN_BIOINF_BLAST`, or `PATH`), and pip reuses the wheels in its own cache.
The Python packages go into a venv of their own, which nothing installed into
the base Python can break. To check for and apply updates:

    perl -MAlien::Bioinf -MData::Dumper -e 'print Dumper(Alien::Bioinf->check_updates)'
    perl -MAlien::Bioinf -e 'print "$_\n" for Alien::Bioinf->update'

## Provenance in the images

Every PNG, SVG, PDF, PS or EPS image these functions draw carries its whole
provenance on one line, as its `Creator` metadata and nothing else, just as
Matplotlib::Simple writes it. The line names the calling script (its full
path), the function, this file and its
version, the Alien::Bioinf version, the user who ran it, the computer it ran
on (hostname and operating system), the perl version and path, and what drew
it: `msa_plot.py`, the Python version and path, the matplotlib version, and
for a tree the Biopython and NumPy versions too. The line has no date; an SVG
has the `<dc:date>` matplotlib writes beside it, taken from
`SOURCE_DATE_EPOCH` where that is set. After a `;` come the image's title
(or "untitled") and what it was made from and how, with the full path and
SHA-256 of each file:

- `plot_msa`: the FASTA file and how many sequences it holds (or the number
  of sequences in a hash ref), the ungapped copy of it that Clustal Omega
  read, with the sequences named `s1`, `s2` and so on, the alignment Clustal
  Omega wrote, with the names put back, the Clustal Omega version, the exact
  command, and the `msa_file` and `tree_file` kept, if any.
- `plot_phylo`: the same when it aligns, with the guide tree it drew;
  otherwise the newick file it drew. Then how many negative branch lengths
  were drawn as 0, if any; the tips, with the label each was shown as; and the
  whole newick tree that was drawn.
- `msa_quality_table`: the metric shown, and either the BLAST report it read
  or the FASTA file, its ungapped copy, the report blastp wrote, the blastp
  version, the exact command, and the `alignment_json` kept, if any.

For example:

    /home/me/work/run.pl called using "plot_phylo" in /.../Cn/Bioinf.pm
    version 0.01 with Alien::Bioinf 0.01 by user me on host myhost (linux)
    with Perl 5.44.0 (/usr/bin/perl), drawn by /.../msa_plot.py with
    Python 3.14.2 (/.../venv/bin/python),
    matplotlib 3.11.2, Biopython 1.87, NumPy 2.4.6; titled "DEG20010421";
    from the newick file /home/me/work/t.newick (SHA-256 f0e8...); 4 tips:
    S.cerevisiae, ...; the tree as drawn, in newick: (S.cerevisiae:0.389085,...);

An SVG holds it in `<dc:creator>`; `exiftool` or `identify -verbose` shows it
in a PNG or PDF.

# FUNCTIONS

## fasta2hash($file, $key)

Reads a FASTA file (gzip-compressed if its name ends in `.gz`, in any case,
which needs a `gzip` program on `PATH`). Returns a hash ref of defline (without the `>`) =>
sequence, or, with `$key`, just the sequence of that defline, reading no
further than the record after it. A defline that appears twice is warned about
and its sequences concatenated. With `$key`, reading stops at the defline
after that record, so only a repeat that follows it directly is seen; a second
record of that name further on is not read, and the first's sequence comes
back alone, with no warning. Read the whole file where that matters. Line
endings may be `\n` or `\r\n`; a file whose lines end in `\r` alone (classic
Mac OS) dies, since without a `\n` it is all one line. Whitespace (space, tab, `\r`, `\f`
and `\x0b`) is dropped from sequences and from the end of deflines, as
Biopython drops it, so a defline of `x` and a space is found as `x`. Deflines and sequences are bytes,
just as they are in the file. A `.gz` that gzip cannot read to its end, such as
a truncated one, dies rather than returning the part that was read.

    my $h = fasta2hash('DEG20010421.fa');

## hash2fasta_file($hash, $filename, $order, $width)

Writes `$hash` as FASTA: the keys in `@$order` (default: sorted), sequences
wrapped at `$width` columns (default 80; 0 for one line each). Returns
`$filename`, and prints `wrote $filename` to STDOUT, with the name in black
on cyan when STDOUT is a terminal. Keys and sequences are written as bytes, as `print` to a `:raw`
handle writes them, so a string that perl holds as UTF-8 is written as the
characters in it. A character above 255 has no single byte and dies; encode
such a string first, as with `Encode::encode('UTF-8', $name)`. A key that is
empty or holds a line feed dies, as does a sequence that is a reference
(unless it is an object that overloads its own text), since `fasta2hash` could
not read any of them back as what was given.

## fasta_index($file)

Writes the index of a FASTA file that `samtools faidx` writes, `$file.fai`,
and returns its name; it prints `wrote` and that name to STDOUT, as
`hash2fasta_file` does. The index has a line for each sequence: its name (the
first word of its defline), its length, the byte where it starts, and how many
bases and how many bytes each of its lines holds. Other programs that read a
`.fai` can use it, and `fasta_region` does.

    my $fai = fasta_index('genome.fa');   # genome.fa.fai

A file can be indexed when, within each sequence, every line but the last is
the same length, which is `samtools`'s rule; a file that breaks it dies, naming
the line. Of two sequences with one name, the first is indexed, with a warning.
A compressed file dies, since a place in it cannot be sought.

## fasta_region($file, @regions)

The parts of a FASTA file that `@regions` name, as a hash ref of region =>
sequence, without reading the rest of the file: the job of `samtools faidx`.

    my $part = fasta_region('genome.fa', 'chr1:1,000-2,000', 'chrM');
    print $part->{'chr1:1,000-2,000'};

A region is a sequence's name, for all of it, or `name:start-end`,
`name:start` (to the end) or `name:-end` (from the start), counting from 1 with
both ends included; commas in the numbers are ignored. A name that has a colon
in it, such as `HLA-A*01:01:01:01`, is taken whole when a sequence has that
name. A region that runs past the end of its sequence is cut short there, and
one that starts past it is empty, as `samtools faidx` gives them; a name that
is not in the file, a start of 0 and an end before the start die.

It uses `$file.fai` when that is there, whether `fasta_index` or `samtools`
wrote it, and warns when the index is older than the FASTA. Without one it
reads through the file to make the index, which it does not write: for a large
file that will be asked more than once, call `fasta_index` first. The file must
not be compressed.

## complement($seq, type => 'DNA')

`$seq` with each nucleotide replaced by the one it pairs with: `A` and `T`,
`C` and `G`, and each IUPAC ambiguity letter with the letter for the bases its
own pair with (`R` and `Y`, `K` and `M`, `B` and `V`, `D` and `H`; `S`, `W` and
`N` are their own). Case is kept, and anything that is not a nucleotide letter,
a gap included, is left as it is.

    complement('ATGAAACTG');                 # TACTTTGAC
    complement('AUGAAACUG', type => 'RNA');  # UACUUUGAC

`type` is `DNA` (the default) or `RNA`, in any case, and says what is written,
`T` or `U`; either is read in both. These are Biopython's `complement` and
`complement_rna`.

## reverse_complement($seq, type => 'DNA')

`complement` of `$seq`, reversed: the other strand, read from its own 5' end.

    reverse_complement('ATGAAACTG');   # CAGTTTCAT

## transcribe($seq), back_transcribe($seq)

`transcribe` writes `U` for every `T` of `$seq`, and `back_transcribe` `T` for
every `U`, in either case; nothing else changes.

    transcribe('ATGAAACTG');        # AUGAAACUG
    back_transcribe('AUGAAACUG');   # ATGAAACTG

## translate($seq, %args)

The protein that the DNA or RNA `$seq` codes for, one letter for each three of
its own, from its first letter.

    translate('GTGGCCATTGTAATGGGCCGCTGAAAGGGTGCCCGATAG');                # VAIVMGR*KGAR*
    translate('GTGGCCATTGTAATGGGCCGCTGAAAGGGTGCCCGATAG', to_stop => 1);  # VAIVMGR
    translate($cds, table => 'Vertebrate Mitochondrial', cds => 1);

- `table`: the genetic code, as NCBI's number for it (1, the standard code, by
  default) or one of its names in any case, such as `Standard`, `SGC0`,
  `Bacterial` or `Vertebrate Mitochondrial`. The codes are those of
  [NCBI's table](https://www.ncbi.nlm.nih.gov/Taxonomy/Utils/wprintgc.cgi),
  version 4.6: 1 to 6, 9 to 16 and 21 to 33.
- `to_stop`: 1 ends the protein before the first stop codon; 0 (the default)
  writes each stop and carries on.
- `stop_symbol`: the character written for a stop, `*` by default.
- `cds`: 1 says `$seq` is a whole coding sequence, and checks it: it must start
  with one of the code's start codons, be a multiple of three long, end with a
  stop codon and have no other. The start codon is then written as `M`,
  whatever it codes for inside a protein, and the stop is left out.
- `gap`: a character, such as `-`, three of which make a codon that is written
  as that character. Without it a gap dies, as any other letter that is not a
  nucleotide's does, naming the codon.

A codon with an ambiguous letter is given what the codons it stands for agree
on: their amino acid when they share one (`ATGAARCTG` is `MKL`), `*` when all
are stops, `B` for aspartate or asparagine, `Z` for glutamate or glutamine, `J`
for leucine or isoleucine, and `X` otherwise, a codon that may or may not be a
stop included. Case is ignored, and `T` and `U` may be mixed.

One or two letters left after the last whole codon are not translated, with a
warning; cut the sequence to a multiple of three to avoid it. Codes 27, 28 and
31 read some codons as an amino acid or as a stop, by context: those are
translated as the amino acid, with a warning, and `to_stop` dies with them.

These rules are Biopython's, whose `Seq.translate` this gives the same answers
as, with one exception: an `X` in a codon dies here, since it is not an IUPAC
nucleotide letter, where Biopython reads it as `N` in some codons.

## translate_six_frames($seq, %args)

`$seq` translated in all six reading frames, as a hash ref: `1`, `2` and `3`
are the frames that start at its first, second and third letter, and `-1`, `-2`
and `-3` those that start at the first, second and third letter of its reverse
complement. Each protein is written from its own N-terminus.

    my $f = translate_six_frames('AUGCUAACAUAAA');
    # { 1 => 'MLT*', 2 => 'C*HK', 3 => 'ANI', -1 => 'FMLA', -2 => 'LC*H', -3 => 'YVS' }

`table` and `stop_symbol` are as for `translate`. Letters left after a frame's
last whole codon are dropped without a warning, since five of the six frames
always have some. The minus frames are numbered as scikit-bio and BLAST number
them, which is EMBOSS `transeq`'s `-alternative`.

## find_orfs($seq, %args)

The open reading frames of `$seq` on both strands, as an array ref of hash
refs in order of where they start:

    my $orfs = find_orfs($plasmid, table => 11, min_length => 100, start => 'code');
    printf "%d-%d %s %s...\n", @{ $_ }{qw(start end strand)}, substr $_->{protein}, 0, 10 for @{ $orfs };

- `table`: the genetic code, as for `translate`.
- `start`: where a frame opens. `any` (the default) is at the codon after a
  stop, or at the sequence's first, so that every stretch between stops is a
  frame. `ATG` is at the first `ATG` after that, and `code` at the first of the
  genetic code's own start codons, which for code 11 include `GTG` and `TTG`;
  with either, the protein starts with `M`, whatever the codon codes for
  elsewhere, and a stretch with no start codon is no frame.
- `min_length`: the fewest amino acids a frame may have, 10 by default.
- `strand`: `both` (the default), `+` or `-`.

Each frame has `start` and `end`, its first and last base in `$seq`, counted
from 1, with `start` the smaller on either strand and the stop codon left out;
`strand`, 1 or -1; `frame`, as `translate_six_frames` numbers them; `length`,
in amino acids; and `protein`. A frame that reaches the end of the sequence
without a stop is returned as far as it goes.

This is what EMBOSS's `getorf` finds: `start => 'any'` is its `-find 0`,
`start => 'ATG'` its `-find 1` with its default table, and `start => 'code'`
its `-find 1` with `-table`; its `-minsize` is in nucleotides, three times
`min_length`.

## gc_content($seq, ambiguous => 'remove')

The share of `$seq` that is G or C, from 0 to 1, in either case; 0 for an
empty sequence. `S`, which is G or C, counts as one.

    gc_content('ACTGN');                           # 0.5
    gc_content('ACTGN', ambiguous => 'ignore');    # 0.4

`ambiguous` says what the other ambiguity letters count for: `remove` (the
default) leaves them out, so that the share is of the letters A, C, G, T, U, S
and W; `ignore` counts them in the length but not as G or C; and `weighted`
counts each as the share of its bases that are G or C, half for `N` and
two-thirds for `B`. This is Biopython's `gc_fraction`.

## kmer_count($seq, $k, %args)

How many times each run of `$k` letters occurs in `$seq`, as a hash ref of
k-mer => count. The letters are taken as they are: fold the case first if `a`
and `A` should count together.

    kmer_count('GATTACA', 3);                 # { GAT => 1, ATT => 1, TTA => 1, TAC => 1, ACA => 1 }
    kmer_count('GATTACA', 3, overlap => 0);   # { GAT => 1, TAC => 1 }

- `overlap`: 1 (the default) counts the k-mer at every letter; 0 counts one
  every `$k` letters, from the first, so that none overlaps another.
- `relative`: 1 gives each k-mer's share of all that were counted, which sum to
  1, in place of its count.

A `$k` longer than the sequence gives an empty hash. This is scikit-bio's
`kmer_frequencies`.

## assembly_stats($seqs)

The statistics of a set of sequences, such as the contigs of an assembly, that
`assembly-stats` prints. `$seqs` is a hash ref of name => sequence, as
`fasta2hash` returns, or an array ref of sequences.

    my $s = assembly_stats(fasta2hash('contigs.fa'));
    print "N50 $s->{n50} in $s->{l50} of $s->{number} contigs\n";

It returns a hash ref of `number`, how many sequences there are;
`total_length`, `mean_length`, `longest` and `shortest`; `n_count`, how many
letters are `N` or `n`, and `gaps`, how many runs of them there are; `n50` and
`l50`; and `nx` and `lx`, hash refs of those two for every tenth from 10 to 100.
N50 is the length of the sequence at which the lengths, added from the longest
down, first reach half of their total, and L50 is how many sequences that took;
`$s->{nx}{90}` and `$s->{lx}{90}` are the same for 90%. With no sequences
every number is 0, and with no sequence of any length every Nx and Lx is.

## molecular_weight($seq, %args)

The weight of a molecule of DNA, RNA or protein, in daltons.

    molecular_weight('AGC');                      # 949.6095
    molecular_weight('AGC', type => 'RNA');       # 997.6077
    molecular_weight('AGC', type => 'protein');   # 249.2874

- `type`: `DNA` (the default), `RNA` or `protein`, in any case.
- `double_stranded`: 1 adds the weight of the strand that pairs with `$seq`.
- `circular`: 1 for a molecule with no ends, which has one more bond.
- `monoisotopic`: 1 uses the weight of each element's commonest isotope, which
  is what a mass spectrometer resolves, rather than its average weight.

A nucleic acid is weighed with a 5' phosphate. Only the plain letters have a
weight -- `ACGT`, `ACGU`, or the 20 amino acids with `O` (pyrrolysine) and `U`
(selenocysteine) -- so any other letter dies, as does an empty sequence;
whitespace is dropped and case ignored. The weights are Biopython's, and this
is its `molecular_weight`.

## isoelectric_point($protein), protein_charge($protein, $pH)

`isoelectric_point` is the pH at which a protein has no net charge, and
`protein_charge` its charge at a pH you give.

    isoelectric_point('INGAR');    # 9.75
    protein_charge('INGAR', 7);    # 0.76

The charge is that of the two ends of the chain and of every K, R, H, D, E, C
and Y, each by the Henderson-Hasselbalch equation, with the pK values of
Bjellqvist et al. (*Electrophoresis* 14:1023, 1993, and 15:529, 1994), which
depend on the residue at each end; these are the values ExPASy's Compute pI/Mw
uses, and the method is that of Biopython's `IsoelectricPoint`. The isoelectric
point is found by bisection and is good to four decimal places. Other letters
carry no charge, case is ignored, and an empty sequence dies.

## subseq($seq, $start, $end)

The part of `$seq` from `$start` to `$end`, counting from 1 with both
included; `$end` is the sequence's end when it is not given.

    subseq('TTGGTGGCGTCAACT', 2, 5);   # TGGT

A start of 0, a start after the end and an end past the sequence die, as they
do in BioPerl's `subseq`. For a part of a sequence in a file, see
`fasta_region`.

## motif_search($seq, $motif, %args)

Where `$motif` occurs in `$seq`, as an array ref of hits in order of where
they start, each a hash ref of `start` and `end` (counted from 1, both
included), `strand` (1 or -1) and `match`, the letters that matched. Hits that
overlap are all found.

    my $hits = motif_search($seq, 'GRATYC', strand => 'both');   # EcoRI and BamHI sites
    my $glyc = motif_search($protein, qr/N[^P][ST][^P]/, type => 'protein');

`$motif` is a string of IUPAC letters or a `qr//` pattern. In a string of
nucleotide letters, each ambiguity letter matches any of its bases (`R` is `A`
or `G`, `N` any of the four), `T` and `U` match each other, and case is
ignored; in a protein's, `B` is `D` or `N`, `Z` is `E` or `Q`, `J` is `I` or
`L`, and `X` is anything. A pattern is used as it is written.

- `type`: `DNA` (the default), `RNA` or `protein`.
- `strand`: `+` (the default), `-` or `both`. The minus strand is searched as
  its own sequence, the reverse complement of `$seq`, so a hit there has the
  motif as its `match`, while its `start` and `end` are still positions in
  `$seq`. A motif that is its own reverse complement is found on both strands
  at each site.

## get_best_alignment_hit($json_file, $sort_criterion)

For a BLAST `-outfmt 15` JSON report, a hash ref of query title => array ref
of that query's hits, best first. Each hit is its best hsp plus `accession`,
`hit_len`, `id` and `title`, and `descriptions`, an array ref of every
description BLAST gave the hit. A hit against a non-redundant database such as
nr has one for each accession of the same sequence; `accession`, `id` and
`title` are those of the first, which is the one BLAST lists first. `$sort_criterion` is an hsp field (default
`evalue`): `align_len`, `bit_score`, `evalue`, `gaps`, `identity`,
`positive` or `score`. Ties are broken on the bit score, then on BLAST's
order. A report with two queries of one title dies, since only one of them
could be returned.

## pdb_search(%args)

Searches the structures of the [RCSB PDB](https://www.rcsb.org/) for a
sequence, and returns the matching ones, best first, each with how well it
aligns and what kind of structure it is:

    use Cn::Bioinf qw(pdb_search);

    my $hits = pdb_search(seq => 'MVLSPADKTNVKAAWGKVGAHAGEYGAEALERMF...');
    my $best = $hits->[0];
    print "$best->{id}: $best->{pident}% identical over $best->{query_cover}% of the query, ",
    	"$best->{method} at $best->{resolution} A, $best->{oligomeric_state}\n";
    # 1BZ1_1: 100% identical over 100% of the query, X-ray at 1.59 A, Hetero 4-mer

    my ($hits, $total) = pdb_search(seq => $seq, max_hits => 10); # and how many RCSB found

It needs the network, and HTTPS, which HTTP::Tiny gets from `IO::Socket::SSL`
and `Net::SSLeay`; without them it dies saying which is missing. It asks two
of RCSB's APIs: the [search API](https://search.rcsb.org/) finds the polymer
entities (one distinct chain of a structure) whose sequence matches, and the
[data API](https://data.rcsb.org/) says what each one's structure is.

RCSB aligns with MMseqs2, not BLAST, so the numbers are MMseqs2's: its E-value
and bit score are on BLAST's scale but are not what `blastp` would give for the
same pair. They are returned under the names `get_best_alignment_hit` gives a
BLAST hsp.

### Arguments

- `seq` (required): the sequence, as a string. Whitespace is removed, lower
  case is made upper case, and a final `*` (a stop) is dropped, so a sequence
  pasted from a FASTA file can be given as it is; any other character that is
  not a letter dies. RCSB itself refuses a sequence shorter than 10 residues.
- `type`: `protein` (the default), `dna` or `rna`.
- `evalue`: hits with this E-value or above are left out. The default is 0.1,
  not BLAST's 10, which in a search of the whole PDB lets in hits expected 10
  times over by chance.
- `identity`: hits with less identity than this percentage are left out
  (default 0).
- `max_hits`: the most hits returned (default 100). RCSB allows up to 10000.
- `computed`: 0 (the default) searches experimental structures only; 1 also
  searches the computed structure models RCSB holds, from AlphaFold DB and
  ModelArchive.
- `report`: 1 (the default) prints a table of the hits to STDOUT; 0 returns
  them only.
- `timeout`: seconds to wait for each request to RCSB (default 60).

### What it returns

An array ref of hits, best first: by E-value, then bit score, then RCSB's own
order, as `get_best_alignment_hit` sorts by `evalue`. Many hits tie: every
structure of the query's own protein aligns the same way. In list context, the
number of hits RCSB found is returned as well, which can be more than
`max_hits`. Nothing matching is an empty array ref, not an error.

Each hit is a hash ref with every one of these keys, `undef` or an empty array
ref where RCSB has no value:

What it is:

- `id`: the polymer entity, as `1BZ1_1`: entry `1BZ1`, entity `1`.
- `entry`, `entity`: the two halves of `id`. A computed model's entry is like
  `AF_AFP69905F1`.
- `url`: the entry's page at RCSB.

How well it aligns:

- `evalue`, `bit_score`: MMseqs2's.
- `align_len`: the length of the alignment, gaps included.
- `identity`: the number of aligned columns where the two agree, and `pident`,
  that as a percentage of `align_len`. These are counted from the aligned
  sequences, since RCSB gives the identity only truncated to 3 places.
  `pident` is `undef` if RCSB gives an `align_len` of 0 or none.
- `mismatches`, `gaps` (gap columns), `gap_opens`.
- `query_from`, `query_to`, `query_len` and `query_cover`, the percentage of
  the query in the alignment, which is `undef` if RCSB gives no `query_len`
  or one of 0.
- `hit_from`, `hit_to`, `hit_len`: the same for the hit's sequence.
- `qseq`, `hseq`: the aligned query and hit, with `-` for gaps.

What kind of structure it is:

- `title`: the entry's title, and `description`, the entity's name.
- `method`: how the structure was determined: `X-ray`, `EM`, `NMR`,
  `Neutron`, `Integrative`, `Multiple methods` or `Other`; `undef` for a
  computed model.
- `methodology`: `experimental`, `computational` or `integrative`.
- `resolution`: in Å, for X-ray and EM structures.
- `plddt`: a computed model's mean pLDDT, 0 to 100.
- `polymer_type`: `Protein`, `DNA`, `RNA`, `NA-hybrid` or `Other`.
- `polymer_composition`: the entry as a whole, such as `homomeric protein`,
  `heteromeric protein` or `protein/NA`.
- `oligomeric_state`, `stoichiometry` and `symmetry`: the global symmetry of
  the first biological assembly, such as `Hetero 4-mer`, `A2B2` and `C2`.
- `chains`: an array ref of the chains that are this entity.
- `organisms`: an array ref of `{ name, taxonomy_id }`.
- `uniprot`: an array ref of UniProt accessions.
- `pfam`, `interpro`: array refs of `{ id, name }`.
- `ligands`: an array ref of `{ id, name }`, one for each kind of small
  molecule in the entry, such as `HEM`.
- `deposited`, `released`: dates, as `YYYY-MM-DD`.

A hit that the data API has no record of (one so new that RCSB's search index
has it first) is warned of, and is returned with its alignment and no structure.

## pgs_score(%args)

Computes a polygenic score for every sample of a VCF from a scoring file of
the [PGS Catalog](https://www.pgscatalog.org/downloads/): for each variant,
the number of copies of the effect allele in the sample's genotype times
`effect_weight`, summed over the variants. [PLINK 2](https://www.cog-genomics.org/plink/2.0/),
which `Alien::Bioinf` installs, reads the genotypes and does the arithmetic
(`--score` with `no-mean-imputation`), so the genotypes are never held in perl:

    use Cn::Bioinf 'pgs_score';

    my $scores = pgs_score(vcf => 'genome.vcf.gz', weights => 'PGS000138.txt.gz');
    # { sample => { score => 1.6742, average => 6.97e-05, variants => 12015,
    #               alleles => 24030, missing => 10259, mismatched => 0 } }

Both arguments may also be data frames, as Stats::LikeR's `read_table`
returns them, which this module takes without loading Stats::LikeR. Every row
of an array of arrays has as many fields as its header, and every column of a
hash of arrays as many values as the others, or the frame dies. A VCF
given as a frame is written to a temporary VCF for PLINK 2. Files cost less
memory, since a frame is all in perl: on 2026-10-17, PGS000907's 1,773,528
variants were scored from files against a 3.5-million-record genome in 25 s,
with perl peaking at 0.8 GB.

- `vcf` (required): a `.vcf`, `.vcf.gz`, `.vcf.bgz` or `.bcf` file, a PLINK 2
  fileset given by its `.pgen` (with its `.pvar` and `.psam` beside it), or a
  data frame in any of `read_table`'s four shapes whose genotypes are columns
  named `<sample>.GT`, as `read_table` gives a VCF by default; one read with
  `explode => 0` has none, and dies. A frame needs `CHROM`, `POS`, `REF` and
  `ALT`, and `ID` too with `match => 'id'`.
- `weights` (required): a scoring file (`.txt` or `.txt.gz`), read a line at a
  time, or a data frame of one. It needs `effect_allele` and `effect_weight`,
  and either `chr_name` and `chr_position` or, with `match => 'id'`, `rsID`.
  `other_allele` is used when present. A harmonized file of the PGS Catalog
  (`..._hmPOS_GRCh38.txt.gz`) is read by `hm_chr` and `hm_pos` (or `hm_rsID`)
  instead, which are on the build its name gives. A variant marked TRUE in
  `is_haplotype`, `is_diplotype`, `is_interaction`, `is_dominant` or
  `is_recessive`, or given a `dosage_0_weight`, `dosage_1_weight` or
  `dosage_2_weight`, dies, since only additive weights are scored.
- `match`: `position` (the default) finds each variant by chromosome and
  position; `id` finds it by rsID, in a VCF whose `ID` column holds them. An
  `ID` of `rs1;rs2` is found by either.
- `build`: `hg19` (or `b37`) or `hg38` (or `b38`). PLINK 2 reads X only once
  told where its pseudo-autosomal regions are, so a score with variants on X
  or Y dies without it. Every sample is taken to be of unknown sex, which PLINK
  2 counts a haploid call on X of as homozygous: 2 copies, 2 alleles.
- `memory`, `threads`: the MiB of memory (640 or more) and the CPUs PLINK 2
  may use. By default it reserves half the machine's memory and uses every
  CPU.

Returns a hash ref keyed by sample, a hash of hashes that `write_table` can
write, with these fields for each sample. A sample is named by its IID, so a
PLINK 2 fileset in which two samples share an IID, in different families, dies
rather than adding their scores together.

- `score`: the sum of the weights times the dosages, PLINK 2's `SCORE1_SUM`.
  PLINK 2 writes it to six significant figures, so it is good to about one
  part in a million.
- `average`: `score` divided by `alleles`, PLINK 2's `SCORE1_AVG`, or undef
  when `alleles` is 0.
- `variants`: the variants of `weights` that were scored for this sample.
- `alleles`: the alleles counted in their genotypes, PLINK 2's `ALLELE_CT`:
  2 for each diploid call.
- `missing`: the variants that were not scored, because the VCF has no
  record of them whose alleles agree, or because the sample's genotype is
  missing (`./.`, or partly missing, such as `./1`). `variants` and `missing`
  add up to the number of rows of `weights`.
- `mismatched`: of `missing`, those at a position (or ID) the VCF has, whose
  alleles disagree with the record's there.

PLINK 2 by default fills a missing genotype in with the effect allele's
frequency in the samples; `pgs_score` leaves it out.

How a variant is matched, which perl decides, a `.pvar` line at a time,
before PLINK 2 scores:

- Chromosomes are compared without UCSC's `chr` prefix and in any case, and
  PLINK's `23`, `24` and `26` and UCSC's `M` are taken as `X`, `Y` and `MT`,
  so `chr1` in a VCF finds `1` in a scoring file.
- A variant agrees with a record when its effect allele and its other allele
  (if it has one) are both among the record's `REF` and `ALT` alleles, in any
  case. A multi-allelic record counts the copies of whichever `ALT` is the
  effect allele, so a `1/2` genotype of `G` to `A,T` holds one `T`. Where two
  records agree, as a multi-allelic site split in two can, the first in
  `CHROM:POS:REF:ALT` order is used.
- A record whose `ALT` is `.`, which a VCF of every site writes where the
  sample matches the reference, agrees with a variant either of whose alleles
  is its `REF`; a `0/0` there is two copies of the effect allele if it is the
  `REF`, and none otherwise.
- Alleles are not complemented, since a VCF and the PGS Catalog's files are
  both on the forward strand. A variant written on the other strand
  disagrees, and A/T and C/G variants, which read the same on either strand,
  are matched as they are written.
- Only `GT` is read: a dosage (`DS`) or a genotype likelihood is not used.

The positions in the scoring file have to be on the same genome build as the
VCF's, since a variant's position in GRCh37 (hg19) and in GRCh38 (hg38) differ;
rsIDs do not, so `match => 'id'` needs no build. Many scoring files say
`genome_build=NR` (not reported), so `pgs_score` cannot compare the builds.
The alleles say what it cannot: it warns when none of the variants was found
with alleles that agree, and when the alleles disagree at more than half of
the variants found. On 2026-10-17, PGS000138, whose header says
`genome_build=NR`, was scored against a GRCh37 genome: 12,015 of its 22,274
variants were found, and the alleles agreed at every one, so its positions
are on GRCh37. With every position moved on one base, the alleles agreed at 9
of the 58 found.

A VCF that lists only the variants a sample carries (as most single-sample
VCFs from a sequencing service do: every genotype holds an `ALT`) has no
record where the sample matches the reference, so those variants are
`missing`, not scored as zero copies. PLINK 2 refuses such a file; `pgs_score`
warns that its score is not comparable and scores it anyway. That genome above
was scored at 12,015 of PGS000138's 22,274 variants, and an exome at 701. A
score is comparable only with another scored on the same variants, so check
`variants` before comparing samples; a VCF called jointly over many samples,
or one of every site, has far fewer missing. The reference blocks of a gVCF,
which cover a range of positions with one record, are not expanded.

PLINK 2 converts the whole of a VCF or BCF before it keeps the score's
positions, which for the 12 GB, 81-million-record BCF of 1000 Genomes took 294
s and 6.2 GB on 2026-10-17. Cut the positions out first with `bcftools view
-R` (16 s), or convert such a reference once with `plink2 --make-pgen` and
give `pgs_score` the `.pgen`: from a `.pgen` of those positions, all 2,504
people were scored in under a second.

The PGS Catalog's search pages export a table of scores with a link to each
one's scoring file (`depression.pgs_scores_data.csv`, for one). That table
has no weights, so `pgs_score` cannot use it, but it can say which files to
download and score:

    use Stats::LikeR 'read_table';
    my $catalog = read_table('depression.pgs_scores_data.csv');
    foreach my $pgs (@{ $catalog }) {
    	my ($file) = $pgs->{'Scoring File (FTP Link)'} =~ m{([^/]+)\z};
    	next unless -f $file;
    	my $s = pgs_score(vcf => 'genome.vcf.gz', weights => $file);
    	printf "%s\t%s\t%g\t%d variants\n", $pgs->{'Polygenic Score ID & Name'}, $_, @{ $s->{$_} }{qw(score variants)}
    		foreach sort keys %{ $s };
    }

## Population genetics: pca, fst, hardy\_weinberg, ld, ld\_prune and gwas

Six functions of a cohort's genotypes, each of which hands them to
[PLINK 2](https://www.cog-genomics.org/plink/2.0/), which `Alien::Bioinf`
installs, and returns what it computes as perl data. The genotypes are never
held in perl. What they share:

- `vcf` (required) is given as to `pgs_score`: a `.vcf`, `.vcf.gz`,
  `.vcf.bgz` or `.bcf` file, a PLINK 2 fileset given by its `.pgen`, or a data
  frame, as Stats::LikeR's `read_table` returns one, whose genotypes are
  columns named `<sample>.GT`.
- Only the biallelic variants on the autosomes (1 to 22) are read. A
  multi-allelic record is left out, and so are X, Y and the mitochondrion,
  which PLINK 2 reads only once told each sample's sex. A VCF with no
  biallelic variant on the autosomes dies.
- Only `GT` is read, and a genotype that is partly missing (`./1`) is
  missing.
- `memory` and `threads` are the MiB of memory (640 or more) and the CPUs
  PLINK 2 may use, as for `pgs_score`.
- A variant is returned as a hash of `chrom`, `pos`, `id`, `ref` and `alt`,
  plus what the function says. `chrom` is PLINK 2's name for the chromosome,
  1 to 22 without a `chr` prefix, whatever the VCF calls it, and `id` is the
  VCF's `ID`, `.` included. Variants come in the VCF's order.
- Samples are named by their IIDs: a VCF's sample names, or a fileset's IIDs.
  A fileset in which two samples share an IID, in different families, dies.
  A fileset's `.psam` may name each sample's parents, and PLINK 2 then counts
  only the founders for allele frequencies and for `hardy_weinberg`; a VCF
  names none, so every sample is a founder.
- PLINK 2 prints its numbers to 6 significant figures, so that is what each
  number returned is good to. A `NA` or `nan` of PLINK 2's is undef.

The usual order is to prune first, and to compute principal components or Fst
on the variants kept, since PLINK 2's own help advises a set of variants in
approximate linkage equilibrium for `--pca`, with no very rare ones. The
functions take no list of variants, so filter the VCF with the variants
`ld_prune` keeps, or with `bcftools view -i`, before handing it to the next.
In the 60 people of three populations of `t/data/popgen.vcf`, variants
20 kb or more apart were still in strong linkage disequilibrium: 97 pairs of
210 such variants had an r² of 0.5 or more.

### pca(%args)

The principal components of the samples, PLINK 2's `--pca`: the leading
eigenvectors of the variance-standardized relationship matrix.

    my $p = pca(vcf => 'cohort.vcf.gz', n => 4);
    # { eigenvalues => [10.79, 6.01, 5.40, ...], variants => 270,
    #   samples => { NA06984 => [-0.0847, -0.0160, 0.0837, ...], ... } }

- `n`: how many components, 10 by default, as PLINK 2 has it.

It returns a hash ref of `eigenvalues` (an array, largest first), `samples`
(each sample's components, an array in the eigenvalues' order), and
`variants`, how many variants were read. A component's sign is arbitrary, as
an eigenvector's is. PLINK 2 needs 50 samples or more to estimate the allele
frequencies it standardizes by, and fewer die with its message. For more than
about 5,000 samples, PLINK 2's help advises its randomized algorithm (`--pca
approx`), which this function does not use.

### fst(%args)

Fst between every two populations, PLINK 2's `--fst`.

    my $f = fst(vcf => 'cohort.vcf.gz', populations => { NA06984 => 'CEU', NA18486 => 'YRI', ... });
    print $f->{fst}{CEU}{YRI};   # 0.170396; and $f->{fst}{YRI}{CEU} is the same

- `populations` (required): a hash ref of sample => population. A sample of
  the VCF that it leaves out is left out of the estimate, a sample it names
  that the VCF lacks is ignored, and a population of none of the VCF's
  samples is not counted. Two populations with samples are needed. A name may
  be anything that is not empty, a number or a phrase with spaces included.
- `method`: `hudson` (the default, as in PLINK 2), the estimator of Bhatia,
  Patterson, Sankararaman and Price (2013), or `wc`, Weir and Cockerham's
  (1984). Either is a ratio of averages over the variants.
- `per_variant`: 1 also returns each variant's Fst; 0 (the default) does not.

It returns a hash ref of `method`, `populations` (each population with
samples in the VCF, and how many), `fst` (`{ A => { B => Fst } }`, given both
ways round), and `variants`. `variants` is undef unless `per_variant` is 1,
and is then `{ A => { B => [ variant, ... ] } }`, one list for each pair,
given both ways round, with each variant's `fst` (undef where it cannot be
estimated).

### hardy\_weinberg(%args)

Tests each variant's genotypes for Hardy-Weinberg equilibrium, by the exact
test of Wigginton, Cutler and Abecasis (2005), PLINK 2's `--hardy`.

    my $h = hardy_weinberg(vcf => 'cohort.vcf.gz');
    # [ { chrom => 1, pos => 30028088, id => '.', ref => 'A', alt => 'G',
    #     hom_ref => 13, het => 23, hom_alt => 24,
    #     observed_het => 0.383333, expected_het => 0.483194, p => 0.113585 }, ... ]

- `midp`: 1 gives the mid-p (Graffelman and Moreno 2013), which is less
  conservative; 0 (the default, as in PLINK 2) gives the exact test's own p.

It returns an array ref of the variants, each with `hom_ref`, `het` and
`hom_alt` (the samples called with each genotype), `observed_het` and
`expected_het` (the share of those samples that are heterozygous, and the
share Hardy-Weinberg proportions would give) and `p`. All the samples are
tested together, so in a cohort of several populations a variant whose
frequency differs between them shows too few heterozygotes; test each
population's VCF alone for that.

### ld(%args)

Linkage disequilibrium between every two variants of a chromosome within a
window, PLINK 2's `--r2-unphased` or `--r2-phased`.

    my $pairs = ld(vcf => 'cohort.vcf.gz', window_kb => 250, min_r2 => 0.8);
    # [ { a => { chrom => 22, pos => 20000428, ... }, b => { chrom => 22, pos => 20003731, ... },
    #     r2 => 0.287761, dprime => undef }, ... ]

- `window_kb`: the farthest apart two variants of a pair are, in kb; 1000 by
  default, as in PLINK 2.
- `window`: the most variants apart they are, 1 being adjacent variants; no
  limit by default.
- `min_r2`: the least r² of a pair returned, 0.2 by default, as in PLINK 2;
  0 returns every pair in the window.
- `phased`: 0 (the default) gives the r² of the two variants' allele counts
  (genotype dosages), which needs no phase. 1 gives the r² of the haplotypes,
  and D′, PLINK 2's `--r2-phased`, which uses each genotype's phase where the
  VCF gives it (`0|1`). D′ is signed, positive where the two variants' major
  alleles go together.

It returns an array ref of pairs, each a hash of `a` and `b` (the two
variants), `r2` and `dprime` (undef unless `phased` is 1). The pairs are
PLINK 2's, in the order of their first variant. On a whole genome with a low
`min_r2` there are a great many; give a high one, or a smaller window.

### ld\_prune(%args)

The variants to keep so that no two in a window are in strong linkage
disequilibrium, PLINK 2's `--indep-pairwise`: within each window, of two
variants whose r² is above `r2`, one is removed, and the window then moves on.

    my $r = ld_prune(vcf => 'cohort.vcf.gz');   # windows of 50 variants, moved on 5, r² 0.5
    my %keep = map { ("$_->{chrom}:$_->{pos}" => 1) } @{ $r->{keep} };

- `window`: the variants in each window, 50 by default.
- `window_kb`: a window in kb instead, which PLINK 2 moves on one variant at a
  time. Give one of `window` and `window_kb`.
- `step`: the variants the window moves on by, 5 by default, or 1 (the only
  value PLINK 2 takes) with `window_kb`.
- `r2`: the r² above which one of two variants is removed, 0.5 by default.

The defaults, 50, 5 and 0.5, are the example the PLINK 1.9 manual gives for
`--indep-pairwise`; PLINK 2 requires a window and an r² and has no defaults
for them. It returns a hash ref of `keep` and `remove`, each an array ref of
variants, which between them hold every variant read. Like `pca`, it needs 50
samples or more, and fewer die with PLINK 2's message; `ld` does not.

### gwas(%args)

Tests every variant for association with a phenotype, PLINK 2's `--glm`: a
linear regression of a quantitative phenotype, or a logistic regression of a
case-control one, on each sample's count of the ALT allele (0, 1 or 2), with
any covariates.

    my $g = gwas(vcf => 'cohort.vcf.gz', phenotypes => 'pheno.tsv', phenotype => 'height',
                 covariates => [qw(age sex PC1 PC2)]);
    my ($top) = sort { $a->{p} <=> $b->{p} } grep { defined $_->{p} } @{ $g->{variants} };
    print "$top->{chrom}:$top->{pos} beta $top->{beta} p $top->{p}\n";

- `phenotypes` (required): the phenotypes and covariates, one row for each
  sample, as a tab-separated file whose first line is its header (it may
  begin with `#`, as PLINK 2's own files do), or as a data frame. A column
  `IID` (or `#IID`) names each row's sample by the VCF's name for it. A value
  that is empty, undef or `NA` is missing, and a sample missing the phenotype
  or a covariate is left out, as is a sample with no row.
- `phenotype` (required): the column to test. Its values must be numbers.
- `covariates`: an array ref of the columns to adjust for. A column of numbers
  is a quantitative covariate, and any other is categorical, which PLINK 2
  turns into an indicator for each value but one. A categorical value may not
  hold whitespace. The principal components from `pca` are the usual
  covariates for ancestry; put them in `phenotypes` as columns.
- `model`: `linear` or `logistic`. By default a phenotype of exactly two
  values, 1 and 2 (PLINK's control and case) or 0 and 1 (control and case),
  is case-control and tested by logistic regression, and any other is
  quantitative and tested by linear regression. `logistic` takes only a
  phenotype of those two kinds. PLINK 2 falls back on Firth's penalized
  regression for a variant where the plain logistic regression does not
  converge.

PLINK 2 takes any column whose values are all 0, 1 and 2 as case-control,
reading a 0 as missing. A quantitative phenotype or covariate of those values
(a count of something, say) is therefore given to it with 3 added, which
changes no variant's test, since in a linear regression neither the slopes nor
their standard errors depend on where the phenotype's or covariates' zeroes
are. Quantitative covariates are standardized (PLINK 2's
`--covar-variance-standardize`), which leaves the variants' tests as they are
too, and keeps a covariate of large values, such as a year, from making the
regression too ill-conditioned for PLINK 2 to solve.

It returns a hash ref of `model` (`linear` or `logistic`), `samples` (those
of the VCF that have a value of the phenotype) and `variants`, an array ref
of the variants, each with:

- `beta`: the change in the phenotype for each copy of the ALT allele, or,
  for a logistic regression, in its log odds, so that `exp(beta)` is the odds
  ratio.
- `se`: the standard error of `beta`.
- `stat`: the t statistic (linear) or z statistic (logistic).
- `p`: its p-value, not corrected for the number of variants tested (5e-8 is
  the usual genome-wide threshold).
- `n`: the samples in the regression.
- `alt_freq`: the ALT allele's frequency among them.
- `firth`: 1 where Firth's regression was used, and 0 otherwise.
- `error`: undef, or PLINK 2's code (its `ERRCODE`) for why the variant
  could not be tested, when `beta`, `se`, `stat` and `p` are undef.

## admixture(%args)

Estimates each sample's ancestry as fractions of `k` ancestral populations,
and each population's allele frequencies, by the model of
[ADMIXTURE](https://dalexander.github.io/admixture/) (Alexander, Novembre and
Lange 2009): a sample's count of a variant's ALT allele is binomial, with the
probability its fractions give, averaged over the populations' frequencies.
Unlike the functions above, it needs no PLINK 2: `Bioinf.xs` reads the VCF and
fits the model, by the EM algorithm of Tang et al. (2005), accelerated by
SQUAREM (Varadhan and Roland 2008).

    my $a = admixture(vcf => 'cohort.vcf.gz', k => 3);
    # { k => 3, loglik => -15257.557473, converged => 1, iterations => 234,
    #   starts => [-15257.557474, -15321.242788, ...],
    #   samples => { NA06984 => [0.544524, 0.000010, 0.455466], ... },
    #   variants => [ { chrom => 1, pos => 30028088, id => '.', ref => 'A', alt => 'G',
    #                   freq => [0.29, 0.94, 0.57] }, ... ] }

- `vcf` (required): a `.vcf`, `.vcf.gz`, `.vcf.bgz` or `.vcf.bz2` file, as
  `sex_check` takes. Only biallelic records on the autosomes (1 to 22) are
  read, as for the functions above; a call of one allele, or with a missing
  allele, is missing.
- `k` (required): the ancestral populations, 2 or more, and fewer than the
  samples. Which `k` fits best is not chosen here; compare the fits of
  several.
- `starts`: the random starts fitted, 10 by default, of which the one with the
  highest likelihood is kept. The likelihood has local maxima: on the 60
  people of three populations in `t/data/popgen.vcf`, ADMIXTURE 1.3.0 itself
  stopped at the lesser of two from 2 of 6 seeds.
- `seed`: start `s` (counting from 0) is drawn from `seed + s`; 1 by default.
  The starts are drawn from integers alone, so a seed gives the same start on
  every platform.
- `tolerance`: a start stops when an iteration raises its log-likelihood by
  less than this, 1e-10 by default. ADMIXTURE's own default is 1e-4, which is
  too loose for EM steps, which creep where the likelihood is flat. On that
  file, 1e-4 stopped 1.1e-3 below ADMIXTURE's maximum, with fractions 8e-4
  from ADMIXTURE's; at 1e-8, starts that reached the log-likelihood to 1e-6
  still had fractions up to 1.4e-4 from it; and at 1e-10 every start that
  reached the greater maximum had every fraction within 1.9e-5, which is
  ADMIXTURE's own precision. A looser tolerance is faster, and may serve on
  a large file.
- `max_iterations`: the iterations (of three EM steps each) after which a
  start stops, 10,000 by default. When the best start stopped so, it warns.
- `min_depth`: a genotype whose `DP` is below this is missing; 0 (the
  default) keeps every one.

It returns a hash ref of `k`, `loglik` (the best start's log-likelihood, as
ADMIXTURE prints it, without the binomial coefficients), `converged` (1 or
0), `iterations`, `starts` (each start's log-likelihood, in order),
`samples` (each sample's fractions, an array of `k` that sums to 1) and
`variants` (each variant, with `freq`, its ALT allele's frequency in each
population). The populations are unnamed, and come in the order of their
share of the samples, the largest first, so that two fits of the same data
give them in the same order. No fraction or frequency is below 1e-5 or above
1 - 1e-5, ADMIXTURE's bounds. A sample with no called genotype gets an even
share of each population, with a warning.

All the genotypes are held, a byte each, so a cohort of 1,000 people at a
million variants takes 1 GB. Prune the variants first, as ADMIXTURE's manual
(section 2.3) advises, since the model takes no account of linkage
disequilibrium; its example, `plink --indep-pairwise 50 10 0.1`, is
`ld_prune(vcf => $vcf, window => 50, step => 10, r2 => 0.1)`. Each iteration takes time in proportion to the
samples, the variants and `k`, times the starts.

## sex_check(%args)

Tells each sample of a VCF as male or female from its genotypes on X, by the
method of [peddy](https://github.com/brentp/peddy)'s `sex_check` (0.4.3): of
the SNVs on X outside its pseudo-autosomal regions, the ratio of heterozygous
calls to homozygous-ALT ones, which is near 0 for a male, whose one X can be
heterozygous only by error, and above 1 for a female. The file is
decompressed by perl and its lines counted in XS, which holds nothing but
seven counters for each sample, so that a whole genome costs about what
decompressing it does. It prints a report to STDOUT and returns the same
results as a hash:

    use Cn::Bioinf 'sex_check';

    my $sex = sex_check(vcf => 'genome.vcf.gz');
    my $same = sex_check('genome.vcf.gz');    # the file may come first, unnamed

prints

    sex_check: genome.vcf.gz
    male when het/hom-ALT, over SNVs on X outside its pseudo-autosomal regions, is below 0.6; genotypes of DP below 7 not counted
    sample  sex   het/hom-ALT  X het  X hom-ALT  X haploid  X missing  Y called
    genome  male        0.029   1990      68035          0          0      2746

with one row for each sample, in the VCF's order, and a last line counting
the samples whose sex is unknown, if any. It returns

    # { sample => { sex => 'male', het_ratio => 0.0292, x_het => 1990,
    #               x_hom_alt => 68035, x_hom_ref => 0, x_haploid => 0,
    #               x_missing => 0, y_called => 2746, y_alt => 2746 } }

On 2026-10-18 a 155 MB `.vcf.gz` of a whole genome (3.5 million records)
took 4.8 s and 47 MB, where `zcat` alone takes 3.7 s; the same file as a
`.vcf.bz2` took 19.4 s, nearly all of it bzip2's.

- `vcf` (required): a `.vcf`, `.vcf.gz`, `.vcf.bgz` or `.vcf.bz2` file, the
  suffix in any case. It may also be given first, without its name, as
  `sex_check($file)` or `sex_check($file, report => 0)`. A VCF may name its chromosomes `chrX`, `X` or `23`
  (and `chrY`, `Y` or `24`); records on any other are skipped unread.
- `cutoff`: a sample whose `het_ratio` is below this is male, and otherwise
  female. The default, 0.6, is peddy's. On five genomes the three males' ratios
  were 0.029 (a whole genome), 0.103 and 0.201 (exomes), and the two
  females' 1.660 and 1.712 (exomes); an exome's off-target calls make more
  false heterozygotes than a genome's.
- `min_depth`: a genotype whose `DP` is below this is not counted. The
  default, 7, is peddy's; 0 counts every genotype. A genotype with no `DP`,
  or a `DP` of `.`, is counted.
- `report`: 1 (the default) prints the report; 0 prints nothing, and only
  returns the results.

What is counted, and where `sex_check` differs from peddy:

- X's pseudo-autosomal regions are taken as X:10000-2781479 and
  X:154931044-156030895, peddy's bounds, which cover GRCh37's and GRCh38's,
  so no build need be given. Y's are both builds' too.
- Only biallelic SNVs are counted: a record whose `REF` or `ALT` is not a
  single base (an indel, a multi-allelic site, or an `ALT` of `.`, `*` or
  `<NON_REF>`) is skipped, where peddy keeps an insertion. A record with no
  `GT` in its `FORMAT` is skipped too.
- Every site is counted, where peddy stops at 10,000, and peddy's filters on
  a site's call rate and ALT frequency across the cohort, which mean nothing
  for one genome, are left out.
- A haploid call, as a caller that knows a sample is male writes it on X,
  counts as homozygous: `1` as hom-ALT, `0` as hom-REF.
- A sample with no het or hom-ALT call on X has `sex` and `het_ratio` undef.
  peddy divides by a hom-ALT count of 0 as if it were 1, and so would call
  such a sample male. When the whole VCF has no SNV on X outside the
  pseudo-autosomal regions, `sex_check` also warns.

Returns a hash ref keyed by sample, a hash of hashes that `write_table` can
write, with these fields for each sample:

- `sex`: `male`, `female`, or undef.
- `het_ratio`: `x_het` divided by `x_hom_alt` (by 1 when `x_hom_alt` is 0),
  or undef when both are 0.
- `x_het`, `x_hom_alt`, `x_hom_ref`: the sample's heterozygous,
  homozygous-ALT and homozygous-REF calls at the SNVs counted on X. A VCF
  that lists only the sites where its sample carries an ALT allele has no
  hom-REF calls.
- `x_haploid`: of those, the haploid calls.
- `x_missing`: the sample's calls there that were missing (`./.`, `.`,
  partly missing, such as `./1`, or cut short, such as `1/`), or not a call of
  one or two alleles of the record's two. A genotype left out by `min_depth` is in no count.
- `y_called`, `y_alt`: the sample's calls at SNVs on Y outside its
  pseudo-autosomal regions, and those of them that carry the `ALT`. They
  decide nothing: an exome of a woman had 530 called SNVs on Y, and one of a
  man 659, since a short read from X often maps to Y. They show at most
  whether Y was called at all.

A BCF or a `.pgen` is not read; convert it with `bcftools view -Oz`.

## parent(%args)

Tells whether two people are parent and child from their genotypes, and
returns 1 if they are and 0 if not. A child has one allele from each parent at
every site, so wherever a parent is homozygous the child carries that allele,
and the two are never opposite homozygotes (one hom-REF and the other
hom-ALT, which is called IBS0) except by a genotyping error. Genotypes cannot
tell which of the two is the parent, so `child` and `parent` may be given
either way round, with the same result. Paternity and maternity are this
together with the parent's sex, which `sex_check` tells.

Over the autosomal biallelic SNVs where either of the two carries the ALT, a
pair is parent and child when the IBS0 rate (the share of those sites that are
IBS0) is below `max_ibs0`, and the
[KING](https://www.kingrelatedness.com/manual.shtml)-robust kinship
coefficient is from 0.177 to 0.354, KING's range for first-degree relatives.
Full siblings have that kinship too, but they share no allele by descent at a
quarter of sites, so they have opposite homozygotes there, and the IBS0 rate
tells them apart. One person sequenced twice, or identical twins, have a
kinship above 0.354, and are not parent and child.

The file is decompressed by perl and counted in XS, as for `sex_check`. The
two people are either two samples of one VCF, or each the one sample of a VCF
of their own, as a sequencing company delivers it:

    use Cn::Bioinf 'parent';

    my $is = parent(child => 'child.vcf.gz', parent => 'father.vcf.gz');
    my ($same, $stats) = parent(vcf => 'family.vcf.gz', child => 'C', parent => 'F');

The first prints

    parent: child child.vcf.gz, parent father.vcf.gz
    parent and child (1): the IBS0 rate, 0.0030, is below 0.012, and kinship 0.2587 is from 0.177 to 0.354, as for first-degree relatives
    sites compared           150970  autosomal biallelic SNVs where either carries the ALT, DP 10 or more
      in both VCFs            98828
      in the child's alone    27645  the parent taken as hom-REF
      in the parent's alone   24497  the child taken as hom-REF
    IBS0                        458  opposite homozygotes
      child hom-ALT             305  and the parent hom-REF
      child hom-REF             153  and the parent hom-ALT
    IBS1                      76262  one allele shared
    IBS2                      74250  both alleles shared
    het in both               43727
    het                       82821  the child's, and 80895 the parent's
    hom-ALT                   43652  the child's, and 42430 the parent's
    kinship                  0.2587  KING-robust, between-family

and returns 1. On 2026-10-18 the exomes of one family, all three sequenced and
called together, gave:

    child, parent    sites compared  IBS0 rate  kinship  returned
    child, father           150,970     0.0030   0.2587         1
    child, mother           158,616     0.0020   0.2604         1
    father, mother          171,033     0.0810   0.0174         0

Each pair took 1.6 s. A genome against an exome took 7.3 s and 89 MB, and is
not to be trusted, for the reason under "Each sample's own VCF" below.

- `child`, `parent` (required): without `vcf`, the two VCF files, each of one
  sample (`.vcf`, `.vcf.gz`, `.vcf.bgz` or `.vcf.bz2`, as for `sex_check`);
  with `vcf`, the names of two of its samples.
- `vcf`: a VCF that holds both samples.
- `min_depth`: a genotype whose `DP` is below this is not counted. The
  default is 10; 0 counts every genotype. A genotype with no `DP`, or a `DP`
  of `.`, is counted. On the family above, counting every genotype gave the
  parent and child pairs IBS0 rates of 0.254 and 0.215, as high as an
  unrelated pair's, from calls of `DP` 1 to 3 made off the exome's targets. A
  `min_depth` of 7 gave 0.0053 and 0.0037, and 10 gave 0.0030 and 0.0020,
  keeping 92% of the sites of 7.
- `max_ibs0`: the IBS0 rate a parent and child must be below. The default,
  0.012, is [peddy](https://github.com/brentp/peddy) 0.4.3's (`ped_check`).
  It lies between the parent and child rates above (0.002 to 0.005) and the
  0.02 or so expected of full siblings, a quarter of the unrelated pair's 0.081.
- `report`: 1 (the default) prints the report to STDOUT; 0 prints nothing.

What is counted:

- Only the autosomes, named `1` to `22` or `chr1` to `chr22`; X is left out,
  since a father gives his X to a daughter and not to a son.
- Only biallelic SNVs: a record whose `REF` or `ALT` is not a single base, or
  that has no `GT`, is skipped.
- A call counts when it is diploid and of the record's `REF` and `ALT`, and
  is not below `min_depth`. A missing or partly missing call (`./.`, `./1`), a
  haploid one, or one with an allele the site lacks leaves that site out.
  So do sites where both are hom-REF, which say nothing about relatedness; a
  cohort's VCF has a great many of them.

Each sample's own VCF lists only the sites where its sample carries an ALT
allele, so a site that one file lacks is taken as hom-REF in that person, and
the two files are compared site by site, holding both in memory (8 bytes a
site, so about 30 MB for a genome). A position is left out when either file has more
than one SNV there (as after `bcftools norm -m-`), a call that does not count,
or a record of more than one `ALT`, or when the two files give it different
`REF` or `ALT` alleles. The files may name and order their chromosomes
differently.

Taking a missing site as hom-REF is right only when the other file was
sequenced and called there too, so two VCFs from one pipeline are what this
compares well. A genome's VCF has millions of sites that an exome's lacks, and
two exome capture kits target different regions; either makes IBS0 out of
sites that one of the two never had sequenced. The report gives the sites in
each file alone for that reason, and `parent` warns when one file has more
than twice as many as the other: the three pairs of the family above had
ratios of 1.13 at most, an exome of another kit had 3.0 to 13 against them,
and a genome against an exome 58 (with a kinship of -19.8). The difference
must also be 50 sites or more, which chance does not give (a ratio over 2 with
a difference of 50 has a chance of 4.8e-5 at most, were a site as likely to be
in either file alone), and 0.9% or more of the sites compared, since fewer
could not carry the parent and child above over `max_ibs0` even if every one
were an opposite homozygote; so two VCFs that list every site and differ by 3
sites against 1 are not warned of. A VCF
that leaves out filtered calls has holes that look hom-REF too.

`parent` dies, rather than return a 0 or 1 that it has no grounds for, when

- fewer than 1,000 sites are compared, which at the unrelated pair's IBS0 rate
  would hold 81 opposite homozygotes on average, 8 standard deviations above
  the 12 that `max_ibs0` allows (an exome gives about 150,000 and a genome 3
  million);
- neither has a hom-REF call where the other carries the ALT, so that IBS0
  cannot be seen. A VCF merged from VCFs that list only their own sample's
  variants, as `bcftools merge` writes it without `-0`, is like that, with
  `./.` wherever a sample had no variant; give each sample's own VCF instead;
- either has no het call at the sites compared, so that no kinship can be
  taken.

In scalar context `parent` returns 1 or 0. In list context it returns that and
a hash ref of what it was decided from, with the same fields on every return:

- `parent`: 1 or 0, as returned.
- `relationship`: `parent-child`, `full siblings`, `duplicate` (one person or
  identical twins), `second-degree`, `third-degree` or `unrelated`, by
  KING's kinship ranges, with the IBS0 rate telling parent and child from
  full siblings.
- `kinship`: the KING-robust between-family estimate (Manichaikul et al. 2010,
  *Bioinformatics* 26:2867), which is what PLINK 2's `--make-king-table`
  gives, and which agreed with it exactly on the VCF of two of the exomes
  above merged by `bcftools merge -0`.
- `ibs0_rate`: `ibs0` divided by `sites`.
- `sites`: the sites compared, and of them `in_both`, `child_only` and
  `parent_only`: those in both own VCFs, in the child's alone and in the
  parent's alone. With `vcf`, every site is `in_both`.
- `ibs0`, `ibs1`, `ibs2`: the sites where the two share no allele, one, or
  both; and `ibs0` split into `child_alt_parent_ref` and
  `child_ref_parent_alt`.
- `het_het`: the sites where both are het; `child_het`, `parent_het`,
  `child_hom_alt` and `parent_hom_alt`: each one's het and hom-ALT calls at
  the sites compared.

A BCF is not read; convert it with `bcftools view -Oz`.

## relatedness(@vcf, %args)

Tells how every two people are related, from their genotypes: each pair's
KING-robust kinship and its IBS0, IBS1 and IBS2 counts, as `parent` takes them
for one pair, and from those a relationship (parent and child, full siblings,
one person twice, second- or third-degree relatives, or unrelated). Each
person's sex is told from X in the same reading, as `sex_check` tells it, so
that the relationship can be named: `father-son`, `mother-daughter`,
`brother-sister`, `brothers`, `sisters`, and so on. Genotypes alone cannot
tell which of a parent and child is the parent, but a third person often can,
and `relatedness` says which when one does.

The people are either every sample of one VCF, or the one sample of each of
several VCFs, as a sequencing company delivers them:

    use Cn::Bioinf 'relatedness';

    my $family = relatedness('family.vcf.gz');              # every pair of its samples
    my $same   = relatedness('mom.vcf.gz', 'dad.vcf.gz', 'kid.vcf.gz', report => 0);
    my ($pairs, $samples) = relatedness(vcf => ['mom.vcf.gz', 'dad.vcf.gz']);

    print $family->{js}{dc}{category}; # father-son
    print $family->{dc}{js}{category}; # the same hash, so the same

The second prints

    relatedness: mom.vcf.gz, dad.vcf.gz, kid.vcf.gz
    KING-robust kinship over autosomal biallelic SNVs where either carries the ALT, genotypes of DP below 10 not counted; first-degree from 0.177 to 0.354, and of those, parent and child when the IBS0 rate is below 0.012; male when het/hom-ALT on X outside its pseudo-autosomal regions is below 0.6
    sample  sex     X het/hom-ALT  VCF
    mom     female          1.690  mom.vcf.gz
    dad     male            0.206  dad.vcf.gz
    kid     female          1.698  kid.vcf.gz
    sample  sample   sites  IBS0 rate  kinship  relationship
    mom     dad     171033     0.0810   0.0174  unrelated
    mom     kid     158616     0.0020   0.2604  mother-daughter (mom the parent)
    dad     kid     150970     0.0030   0.2587  father-daughter (dad the parent)

for the exomes of the family under `parent`, and returns the same. Every
pair's counts are those `parent` gives for it.

The VCFs are decompressed by perl and counted in XS. One VCF of several
samples is read a record at a time, keeping nothing but each pair's counters,
and each pair's counts are taken 64 sites at a time from bit masks of the
samples' genotypes; several VCFs of one sample each are held in memory, 8 bytes
a site, as `parent` holds two, and opened one at a time. On 2026-10-19 the
three exomes above took 2.5 s and 30 MB, where `parent` takes 1.6 s for one
pair of them. The 17 samples of the CEPH 1463 pedigree (peddy's
`ceph1463.peddy.vcf.gz`, 20,000 sites) took 0.27 s. A made-up VCF of 1,000
samples and 20,000 sites took 5.3 s and 890 MB: the counting took 1.7 s and 96
MB, and nearly all the rest is the 499,500 hashes returned.

- The VCFs are given first, as `relatedness($file)` or
  `relatedness($file, $file2, ...)`, before any option, or as `vcf`. Each is a
  `.vcf`, `.vcf.gz`, `.vcf.bgz` or `.vcf.bz2` file, as for `sex_check`. One VCF
  must have two samples or more; each of several must have one, and no two the
  same sample name, which is what each sample is known by.
- `vcf`: a VCF, or an array ref of them, in place of giving them first.
- `min_depth`: a genotype whose `DP` is below this is not counted, on X as on
  the autosomes. The default, 10, is `parent`'s, for `parent`'s reasons; 0
  counts every genotype.
- `max_ibs0`: the IBS0 rate that a parent and child must be below, which tells
  them from full siblings. The default, 0.012, is `parent`'s.
- `report`: 1 (the default) prints the report to STDOUT; 0 prints nothing.

What is counted is what `parent` counts, for every pair: the autosomal
biallelic SNVs where either of the two carries the ALT, a site that one own VCF
lacks taken as hom-REF in that person, and a site left out of a pair for the
reasons given under `parent`. Each person's sex is from SNVs on X outside its
pseudo-autosomal regions, as `sex_check` tells it with its default `cutoff`
(0.6), but with `min_depth` as given here.

A pair's relationship is decided as `parent` decides it: by KING's kinship
ranges, with the IBS0 rate telling parent and child from full siblings. Its
category names it from the two sexes:

- A parent and child is `father-son`, `father-daughter`, `mother-son` or
  `mother-daughter` when it is known which is the parent and both sexes are
  known, with `parent` or `child` in place of a word whose sex is unknown
  (`parent-son`). When it is not known which is the parent, two men are
  `father-son` and two women `mother-daughter` all the same, and a man and a
  woman are `parent-child`.
- Full siblings are `brothers`, `sisters` or `brother-sister`, or
  `full siblings` when either's sex is unknown.
- Any other relationship is its own category: `duplicate`, `second-degree`,
  `third-degree` or `unrelated`.

Which of a parent and child is the parent is told by a third person: x is y's
parent when x has another child who is y's full sibling, or when y has another
parent who is unrelated to x (the two being y's parents). When neither is
said, or both, as in a pedigree that this reading cannot untangle, `parent` is
undef. On CEPH 1463, three generations of 17 people, `relatedness` agreed with
the pedigree on all 17 sexes and on 134 of the 136 pairs, including every
father, mother, son, daughter, brother and sister, and which of each parent
and child was the parent. The other two pairs were the grandson NA12893 with
his grandfather and with his grandmother, whose kinships of 0.0839 and 0.0799
are just under KING's 0.0884 for second-degree relatives, and so are
`third-degree`.

Where `parent` would die, `relatedness` decides nothing about that pair and
goes on to the next: its `relationship` and `category` are undef and
`undecided` says why, and `relatedness` warns once, counting such pairs. That
is when fewer than 1,000 sites are compared, when neither has a hom-REF call
where the other carries the ALT (as in a VCF merged without `-0`), or when one
has no het call, which leaves `kinship` undef too. When several VCFs are
given, `relatedness` also warns once about the pairs whose VCFs look
sequenced over different regions, as `parent` warns about one.

In scalar context `relatedness` returns a hash of hashes keyed by each sample
and then by each other sample, so that `$r->{js}{dc}` and `$r->{dc}{js}` are
the same pair, and the same hash: changing one changes the other. In list
context it returns that and a hash ref of the samples. A pair's hash has these
fields on every return:

- `relationship`: as `parent` gives it (`parent-child`, `full siblings`,
  `duplicate`, `second-degree`, `third-degree` or `unrelated`), or undef when
  the pair is undecided.
- `category`: the relationship named by sex, as above, or undef.
- `parent`: the name of the one that is the parent, for a parent and child
  where a third person says which; otherwise undef.
- `undecided`: why the pair is undecided, or undef.
- `kinship`: the KING-robust between-family estimate, or undef when either has
  no het call. On `t/data/parent.vcf` it agreed with PLINK 2's
  `--make-king-table` for all 21 pairs.
- `ibs0_rate`: `ibs0` divided by `sites`, or undef when there are no sites.
- `sites`: the sites compared, of which `in_both` were in both VCFs, and
  `only`, a hash of each of the two samples, those in that sample's VCF alone.
  With one VCF, every site is `in_both`.
- `ibs0`, `ibs1`, `ibs2`: the sites where the two share no allele, one, or
  both; `het_het`: those where both are het; `het`, a hash of each of the two
  samples: its het calls at the sites compared.

`parent`'s split of `ibs0`, and each one's hom-ALT count, are left out, since
each hash of two numbers adds a third to a pair's memory; `parent` gives them
for any one pair.

The samples' hash has, for each sample, what `sex_check` returns for it
(`sex`, `het_ratio`, `x_het`, `x_hom_alt` and the rest), and `file`, its VCF.

A BCF is not read; convert it with `bcftools view -Oz`.

## concordance(%args)

Compares the genotype calls of a VCF under test with those of a truth VCF,
sample by sample, and counts each kind of agreement and disagreement, as
`x.low_ram_local_concordance.pl` did:

    use Cn::Bioinf 'concordance';

    my $r = concordance(truth => 'truth.vcf.gz', test => 'test.vcf.gz');
    print $r->{NA12878}{metrics}{genotype_concordance};
    foreach my $site (@{ $r->{NA12878}{discordances} }) {
    	print "$site->{chrom}:$site->{pos} $site->{type}: test $site->{test}, truth $site->{truth}\n";
    }

This is based off of https://link.springer.com/article/10.1186/s12920-022-01199-8

Each of the test's samples is compared with the truth's sample of the same
name, and a sample in only one of the files is left out. When each file has
exactly one sample, the two are compared whatever they are called, so a run
named `run42` can be compared with its truth `NA12878`. When no sample can be
paired, `concordance` dies and names some of each file's samples.

Every record of the test is compared with the truth's record of the same
CHROM, POS, REF and ALT. A `chr` prefix on CHROM, in any case, is ignored, and
so is ID. When the truth has no such record, its call there is a no-call. A
site that the truth has and the test lacks is not compared at all, so the
test's sites are the ones measured, as for a genotyping panel against a
genome. A site whose ALTs are listed in another order, or split over two
records, is a different site.

The two files have to be on the same genome build, since a site's POS in
GRCh37 (hg19) is not the same place in GRCh38 (hg38). Before either file is
read, `concordance` compares the lengths that their headers' `##contig` lines
give, matching contigs by name without `chr`, as sites are matched. It dies if
any contig that both give a length for has different lengths, and names the
contigs and the build each header gives (its `assembly`, or else its
`##reference`). hg19 and b37, whose chromosomes are the same lengths, pass. A
header with no `##contig` lengths cannot be checked this way. When none of the
test's sites is in the truth, `concordance` warns that the builds may differ.

On `t/data/concordance.test.vcf` against `t/data/concordance.truth.vcf` it
prints

    concordance: test concordance.test.vcf against truth concordance.truth.vcf
    each test site compared with the truth's of the same CHROM, POS, REF and ALT, a site the truth lacks being a no-call there; precision, recall and specificity are of genotypes
    sample  sites  in truth  concordant  discordant  gained  lost  concordance  precision  recall  specificity
    B          46        45          34          10       2     0       0.7674     0.9412  0.8889       0.9375
    A          46        45          11          32       2     1       0.2381     0.4286  0.4286       0.1111
    1 of the test's 3 samples are not in the truth: D

When the paired samples' names differ, a `truth sample` column follows
`sample`.

The VCFs are decompressed by perl and compared in XS. The test is read first,
and its sites are kept with their calls for the samples compared, about 100
bytes a site for one sample. Then the truth is read a record at a time and
looked up among them, so memory grows with the test, which is usually the
smaller file. On 2026-10-19, one exome compared against another (274,879 test
sites) took 1.9 s and 211 MB, or 1.7 s and 47 MB with `discordances => 0`,
because most of that memory is the 163,376 discordant and gained sites
returned. A genome compared with itself (3.5 million sites) took 14 s and 362
MB, most of the time being gzip.

- `truth`, `test`: the two VCFs, each a `.vcf`, `.vcf.gz`, `.vcf.bgz` or
  `.vcf.bz2` file, as for `sex_check`.
- `min_depth`: a genotype whose `DP` is below this is a no-call, in either
  file. The default, 0, compares every genotype, as the script did. A `DP`
  that is absent or `.` leaves the genotype compared.
- `discordances`: 1 (the default) lists each discordant, gained and lost site
  in `discordances`; 0 only counts them, and leaves `discordances` undef.
- `report`: 1 (the default) prints the report to STDOUT; 0 prints nothing.

A call is compared by its alleles, in either order and phased or not, so
`1/0`, `0|1` and `0/1` are the same call. Each call is one of hom-REF
(`0/0`), het-REF (`0/1`), hom-ALT (`1/1`, `2/2`), het-ALT (`1/2`),
haploid-REF (`0`), haploid-ALT (`1`), or a no-call. A missing call (`.` or
`./.`), a partly missing one (`./1`), one of more than two alleles, and one
where FORMAT has no `GT` are all no-calls. Each comparison, truth first, is one
of 45 kinds, the script's:

- `concordant_` and the class, when the two calls are the same:
  `concordant_hom_ref`, `concordant_het_ref`, `concordant_hom_alt`,
  `concordant_het_alt`, `concordant_haploid_ref`, `concordant_haploid_alt` and
  `concordant_no_call`.
- `concordant_diploid_ref_to_haploid_ref` and
  `concordant_haploid_ref_to_diploid_ref`, for `0/0` against `0` and `0`
  against `0/0`; `concordant_hom_alt_to_diploid_alt` and
  `concordant_haploid_alt_to_hom_alt`, for `1/1` against `1` and `1` against
  `1/1`.
- `lost_site`, when the truth has a call and the test a no-call, and
  `gained_site`, when the test has a call and the truth a no-call.
- `discordant_` and the two classes otherwise, as in
  `discordant_het_ref_to_hom_alt` (`0/1` in the truth, `1/1` in the test).
  Two different calls of the same class are discordant too, as in
  `discordant_het_ref_to_het_ref` (`0/1` against `0/2`).

`concordance` returns a hash keyed by the test's name for each sample
compared. Each sample's hash has these fields on every return:

- `test_sample`, `truth_sample`: the sample's name in each file.
- `sites`: the test's records, every one compared; `in_truth`: how many of them
  the truth has.
- `counts`: a hash of the 45 kinds, each with its count, 0 included.
- `metrics`: a hash of the script's metrics, taken from `counts`:
  - `tp_site`: the matched calls that carry an ALT: `concordant_het_ref`,
    `concordant_het_alt`, `concordant_hom_alt`, `concordant_haploid_alt`,
    `concordant_hom_alt_to_diploid_alt` and
    `concordant_haploid_alt_to_hom_alt`. `tp_genotype` is the same number.
  - `fp_site`: `gained_site`; `fn_site`: `lost_site`.
  - `tn_site`: the matched reference calls: `concordant_hom_ref`,
    `concordant_haploid_ref`, `concordant_diploid_ref_to_haploid_ref` and
    `concordant_haploid_ref_to_diploid_ref`. `tn_genotype` is the same
    number.
  - `fp_genotype`: the discordances where the test's call carries an ALT,
    whether the truth's is a reference call or another ALT-carrying call;
    `fn_genotype`: those where the truth's call carries an ALT, whether the
    test's is a reference call or another ALT-carrying call. A discordance of
    two ALT-carrying calls, such as `0/1` against `1/1`, is thus counted in
    both, since the test's call is wrong and the truth's is missed.
  - `genotype_concordance`: the concordant comparisons, less
    `concordant_no_call`, over every comparison but `concordant_no_call`,
    `gained_site` and `lost_site`.
  - `precision_site`: `tp_site / (tp_site + fp_site)`; `recall_site`:
    `tp_site / (tp_site + fn_site)`; `precision_genotype`:
    `tp_genotype / (tp_genotype + fp_genotype)`; `recall_genotype`:
    `tp_genotype / (tp_genotype + fn_genotype)`; `specificity_genotype`:
    `tn_genotype` over `tn_genotype` and those of `fp_genotype` where the
    truth is a reference call, since only those truths are negatives. Each
    ratio is undef when its
    denominator is 0, where the script gave the string `undefined`.
- `discordances`: an array ref of the discordant, gained and lost sites, in the
  test's order, each a hash of `chrom`, `pos`, `id`, `ref` and `alt` as the
  test has them, `type` (the kind), and `test` and `truth`, the two calls as
  GT writes them, or `.` for a no-call; or undef with `discordances => 0`.

Four of the metrics are corrected from the script's. Its `tp_site` pattern,
`/^conc\w+(?:alt|hom)/`, matched the `hom` in `concordant_hom_ref`, so a
hom-REF site was a true positive as well as a true negative, and it missed
`concordant_het_ref`, the commonest true positive. Its `tn_site` missed
`concordant_diploid_ref_to_haploid_ref`, though it took the reverse. And its
`tn_genotype` was `concordant_hom_ref` alone, though its false positives
counted a haploid-REF truth called wrong, so `specificity_genotype` gave no
credit for one called right, as on a male's X. And it counted a discordance
of two ALT-carrying calls in neither `fp_genotype` nor `fn_genotype`, so that
a wrong genotype at a variant site changed neither `precision_genotype` nor
`recall_genotype`.

`concordance` departs from the script where the script failed. The script
took ID as part of a site, and dropped `chr` from the truth's CHROM alone, so
two files that both had it shared no site. It compared GT strings, and so died
on `1/0`, `0|1`, `./1` and calls of three alleles. And it made a no-call
against `.` `discordant_no_call_to_no_call`, outside its own 45 kinds. Its XLSX workbook,
JSON files and ACMG59 column are left to the caller, who has everything they
were made from.

`concordance` warns when the test has no records, and when none of the test's
sites is in the truth, which usually means two genome builds, or two naming
schemes for the chromosomes other than `chr`.

A BCF is not read; convert it with `bcftools view -Oz`.

## blood_type(%args)

Tells each sample's ABO blood group and whether it is RhD positive or
negative from a VCF, with the genotype behind each:

    use Cn::Bioinf 'blood_type';

    my $b = blood_type(vcf => 'exome.vcf.gz');
    print $b->{NA12878}{type};               # A+
    print $b->{NA12878}{abo}{genotype};      # AO
    print $b->{NA12878}{rhesus}{phenotype};  # positive

and prints

    blood_type: exome.vcf.gz
    ABO from rs8176719 (O's deletion), rs8176746 (B) and rs41302905 (O2); RhD from 15 sites of RHD, or a record of the gene's deletion; matched by position on b37; genotypes of DP below 7 not counted
    sample   type  ABO  ABO genotype  RhD       RhD genotype  RHD sites
    NA12878  A+    A    AO            positive  D.                 2/15
    "RHD sites" is how many of the sites the sample has an ALT allele at; one is enough for RhD positive
    not in the file, and taken as homozygous for the reference allele: rs8176746, rs41302905, 13 of the 15 RHD sites

with one row for each sample, in the VCF's order.

**This is not a blood test, and must not be used to choose blood for a
transfusion or for any other clinical purpose.** It reads the common alleles
and nothing else: a weak or partial D, an *RHD* gene that is present but does
not work (the *RHD* pseudogene, common in people of African ancestry, makes
somebody RhD negative whom this calls positive), a hybrid of *RHD* and *RHCE*,
the A2 and other subgroups, cis-AB and the rare O alleles are all outside it.

An exome's 22 MB `.vcf.gz` took 0.8 s and 20 MB, and a whole genome's 155 MB
6.1 s and 47 MB (perl 5.44.0, 2026-11-10). The markers are in
`share/blood_type_panel.tsv`, which `share/make_blood_type_panel.pl` writes;
its header comment says where each comes from, and the module never runs it.

### ABO

Three markers are read. `rs8176719` is the single-base deletion that makes the
common O alleles; the reference genome carries the deletion, on GRCh37 and on
GRCh38, so a VCF writes a working gene there as an insertion, and a chromosome
with that insertion is A or B. `rs8176746` is one of the changes that make
the B enzyme, and `rs41302905` is the O2 allele, an O with no deletion, which
would otherwise be read as A. So a chromosome without the insertion is O,
whatever else it carries; one with it is B with `rs8176746`'s T, O with
`rs41302905`'s T, and otherwise A. The genotype is the two letters, A before B
before O (`AO`, `BO`, `AB`, `OO`), and the phenotype is what they make: `A`,
`B`, `AB` or `O`.

The genotypes are not phased, so somebody heterozygous at both `rs8176719`
and `rs8176746` is read as `BO`, the B allele being taken to be on the
chromosome with the working gene. Of the 5,008 haplotypes of 1000 Genomes'
phase 3, 721 carried both and 44 the B allele without the insertion, which
makes that reading right 98.1% of the time.

Checked against 1000 Genomes on 2026-11-10: the ABO genotype read from phase
3's calls on GRCh37 and the one read from the New York Genome Center's 30x
resequencing of the same people, called afresh on GRCh38, were the same for
all 2,504 of them.

### RhD

Most people who are RhD negative have no *RHD* gene on either chromosome, and
a VCF of SNVs has no record for a gene that is not there. `blood_type` reads
it in one of two ways.

Where the file has a record of a deletion that covers the whole gene, as 1000
Genomes' phase 3 does (`1:25592642 <CN0>`, `END=25661222`), the sample's
genotype there is the answer: `DD`, `Dd` or `dd`. A deletion is an ALT of
`<CN0>`, `<DEL>` or `<DEL:...>`, and has to start at or before the gene and
end, by `END` or `SVLEN`, at or after it.

Otherwise it reads 15 sites inside the gene at which the reference genome
carries a rare allele, so that almost everybody who has the gene has an ALT
call there, and nobody without it has. One such call makes a sample RhD
positive, written `D.`, since SNVs cannot say whether the second chromosome
has the gene too: the ratio of heterozygous to homozygous-ALT calls inside the
gene, which tells sex on X, got a tenth to a quarter of 2,343 people wrong at
any cutoff. No such call makes a sample `dd`, RhD negative, as long as it has
a genotype at one site at least: a call, or a site the file has no record of
that is read as REF (see below). A sample whose calls at every site are
missing, are not diploid, or have a DP below `min_depth` has no RhD type.

The sites were chosen, and counted, in 1000 Genomes: the 30x calls of the
2,493 people whose deletion genotype phase 3 gives. Of the 150 with no gene,
none had a call at any of the 15; of the 2,343 with one or two, 5 had a call
at none, and so are called negative, and 2 at only one. Choosing the sites
on a random half of the people and counting on the other half chose the same
15 and gave the same counts.

An exome sees little of this: the capture kit of the three exomes tried
reached 2 of the 15 sites, at a depth of 13. The types of those three are
known from the depth of their reads: two cover *RHD*'s exons at a mean depth
of 3 and 2 against 90 and 97 over *RHCE*'s, and the third at 30 against 84;
`blood_type` called them negative, negative and positive. A kit that reaches
none of the 15 sites would call everybody
negative, and `carried` and `listed`, below, are returned so that an answer
from few sites can be seen for what it is.

### A marker the file has no record of

A VCF of one person usually lists only the sites where that person carries an
ALT allele, so that somebody who is OO, or has no B allele, or has no *RHD*
gene, simply has no record at those markers. By default a marker with no
record is therefore read as homozygous for the reference allele, and each
answer says which markers that was done for. Two things are not read that
way, because the file could not have held the record:

- a marker on a chromosome the file has no record on at all;
- `rs8176719`, an insertion, in a file with no allele longer than one base on
  chromosome 9. Such a file holds SNVs only, and reading the insertion's
  absence as REF would call everybody O; no ABO type is given, and `why` says
  so.

A file of every site, a cohort's, or a genotyping array's does have a record
where a sample is homozygous REF, and `assume_ref => 0` makes a marker with
no record a marker with no genotype.

### Arguments

- `vcf` (required): a `.vcf`, `.vcf.gz`, `.vcf.bgz` or `.vcf.bz2` file. As
  `sex_check` does, it may be given first and on its own:
  `blood_type('genome.vcf.gz')`.
- `assume_ref`: 1 (the default) reads a marker the file has no record of as
  homozygous for the reference allele, as above; 0 leaves it without a
  genotype.
- `build`: `hg19`, `b37`, `hg38` or `b38`, saying which of the panel's two sets
  of coordinates to match on. By default it is read from the VCF's `##contig`
  lengths, as `hirisplex_genotypes` reads it, and `blood_type` dies asking for
  it when the header gives no length it knows.
- `min_depth`: a genotype whose FORMAT `DP` is below this is not counted.
  Defaults to 7, which is `sex_check`'s and the depth the RhD sites were chosen
  at; 0 counts every call whatever its depth. A genotype with no `DP` is
  always counted.
- `report`: 1 (the default) prints the table to STDOUT; 0 returns the answers
  only.

### What it returns

A hash ref keyed by sample name, each holding:

- `type`: the two together, as `A+` or `O-`, or `undef` when either is not
  known.
- `abo`: a hash ref of
    - `genotype` and `phenotype`: as above, or `undef`;
    - `markers`: a hash ref of rs number => 0, 1 or 2 copies of the allele
      counted, or `undef` where the sample has no genotype;
    - `assumed_ref`: an array ref of the markers the file has no record of
      that were read as homozygous REF;
    - `why`: `undef`, or why no type could be given.
- `rhesus`: a hash ref of
    - `genotype`: `DD`, `Dd` or `dd` from a record of the deletion; `D.` or
      `dd` from the sites; or `undef`;
    - `phenotype`: `positive`, `negative` or `undef`;
    - `basis`: `deletion` or `sites`, saying which of the two it was read
      from, or `undef`;
    - `sites`, `listed` and `carried`: how many RhD sites the panel has, how
      many of them the file has a record of, and at how many this sample has
      an ALT allele;
    - `deleted`: the copies of the deletion the sample has, 0 to 2, or `undef`
      when the file has no record of it that calls the sample;
    - `why`: `undef`, or why no type could be given.

A genotype is counted only when the call is diploid and complete, as
`hirisplex_genotypes` counts one. `blood_type` warns when the file has no
record on chromosome 1 or on chromosome 9, which usually means the wrong
build.

## hirisplex_genotypes(%args)

Reads the 41 markers of the HIrisPlex-S eye, hair and skin colour panel out of
a VCF, counting for each sample how many copies of each marker's model allele
it carries, and can write them as the CSV the HIrisPlex-S webtool uploads:

    use Cn::Bioinf 'hirisplex_genotypes';

    my $g = hirisplex_genotypes(vcf => 'genome.vcf.gz', file => 'hirisplexs.csv');
    print $g->{NA12878}{genotype}{'rs12913832_T'};  # 0, 1, 2, or undef
    print scalar @{ $g->{NA12878}{missing} }, " markers missing\n";

**This distribution ships no prediction model, and `hirisplex_genotypes` makes
no prediction.** The HIrisPlex-S regression coefficients are not published:
Chaitanya et al. (2018) cite them by reference rather than tabulating them,
the webtool offers no download and says that no part of it may be reproduced
without consent, and part of the knowledge behind it is covered by European
patent EP2195448. What is public, and what this function uses, is the panel
itself -- which markers, in which order, and which allele each model counts --
taken from the webtool's own input form. So `hirisplex_genotypes` prepares the
input, and the prediction is made either at
[the webtool](https://hirisplex.erasmusmc.nl/) or by `trait_predict` from a
model table you hold yourself.

### The panel

`share/hirisplex_s_panel.tsv` holds the panel: each marker's rs number, gene,
the allele the model counts, its positions on GRCh37 and GRCh38, and whether
it belongs to the 6-marker IrisPlex and 24-marker HIrisPlex subsets.
`share/make_hirisplex_panel.pl` writes that file from the webtool's form and
Ensembl, and its header comment says how to re-run it; the committed file is
what is used, and the generator is never run by the module.

The webtool asks for a count of the allele on the assay's strand, which is not
always the strand a VCF is written on, and the panel records the forward-strand
allele to count for each marker so that nothing has to be guessed at run time.
Fourteen of the 41 are counted as the complement of the allele the webtool
names. One, ASIP `rs6119471`, carries the named allele on the forward strand
*and* still has to be flipped -- the HIrisPlex-S manual singles it out as "the
only SNP that may cause confusion and therefore must be converted (from NCBI's
forward orientation)" -- so a tool that simply matched the named allele would
silently count the wrong one. MC1R `rs312262906` is not a SNP but the 86insA
frameshift, merged in dbSNP into `rs796296176`; it is counted as the `ALT`
that is `REF` with one `A` put in (`A` to `AA`, or `AA` to `AAA` as GRCh38
writes it), so that an MNV or a symbolic `<INS>` at that position is not taken
for it, and matching by rs number looks for both numbers. Bases are compared
regardless of case.

### Arguments

- `vcf` (required): a `.vcf`, `.vcf.gz`, `.vcf.bgz` or `.vcf.bz2` file. As
  `sex_check` does, it may be given first and on its own:
  `hirisplex_genotypes('genome.vcf.gz')`.
- `match`: `position` (the default) matches CHROM and POS against the panel's
  coordinates; `id` matches the ID column against the markers' rs numbers,
  which finds nothing in a VCF whose ID column is `.`. An ID of several
  names, separated by semicolons as the VCF specification has them, matches
  when any of them is a marker's.
- `build`: `hg19`, `b37`, `hg38` or `b38`, saying which of the panel's two sets
  of coordinates to match on. By default it is read from the VCF's `##contig`
  lengths, and `hirisplex_genotypes` dies asking for it when the header gives
  no length it knows, or lengths that are neither build's.
- `min_depth`: a genotype whose FORMAT `DP` is below this is not counted.
  Defaults to 7, `sex_check`'s default; 0 counts every call whatever its depth.
  A genotype with no `DP` is always counted.
- `file`: write the webtool's CSV here. Its header is that of the webtool's own
  template, column for column, and a marker with no genotype is written `NA`.
- `report`: 1 (the default) prints a table of the samples to STDOUT; 0 returns
  them only.

### What it returns

A hash ref keyed by sample name, each holding:

- `genotype`: a hash ref keyed as the webtool's CSV heads its columns,
  `<rs number>_<input allele>`, holding 0, 1 or 2 copies of that allele, or
  `undef` where the sample has no usable call.
- `missing`: an array ref of the rs numbers with no genotype, in the panel's
  order.
- `markers` and `called`: how many markers the panel holds, and how many this
  sample has a genotype for.
- `eye`, `hair`, `skin`: 1 or 0, whether the HIrisPlex-S rules allow that
  prediction from these markers at all. The manual refuses an eye prediction
  without HERC2 `rs12913832`, a hair prediction when all 11 MC1R markers are
  missing, and both when HERC2, SLC45A2 and IRF4 are all missing, because the
  loss in AUC is too great. It sets no such rule for skin, so `skin` is 0 only
  when nothing at all was called. `trait_predict` honours these.

A genotype is counted only when the call is diploid and complete: a `./.`, a
`./1`, a haploid call (the panel is autosomal) or one below `min_depth` leaves
the marker without a genotype. A site split into one record per ALT is counted
from whichever record carries the counted allele, in either order, and a record
at a marker's position whose REF is longer than one base is some other variant
and is passed over.

`hirisplex_genotypes` warns when the file holds none of the 41 markers, which
usually means the wrong build or an ID column of `.`.

Reading the markers is done in XS, in one pass, keeping one byte per sample per
marker, so a whole-genome VCF costs no more memory than a small one. A
275,879-record exome of 22 MB gzipped took 0.86 s (perl 5.44.0, 2026-10-20).

Most of the panel is intronic or intergenic, so an exome carries little of it:
that same exome held 9 of the 41 markers. A whole-genome VCF, a genotyping
array that covers the panel, or the SNaPshot assay the panel was designed for
is what the prediction expects, and `missing` and `called` are returned so that
a prediction made from a handful of markers can be seen for what it is.

## trait_predict(%args)

Applies a multinomial logistic regression -- which is what the HIrisPlex-S,
HIrisPlex and IrisPlex models are -- to genotypes, and returns a probability
for each category of each trait:

    use Cn::Bioinf qw(hirisplex_genotypes trait_predict);

    my $g = hirisplex_genotypes(vcf => 'genome.vcf.gz', report => 0);
    my $p = trait_predict(genotypes => $g, model => 'my_model.tsv');
    print $p->{NA12878}{eye}{call};          # the most probable category
    print $p->{NA12878}{eye}{p}{blue};       # its probability

The model is yours to supply: see `hirisplex_genotypes` above for why this
distribution ships none. Any model written in the form below works, so this is
not limited to pigmentation.

### The model table

A tab-separated file (optionally gzipped), or a data frame as
`Stats::LikeR`'s `read_table` returns, with four columns:

    trait	category	marker	beta
    eye	blue	(intercept)	3.94
    eye	blue	rs12913832_T	-4.81
    eye	brown	(intercept)	0

`marker` is a key of the `genotype` hash `hirisplex_genotypes` returns, which
is `<rs number>_<input allele>`, or the literal `(intercept)` for the
category's intercept. A category whose only row is an intercept of 0 is the
reference category, which is how a model of *k* categories is written with
*k* - 1 sets of betas; every category that should appear in the result needs at
least one row. Traits and their categories come out in the order the table
first names them. A frame's rows and columns must be of one length, as
`pgs_score`'s must, and a gzipped file that ends early dies.

For each category the linear predictor is its intercept plus the sum of its
betas times the genotypes, and the probabilities are `exp` of those over their
sum. The largest is taken out before `exp`, so a linear predictor large enough
to overflow gives 1 rather than a NaN.

### Arguments

- `genotypes` (required): what `hirisplex_genotypes` returned, or a plain hash
  ref of sample => { marker => 0, 1 or 2 }. A dosage may be any number from 0
  to 2, as imputation gives, and `undef` is no genotype; anything else, `NA`
  included, dies naming the sample and the marker. Only the markers the model
  uses are looked at.
- `model` (required): the table above, as a file name or a data frame.
- `force`: 0 (the default) makes no prediction for a trait that the genotypes
  say cannot be predicted -- that is, where `hirisplex_genotypes` set `eye`,
  `hair` or `skin` to 0; 1 predicts it anyway. A trait the genotypes say
  nothing about is always predicted.
- `report`: 1 (the default) prints a table of the samples to STDOUT; 0 returns
  them only.

### What it returns

A hash ref keyed by sample and then by trait, each holding:

- `p`: a hash ref of category => probability, which sum to 1; empty when the
  prediction was refused.
- `call`: the most probable category, or `undef` when it was refused. A tie is
  broken by the category's name, so the answer does not depend on hash order.
- `markers` and `called`: how many markers the trait's categories use between
  them, and how many this sample has a genotype for.
- `missing`: an array ref of the markers the model names and the sample has no
  genotype for.
- `refused`: `undef`, or why no prediction was made.

A marker the sample has no genotype for drops out of the sum, which is the same
as counting it 0 copies of the counted allele. That is a choice, not something
the HIrisPlex-S authors specify, and it biases the result towards whatever 0
copies means for that marker; `missing` and `called` are returned so that a
prediction made from few markers can be reported as such. The webtool reports a
loss in AUC for exactly this reason.

## plot_msa(%args)

Aligns sequences with Clustal Omega and draws the alignment. Returns a hash ref
of the files made: `filename`, `msa_file`, `python_file` (see `fh` and
`execute` below), and `tree_file` if it was given. Once the image is written it
prints `wrote` and its file name to STDOUT, the name in black on yellow when
STDOUT is a terminal; with `execute => 0` it prints `will write` instead.

    plot_msa(
    	fasta      => 't/data/DEG20010421.fa',
    	filename   => 'DEG20010421.msa.svg',
    );

- `fasta`, `filename` (required): the sequences, as a FASTA file name or a
  hash ref of name => sequence (the function tells the two apart by whether it
  is a reference); and the image to draw, whose extension picks the format.
  A name may hold spaces and punctuation: Clustal Omega is given the sequences
  as `s1`, `s2` and so on, and the alignment and tree it writes get their
  names back, in UTF-8. In the tree, a name with whitespace or any of
  `()[]':;,` in it is quoted as newick quotes one, as `'it''s (x:1)'`.
- `msa_file`, `tree_file`: where to keep clustalo's alignment (FASTA; a
  temporary file otherwise) and its guide tree (newick; not made otherwise).
  Keep the tree to draw it with `plot_phylo` without aligning a second time.
- `order`: names, first to last (default: the input order; for a hash,
  sorted). Only these are drawn, and the first is drawn at the bottom.
- `labels`: a hash ref of name => label to show instead. matplotlib mathtext
  works: `'C.albicans' => '$\it{C. albicans}$'`. Two sequences drawn under one
  label die, since they would be one row of the image.
- `active_site_aa`, `query`: `{ His395 => 395, ... }`, a dashed vertical line
  at each of these 1-based residue numbers of the sequence named by `query`.
  A number below 1 dies.
- `tooltips`: 1 to give each residue a tooltip, which a browser shows when
  the pointer rests on it, naming the sequence, the residue and its number
  in that sequence, and the alignment column, as
  `S.cerevisiae: Lys100, alignment column 105` (default 0). The sequence is
  named as it was given, not by its label. Only SVG carries tooltips, so
  `filename` must end in `.svg`. Each residue is an element of the SVG, so a
  large alignment makes a large file.
- `title`, `xlabel`, `ylabel`, `threads`, `clustal_args`: the plot title; the
  axis labels (default "Amino Acid Residue" and "Protein & Species");
  clustalo threads (default 1); and an array ref of extra clustalo arguments.
- `fh`, `execute`: as for Matplotlib::Simple's `plt`. The image is drawn by a
  Python script, and `fh` is a `File::Temp` object to append that script to;
  without it, the script goes in a new temporary file. `execute` is 1 (the
  default) to run the script now, under Alien::Bioinf's Python, or 0 only to
  write it. So several calls with one `fh` and `execute => 0`, then a last one
  with `execute => 1`, draw every image in one run of Python. The `fh` may be
  one that Matplotlib::Simple's `plt` also writes to, since the Python each
  function appends stands alone. Clustal Omega runs either way; only the
  drawing waits.

  `python_file` is the script's file name: `fh`'s, or the temporary file's,
  which is kept after perl exits only when `execute` is 0. The script carries
  the alignment and everything else it reads, so it can be run later, with
  `perl -MAlien::Bioinf -e 'print Alien::Bioinf->python'` giving the Python to
  run it with, after perl's own temporary files have gone.

With fewer than two sequences it warns and returns an empty hash ref.

## plot_phylo(%args)

Draws a guide tree, with Biopython's `Bio.Phylo`, from a FASTA (aligned with
Clustal Omega first) or from a newick file that `plot_msa` kept. Returns a
hash ref of the files made or used: `output_file`, `python_file`, and
`tree_file` and `msa_file` as below.

    plot_phylo(fasta => 't/data/DEG20010421.fa');   # writes phylo.svg
    plot_phylo(
    	tree_file   => 'DEG20010421.newick',
    	output_file => 'DEG20010421.tree.png',
    );

- `output_file`: the image to draw (default `phylo.svg`, in the working
  directory); the extension picks the format.
- `fasta`, `tree_file`: with `fasta` (as for `plot_msa`), the sequences are
  aligned with Clustal Omega and the guide tree drawn; `tree_file` and
  `msa_file` then say where to keep the tree and alignment, and `threads` and
  `clustal_args` are as for `plot_msa`. Without `fasta`, `tree_file` is an
  existing newick file to draw, such as one `plot_msa` kept, and no alignment
  is made.
- `labels`, `title`: a hash ref of name => label for the tips, as for
  `plot_msa`; and the plot title.
- `fh`, `execute`: as for `plot_msa`, which can share an `fh` with this; the
  script carries the newick tree it draws. `python_file` is the script's file
  name.

With `fasta` of fewer than two sequences it warns and returns an empty hash
ref.

## msa_quality_table(%args)

Draws an all-against-all BLAST score table with matplotlib, and returns
`filename`. The simplest call is

    msa_quality_table(
    	fasta      => 't/data/DEG20010421.fa',  # or { name => sequence }, aligned or not
    	filename   => 'DEG20010421.scores.png',
    );

- `fasta`, `filename` (required): the sequences, as a FASTA file name or a
  hash ref of name => sequence, as for `plot_msa`; they are aligned all
  against all with `blastp`. Gaps are stripped first, so an aligned FASTA,
  such as the one `plot_msa` keeps, will do. Names must look like
  `Genus.species[.strain]`. `fasta` is not needed when an existing
  `alignment_json` is given. `unaligned_fa` is its old name.
- `alignment_json`: the `blastp -outfmt 15` report, as a parsed hash ref or a
  file name. An existing file is read, and nothing is aligned; otherwise
  `blastp` is run on `fasta` and its report kept there for next time. Without
  it, the report is a temporary file.
- `metric`: the hsp field to show (default `score`).
- `normalize`: divide every value by the largest, after adding
  `logscale_add` to both, so the scale runs to 1. A largest value of 0 or
  less, as `evalue` has when BLAST has rounded every e-value to 0, dies.
- `order`, `logscale_add`, `default_undefined`, `title`, `cb_label`, `cb_min`,
  `cb_max`, `cblogscale`, `show_numbers`: the sequences to show, in order; a
  number added to every value; the value of a pair with no hit (otherwise
  drawn grey); the title; the colour bar's label, lower and upper ends, and
  whether it is logarithmic; and whether each cell shows its number. A name
  in `order` that the report does not hold dies, and so does a
  `logscale_add`, `default_undefined`, `cb_min`, `cb_max` or `normalize` that
  is not a number.

`msa_file` is accepted and ignored, for old callers.

## view_alignment($alignment, %args)

Shows an alignment in the terminal, as Stats::LikeR's `view` shows a
dataframe, and draws it as an SVG or writes it as LaTeX tables when asked, with
chosen residues colored. It was `clustal_view_residues` until 2026-11-16,
which wrote only the LaTeX.

    my %seqs = (a => 'MK-LV', b => 'M-QLV');
    view_alignment(\%seqs, row_width => 3, track => 'a',
        color_residues => { a => { 2 => 'red', 3 => [1, 0, 0] } });

prints

    # alignment: 2 sequences x 5 columns
             1 3
    a        MK-  2
    a track  -2-
    b        M-Q  2

             4
    a        LV   4
    a track  3-
    b        LV   4
    # alignment: 2 sequences x 5 columns

Each block of `row_width` columns has its first and last alignment column
above it, and each row ends with how many residues that sequence has had so
far. Colored residues are in their colors when the output is a terminal. As
in `view`, the banner comes first and last, so that an alignment longer than
the screen still says what it is where the scrolling stops.

    view_alignment('orthologs.fa', output_file => 'orthologs.svg');      # an SVG too
    view_alignment(msa_file => 'orthologs.fa', output_file => 'aln.tex'); # LaTeX tables
    my $text = view_alignment(\%seqs, return_only => 1);                 # print nothing

The alignment is the first argument, a hash ref of `name => sequence` or a FASTA
file name, followed by `name => value` pairs. It can also be given as
`msa_file` among the pairs. If its sequences are all one length (such as the
alignment `plot_msa` keeps), it is shown as it is. If not, it is first aligned
with Clustal Omega, which needs Alien::Bioinf; a FASTA file given is never
written. `view_alignment` always returns the text, as UTF-8 bytes and without
the colors, whether or not it also prints it. When it writes a file, it then
prints `wrote` and that file name to STDOUT, the name in black on cyan when
STDOUT is a terminal.

- `msa_file`: the FASTA file, when it is not given first.
- `output_file`: a file to write as well, whose name says what it is: a
  `.svg` is drawn as the terminal shows the alignment, and a `.tex` is written
  as LaTeX tables, to be `\input` into a document whose preamble loads
  `xcolor` (for the colors) and `placeins` (for the `\FloatBarrier` after each
  table). Any other ending dies.
- `title`: a line above the alignment in `output_file`. The SVG draws it
  in bold above the first block, and widens the image when the title is wider
  than the alignment. The LaTeX writes it in bold above each table, with
  "(continued)" after the first table. It is plain text, written so that LaTeX
  prints it as it is, so `_`, `&` and `%` need no escaping. The terminal and the
  text returned do not show it. Without an `output_file` it dies, and so does
  a title that holds a control character, such as a newline. The default is no
  title.
- `color_residues`: `{ protein => { residue number => color } }`, where
  residue numbers are 1-based and a color is one of xcolor's 19 base colors
  (`black`, `blue`, `brown`, `cyan`, `darkgray`, `gray`, `green`,
  `lightgray`, `lime`, `magenta`, `olive`, `orange`, `pink`, `purple`, `red`,
  `teal`, `violet`, `white` and `yellow`, with the RGB values xcolor 3.01
  gives them) or `[r, g, b]`, each 0 to 1. A colored column is colored in every
  protein.
- `color`: 1 to put every residue on its own color, as `plot_msa` colors it
  and as other alignment viewers do (default 0, which colors only
  `color_residues`). See [Coloring every residue](#coloring-every-residue).
- `track`: a protein that gets a row under it showing its colored residue
  numbers, each starting at its residue's column, or just after the number
  before it. A number that would run past the end of its block ends at the
  block's last column instead, and is left out only when it would then
  overwrite the number before it.
- `order`: an array ref of the proteins to show, top to bottom (default:
  sorted, ignoring case).
- `row_width`: alignment columns per block (default 100).
- `to`: the filehandle to print to (default: the one `select` names, which is
  STDOUT unless the program changed it).
- `return_only`: 1 to print nothing, not even the `wrote` line, and only
  return the text (default 0).
- `threads`, `clustal_args`: clustalo threads (default 1) and an array ref of
  further clustalo arguments, when the sequences have to be aligned.

These four shape the LaTeX only, and die with any other `output_file`:

- `split`: blocks per LaTeX table (default 4); further tables are captioned
  "(continued)".
- `caption`: the table caption (default empty).
- `label`: written as `\label{tab:label}`, or as `tab:label0`, `tab:label1`,
  ... when there is more than one table.
- `table_text_size`: the LaTeX size command put at the start of each table
  (default `\footnotesize`).

In the terminal and the SVG, a tab, carriage return or newline in a name is
shown as `\t`, `\r` or `\n`, and any other control character as `\x{..}`. A
sequence that holds a control character dies. In LaTeX, names and residues are
written so that LaTeX prints them as they are, `_`, `^`, `{`, `|`, `<` and the
like included.

### Coloring every residue

With `color => 1`, every residue is on the color `plot_msa` draws it in:
CIAlign's color-blind-safe "CBS" palette (Tumescheit, Firth & Brown, PeerJ
2022), which gives residues of like chemistry one color (D and E, K and R, S
and T, F and Y, N and Q, and L, V and I share theirs). The nucleotide palette is
used instead when every character is a nucleotide code or a gap, as `plot_msa`
decides it, so a protein made only of letters that are also IUPAC nucleotide
codes (such as `ACGT`) is colored as DNA. Gaps and `*` stay uncolored. Each
residue's letter is white or black, whichever contrasts more with its color
by WCAG 2.2's contrast ratio.

The residues of `color_residues` are then on their own colors instead, and
are bold and underlined. In the terminal the colors are 24-bit ANSI
backgrounds, which most terminals show; the text returned has none. In the SVG
each run of a color is one rectangle under the row. In LaTeX each residue is a
`\colorbox`, and each table sets `\fboxsep` to 0 so that the boxes meet.

    view_alignment('orthologs.fa', color => 1, output_file => 'aln.svg');

### The SVG

The SVG is written by this module, not by matplotlib, so an aligned input
needs neither Alien::Bioinf nor Python. Its text stays text: a sequence can be
selected and copied out of it, and searched for in a browser. Each
residue is placed at the center of its own column, so the letters line up with
each other and with their colors in any font and any viewer, Eye of GNOME
(librsvg) included. Each colored residue has a
tooltip that names its sequence, its residue number and its alignment column,
such as `a: K2, alignment column 2`.

Its provenance is where Matplotlib::Simple puts it, as the only metadata in
the file, in `<dc:creator><cc:Agent><dc:title>`, on one line:

    /home/me/view.pl called using "view_alignment" in .../Cn/Bioinf.pm version 0.031 by user me on host box (linux) with Perl 5.44.0 (/usr/bin/perl), written as SVG by .../Cn/Bioinf.pm itself; from the FASTA file /home/me/orthologs.fa (SHA-256 781f...) of 4 sequences; showing 4 of 4 sequences in blocks of 100 columns, tracking S.cerevisiae, coloring 3 columns

When the sequences had to be aligned, the clause after "itself" says how, as
`plot_msa`'s does: the ungapped file clustalo read, the Clustal Omega and
Alien::Bioinf versions, the alignment it wrote, each with its SHA-256, and the
command. A LaTeX file has the same line as its first, a `%` comment.

# Thanks

A lot of this work (not all!) used Claude AI, which was paid for by the University of Idaho's IMCI
