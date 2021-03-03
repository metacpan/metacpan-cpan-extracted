#!/usr/bin/env perl
# PODNAME: inst-qual-filter.pl
# ABSTRACT: Discard low-quality nt seqs in FASTA files (optimized)
# CONTRIBUTOR: Valerian LUPO <valerian.lupo@doct.uliege.be>

use Modern::Perl '2011';
use autodie;

use Getopt::Euclid qw(:vars);
use Smart::Comments;

use Bio::MUST::Core;
use Bio::MUST::Core::Constants qw(:seqtypes);
use Bio::MUST::Core::Utils qw(secure_outfile);
use aliased 'Bio::MUST::Core::Ali';


my @bad_seqs;

my $purity_filter = sub {
    my $seq = shift;

    # compute purity
    my $purity = $seq->purity;
    if ($purity < $ARGV_min_purity) {
        push @bad_seqs, $seq;
        return;
    }

    # store allowed seqs
    my $str = '>' . $seq->full_id . "\n";
    $str .= $seq->wrapped_str;

    return $str;
};

for my $infile (@ARGV_infiles) {
    # --out-suffix is required in this script
    my $outfile = secure_outfile($infile, $ARGV_out_suffix);

    ### Processing: $infile
    Ali->instant_store(
        $outfile, { infile => $infile, coderef => $purity_filter }
    );
}

if ($ARGV_filter_out) {

    ### Storing filtered seqs in: $ARGV_filter_out
    my $ali = Ali->new( seqs => \@bad_seqs, guessing => 0 );
    $ali->store_fasta($ARGV_filter_out);
}

__END__

=head1 USAGE

    inst-qual-filter.pl <infiles> --out=<suffix> [optional arguments]

=head1 REQUIRED ARGUMENTS

=over

=item <infiles>

Path to input FASTA files [repeatable argument].

=for Euclid:
    infiles.type: readable
    repeatable

=item --out[-suffix]=<suffix>

Suffix to append to infile basenames for deriving outfile names.

=for Euclid:
    suffix.type: string

=back

=head1 OPTIONAL ARGUMENTS

=over

=item --filter-out=<file>

Path to FASTA outfile collecting unpure sequences that have been filtered out
[default: none].

=for Euclid:
    file.type: writable

=item --min[-purity]=<n>

Fraction (between 0 and 1) of pure DNA character states (ACGT) required by a
sequence for it to be retained [default: 1]. All other states (including
ambiguous, missing and gap-like character states) are considered as non-pure.

=for Euclid:
    n.type:    number
    n.default: 1

=item --version

=item --usage

=item --help

=item --man

Print the usual program information

=back
