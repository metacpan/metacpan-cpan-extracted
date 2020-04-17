#!/usr/bin/env perl
# PODNAME: inst-qual-filter.pl
# ABSTRACT: Discard low-quality nt seqs in FASTA files

use Modern::Perl '2011';
use autodie;

use Getopt::Euclid qw(:vars);
use Smart::Comments;

use Bio::MUST::Core;
use Bio::MUST::Core::Constants qw(:seqtypes);
use Bio::MUST::Core::Utils qw(secure_outfile);
use aliased 'Bio::MUST::Core::Ali';


my $purity_filter = sub {
    my $seq = shift;

    # compute purity
    # TODO: refactor in module
    (my $pure_seq = $seq->seq) =~ s/$NONPUREDNA//xmsg;
    my $purity = 1.0 * length($pure_seq) / $seq->seq_len;
    return if $purity < $ARGV_min_purity;

    # store allowed seqs (optonally unwrapped)
    # TODO: refactor in module
    my $width = $seq->seq_len;
    my $chunk = $ARGV_nowrap ? $width : 60;     # optionally disable wrap

    my $str = '>' . $seq->full_id . "\n";
    for (my $site = 0; $site < $width; $site += $chunk) {
        $str .= $seq->edit_seq($site, $chunk) . "\n";
    }

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


__END__

=head1 USAGE

qual-filter-fas.pl <infiles> --min[-purity]=<n> [optional arguments]

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

=item --min[-purity]=<n>

Fraction (between 0 and 1) of pure DNA character states (ACGT) required by a
sequence for it to be retained [default: 1]. All other states (including
ambiguous, missing and gap-like character states) are considered as non-pure.

=for Euclid:
    n.type:    number
    n.default: 1

=item --[no]wrap

[Don't] wrap sequences [default: yes].

=item --version

=item --usage

=item --help

=item --man

Print the usual program information

=back
