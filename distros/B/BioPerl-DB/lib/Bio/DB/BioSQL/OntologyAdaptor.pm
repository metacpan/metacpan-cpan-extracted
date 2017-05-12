# $Id$
#
# BioPerl module for Bio::DB::BioSQL::OntologyAdaptor
#
# Please direct questions and support issues to <bioperl-l@bioperl.org> 
#
# Cared for by Hilmar Lapp <hlapp at gmx.net>
#

#
# (c) Hilmar Lapp, hlapp at gmx.net, 2003.
# (c) GNF, Genomics Institute of the Novartis Research Foundation, 2003.
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

Bio::DB::BioSQL::OntologyAdaptor - DB Adaptor for Ontology objects

=head1 SYNOPSIS

   # don't use directly

=head1 DESCRIPTION

DB adaptor for Bio::Ontology::OntologyI compliant objects.

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

  bioperl-bugs@bioperl.org
  http://redmine.open-bio.org/projects/bioperl/

=head1 AUTHOR - Hilmar Lapp

Email hlapp at gmx.net

=head1 APPENDIX

The rest of the documentation details each of the object
methods. Internal methods are usually preceded with a _

=cut


# Let the code begin...


package Bio::DB::BioSQL::OntologyAdaptor;
use vars qw(@ISA);
use strict;

# Object preamble 

use Bio::DB::BioSQL::BasePersistenceAdaptor;
use Bio::DB::PersistentObjectI;
use Bio::Ontology::Ontology;

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

 Example :
 Returns : an array of method names constituting the serializable slots
 Args    : the object about to be inserted or updated


=cut

sub get_persistent_slots{
    my ($self,@args) = @_;

    return ("name", "definition");
}

=head2 get_persistent_slot_values

 Title   : get_persistent_slot_values
 Usage   :
 Function: Obtain the values for the slots returned by get_persistent_slots(),
           in exactly that order.

 Example :
 Returns : A reference to an array of values for the persistent slots of this
           object. Individual values may be undef.
 Args    : The object about to be serialized.
           A reference to an array of foreign key objects if not retrievable 
           from the object itself.


=cut

sub get_persistent_slot_values {
    my ($self,$obj,$fkobjs) = @_;
    my @vals = ($obj->name(),
		$obj->definition()
		);
    return \@vals;
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
	    $obj = Bio::Ontology::Ontology->new();
	}
	$self->populate_from_row($obj, $row);
    }
    return $obj;
}

=head2 populate_from_row

 Title   : populate_from_row
 Usage   :
 Function: Instantiates the class this object is an adaptor for, and populates
           it with values from columns of the row.

 Example :
 Returns : An object, or undef, if the row contains no values
 Args    : The object to be populated.
           A reference to an array of column values. The first column is the
           primary key, the other columns are expected to be in the order 
           returned by get_persistent_slots().


=cut

sub populate_from_row{
    my ($self,$obj,$rows) = @_;

    if(! ref($obj)) {
	$self->throw("\"$obj\" is not an object. Probably internal error.");
    }
    if($rows && @$rows) {
	$obj->name($rows->[1]) if $rows->[1];
	$obj->definition($rows->[2]) if $rows->[2];
	if($obj->isa("Bio::DB::PersistentObjectI")) {
	    $obj->primary_key($rows->[0]);
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

    # UK for ontology is its name
    if($obj->name()) {
	$uk_h->{'name'} = $obj->name();
    }
    
    return $uk_h;
}

=head1 Methods overriden from BasePersistenceAdaptor

=cut

=head2 create_persistent

 Title   : create_persistent
 Usage   :
 Function: Takes the given object and turns it onto a
           PersistentObjectI implementing object. Returns the
           result. Does not actually create the object in a database.

           Calling this method is expected to have a recursive effect
           such that all children of the object, i.e., all slots that
           are objects themselves, are made persistent objects, too.

           We override this method here because we need to temporarily
           break the cycle between ontology and its term and
           relationship objects.

 Example :
 Returns : A Bio::DB::PersistentObjectI implementing object wrapping the
           passed object.
 Args    : An object to be made into a PersistentObjectI object (the class
           will be suitable for this adaptor).
           Optionally, the class which actually implements wrapping the object
           to become a PersistentObjectI.


=cut

sub create_persistent{
    my ($self,$obj,$pwrapper) = @_;

    return unless $obj;

    my $engine;
    if($obj->can('engine')) {
	$engine = $obj->engine();
	$obj->engine(undef);
    }
    my $pobj = $self->SUPER::create_persistent($obj,$pwrapper);
    # restore engine
    $pobj->engine($engine) if $engine;
    
    return $pobj;
}

=head1 Methods specific to this adaptor

=cut

=head2 compute_transitive_closure

 Title   : compute_transitive_closure
 Usage   :
 Function: Compute the transitive closure over a given ontology
           and populate the respective path table in the relational
           schema.

           There are options that allow one to create certain
           necessary relationships between predicates on-the-fly. Read
           below.

 Example :
 Returns : TRUE on success, and FALSE otherwise
 Args    : The ontology over which to create the transitive closure
           (a Bio::Ontology::OntologyI compliant object).

           In addition, named parameters. Currently, the following are
           recognized.

             -truncate   If assigned a true value, will cause an existing
                         transitive closure for the ontology be deleted
                         from the path table. Usually, this option should
                         be enabled.

             -predicate_superclass A Bio::Ontology::TermI compliant object
                         that specifies a common ancestor predicate
                         for all predicates in the ontology. If this
                         is specified, the method will create and
                         serialize relationships between all
                         predicates in the ontology and the ancestor
                         predicate, where the ancestor predicate is
                         the object, the predicate is either the one
                         given by -subclass_predicate or the term
                         'subclasses', and the ontology is the
                         ontology referenced by the ancestor
                         predicate.

                         If this is not provided, the aforementioned
                         relationships should be present in an
                         ontology in the database already, unless the
                         ontology over which to compute the transitive
                         closure has only one predicate, or if paths
                         over mixed predicates are void. Otherwise the
                         transitive closure will not be complete for
                         mixed predicate paths.

             -subclass_predicate A Bio::Ontology::TermI compliant object
                         that represents the predicate for the
                         relationship between predicate A and
                         predicate B if predicate A can be considered
                         to subclass predicate B.

             -identity_predicate A Bio::Ontology::TermI compliant object
                         that represents the predicate for the
                         identity of a predicate with itself. If
                         provided, the method will create
                         relationships for all predicates in the
                         ontology, where subject and object are the
                         predicate of the ontology, the predicate is
                         the supplied identity predicate, and the
                         ontology is the ontology referenced by the
                         supplied term object.

                         If this is not provided, the aforementioned
                         relationships should be present in an
                         ontology in the database already. Otherwise the
                         transitive closure will be incomplete.

                         The predicate will also be used for
                         indicating identity between a term and itself
                         for the paths of distance zero between a term
                         and itself. If undef the zero distance paths
                         will not be created.


=cut

sub compute_transitive_closure{
    my $self = shift;
    # the main implementation actually sits in the path adaptor
    my $pathadp = $self->db->get_object_adaptor("Bio::Ontology::PathI");
    return $pathadp->compute_transitive_closure(@_);
}

1;
