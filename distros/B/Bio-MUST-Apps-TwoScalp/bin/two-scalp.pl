#!/usr/bin/env perl
# PODNAME: two-scalp.pl
# ABSTRACT: Align or re-align sequences using various strategies

use Modern::Perl '2011';

use Getopt::Euclid qw(:vars);

## no critic (RequireLocalizedPunctuationVars)
BEGIN{
    $ENV{Smart_Comments} = $ARGV_verbosity
        ? join q{ }, map { '#' x (2 + $_) } 1..$ARGV_verbosity
        : q{}
    ;
}
## use critic

use Smart::Comments;

use Bio::MUST::Apps::TwoScalp;
use aliased 'Bio::MUST::Apps::TwoScalp::Seq2Seq';


for my $infile (@ARGV_infiles) {

    ### Processing: $infile
    Seq2Seq->new(
        ali => $infile,
        out_suffix   => $ARGV_out_suffix,
        coverage_mul => $ARGV_coverage_mul,
        single_hsp   => $ARGV_single_hsp,
    );
}

__END__

=pod

=head1 NAME

two-scalp.pl - Align or re-align sequences using various strategies

=head1 VERSION

version 0.180160

=head1 USAGE

    two-scalp.pl <infiles> [optional arguments]

=head1 REQUIRED ARGUMENTS

=over

=item <infiles>

Path to input ALI files [repeatable argument].

=for Euclid: infiles.type: readable
    repeatable

=back

=head1 OPTIONAL ARGUMENTS

=over

=item --out[-suffix]=<suffix>

Suffix to append to infile basenames for deriving outfile names [default:
none]. When not specified, outfile names are taken from infiles but original
infiles are preserved by being appended a .bak suffix.

=for Euclid: suffix.type: string

# =item --mode=scratch|seqs2seqs|seqs2prof|prof2prof

# =item --coding-seqs
#
# Consider the nucleotide alignment as containing coding sequences [default:
# no]. Currently, enabling this switch leads to using TBLASTX instead of BLASTN
# when aligning sequences.

=item --coverage-mul=<n>

Coverage improvement required for aligning a new seq more than once [default:
1.1]. This means that if the BLAST alignment with the second template is at
least 110% of the BLAST alignment with the first template, the new seq will be
added twice to the ALI (under the ids *.H1.N and *.H2.N). Currently five
templates are considered but this might change if needed.

=for Euclid: n.type: number
    n.default: 1.1

=item --single-hsp

Ensure that a single HSP is aligned for each sequence [default: no]. When
specified, only the best HSP of the template with the best coverage is
retained in the alignment. In this case, a larger part of the sequence might
be discarded. By default, more than one HSPs can be added and these have to be
consolidated using an interactive alignment editor.

=item --verbosity=<level>

Verbosity level for logging to STDERR [default: 0]. Available levels range from
0 to 6. Level 6 corresponds to debugging mode.

=for Euclid: level.type: int, level >= 0 && level <= 6
    level.default: 0

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
