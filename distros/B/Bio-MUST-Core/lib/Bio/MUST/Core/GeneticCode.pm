package Bio::MUST::Core::GeneticCode;
# ABSTRACT: Genetic code for conceptual translation
$Bio::MUST::Core::GeneticCode::VERSION = '0.251810';
use Moose;
use namespace::autoclean;

use autodie;
use feature qw(say);

use Bio::MUST::Core::Constants qw(:gaps);
use aliased 'Bio::MUST::Core::Seq';


has 'ncbi_id' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

# _code private hash for translation
has '_code' => (
    traits   => ['Hash'],
    is       => 'ro',
    isa      => 'HashRef[Str]',
    required => 1,
    handles  => {
                aa_for => 'get',
        amino_acid_for => 'get',
    },
);



sub translate {                             ## no critic (RequireArgUnpacking)
    my $self = shift;
    my $seq  = shift;

    return Seq->new(
        seq_id => $seq->full_id,            # clone seq_id
        seq    => join q{}, map {
                                $self->aa_for(uc $_) // $FRAMESHIFT
                            } @{ $seq->codons(@_) }
    );                                      # specify frame through currying
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=head1 NAME

Bio::MUST::Core::GeneticCode - Genetic code for conceptual translation

=head1 VERSION

version 0.251810

=head1 SYNOPSIS

    # TODO

=head1 DESCRIPTION

    # TODO

=head1 METHODS

=head2 translate

=head1 AUTHOR

Denis BAURAIN <denis.baurain@uliege.be>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by University of Liege / Unit of Eukaryotic Phylogenomics / Denis BAURAIN.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
