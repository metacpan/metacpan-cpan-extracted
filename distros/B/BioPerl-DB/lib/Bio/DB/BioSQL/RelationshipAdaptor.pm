# $Id$
#
# BioPerl module for Bio::DB::BioSQL::RelationshipAdaptor
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

Bio::DB::BioSQL::RelationshipAdaptor - DESCRIPTION of Object

=head1 SYNOPSIS

Give standard usage here

=head1 DESCRIPTION

Bio::Ontology::RelationshipI DB adaptor 

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


package Bio::DB::BioSQL::RelationshipAdaptor;
use vars qw(@ISA);
use strict;

# Object preamble 

use Bio::DB::BioSQL::BasePersistenceAdaptor;
use Bio::DB::PersistentObjectI;
use Bio::Ontology::Relationship;

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
   #well I'm not sure about this
   #push(@args, "-cache_objects", 1) unless grep { /cache_objects/i; } @args;
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

    return ();
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
    my @vals = ();
    return \@vals;
}

=head2 get_foreign_key_objects

 Title   : get_foreign_key_objects
 Usage   :
 Function: Gets the objects referenced by this object, and which therefore need
           to be referenced as foreign keys in the datastore.

           Note that the objects are expected to implement
           Bio::DB::PersistentObjectI.

           An implementation needs to make sure that the
           order of foreign key objects returned is always the same.

 Example :
 Returns : an array of Bio::DB::PersistentObjectI implementing objects
 Args    : The object about to be inserted or updated, or undef if the call
           is for a SELECT query. In the latter case return class or interface
           names that are mapped to the foreign key tables.

           Optionally, additional named parameters. A common parameter
           will be -fkobjs, with a reference to an array of foreign
           key objects that are not retrievable from the persistent
           object itself.

=cut

sub get_foreign_key_objects{
    my ($self,$obj,$fkobjs) = @_;
    my ($subj_term,$pred_term,$obj_term,$ont);

    # initialize with defaults
    if(ref($obj)) {
	$subj_term = $obj->subject_term();
	$pred_term = $obj->predicate_term();
	$obj_term = $obj->object_term();
	# make sure the contexts are set
	$subj_term->foreign_key_slot(ref($self) ."::subject");
	$obj_term->foreign_key_slot(ref($self) ."::object");
	$pred_term->foreign_key_slot(ref($self) ."::predicate");
	# and the ontology FK
	$ont = $obj->ontology();
    } 
    $ont = "Bio::Ontology::OntologyI" unless $ont;
    $subj_term = "Bio::Ontology::TermI::subject" unless $subj_term;
    $pred_term = "Bio::Ontology::TermI::predicate" unless $pred_term;
    $obj_term = "Bio::Ontology::TermI::object" unless $obj_term;
    return ($subj_term,$pred_term,$obj_term,$ont);
}

=head2 attach_foreign_key_objects

 Title   : attach_foreign_key_objects
 Usage   :
 Function: Attaches foreign key objects to the given object as far as
           necessary.

           This method is called after find_by_XXX() queries, not for INSERTs
           or UPDATEs.

 Example :
 Returns : TRUE on success, and FALSE otherwise.
 Args    : The object to which to attach foreign key objects.
           A reference to an array of foreign key values, in the order of
           foreign keys returned by get_foreign_key_objects().


=cut

