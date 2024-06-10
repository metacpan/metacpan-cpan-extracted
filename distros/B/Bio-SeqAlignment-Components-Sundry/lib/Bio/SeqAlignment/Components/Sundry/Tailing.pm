package Bio::SeqAlignment::Components::Sundry::Tailing;
$Bio::SeqAlignment::Components::Sundry::Tailing::VERSION = '0.01';
use strict;
use warnings;

use Carp;
use Bio::SeqAlignment::Examples::TailingPolyester::PDLRNG;
use Bio::SeqAlignment::Examples::TailingPolyester::SimulatePDLGSL;
use PDL::Lite;

use Exporter qw(import);
our @EXPORT_OK = qw(add_polyA);

sub add_polyA {
    my ( $bioseq_objects, $taildist, $seed, @distparams ) = @_;
    my $num_of_seqs       = $#$bioseq_objects + 1;
    my $right_trunc_limit = pop @distparams;
    my $left_trunc_limit  = pop @distparams;

    my $rng =
      Bio::SeqAlignment::Examples::TailingPolyester::SimulatePDLGSL->new(
        seed       => $seed,
        rng_plugin => 'Bio::SeqAlignment::Examples::TailingPolyester::PDLRNG'
      );

    my $tails = $rng->simulate_trunc(
        random_dim      => [$num_of_seqs],
        distr           => $taildist,
        params          => \@distparams,
        left_trunc_lmt  => $left_trunc_limit,
        right_trunc_lmt => $right_trunc_limit,
    );

    $tails->inplace->rint;    ## round the values to the nearest integer

    my %modifications_HoH = ();
    for my $i ( 0 .. $num_of_seqs - 1 ) {
        my $seq_id      = $bioseq_objects->[$i]->id;
        my $old_seq_len = length $bioseq_objects->[$i]->seq;
        my $tail        = $tails->at($i);
        my $seq         = $bioseq_objects->[$i]->seq;
        my $tailseq     = 'A' x $tail;
        $bioseq_objects->[$i]->seq( $seq . $tailseq );

        ## store modifications for latter use
        $modifications_HoH{$seq_id}{polyA_tail}{tail_len}   = $tail;
        $modifications_HoH{$seq_id}{polyA_tail}{tail_start} = $old_seq_len + 1;
    }
    return ( \%modifications_HoH );
}

1;

__END__

=head1 NAME

Bio::SeqAlignment::Components::Sundry::Tailing - Add various tails to sequences

=head1 VERSION

version 0.01

=head1 SYNOPSIS

  use Bio::SeqAlignment::Components::Sundry::Tailing;
  my $modifications_HoH = add_polyA( $bioseq_objects, $taildist, $seed, @distparams );

=head1 DESCRIPTION

This module provides functions to add various tails to the 3' of biological
sequences. Such modifications are useful for e.g. simulating polyA tails 
in RNAseq, adding UMI tags to sequences, etc.

=head1 EXPORT

add_polyA

=head1 SUBROUTINES

=head2 add_polyA

  my $modifications_HoH = add_polyA( $bioseq_objects, $taildist, $seed, @distparams );

Add a polyA tail to each sequence in the array of biological sequence objects.
The functiontakes a reference to an array of biological sequence objects (e.g. 
Bio::Seq,BioX::Seq, FAST::Bio::Seq, or anything that provides a seq and id 
method), a possibly truncated tail distribution from the Gnu Scientific Library, 
a seed and a list of distribution parameters for the tail distribution. The
function modifies the array in situ and returns a reference to a hash of 
modifications (i.e. the position the polyA tail was added as well as its length. 
Note that this function uses simulation to generate a tail of random length.


=head1 SEE ALSO

=over 4

=item * L<Bio::SeqAlignment::Examples::TailingPolyester>

A collection of examples that demonstrate how to extend the polyester RNA 
sequencing tool by including polyA tails in the reference RNA being used to 
generate the simulated RNA sequencing data.


=back

=head1 AUTHOR

Christos Argyropoulos <chrisarg *at* cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Christos Argyropoulos.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
