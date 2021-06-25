package Bio::MUST::Apps::TwoScalp;
# ABSTRACT: Main class for two-scalp tool
$Bio::MUST::Apps::TwoScalp::VERSION = '0.211710';
use strict;
use warnings;

use Bio::MUST::Apps::SlaveAligner::Local;
use Bio::MUST::Apps::TwoScalp::Seq2Seq;
use Bio::MUST::Apps::TwoScalp::Profile2Profile;
use Bio::MUST::Apps::TwoScalp::Seqs2Profile;
use Bio::MUST::Apps::TwoScalp::AlignAll;

1;

__END__

=pod

=head1 NAME

Bio::MUST::Apps::TwoScalp - Main class for two-scalp tool

=head1 VERSION

version 0.211710

=head1 SYNOPSIS

    # get documentation
    $ two-scalp.pl --man

    # align unaligned sequences within provided example ALI file
    $ two-scalp.pl test/PTHR22663.ali --out=-ts

=head1 DESCRIPTION

C<two-scapl.pl> is an application to align or re-align sequences in existing
multiple sequences alignments (FASTA or ALI file formats). Its main engine is
BLAST L<https://blast.ncbi.nlm.nih.gov/>.

Note that only alignable regions of the sequences are added to the alignment,
which may lead to discarding low-conserved regions. Moreover, some sequences
can generate multiple aligned fragments (BLAST HSPs). If you do not like this
behavior, C<two-scalp.pl> is not for you!

=head1 AUTHOR

Denis BAURAIN <denis.baurain@uliege.be>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by University of Liege / Unit of Eukaryotic Phylogenomics / Denis BAURAIN.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
