# $Id$
#
# BioPerl module for Bio::DB::BioSQL::DBLinkAdaptor
#
# Please direct questions and support issues to <bioperl-l@bioperl.org> 
#
# Cared for by Ewan Birney <birney@ebi.ac.uk>
#
# Copyright Ewan Birney
#
# You may distribute this module under the same terms as perl itself

# 
# Version 1.10 and up are also
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

Bio::DB::BioSQL::DBLinkAdaptor - DBLink Adaptor

=head1 SYNOPSIS

Do not use create this object directly

=head1 DESCRIPTION

Adaptor for DBLinks 

=head1 FEEDBACK

=head2 Mailing Lists

User feedback is an integral part of the evolution of this
and other Bioperl modules. Send your comments and suggestions preferably
 to one of the Bioperl mailing lists.
Your participation is much appreciated.

  bioperl-l@bio.perl.org

=head2 Support 

Please direct usage questions or support issues to the mailing list:

I<bioperl-l@bioperl.org>

rather than to the module maintainer directly. Many experienced and 
reponsive experts will be able look at the problem and quickly 
address it. Please include a thorough description of the problem 
with code and data examples if at all possible.

=head2 Reporting Bugs

Report bugs to the Bioperl bug tracking system to help us keep track
 the bugs and their resolution.
 Bug reports can be submitted via email or the web:

  bioperl-bugs@bio.perl.org
  http://bio.perl.org/bioperl-bugs/

=head1 AUTHOR - Ewan Birney, Hilmar Lapp

Email birney@ebi.ac.uk
Email hlapp at gmx.net

Describe contact details here

=head1 APPENDIX

The rest of the documentation details each of the object methods. Internal methods are usually preceded with a _

=cut


# Let the code begin...


package Bio::DB::BioSQL::DBLinkAdaptor;
use vars qw(@ISA);
use strict;

use Bio::Annotation::DBLink;
use Bio::DB::BioSQL::BasePersistenceAdaptor;
use Bio::DB::PersistentObjectI;
use Bio::BioEntry;

@ISA = qw(Bio::DB::BioSQL::BasePersistenceAdaptor);


=head2 new

 Title   : new
 Usage   :
 Function: Instantiates the persistence adaptor.
 Example :
 Returns : 
 Args    :


=cut

sub new{
   my ($class,@args) = @_;

   # we want to enable object caching
   push(@args, "-cache_objects", 1) unless grep { /cache_objects/i; } @args;
   my $self = $class->SUPER::new(@args);

   return $self;
}


=head2 get_persistent_slots

 Title   : get_persistent_slots
 Usage   :
 Function: Get the slots of the object that map to attributes in its respective
           entity in the datastore.

           Slots should be methods callable without an argument.

           This is a strictly abstract method. A derived class MUST override
           it to return something meaningful.
 Example :
 Returns : an array of method names constituting the serializable slots
 Args    : the object about to be inserted or updated


=cut

sub get_persistent_slots{
    my ($self,@args) = @_;

    return ("database", "primary_id", "version", "rank");
}

=head2 get_persistent_slot_values

 Title   : get_persistent_slot_values
 Usage   :
 Function: Obtain the values for the slots returned by get_persistent_slots(),
           in exactly that order.

           The reason this method is here is that sometimes the actual slot
           values need to be post-processed to yield the value that gets
           actually stored in the database. E.g., slots holding arrays
           will need some kind of join function applied. Another example is if
           the method call needs additional arguments. Supposedly the
           adaptor for a specific interface knows exactly what to do here.

           Since there is also populate_from_row() the adaptor has full
           control over mapping values to a version that is actually stored.
 Example :
 Returns : A reference to an array of values for the persistent slots of this
           object. Individual values may be undef.
 Args    : The object about to be serialized.
           A reference to an array of foreign key objects if not retrievable 
           from the object itself.


=cut

sub get_persistent_slot_values {
    my ($self,$obj,$fkobjs) = @_;
    my @vals = ($obj->database(),
		$obj->primary_id(),
		$obj->version() || 0,
                $obj->can('rank') ? $obj->rank() : undef,
		);
    return \@vals;
}

=head2 get_foreign_key_objects

 Title   : get_foreign_key_objects
 Usage   :
 Function: Gets the objects referenced by this object, and which therefore need
           to be referenced as foreign keys in the datastore.

           Bio::Annotation::DBLink has no FKs, therefore this version just
           returns an empty array.
 Example :
 Returns : an array of Bio::DB::PersistentObjectI implementing objects
 Args    : The object about to be inserted or updated.
           Optionally, additional named parameters. A common parameter will
           be -fkobjs, with a reference to an array of foreign key objects
           that are not retrievable from the persistent object itself.


