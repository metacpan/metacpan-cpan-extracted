# $Id$
#
# BioPerl module for Bio::DB::PersistentObjectI
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

Bio::DB::PersistentObjectI - DESCRIPTION of Interface

=head1 SYNOPSIS

Give standard usage here

=head1 DESCRIPTION

Describe the interface here

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


package Bio::DB::PersistentObjectI;
use vars qw(@ISA);
use strict;
use Carp;
use Bio::Root::RootI;

@ISA = qw( Bio::Root::RootI );

=head1 Methods for managing persistence of this object

   Create (insert), store (update), remove (delete), and the primary
   key

=cut

=head2 create

 Title   : create
 Usage   : $obj->create()
 Function: Creates the object as a persistent object in the datastore. This
           is equivalent to an insert.

           Note that you will be able to retrieve the primary key at any time
           by calling primary_key() on the object.
 Example :
 Returns : The newly assigned primary key.
 Args    : Optionally, additional named parameters. A common parameter will
           be -fkobjs, with a reference to an array of foreign key objects
           that are not retrievable from the persistent object itself.


=cut

sub create{
    my ($self,@args) = @_;
   
    $self->throw_not_implemented();
}

=head2 store

 Title   : store
 Usage   : $obj->store()
 Function: Updates the persistent object in the datastore to reflect its
           attribute values.
 Example :
 Returns : TRUE on success and FALSE otherwise
 Args    : Optionally, additional named parameters. A common parameter will
           be -fkobjs, with a reference to an array of foreign key objects
           that are not retrievable from the persistent object itself.


=cut

sub store{
    my ($self,@args) = @_;

    $self->throw_not_implemented();
}

=head2 remove

 Title   : remove
 Usage   : $obj->remove()
 Function: Removes the persistent object from the datastore.
 Example :
 Returns : TRUE on success and FALSE otherwise
 Args    : none


=cut

sub remove{
    my ($self,@args) = @_;

    $self->throw_not_implemented();
}

=head2 primary_key

 Title   : primary_key
 Usage   : $obj->primary_key($newval)
 Function: Get the primary key of the persistent object in the datastore.

           Note that an implementation may not permit changing the
           primary key once it has been set. For most applications,
           changing an existing primary key value to another one is a
           potentially very hazardous operation and will hence be
           prohibited.

 Example : 
 Returns : value of primary_key (a scalar)
 Args    : new value (a scalar, optional)


=cut

sub primary_key{
    my ($self,$value) = @_;
    $self->throw_not_implemented();
}

=head2 obj

 Title   : obj
 Usage   : $obj->obj()
 Function: Get/set the object that is made persistent through this adaptor.

           Note that an implementation is not required to allow
           setting a value. In fact, an implementation is encouraged
           to disallow changing the value once it has been set.

           Implementations based on inheriting from the class to be
           made persistent will just return $self here.

 Example : 
 Returns : The object made persistent through this adaptor
 Args    : On set, the new value. Read above for caveat.


=cut

sub obj{
    my ($self,$value) = @_;
    $self->throw_not_implemented();
}

=head1 Methods for transactional control

   Rollback and commit

=cut

=head2 commit

 Title   : commit
 Usage   :
 Function: Commits the current transaction, if the underlying driver
           supports transactions.
 Example :
 Returns : TRUE
 Args    : none


=cut

sub commit{
    shift->throw_not_implemented();
}

=head2 rollback

 Title   : rollback
 Usage   :
 Function: Triggers a rollback of the current transaction, if the
           underlying driver supports transactions.
 Example :
 Returns : TRUE
 Args    : none


=cut

sub rollback{
    shift->throw_not_implemented();
}

=head1 Decorating methods

These methods aren't intrinsically necessary on this interface, but
rather ease recurrent tasks when serializing objects and translate
from object model to relational model.

=cut

=head2 rank

 Title   : rank
 Usage   : $obj->rank($newval)
 Function: Get/set the rank of this persistent object in a 1:n or n:n
           relationship.

           This method is here in order to ease maintaining the order
           of objects in an array property or cardinality-n
           association. Unless the schema mandates the corresponding
           attribute as NOT NULL, derived classes may override the
           implementation given here with an empty one.

           In practice it may only pertain to few objects and hence
           could be just as well stuck onto those classes instead of
           also on the interface. This design decision is up for debate -
           if people don''t like it, it can be changed without too
           much effort.

 Example : 
 Returns : value of rank (a scalar)
 Args    : new value (a scalar or undef, optional)


=cut

sub rank{
    shift->throw_not_implemented();
}

=head2 foreign_key_slot

 Title   : foreign_key_slot
 Usage   : $obj->foreign_key_slot($newval)
 Function: Get/set of the slot name that is referring to this persistent
           object as a foreign key.

           This should come in a fully-qualified form. The fully qualified
           form is the class name (or adaptor name for the class) that defines
           the slot, followed by a double-colon and the name of the slot 
           (method) itself. I.e., it is the name of the method as class
           method.

           Without this method, the name of the foreign key may be determined
           automatically based on naming convention, or based on a full
           mapping table. Neither is always possible because the situation can
           be ambiguous, e.g., if an entity references another instance of
           itself as foreign key, or if an entity references the same other
           entity via multiple foreign keys (e.g. entity associated to itself).

           This method is here only to aid ferrying this value from adaptors
           to schema drivers and mappers who need to actually figure the
           name of the foreign key column in the physical schema. An adaptor
           is not required to use it, and everyone else other than the intended
           sender and recipient should know what he/she is doing before
           tampering with it.

 Example : 
 Returns : value of foreign_key_slot (a scalar)
 Args    : new value (a scalar or undef, optional)


=cut

sub foreign_key_slot{
    shift->throw_not_implemented();
}

1;
