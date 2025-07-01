package Bio::MUST::Core;
# ABSTRACT: Core classes and utilities for Bio::MUST
# CONTRIBUTOR: Catherine COLSON <ccolson@doct.uliege.be>
# CONTRIBUTOR: Arnaud DI FRANCO <arnaud.difranco@gmail.com>
# CONTRIBUTOR: Raphael LEONARD <rleonard@doct.uliege.be>
# CONTRIBUTOR: Valerian LUPO <valerian.lupo@uliege.be>
# CONTRIBUTOR: Loic MEUNIER <loic.meunier@doct.uliege.be>
# CONTRIBUTOR: Mick VAN VLIERBERGHE <mvanvlierberghe@doct.uliege.be>
$Bio::MUST::Core::VERSION = '0.251810';
use strict;
use warnings;

use Bio::MUST::Core::Types;
use Bio::MUST::Core::SeqId;
use Bio::MUST::Core::Seq;
use Bio::MUST::Core::SeqMask;
use Bio::MUST::Core::SeqMask::Pmsf;
use Bio::MUST::Core::SeqMask::Profiles;
use Bio::MUST::Core::SeqMask::Rates;
use Bio::MUST::Core::SeqMask::Weights;
use Bio::MUST::Core::IdList;
use Bio::MUST::Core::IdMapper;
use Bio::MUST::Core::Ali;
use Bio::MUST::Core::Ali::Stash;
use Bio::MUST::Core::Ali::Temporary;
use Bio::MUST::Core::Tree;
use Bio::MUST::Core::Tree::Forest;
use Bio::MUST::Core::Tree::Splits;
use Bio::MUST::Core::Taxonomy;
use Bio::MUST::Core::GeneticCode::Factory;
use Bio::MUST::Core::PostPred;

# TODO: switch to factory (see Bio::Phylo::Factory) to avoid 'use aliased'

1;

__END__

=pod

=head1 NAME

Bio::MUST::Core - Core classes and utilities for Bio::MUST

=head1 VERSION

version 0.251810

=head1 DESCRIPTION

This distribution is the base of the C<Bio::MUST> module collection designed
for writing phylogenomic applications in Perl. Their main strength lies in
their transparent handling of the NCBI Taxonomy database (see
L<https://www.ncbi.nlm.nih.gov/taxonomy>), for example to automatically label
ancestral nodes in phylogenetic trees.

C<Bio::MUST> classes do not need (and are not meant as a replacement for)
L<BioPerl>. In contrast, they depend on both L<Bio::LITE::Taxonomy> and
L<Bio::Phylo>, two non-BioPerl distribution for dealing with biological data.

C<Bio::MUST> modules have been used in production since 2013 but are not yet
ready for wider adoption due to their lack of documentation. This should
improve over time. Meanwhile, adventurous users can have a look at the
L<Bio::MUST::Core::Ali> class which is already fully documented.

=head1 AUTHOR

Denis BAURAIN <denis.baurain@uliege.be>

=head1 CONTRIBUTORS

=for stopwords Catherine COLSON Arnaud DI FRANCO Raphael LEONARD Valerian LUPO Loic MEUNIER Mick VAN VLIERBERGHE

=over 4

=item *

Catherine COLSON <ccolson@doct.uliege.be>

=item *

Arnaud DI FRANCO <arnaud.difranco@gmail.com>

=item *

Raphael LEONARD <rleonard@doct.uliege.be>

=item *

Valerian LUPO <valerian.lupo@uliege.be>

=item *

Loic MEUNIER <loic.meunier@doct.uliege.be>

=item *

Mick VAN VLIERBERGHE <mvanvlierberghe@doct.uliege.be>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by University of Liege / Unit of Eukaryotic Phylogenomics / Denis BAURAIN.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
