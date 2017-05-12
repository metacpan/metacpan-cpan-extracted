# $Id$
#
# BioPerl module for Bio::DB::PersistenceAdaptorI
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

Bio::DB::PersistenceAdaptorI - DESCRIPTION of Interface

=head1 SYNOPSIS

Give standard usage here

=head1 DESCRIPTION

This interface gives the base methods to be implemented by modules that
bridge persistent objects to and from their datastores.

The design choice mixes the strategy pattern with the factory pattern
(find_by_XXXX()).

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


package Bio::DB::PersistenceAdaptorI;
use vars qw(@ISA);
use strict;
use Carp;
use Bio::Root::RootI;

@ISA = qw( Bio::Root::RootI );

=head1 Methods for managing persistent objects

   Create (insert), store (update), remove (delete)

=cut

=head2 create

 Title   : create
 Usage   : $objectstoreadp->create($obj)
 Function: Creates the object as a persistent object in the datastore. This
           is equivalent to an insert.

           If the object already implements this interface, it will be
           populated with values, and the primary key will be set.

 Example :
 Returns : A Bio::DB::PersistentObjectI implementing object wrapping
           the inserted object.
 Args    : The object to be inserted.

           Optionally, additional named parameters. A common parameter
           will be -fkobjs, with a reference to an array of foreign
           key objects if these cannot be obtained from the object
           itself.


=cut

sub create{
    shift->throw_not_implemented();
}

=head2 create_persistent

 Title   : create_persistent
 Usage   :
 Function: Takes the given object and turns it onto a
           L<Bio::DB::PersistentObjectI> implementing object. Returns
           the result. Does not actually create the object in a
           database.

           Calling this method is expected to have a recursive effect
           such that all children of the object, i.e., all slots that
           are objects themselves, are made persistent objects, too.

 Example :
 Returns : A Bio::DB::PersistentObjectI implementing object wrapping the
           passed object.
 Args    : An object to be made into a PersistentObjectI object, and the class
           of which is suitable for this adaptor.

           Optionally, the class which actually implements wrapping
           the object to become a PersistentObjectI.


=cut

sub create_persistent{
    shift->throw_not_implemented();
}

=head2 store

 Title   : store
 Usage   : $objectstoreadp->store($persistent_obj)
 Function: Updates the given persistent object in the datastore.

           Implementations should be flexible and delegate to create()
           if the primary_key() method of the object returns undef.

 Example :
 Returns : TRUE on success and FALSE otherwise
 Args    : The object to be updated, which must implement
           Bio::DB:PersistentObjectI.

           Optionally, additional named parameters. A common parameter
           will be -fkobjs, with a reference to an array of foreign
           key objects if these cannot be obtained from the object
           itself.


=cut

sub store{
    shift->throw_not_implemented();
}

=head2 remove

 Title   : remove
 Usage   : $objectstoreadp->remove($persistent_obj, @params)
 Function: Removes the persistent object from the datastore.
 Example :
 Returns : TRUE on success and FALSE otherwise
 Args    : The object to be removed, and optionally additional (named) 
           parameters.


=cut

sub remove{
    shift->throw_not_implemented();
}

=head1 Methods for locating objects

    Find by primary key, by unique key, by association, and by query.

=cut

=head2 find_by_primary_key

 Title   : find_by_primary_key
 Usage   : $popj = $objectstoreadp->find_by_primary_key($pk)
 Function: Locates the entry associated with the given primary key and
           initializes a persistent object with that entry.
 Example :
 Returns : An instance of the class this adaptor adapts, represented by an
           object implementing Bio::DB::PersistentObjectI, or undef if no
           matching entry was found.
 Args    : The primary key


=cut

sub find_by_primary_key{
    shift->throw_not_implemented();
}

=head2 find_by_unique_key

 Title   : find_by_unique_key
 Usage   :
 Function: Locates the entry matching the unique key attributes as set in the
           passed object, and populates a persistent object with this entry.
 Example :
 Returns : A Bio::DB::PersistentObjectI implementing object, with the
           attributes populated with values provided by the entry in
           the datastore, or undef if no matching entry was found. If
           one was found, the object returned will be the first
           argument if that implemented Bio::DB::PersistentObjectI
           already.

 Args    : The object with those attributes set that constitute the
           chosen unique key (note that the class of the object must
           be suitable for the adaptor).

           Additional attributes and values if required, passed as a
           reference to a hash map.


=cut

sub find_by_unique_key{
    shift->throw_not_implemented();
}

=head2 find_by_association

 Title   : find_by_association
 Usage   :
 Function: Locates those records associated between a number of
           objects. The focus object (the type to be instantiated)
           depends on the adaptor class that inherited from this
           class.

 Example :
 Returns : A Bio::DB::Query::QueryResultI implementing object 
 Args    : Named parameters. At least the following must be recognized:
               -objs   a reference to an array of objects to be associated with
                       each other
               -obj_factory the factory to use for instantiating objects from
                       the found rows
  Caveats: Make sure you *always* give the objects to be associated in the
           same order.


=cut

sub find_by_association{
    shift->throw_not_implemented();
}

=head2 find_by_query

 Title   : find_by_query
 Usage   :
 Function: Locates entries that match a particular query and returns the
           result as an array of peristent objects.

           The query is represented by an instance of
           Bio::DB::Query::BioQuery or a derived class. Note that
           SELECT fields will be ignored and auto-determined. Give
           tables in the query as objects, class names, or adaptor
           names, and columns as slot names or foreign key class names
           in order to be maximally independent of the exact
           underlying schema. The driver of this adaptor will
           translate the query into tables and column names.

 Example :
 Returns : A Bio::DB::Query::QueryResultI implementing object
 Args    : The query as a Bio::DB::Query::BioQuery or derived instance.
           Note that the SELECT fields of that query object will inadvertantly
           be overwritten.
           Optionally additional (named) parameters. Recognized parameters
           at this time are
              -fkobjs    a reference to an array of foreign key objects that
                         are not retrievable from the persistent object itself
              -obj_factory  the object factory to use for creating objects for
                         resulting rows
              -name      a unique name for the query, which will make the
                         the statement be a cached prepared statement, which
                         in subsequent invocations will only be re-bound with
                         parameters values, but not recreated
              -values    a reference to an array holding the values to be
                         bound, if the query is a named query


=cut

sub find_by_query{
    shift->throw_not_implemented();
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

1;
