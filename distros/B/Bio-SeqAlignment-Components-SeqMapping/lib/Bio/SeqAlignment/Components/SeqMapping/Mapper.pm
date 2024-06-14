use strict;
use warnings;
package Bio::SeqAlignment::Components::SeqMapping::Mapper;
$Bio::SeqAlignment::Components::SeqMapping::Mapper::VERSION = '0.02';
use Module::Find;

#ABSTRACT: Imports all mapper modules

## exercise personal accountability when nuking your namespace with all these modules

useall Bio::SeqAlignment::Components::SeqMapping::Mapper;

1;

=head1 NAME

Bio::SeqAlignment::Components::SeqMapping::Mapper Components that map sequences to reference databases

=head1 VERSION

version 0.02

=head1 SYNOPSIS

  use Bio::SeqAlignment::Components::SeqMapping::Mapper;
  use Bio::SeqAlignment::Components::SeqMapping::Mapper::ComponentName;

=head1 DESCRIPTION

This module loads all the components that can actually map sequences to a reference
database. If you don't want to nuke your namespace with all the components, you can 
load them as needed by using the specific component name, e.g.:

  use Bio::SeqAlignment::Components::SeqMapping::Mapper::ComponentName;

where ComponentName is the name of the component you need.
If you choose violence, you can load all the components at once by using:

  use Bio::SeqAlignment::Components::SeqMapping::Mapper;


=head1 COMPONENTS

=over 4

=item * B<Generic>

This module provides a Generic sequence mapping that not only must consume a
Dataflow role but also must implement a series of methods that are required
for the mapping to work. These methods are detailed in the documentation of
the module itself.
This module is primarily intended for development of a new mapping module, 
without having to author a new module. The user can simply compose a Dataflow
role into Generic module and implement the required methods in a Perl script,
effectively "Jupyterizing" (as in Jupyter notebook, not the planet) the 
development of a new mapping module. Once the details have been ironed out,
one hopefully would author a fuly fledged module, using an appropriate OO
framework, such as Moose, Moo, Class::Tiny that can compose roles.
See the documentation of the module for more details and examples of usage.

=back

=head1 AUTHOR

Christos Argyropoulos <chrisarg@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Christos Argyropoulos.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