sub attach_foreign_key_objects{
    my ($self,$obj,$fks) = @_;
    my $ok = 1;
    
    if($fks && @$fks) {
	# we expect to find 4 foreign keys: subject, predicate, object, and
	# namespace (ontology)
	my $i = 0;
	foreach my $meth ("subject_term", "predicate_term", "object_term") {
	    next unless $fks->[$i]; # this actually always be defined
	    my $term = $self->_term_adaptor->find_by_primary_key($fks->[$i]);
	    $ok = defined($term) && $ok;
	    $obj->$meth($term) if $term;
	    $i++;
	}
	# foreign key to ontology 
	if($fks->[$i]) {
	    my $ont = $self->_ont_adaptor->find_by_primary_key($fks->[$i]);
	    $ok = defined($ont) && $ok;
	    $obj->ontology($ont) if $ont;
	}
    }
    return $ok;
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
	    $obj = Bio::Ontology::Relationship->new();
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

    # UK for a relationship is the tuple of all its foreign keys:
    # (subject,predicate,object,ontology)
    if(ref($obj)) {
	my $tadp = $self->_term_adaptor;
	my %name_map = ("subject_term"   => "subject",
			"object_term"    => "object",
			"predicate_term" => "predicate");
	foreach my $meth (keys %name_map) {
	    my $term = $obj->$meth;
	    if($term && (!$term->isa("Bio::DB::PersistentObjectI"))) {
		$term = $tadp->find_by_unique_key($term);
	    }
	    $uk_h->{$name_map{$meth}} = $term ? $term->primary_key : undef;
	}
	my $ont = $obj->ontology();
	if($ont && (!$ont->isa("Bio::DB::PersistentObjectI"))) {
	    $ont = $self->_ont_adaptor->find_by_unique_key($ont);
	}
	$uk_h->{"ontology"} = $ont ? $ont->primary_key : undef;
    }
    
    return $uk_h;
}

=head2 remove_all_relationships

 Title   : remove_all_relationships
 Usage   :
 Function: Removes all relationships within a given ontology.

           This is mostly a convenience method for calling
           remove_association() with the appropriate arguments.

 Example :
 Returns : TRUE on success and FALSE otherwise
 Args    : the ontology as an Bio::Ontology::OntologyI compliant object


=cut

sub remove_all_relationships{
    my ($self,$ont) = @_;

    if (! ($ont && ref($ont) && $ont->isa("Bio::Ontology::OntologyI"))) {
        $self->throw("argument must be an OntologyI-compliant object");
    }
    if (! ($ont->isa("Bio::DB::PersistentObjectI") && $ont->primary_key)) {
        # to avoid side effects like clobbering this ontology's
        # properties with possibly older ones from the database we'll
        # need an object factory
        $ont = $ont->obj() if $ont->isa("Bio::DB::PeristentObjectI");
        my $ontfact = Bio::Factory::ObjectFactory->new(-type => ref($ont));
        my $adp = $self->_ont_adaptor();
        $ont = $adp->find_by_unique_key($ont, '-obj_factory' => $ontfact);
    }
    return ref($ont) ?
        # note that having the persistent object in the -objs array
        # will constrain by the foreign key to that object
        $self->remove_association(-objs => ["Bio::Ontology::TermI",
                                            "Bio::Ontology::TermI",
                                            "Bio::Ontology::TermI",
                                            $ont]
                                  )
        # if the ontology couldn't be found, there can't be relationships
        # for it either
        : 1;
}


=head1 Methods overriden from BasePersistenceAdaptor

=cut

=head1 Private methods

 These are mostly convenience and/or short-hand methods.

=cut

=head2 _ont_adaptor

 Title   : _ont_adaptor
 Usage   : $obj->_ont_adaptor($newval)
 Function: Get/set the ontology persistence adaptor. 
 Example : 
 Returns : value of _ont_adaptor (a Bio::DB::PersistenceAdaptorI object)
 Args    : on set, new value (a Bio::DB::PersistenceAdaptorI object
           or undef, optional)


=cut

sub _ont_adaptor{
    my $self = shift;

    return $self->{'_ont_adaptor'} = shift if @_;
    if(! exists($self->{'_ont_adaptor'})) {
	$self->{'_ont_adaptor'} =
	    $self->db->get_object_adaptor("Bio::Ontology::OntologyI");
    }
    return $self->{'_ont_adaptor'};
}

=head2 _term_adaptor

 Title   : _term_adaptor
 Usage   : $obj->_term_adaptor($newval)
 Function: Get/set the ontology term persistence adaptor. 
 Example : 
 Returns : value of _term_adaptor (a Bio::DB::PersistenceAdaptorI object)
 Args    : on set, new value (a Bio::DB::PersistenceAdaptorI object
           or undef, optional)


=cut

sub _term_adaptor{
    my $self = shift;

    return $self->{'_term_adaptor'} = shift if @_;
    if(! exists($self->{'_term_adaptor'})) {
	$self->{'_term_adaptor'} =
	    $self->db->get_object_adaptor("Bio::Ontology::TermI");
    }
    return $self->{'_term_adaptor'};
}

1;
