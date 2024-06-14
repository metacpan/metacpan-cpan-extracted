use strict;
use warnings;
package Bio::SeqAlignment::Components::SeqMapping;
$Bio::SeqAlignment::Components::SeqMapping::VERSION = '0.02';
use Module::Find;

#ABSTRACT: Imports all modules relevant to sequence mapping

## exercise personal accountability when nuking your namespace with all these modules
useall Bio::SeqAlignment::Components::SeqMapping;


1;

=head1 NAME

Bio::SeqAlignment::Components::SeqMapping Components relevant to sequence mapping

=head1 VERSION

version 0.02

=head1 SYNOPSIS

  use Bio::SeqAlignment::Components::SeqMapping;
  use Bio::SeqAlignment::Components::SeqMapping::Mapper;
  use Bio::SeqAlignment::Components::SeqMapping::Dataflow;
  use Bio::SeqAlignment::Components::SeqMapping::Mapper::ComponentName;
  use Bio::SeqAlignment::Components::SeqMapping::Dataflow::ComponentName;

=head1 DESCRIPTION

This module loads all the components relevant to sequence mapping. If you don't
want to nuke your namespace with all the components, you can load them as needed
by using the specific component name, e.g.:

  use Bio::SeqAlignment::Components::SeqMapping::Mapper::ComponentName;
  use Bio::SeqAlignment::Components::SeqMapping::Dataflow::ComponentName;

where ComponentName is the name of the component you need.
If you choose violence, you can load all the components at once by using:

  use Bio::SeqAlignment::Components::SeqMapping;

or components from one of the two categories of modules, i.e. Mapper or Dataflow:

  use Bio::SeqAlignment::Components::SeqMapping::Mapper;
  use Bio::SeqAlignment::Components::SeqMapping::Dataflow;


=head1 COMPONENTS

=over 4

=item B<Mapper>

This module provides mapping modules for sequences. These modules available
for loading are detailed in the documentation of the module itself.

=item B<Dataflow>

This module provides dataflow modules for sequences. These modules available
for loading are detailed in the documentation of the module itself.

=back

=head1 AUTHOR

Christos Argyropoulos <chrisarg@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Christos Argyropoulos.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
