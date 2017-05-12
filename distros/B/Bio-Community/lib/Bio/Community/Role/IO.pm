# BioPerl module for Bio::Community::Role::IO
#
# Please direct questions and support issues to <bioperl-l@bioperl.org>
#
# Copyright 2011-2014 Florent Angly <florent.angly@gmail.com>
#
# You may distribute this module under the same terms as perl itself


=head1 NAME

Bio::Community::Role::IO - Role for IO layer

=head1 SYNOPSIS

  package My::Package;

  use Moose;
  with 'Bio::Community::Role::IO';

  # ...

  1;

=head1 DESCRIPTION

This role is an IO layer to read and write community files. The only thing it
does is define methods that the role-consuming class must implement. In practice,
this role is should be used by all the IO drivers in the Bio::Community::IO::*
namespace.

Input methods: next_member, next_community, _next_community_init, _next_community_finish
Output methods: write_member, write_community, _write_community_init, _write_community_finish, sort_members

=head1 AUTHOR

Florent Angly L<florent.angly@gmail.com>

=head1 SUPPORT AND BUGS

User feedback is an integral part of the evolution of this and other Bioperl
modules. Please direct usage questions or support issues to the mailing list, 
L<bioperl-l@bioperl.org>, rather than to the module maintainer directly. Many
experienced and reponsive experts will be able look at the problem and quickly 
address it. Please include a thorough description of the problem with code and
data examples if at all possible.

If you have found a bug, please report it on the BioPerl bug tracking system
to help us keep track the bugs and their resolution:
L<https://redmine.open-bio.org/projects/bioperl/>

=head1 COPYRIGHT

Copyright 2011-2014 by Florent Angly <florent.angly@gmail.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.

=head1 APPENDIX

The rest of the documentation details each of the object
methods. Internal methods are usually preceded with a _

=cut


package Bio::Community::Role::IO;

use Moose::Role;
use namespace::autoclean;

# TODO: POD that describes each method and its inputs and outputs

requires
   # Methods implemented by the Bio::Community::IO::* drivers
   '_next_community_init',
   '_next_community_finish',
   '_write_community_init',
   '_write_community_finish',
   '_next_metacommunity_init',
   '_next_metacommunity_finish',
   '_write_metacommunity_init',
   '_write_metacommunity_finish',
   'next_member',
   'write_member',
   # Methods implemented by the Bio::Community::IO (that the drivers inherit from)
   'next_community',
   'next_metacommunity',
   'write_community',
   'write_metacommunity',
   'sort_members',
   'abundance_type',
   'missing_string',
   'multiple_communities',
   'weight_files',
   'weight_assign',
;


1;
