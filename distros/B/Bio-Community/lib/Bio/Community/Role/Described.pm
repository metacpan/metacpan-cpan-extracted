# BioPerl module for Bio::Community::Role::Described
#
# Please direct questions and support issues to <bioperl-l@bioperl.org>
#
# Copyright 2011-2014 Florent Angly <florent.angly@gmail.com>
#
# You may distribute this module under the same terms as perl itself


=head1 NAME

Bio::Community::Role::Described - Role for objects that have a description

=head1 SYNOPSIS

  package My::Package;

  use Moose;
  with 'Bio::Community::Role::Described';

  # Use the desc() method as needed
  # ...

  1;

=head1 DESCRIPTION

This role provides the capability to add an arbitrary description (a string)
to objects of the class that consumes this role.

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


package Bio::Community::Role::Described;

use Moose::Role;
use namespace::autoclean;


=head2 desc

 Usage   : my $description = $member->desc();
 Function: Get or set a description for this object.
 Args    : A string
 Returns : A string

=cut

has desc => (
   is => 'rw',
   isa => 'Str',
   required => 0,
   default => '',
   init_arg => '-desc',
   lazy => 1,
);


1;
