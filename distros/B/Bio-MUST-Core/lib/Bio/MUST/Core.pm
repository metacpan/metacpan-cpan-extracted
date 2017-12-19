package Bio::MUST::Core;
# ABSTRACT: Core classes and utilities for Bio::MUST
# CONTRIBUTOR: Catherine COLSON <ccolson@doct.uliege.be>
# CONTRIBUTOR: Arnaud DI FRANCO <arnaud.difranco@gmail.com>
# CONTRIBUTOR: Raphael LEONARD <rleonard@doct.uliege.be>
# CONTRIBUTOR: Loic MEUNIER <loic.meunier@doct.uliege.be>
# CONTRIBUTOR: Mick VAN VLIERBERGHE <mvanvlierberghe@doct.uliege.be>
$Bio::MUST::Core::VERSION = '0.173500';
use strict;
use warnings;

use Bio::MUST::Core::Types;
use Bio::MUST::Core::SeqId;
use Bio::MUST::Core::Seq;
use Bio::MUST::Core::SeqMask;
use Bio::MUST::Core::SeqMask::Profiles;
use Bio::MUST::Core::IdList;
use Bio::MUST::Core::IdMapper;
use Bio::MUST::Core::Ali;
use Bio::MUST::Core::Ali::Stash;
use Bio::MUST::Core::Ali::Temporary;
use Bio::MUST::Core::Tree;
use Bio::MUST::Core::Tree::Forest;
use Bio::MUST::Core::Taxonomy;
use Bio::MUST::Core::ColorScheme;
use Bio::MUST::Core::GeneticCode::Factory;
use Bio::MUST::Core::PostPred;

# TODO: switch to factory (see Bio::Phylo::Factory) to avoid 'use aliased'

1;

__END__

=pod

=head1 NAME

Bio::MUST::Core - Core classes and utilities for Bio::MUST

=head1 VERSION

version 0.173500

=head1 SYNOPSIS

    # TODO

=head1 DESCRIPTION

    # TODO

=head1 AUTHOR

Denis BAURAIN <denis.baurain@uliege.be>

=head1 CONTRIBUTORS

=for stopwords Catherine COLSON Arnaud DI FRANCO Raphael LEONARD Loic MEUNIER Mick VAN VLIERBERGHE

=over 4

=item *

Catherine COLSON <ccolson@doct.uliege.be>

=item *

Arnaud DI FRANCO <arnaud.difranco@gmail.com>

=item *

Raphael LEONARD <rleonard@doct.uliege.be>

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