=cut

sub get_foreign_key_objects{
    return ();
}

=head2 store_children

 Title   : store_children
 Usage   :
 Function: Inserts or updates the child entities of the given object in the 
           datastore.

           Bio::Annotation::DBLink has no children,
           so this version just returns TRUE.
 Example :
 Returns : TRUE on success, and FALSE otherwise
 Args    : The Bio::DB::PersistentObjectI implementing object for which the
           child objects shall be made persistent.
           Optionally, additional named parameters. A common parameter will
           be -assoc_objs, with a reference to an array of objects to which
           this object should be associated in the database if those objects
           are not retrievable from the persistent object itself.


=cut

sub store_children{
    return 1;
}

=head2 remove_children

 Title   : remove_children
 Usage   :
 Function: This method is to cascade deletes in maintained objects.

           We just return TRUE here.

 Example :
 Returns : TRUE on success and FALSE otherwise
 Args    : The persistent object that was just removed from the database.
           Additional (named) parameter, as passed to remove().


=cut

sub remove_children{
    return 1;
}

=head2 instantiate_from_row

 Title   : instantiate_from_row
 Usage   :
 Function: Instantiates the class this object is an adaptor for, and populates
           it with values from columns of the row.

           This implementation call populate_from_row() to do the real job.
 Example :
 Returns : An object, or undef, if the row contains no values
 Args    : A reference to an array of column values. The first column is the
           primary key, the other columns are expected to be in the order 
           returned by get_persistent_slots().
           Optionally, the object factory to be used for instantiating the
           proper class. The adaptor must be able to instantiate a default
           class if this value is undef.


=cut

sub instantiate_from_row{
    my ($self,$row,$fact) = @_;
    my $obj;

    if($row && @$row) {
	if($fact) {
	    $obj = $fact->create_object();
	} else {
	    $obj = Bio::Annotation::DBLink->new();
	}
        # in order to store rank we need a persistent object - sooner or later
        # it will be turned into one anyway
        if (!$obj->isa("Bio::DB::PersistentObjectI")) {
            $obj = $self->create_persistent($obj);
        }
        # now populate
	$self->populate_from_row($obj, $row);
    }
    return $obj;
}

=head2 populate_from_row

 Title   : populate_from_row
 Usage   :
 Function: Instantiates the class this object is an adaptor for, and populates
           it with values from columns of the row.

           Usually a derived class will instantiate the proper class and pass
           it on to populate_from_row().

           This method MUST be overridden by a derived object.
 Example :
 Returns : An object, or undef, if the row contains no values
 Args    : The object to be populated.
           A reference to an array of column values. The first column is the
           primary key, the other columns are expected to be in the order 
           returned by get_persistent_slots().


=cut

sub populate_from_row{
    my ($self,$obj,$row) = @_;

    if(! ref($obj)) {
	$self->throw("\"$obj\" is not an object. Probably internal error.");
    }
    if($row && @$row) {
	$obj->database($row->[1]) if $row->[1];
	$obj->primary_id($row->[2]) if $row->[2];
	$obj->version($row->[3]) if $row->[3];
        $obj->rank($row->[4]) if $row->[4] && $obj->can('rank');
	if($obj->isa("Bio::DB::PersistentObjectI")) {
	    $obj->primary_key($row->[0]);
	}
	return $obj;
    }
    return undef;
}

=head2 get_unique_key_query

 Title   : get_unique_key_query
 Usage   :
 Function: Obtain the suitable unique key slots and values as determined by the
           attribute values of the given object and the additional foreign
           key objects, in case foreign keys participate in a UK. 

 Example :
 Returns : One or more references to hash(es) where each hash
           represents one unique key, and the keys of each hash
           represent the names of the object's slots that are part of
           the particular unique key and their values are the values
           of those slots as suitable for the key.
 Args    : The object with those attributes set that constitute the chosen
           unique key (note that the class of the object will be suitable for
           the adaptor).
           A reference to an array of foreign key objects if not retrievable 
           from the object itself.


=cut

sub get_unique_key_query{
    my ($self,$obj,$fkobjs) = @_;
    my $uk_h = {};

    # UK is the combination of accession and database
    if($obj->namespace()) {
	$uk_h->{'primary_id'} = $obj->primary_id();
	$uk_h->{'database'} = $obj->database() if $obj->database();
	$uk_h->{'version'} = $obj->version() || 0;
    } 
    
    return $uk_h;
}


1;
