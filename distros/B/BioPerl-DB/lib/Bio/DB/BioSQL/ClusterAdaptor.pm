# $Id$
#
# BioPerl module for Bio::DB::BioSQL::ClusterAdaptor
#
# Please direct questions and support issues to <bioperl-l@bioperl.org> 
#
# Cared for by Hilmar Lapp, hlapp at gmx.net
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

Bio::DB::BioSQL::ClusterAdaptor - DESCRIPTION of Object

=head1 SYNOPSIS

Give standard usage here

=head1 DESCRIPTION

Describe the object here

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
  http://redmine.open-bio.org/projects/bioperl/

=head1 AUTHOR - Hilmar Lapp

Email hlapp at gmx.net

=head1 APPENDIX

The rest of the documentation details each of the object
methods. Internal methods are usually preceded with a _

=cut


# Let the code begin...


package Bio::DB::BioSQL::ClusterAdaptor;
use vars qw(@ISA);
use strict;

use Bio::DB::BioSQL::BasePersistenceAdaptor;
use Bio::DB::Persistent::BioNamespace;
use Bio::BioEntry;
use Bio::Ontology::Ontology;
use Bio::Ontology::Term;
use Bio::Annotation::SimpleValue;
use Bio::Cluster::UniGene;
use Bio::Cluster::ClusterFactory;

@ISA = qw(Bio::DB::BioSQL::BasePersistenceAdaptor);

my %member_type_map = (
		       "Bio::Cluster::UniGene" => "Bio::SeqI",
		       "Bio::Cluster::SequenceFamily" => "Bio::SeqI",
		       );

# new inherited from base adaptor.
#
# if we wanted caching we'd have to override new here

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

    return ("display_id", "accession_number", "description", "version");
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
    my @vals = ($obj->display_id(),
		$obj->display_id(),
		$obj->description(),
		$obj->isa("Bio::IdentifiableI") ? ($obj->version() || 0) : 0);
    return \@vals;
}

=head2 get_foreign_key_objects

 Title   : get_foreign_key_objects
 Usage   :
 Function: Gets the objects referenced by this object, and which therefore need
           to be referenced as foreign keys in the datastore.

           A Bio::ClusterI references a namespace with authority, and
           possibly a species.

 Example :
 Returns : an array of Bio::DB::PersistentObjectI implementing objects
 Args    : The object about to be inserted or updated, or undef if the call
           is for a SELECT query. In the latter case return class or interface
           names that are mapped to the foreign key tables.


=cut

sub get_foreign_key_objects{
    my ($self,$obj) = @_;
    my ($ns,$taxon);

    if($obj) {
	# there is no "namespace" or Bio::Identifiable object in bioperl, so
	# we need to create one here
	$ns = Bio::DB::Persistent::BioNamespace->new(-identifiable => $obj);
	$ns->adaptor($self->_bionamespace_adaptor());
	# species is optional
	$taxon = $obj->species() if $obj->can('species');
    } else {
	$ns = "Bio::DB::Persistent::BioNamespace";
    }
    $taxon = "Bio::Species" unless $taxon;
    return ($ns, $taxon);
}

=head2 attach_foreign_key_objects

 Title   : attach_foreign_key_objects
 Usage   :
 Function: Attaches foreign key objects to the given object as far as
           necessary.

           This method is called after find_by_XXX() queries, not for INSERTs
           or UPDATEs.

           ClusterIs have a BioNamespace as foreign key, and possibly
           a species.

 Example :
 Returns : TRUE on success, and FALSE otherwise.
 Args    : The object to which to attach foreign key objects.
           A reference to an array of foreign key values, in the order of
           foreign keys returned by get_foreign_key_objects().


=cut

sub attach_foreign_key_objects{
    my ($self,$obj,$fks) = @_;
    my $ok = 0;
    
    # retrieve namespace by primary key
    my $nsadp = $self->_bionamespace_adaptor();
    my $ns = $nsadp->find_by_primary_key($fks->[0]);
    if($ns) {
	$obj->namespace($ns->namespace()) if $ns->namespace();
	$obj->authority($ns->authority()) if $ns->authority();
	$ok = 1;
    }
    # there's also possibly a species
    if($fks && $fks->[1] && $obj->can('species')) {
	my $adp = $self->db()->get_object_adaptor("Bio::Species");
	my $species = $adp->find_by_primary_key($fks->[1]);
	$ok &&= $species;
	$obj->species($species);
    }
    return $ok;
}

