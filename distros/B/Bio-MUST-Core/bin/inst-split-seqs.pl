#!/usr/bin/env perl
# PODNAME: inst-split-seqs.pl
# ABSTRACT: Split sequences of FASTA files into shorter sequences (optimized)
# CONTRIBUTOR: Valerian LUPO <valerian.lupo@uliege.be>

use Modern::Perl '2011';
use autodie;

use Getopt::Euclid qw(:vars);
use Smart::Comments '###';

use Bio::MUST::Core;
use Bio::MUST::Core::Utils qw(secure_outfile);
use aliased 'Bio::MUST::Core::Ali';
use aliased 'Bio::MUST::Core::Seq';


my $split = sub {
    my $seq = shift;

    my $base_id = ( split /\s+/xms, $seq->full_id )[0];
    my $max_pos = $seq->seq_len - $ARGV_chunk;

    my $n = 0;
    my $out_str;
    for (my $pos = 0; $pos <= $max_pos; $pos += $ARGV_step, $n++) {     ## no critic (ProhibitCommaSeparatedStatements)
        $out_str .= ">$base_id.$n\n" . (
            Seq->new( seq_id => "seq$n", seq => $seq->edit_seq($pos,
            $pos + $ARGV_chunk <= $max_pos ? $ARGV_chunk : 2 * $ARGV_chunk) )
        )->wrapped_str;
    }

    return $out_str;
};

for my $infile (@ARGV_infiles) {
    my $outfile = secure_outfile($infile, $ARGV_out_suffix);

    ### Processing: $infile
    Ali->instant_store(
        $outfile, { infile => $infile, coderef => $split }
    );
}

__END__

=pod

=head1 NAME

inst-split-seqs.pl - Split sequences of FASTA files into shorter sequences (optimized)

=head1 VERSION

version 0.251810

=head1 USAGE

   inst-split-seqs.pl <infiles> --out=<suffix> [optional arguments]

=head1 REQUIRED ARGUMENTS

=over

=item <infiles>

Path to input FASTA files [repeatable argument].

=for Euclid: infiles.type: readable
    repeatable

=item --out[-suffix]=<suffix>

Suffix to append to infile basenames for deriving outfile names.

=for Euclid: suffix.type: string

=back

=head1 OPTIONAL ARGUMENTS

=over

=item --chunk=<n>

Window (chunk) size [default: n.default].

=for Euclid: n.type: +number
    n.default: 250

=item --step=<n>

Sliding window step [default: n.default].

=for Euclid: n.type: +number
    n.default: 250

=item --version

=item --usage

=item --help

=item --man

Print the usual program information

=back

=head1 AUTHOR

Denis BAURAIN <denis.baurain@uliege.be>

=head1 CONTRIBUTOR

=for stopwords Valerian LUPO

Valerian LUPO <valerian.lupo@uliege.be>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by University of Liege / Unit of Eukaryotic Phylogenomics / Denis BAURAIN.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
