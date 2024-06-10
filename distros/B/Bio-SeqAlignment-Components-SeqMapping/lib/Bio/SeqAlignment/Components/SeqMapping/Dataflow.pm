use strict;
use warnings;
package Bio::SeqAlignment::Components::SeqMapping::Dataflow;
$Bio::SeqAlignment::Components::SeqMapping::Dataflow::VERSION = '0.01';
use Module::Find;

#ABSTRACT: Imports all modules relevant to Dataflow for sequence mapping

## exercise personal accountability when nuking your namespace with all these modules

useall Bio::SeqAlignment::Components::SeqMapping::Dataflow;

1;

=head1 NAME

Bio::SeqAlignment::Components::SeqMapping::Dataflow Components that implement dataflows for sequence mapping

=head1 VERSION

version 0.01

=head1 SYNOPSIS

  use Bio::SeqAlignment::Components::SeqMapping::Dataflow;
  use Bio::SeqAlignment::Components::SeqMapping::Dataflow::ComponentName;

=head1 DESCRIPTION

This module loads all the components that implement dataflows for mapping query
sequences against a database of reference sequences . If you don't want to nuke 
your namespace with all the components, you can load them as needed by using the 
specific component name, e.g.:

  use Bio::SeqAlignment::Components::SeqMapping::Dataflow::ComponentName;

where ComponentName is the name of the component you need.
If you choose violence, you can load all the components at once by using:

  use Bio::SeqAlignment::Components::SeqMapping::Dataflow;


=head1 COMPONENTS

=over 4

=item * B<LinearGeneric>

This module provides a Linear Dataflow for use with the Generic Mapper.
The Linear Dataflow is a simple linear-linear dataflow that maps a list of
query sequences to a reference database of sequences. The module is intended
to be B<applied> as a role to the class Bio::SeqAlignment::Components::SeqMapping::Mapper::Generic
See the documentation of the Bio::SeqAlignment::Components::SeqMapping::Mapper::Generic 
module for more information and the EnhancingEdlib for a concrete example.

=item * B<Linear>

This module provides a Linear Dataflow for use with a fully fledged, non-generic
mapper. The Linear Dataflow is a simple linear-linear dataflow that maps a list of
query sequences to a reference database of sequences. The module is intended
to be B<composed> as a role to a class such as a putative 
Bio::SeqAlignment::Components::SeqMapping::Mapper::AwesomeMapper module.
The AwesomeModule is a hypothetical module that implements a mapper that is not
generic, but is specific to a particular (pseudo)alignment library, similarity
metric, reduction technique, etc. In fact, we suggest you don't use the name 
AwesomeMapper, but rather something more descriptive of the mapper you are using.
This could be something like:
AlignmentAlgorithm_Dataflow_SimilarityMetric_ReductionTechnique_Mapper
But really it can be anything you want, and it doesn't have to be that long,
or even be stored under the Bio::SeqAlignment::Components::SeqMapping::Mapper
namespace.

=item * B<LinearLinearGeneric>

This module provides a Linear-Linear Dataflow for use with the Generic Mapper.
The Linear-Linear Dataflow is a simple linear-linear dataflow that maps a list of
query sequences to a reference database of sequences. The module is intended
to be B<applied> as a role to the class Bio::SeqAlignment::Components::SeqMapping::Mapper::Generic
See the documentation of the Bio::SeqAlignment::Components::SeqMapping::Mapper::Generic
module for more information and the EnhancingEdlib link for a concrete example.

=item * B<LinearLinear>

This module provides a Linear-Linear Dataflow for use with a fully fledged, non-generic
mapper. The Linear-Linear Dataflow is a simple linear-linear dataflow that maps a list of
query sequences to a reference database of sequences. The module is intended
to be B<composed> as a role to a class such as a putative 
Bio::SeqAlignment::Components::SeqMapping::Mapper::AwesomeMapper module.
See under Linear for more information and naming suggestions.

=back

=head1 SEE ALSO

=over 4

=item * L<Bio::SeqAlignment::Components::SeqMapping::Mapper::Generic|https://metacpan.org/pod/Bio::SeqAlignment::Components::SeqMapping::Mapper::Generic>

The Generic Mapper module can use the LinearGeneric Dataflow role to map query sequences 
to a reference database of sequences.


=item * L<Bio::SeqAlignment::Examples::EnhancingEdlib|https://metacpan.org/pod/Bio::SeqAlignment::Examples::EnhancingEdlib>

Example of how to use the Generic Mapper with the LinearLinearGeneric and the 
LinearGeneric Dataflow roles, along with the Edlib alignment library.

=back

=head1 AUTHOR

Christos Argyropoulos <chrisarg@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Christos Argyropoulos.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
