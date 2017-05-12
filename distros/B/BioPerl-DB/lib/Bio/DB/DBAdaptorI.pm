# $Id$
#
# BioPerl module for Bio::DB::DBAdaptorI
#
# Please direct questions and support issues to <bioperl-l@bioperl.org> 
#
# Cared for by Hilmar Lapp <hlapp at gmx.net>
#
# Copyright Hilmar Lapp
#
# You may distribute this module under the same terms as perl itself

#
# (c) Hilmar Lapp, hlapp at gmx.net, 2002.
# (c) GNF, Genomics Institute of the Novartis Research Foundation, 2002.
#
# You may distribute this module under the same terms as perl itself.
# Refer to the Perl Artistic License (see the license accompanying this
# software package, or see http://www.perl.com/language/misc/Artistic.html)
# for the terms under which you may use, modify, and redistribute this module.
# 
# THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
# WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
# MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.
#

# POD documentation - main docs before the code

=head1 NAME

Bio::DB::DBAdaptorI - DESCRIPTION of Interface

=head1 SYNOPSIS

Give standard usage here

=head1 DESCRIPTION

This interface describes the basic datastore adaptor that acts as a factory.

It allows one to obtain adaptors for specific classes or objects, as well as
objects that make a class or object peristent.

=head1 FEEDBACK

=head2 Mailing Lists

User feedback is an integral part of the evolution of this and other
Bioperl modules. Send your comments and suggestions preferably to
the Bioperl mailing list.  Your participation is much appreciated.

  bioperl-l@bioperl.org                  - General discussion
  http://bioperl.org/wiki/Mailing_lists  - About the mailing lists

=head2 Support 

Please direct usage questions or support issues to the mailing list:

I<bioperl-l@bioperl.org>

rather than to the module maintainer directly. Many experienced and 
reponsive experts will be able look at the problem and quickly 
address it. Please include a thorough description of the problem 
with code and data examples if at all possible.

=head2 Reporting Bugs

Report bugs to the Bioperl bug tracking system to help us keep track
of the bugs and their resolution. Bug reports can be submitted via
the web:

  http://redmine.open-bio.org/projects/bioperl/

=head1 AUTHOR - Hilmar Lapp

Email hlapp at gmx.net

Describe contact details here

=head1 CONTRIBUTORS

Additional contributors names and emails here

=head1 APPENDIX

The rest of the documentation details each of the object methods.
Internal methods are usually preceded with a _

=cut


# Let the code begin...


package Bio::DB::DBAdaptorI;
use vars qw(@ISA);
use strict;
use Carp;
use Bio::Root::RootI;

@ISA = qw( Bio::Root::RootI );

=head2 get_object_adaptor

 Title   : get_object_adaptor
 Usage   : $objadp = $adaptor->get_object_adaptor("Bio::SeqI");
 Function: Obtain an PersistenceAdaptorI compliant object for the given class
           or object.
 Example :
 Returns : The appropriate object adaptor, a Bio::DB::PersistenceAdaptorI
           implementing object.
 Args    : The class (a string) or object for which the adaptor is to be
           obtained. Optionally, a DBContextI implementing object to initialize
           the adaptor with. 


=cut

sub get_object_adaptor{
   my ($self,@args) = @_;

   $self->throw_not_implemented();
}

=head2 create_persistent

 Title   : create_persistent
 Usage   : $dbadaptor->create_persistent($obj)
 Function: Creates a PersistentObjectI implementing object that adapts the
           given object to the datastore.
 Example :
 Returns : A Bio::DB::PeristentObjectI implementing object
 Args    : An object of a type that can be stored in the datastore adapted
           by this factory. Alternatively, the class name of such an object.
           All remaining arguments should be passed to the constructor of the
           class if the first argument is a class name.


=cut

sub create_persistent{
   my ($self,@args) = @_;

   $self->throw_not_implemented();
}


1;
