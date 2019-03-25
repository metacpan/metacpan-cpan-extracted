package Bio::MUST::Apps::FortyTwo;
# ABSTRACT: Main class for forty-two tool
$Bio::MUST::Apps::FortyTwo::VERSION = '0.190820';
use Moose;
use namespace::autoclean;

use autodie;
use feature qw(say);

use Smart::Comments -ENV;

use aliased 'Bio::MUST::Apps::FortyTwo::RunProcessor';

with 'Bio::MUST::Apps::Roles::Configable';


sub run_proc {                              ## no critic (RequireArgUnpacking)
    my $self = shift;

    ### [42] Welcome to FortyTwo!
    RunProcessor->new( $self->inject_args(@_) );
    ### [42] Done with FortyTwo!

    return;
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=head1 NAME

Bio::MUST::Apps::FortyTwo - Main class for forty-two tool

=head1 VERSION

version 0.190820

=head1 DESCRIPTION

This distribution includes our software C<FortyTwo> (C<42>). The aim of C<42> is
to add (and optionally align) sequences to a preexisting multiple sequence
alignment while controlling for orthology relationships and potentially
contaminating sequences. Sequences to add are either nucleotide transcripts
resulting from transcriptome assembly or already translated protein sequences.
One can also use genomic nucleotide sequences (because C<42> can splice
introns), but this possibility has not been extensively tested so far.

For information can be found in the L<Manual|forty-two-manual>.

=head1 AUTHOR

Denis BAURAIN <denis.baurain@uliege.be>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by University of Liege / Unit of Eukaryotic Phylogenomics / Denis BAURAIN.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