=head2 store_children

 Title   : store_children
 Usage   :
 Function: Inserts or updates the child entities of the given object in the 
           datastore.

           Bio::ClusterI has annotations as children.

 Example :
 Returns : TRUE on success, and FALSE otherwise
 Args    : The Bio::DB::PersistentObjectI implementing object for which the
           child objects shall be made persistent.


=cut

sub store_children{
    my ($self,$obj) = @_;
    my $ok = 1;

    # cluster size becomes a qualifier/value association, which essentially
    # is a SimpleValue annotation
    my $sizeann = $self->_object_slot('cluster size',$obj->size());
    $sizeann = $sizeann->create();
    # since we don't (can't very well due to the difficult definition of
    # alternative keys) update associations, first remove the old size
    # slot (value() won't be considered here)
    $ok = $sizeann->adaptor->remove_association(-objs => [$sizeann, $obj],
						-values => {"rank" => 1});
    # add the new size
    $ok = $sizeann->adaptor->add_association(-objs => [$sizeann, $obj],
					     -values => {"rank" => 1});

    # we need to store the annotations, and associate ourselves with them
    if($obj->can('annotation')) {
	my $ac = $obj->annotation();
	# the annotation object might just have been created on the fly, and
	# hence may not be a PersistentObjectI (if that's the case we'll
	# assume it's empty, and there's no point storing anything)
	if($ac->isa("Bio::DB::PersistentObjectI")) {
	    $ok = $ac->store(-fkobjs => [$obj]) && $ok;
	    $ok = $ac->adaptor()->add_association(-objs => [$ac, $obj]) && $ok;
	}
    }

    # finally, store the members
    #
    # obtain the type term for the association upfront
    my $assoctype = $self->_ontology_term('cluster member',
					  'Relationship Type Ontology',
					  'FIND IT');
    $assoctype->create() unless $assoctype->primary_key();
    foreach my $mem ($obj->get_members()) {
	# each member needs to be persistent object
	if(! $mem->isa("Bio::DB::PersistentObjectI")) {
	    $mem = $self->db->create_persistent($mem);
	}
	# each member needs to have a primary key
	if(! $mem->primary_key()) {
	    if(my $found = $mem->adaptor->find_by_unique_key($mem, 
                                                             -flat_only =>1)) {
		$mem->primary_key($found->primary_key());
	    } else {
		$ok = $mem->create() && $ok;
	    }
	}
	# associate the cluster with the member
	$mem->adaptor->add_association(-objs =>    [$obj, $mem, $assoctype],
				       -contexts =>["subject","object",undef]);
    }
    # done
    return $ok;
}

=head2 remove_children

 Title   : remove_children
 Usage   :
 Function: This method is to cascade deletes in maintained objects.

           We need to undefine the primary keys of all contained
           annotation objects here.

 Example :
 Returns : TRUE on success and FALSE otherwise
 Args    : The persistent object that was just removed from the database.
           Additional (named) parameter, as passed to remove().


=cut

sub remove_children{
    my $self = shift;
    my $obj = shift;

    # annotation collection
    if($obj->can('annotation')) {
	my $ac = $obj->annotation();
	if($ac->isa("Bio::DB::PersistentObjectI")) {
	    $ac->primary_key(undef);
	    $ac->adaptor()->remove_children($ac);
	}
    }
    # done
    return 1;
}

=head2 remove_members

 Title   : remove_members
 Usage   :
 Function: Dissociates all cluster members from this cluster. 

           Note that this method does not delete the members
           themselves, it only removes the association between them
           and this cluster.

 Example :
 Returns : TRUE on success and FALSE otherwise
 Args    : The persistent object for which to remove the members


=cut

sub remove_members{
    my $self = shift;
    my $obj = shift;

    my $assoctype = $self->_ontology_term('cluster member',
					  'Relationship Type Ontology',
					  'FIND IT');
    my $ok = 1;
    # if the association type isn't known yet, there can't be any
    # members either
    if($assoctype) {
	$ok = $self->remove_association(-objs => [$obj,"Bio::SeqI",$assoctype],
					-contexts=>["subject","object",undef]);
    }
    return $ok;
}

=head2 attach_children

 Title   : attach_children
 Usage   :
 Function: Possibly retrieve and attach child objects of the given object.

           This is needed when whole object trees are supposed to be built
           when a base object is queried for and returned. An example would
           be Bio::SeqI objects and all the annotation objects that hang off
           of it.

           This is called by the find_by_XXXX() methods once the base object
           has been built. 

           For Bio::ClusterIs, we need to get the annotation objects.

 Example :
 Returns : TRUE on success, and FALSE otherwise.
 Args    : The object for which to find and to which to attach the child
           objects.


