# BioPerl module for Bio::Community::Role::Sequenced
#
# Please direct questions and support issues to <bioperl-l@bioperl.org>
#
# Copyright 2011-2014 Florent Angly <florent.angly@gmail.com>
#
# You may distribute this module under the same terms as perl itself


=head1 NAME

Bio::Community::Role::Sequenced - Role for objects that have a sequence

=head1 SYNOPSIS

  package My::Package;

  use Moose;
  with 'Bio::Community::Role::Sequenced';

  # Use the seqs() method as needed
  # ...

  1;

=head1 DESCRIPTION

This role provides the capability to add an arrayref of sequences (Bio::PrimarySeq
compliant objects) to objects of the class that consumes this role.

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


package Bio::Community::Role::Sequenced;

use Moose::Role;
use namespace::autoclean;


=head2 seqs

 Usage   : my $seqs = $member->seqs();
 Function: Get or set some sequences for this object.
 Args    : An arrayref of Bio::SeqI objects
 Returns : An arrayref of Bio::SeqI objects

=cut

has seqs => (
   is => 'rw',
   isa => 'Maybe[ArrayRef[Bio::PrimarySeqI]]',
   required => 0,
   default => sub{ [] },
   init_arg => '-seqs',
   lazy => 1,
);


1;