=cut

sub attach_children{
    my ($self,$obj) = @_;
    my $ok = 1;

    # we need to associate annotation
    my $ac;
    if($obj->can('annotation')) {
	my $annadp = $self->db()->get_object_adaptor(
					       "Bio::AnnotationCollectionI");
	my $qres = $annadp->find_by_association(-objs => [$annadp,$obj]);
	$ok &&= $qres;
	$ac = $qres->next_object();
	if($ac) {
	    $obj->annotation($ac);
	}
    }
    # remove the Annotation::OntologyTerm objects that are rather terms for
    # object slots (actually, there shouldn't be any because they
    # should have been precluded by ontology constraint)
    $ac->remove_Annotations('Object Slots') if $ac;
    #
    # find the tag/value pairs corresponding to object slots
    my $slotval = $self->_object_slot('dummy');
    # we simply pass the wrapped object, because otherwise the base adaptor
    # thinks we want to constrain by the name of the tag, whereas we want
    # to constrain by the ontology of the tag
    my $qres = $slotval->adaptor->find_by_association(
					      -objs => [$slotval->obj, $obj]);
    $ok &&= $qres;
    while($slotval = $qres->next_object()) {
	if($slotval->tagname() eq 'cluster size') {
	    $obj->size($slotval->value());
	}
    }
    #
    # find and attach the cluster members
    my $assoctype;
    if($obj->can('add_member') &&
       # if the association type isn't known yet, there won't be any
       # members either
       ($assoctype = $self->_ontology_term('cluster member',
					   'Relationship Type Ontology',
					   'FIND IT'))) {
	# pre-determine type of member - we need this to determine the adaptor
	my $memtype = $member_type_map{ref($obj->obj)};
	if(! $memtype) {
	    $self->warn("type of members for ".ref($obj->obj)." not mapped - ".
			"assuming Bio::SeqI as the default");
	    $memtype = "Bio::SeqI";
	}
	# obtain adaptor for desired type
	my $adp = $self->db->get_object_adaptor($memtype);
	# setup the query
	my $qres = $adp->find_by_association(-objs     => [$memtype, $obj, 
							   $assoctype],
					     -contexts => ["object", "subject",
							   undef]);
	while(my $mem = $qres->next_object()) {
	    $obj->add_member($mem);
	}
    }
    # done
    return $ok;
}

=head2 instantiate_from_row

 Title   : instantiate_from_row
 Usage   :
 Function: Instantiates the class this object is an adaptor for, and populates
           it with values from columns of the row.

 Example :
 Returns : An object, or undef, if the row contains no values
 Args    : A reference to an array of column values. The first column is the
           primary key, the other columns are expected to be in the order 
           returned by get_persistent_slots().
           Optionally, a Bio::Factory::ObjectFactoryI compliant object to
           be used for creating the object.


=cut

sub instantiate_from_row{
    my ($self,$row,$fact) = @_;
    my $obj;

    if($row && @$row) {
	if(! $fact) {
	    # there is no good default implementation currently
	    $fact = $self->_cluster_factory();
	}
	$obj = $fact->create_object(-display_id => $row->[1]);
	$self->populate_from_row($obj, $row);
    }
    return $obj;
}

=head2 populate_from_row

 Title   : populate_from_row
 Usage   :
 Function: Populates an object with values from columns of the row.

 Example :
 Returns : The object populated, or undef, if the row contains no values
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
	my $has_lsid = $obj->isa("BioIdentifiableI");
	$obj->display_id($rows->[1]) if $rows->[1];
	$obj->object_id($rows->[2]) if $rows->[2] && $has_lsid;
	$obj->description($rows->[3]) if $rows->[3];
	$obj->version($rows->[4]) if $rows->[4] && $has_lsid;
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

    # UK for ClusterI is (display ID,namespace,version),
    #
    if($obj->display_id()) {
	$uk_h->{'accession_number'} = $obj->display_id();
	$uk_h->{'version'} =
	    $obj->isa("Bio::IdentifiableI") ? ($obj->version() || 0) : 0;
	# add namespace if possible
	if($obj->namespace()) {
	    my $ns = Bio::BioEntry->new(-namespace => $obj->namespace());
	    $ns = $self->_bionamespace_adaptor()->find_by_unique_key($ns);
	    $uk_h->{'bionamespace'} = $ns->primary_key() if $ns;
	}
    }

    return $uk_h;
}

=head1 Internal methods

 These are mostly private or 'protected.' Methods which are in the
 latter class have this explicitly stated in their
 documentation. 'Protected' means you may call these from derived
 classes, but not from outside.

 Most of these methods cache certain adaptors or otherwise reduce call
 path and object creation overhead. There's no magic here.

=cut

=head2 _bionamespace_adaptor

 Title   : _bionamespace_adaptor
 Usage   : $obj->_bionamespace_adaptor($newval)
 Function: Get/set cached persistence adaptor for the bionamespace.

           In OO speak, consider the access class of this method protected.
           I.e., call from descendants, but not from outside.
 Example : 
 Returns : value of _bionamespace_adaptor (a Bio::DB::PersistenceAdaptorI
	   instance)
 Args    : new value (a Bio::DB::PersistenceAdaptorI instance, optional)


=cut

sub _bionamespace_adaptor{
    my ($self,$adp) = @_;
    if( defined $adp) {
	$self->{'_bions_adaptor'} = $adp;
    }
    if(! exists($self->{'_bions_adaptor'})) {
	$self->{'_bions_adaptor'} =
	    $self->db->get_object_adaptor("BioNamespace");
    }
    return $self->{'_bions_adaptor'};
}

=head2 _cluster_factory

 Title   : _cluster_factory
 Usage   : $obj->_cluster_factory($newval)
 Function: Get/set the Bio::Factory::ObjectFactoryI to use
 Example : 
 Returns : value of _cluster_factory (a scalar)
 Args    : on set, new value (a scalar or undef, optional)


=cut

sub _cluster_factory{
    my $self = shift;

    return $self->{'_cluster_factory'} = shift if @_;
    if(! exists($self->{'_cluster_factory'})) {
	$self->{'_cluster_factory'} = Bio::Cluster::ClusterFactory->new();
    }
    return $self->{'_cluster_factory'};
}

=head2 _object_slot

 Title   : _object_slot
 Usage   : $term = $obj->_object_slot($slot, $value);
 Function: Obtain the persistent L<Bio::Annotation::SimpleValue>
           representation of certain slots that map to ontology term
           associations (e.g. size).

           This is an internal method.

 Example : 
 Returns : A persistent L<Bio::Annotation::SimpleValue> object
 Args    : The slot for which to obtain the SimpleValue object.
           The value of the slot.


=cut

sub _object_slot{
    my ($self,$slot,$val) = @_;
    my $svann;

    if(! exists($self->{'_object_slots'})) {
	$self->{'_object_slots'} = {};
    }

    if(! exists($self->{'_object_slots'}->{$slot})) {
	my $ont = Bio::Ontology::Ontology->new(-name => 'Object Slots');
	my $term = Bio::Ontology::Term->new(-name     => $slot,
					    -ontology => $ont);
	$svann = Bio::Annotation::SimpleValue->new(-tag_term => $term);
	$self->{'_object_slots'}->{$slot} = $svann;
    } else {
	$svann = $self->{'_object_slots'}->{$slot};
    }
    # always create a new persistence wrapper for it - otherwise we run the
    # risk of messing with cached objects
    $svann->value($val);
    $svann = $self->db()->create_persistent($svann);
    return $svann;
}

=head2 _ontology_term

 Title   : _ontology_term
 Usage   : $term = $obj->_ontology_term($name,$ontology)
 Function: Obtain the persistent ontology term with the given name
           and ontology.

           This is an internal method.

 Example : 
 Returns : A persistent Bio::Ontology::TermI object
 Args    : The name for the term.
           The ontology name for the term.
           Whether or not to find the term.


=cut

sub _ontology_term{
    my ($self,$name,$cat,$find_it) = @_;
    my $term;

    if(! exists($self->{'_ontology_terms'})) {
	$self->{'_ontology_terms'} = {};
    }

    if(! exists($self->{'_ontology_terms'}->{$name})) {
	$term = Bio::Ontology::Term->new(-name => $name,
					 -ontology => $cat);
	$self->{'_ontology_terms'}->{$name} = $term;
    } else {
	$term = $self->{'_ontology_terms'}->{$name};
    }
    if($find_it) {
	my $adp = $self->db->get_object_adaptor($term);
	my $found = $adp->find_by_unique_key($term);
	if (ref($found)) {
	    $term = $found;
	} else {
	    $term = $self->db()->create_persistent($term);
	}
    }
    return $term;
}

1;
