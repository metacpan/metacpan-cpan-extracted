# $Id$
#
# BioPerl module for Bio::DB::BioSQL::ReferenceAdaptor
#
# Please direct questions and support issues to <bioperl-l@bioperl.org> 
#
# Cared for by Elia Stupka <elia@ebi.ac.uk>
#
# Copyright Elia Stupka
#
# You may distribute this module under the same terms as perl itself

# 
# Version 1.13 and up are also
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

Bio::DB::BioSQL::ReferenceAdaptor - DESCRIPTION of Object

=head1 SYNOPSIS

Give standard usage here

=head1 DESCRIPTION

Adaptor for Reference objects inside bioperl db 

=head1 FEEDBACK

=head2 Mailing Lists

User feedback is an integral part of the evolution of this
and other Bioperl modules. Send your references and suggestions preferably
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

=head1 AUTHOR - Elia Stupka, Hilmar Lapp

Email elia@ebi.ac.uk
Email hlapp at gmx.net

=head1 APPENDIX

The rest of the documentation details each of the object methods. Internal methods are usually preceded with a _

=cut


# Let the code begin...

package Bio::DB::BioSQL::ReferenceAdaptor;
use vars qw(@ISA);
use strict;

use Bio::Annotation::Reference;
use Bio::Annotation::DBLink;
use Bio::DB::BioSQL::BasePersistenceAdaptor;
use Bio::DB::PersistentObjectI;

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

    return ("authors","title","location","doc_id","start","end","rank");
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
    my @vals = ($obj->authors(),
		$obj->title(),
		$obj->location(),
		$self->_crc64($obj),
		$obj->start(),
		$obj->end(),
                $obj->can('rank') ? $obj->rank() : undef,
		);
    return \@vals;
}

=head2 get_foreign_key_objects

 Title   : get_foreign_key_objects
 Usage   :
 Function: Gets the objects referenced by this object, and which
           therefore need to be referenced as foreign keys in the
           datastore.

           Bio::Annotation::Reference has a virtual dbxref (e.g., the
           MEDLINE link) as foreign key. Virtual means that in the
           object model there is no such reference, but there is in
           the BioSQL schema.

 Example :
 Returns : an array of Bio::DB::PersistentObjectI implementing objects
 Args    : The object about to be inserted or updated, or undef if the call
           is for a SELECT query. In the latter case return class or interface
           names that are mapped to the foreign key tables.

           Optionally, additional named parameters. A common parameter will
           be -fkobjs, with a reference to an array of foreign key objects
           that are not retrievable from the persistent object itself.


=cut

sub get_foreign_key_objects{
    my $self = shift;
    my $obj = shift;
    my $fk;

    if($obj) {
	$fk = $self->_dblink_fk($obj);
    }
    $fk = "Bio::Annotation::DBLink" unless $fk;
    return $fk;
}

=head2 attach_foreign_key_objects

 Title   : attach_foreign_key_objects
 Usage   :
 Function: Attaches foreign key objects to the given object as far as
           necessary.

           This method is called after find_by_XXX() queries, not for INSERTs
           or UPDATEs.

           Bio::Annotation::Reference has a virtual dbxref (e.g., the
           MEDLINE link) as foreign key. Virtual means that in the
           object model there is no such reference, but there is in
           the BioSQL schema.

 Example :
 Returns : TRUE on success, and FALSE otherwise.
 Args    : The object to which to attach foreign key objects.
           A reference to an array of foreign key values, in the order of
           foreign keys returned by get_foreign_key_objects().


=cut

sub attach_foreign_key_objects{
    my ($self,$obj,$fks) = @_;
    my $ok = 1;
    
    if($fks && @$fks && $fks->[0]) {
	my $dbl = $self->_dbxref_adaptor->find_by_primary_key($fks->[0]);
	if($dbl) {
	    if(uc($dbl->database()) eq "PUBMED") {
		$obj->pubmed($dbl->primary_id());
	    } else {
		# we treat everything else as MEDLINE. Not very clean.
		$obj->medline($dbl->primary_id());
	    }
	} else {
	    $ok = 0;
	}
    }
    return $ok;
}

=head2 store_children

 Title   : store_children
 Usage   :
 Function: Inserts or updates the child entities of the given object in
           the datastore.

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

           We just return TRUE here, because the dbxref child is only
           virtual.

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
	    $obj = Bio::Annotation::Reference->new();
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
	$obj->authors($row->[1]) if $row->[1];
	$obj->title($row->[2]) if $row->[2];
	$obj->location($row->[3]) if $row->[3];
	$obj->start($row->[5]) if $row->[5];
	$obj->end($row->[6]) if $row->[6];
        $obj->rank($row->[7]) if $row->[7] && $obj->can('rank');
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
 Function: Obtain the suitable unique key slots and values as
           determined by the attribute values of the given object and
           the additional foreign key objects, in case foreign keys
           participate in a UK.

 Example :
 Returns : One or more references to hash(es) where each hash
           represents one unique key, and the keys of each hash
           represent the names of the object's slots that are part of
           the particular unique key and their values are the values
           of those slots as suitable for the key.
 Args    : The object with those attributes set that constitute the
           chosen unique key (note that the class of the object will
           be suitable for the adaptor).

           A reference to an array of foreign key objects if not
           retrievable from the object itself.


=cut

sub get_unique_key_query{
    my ($self,$obj,$fkobjs) = @_;
    my @ukqueries = ();

    # UK is either the dbxref foreign key, or the (computed) identifier
    # for this object
    if($obj->medline()) {
	my $dbl = Bio::Annotation::DBLink->new(-database => "MEDLINE",
					       -primary_id => $obj->medline);
	$dbl = $self->_dbxref_adaptor->find_by_unique_key($dbl);
	if($dbl) {
	    push(@ukqueries, {
		'medline' => $dbl->primary_key(),
	    });
	}
    }
    if($obj->pubmed()) {
	my $dbl = Bio::Annotation::DBLink->new(-database => "PUBMED",
					       -primary_id => $obj->pubmed);
	$dbl = $self->_dbxref_adaptor->find_by_unique_key($dbl);
	if($dbl) {
	    push(@ukqueries, {
		'pubmed' => $dbl->primary_key(),
	    });
	}
    }
    # note that according to the BioSQL v1.0 schema location is mandatory,
    # so this clause should always evaluate to true, at least if the
    # annotation comes from a legitimate source (such as Genbank, UniProt, etc)
    if($obj->authors() || $obj->title() || $obj->location()) {
	push(@ukqueries, {
	    'doc_id' => $self->_crc64($obj),
	});
    }
    
    return @ukqueries;
}


=head1 Overridden Inherited Methods

=cut

=head2 add_association

 Title   : add_assocation
 Usage   :
 Function: Stores the association between given objects in the datastore.

           We override this here to add start() and end() to the values
           hash. Everything else is left untouched and passed on to the
           inherited implementation.
 Example :
 Returns : TRUE on success and FALSE otherwise
 Args    : Named parameters. At least the following must be recognized:
               -objs   a reference to an array of objects to be associated with
                       each other
               -values a reference to a hash the keys of which are abstract
                       column names and the values are values of those columns.
                       These columns are generally those other than
                       the ones for foreign keys to the entities to be
                       associated
               -obj_contexts optional, if given it denotes a reference to an
                       array of context keys (strings), which allow the
                       foreign key name to be determined through the
                       association map rather than through foreign_key_name().
                       This is necessary if more than one object of the same
                       type takes part in the association. The array must be
                       in the same order as -objs, and have the same number
                       of elements. Put "default" for objects for which there
                       are no multiple contexts.
  Caveats: Make sure you *always* give the objects to be associated in the
           same order.


=cut

sub add_association{
    my ($self,@args) = @_;
    my ($i);

    # get arguments
    my ($objs, $values) = $self->_rearrange([qw(OBJS VALUES)], @args);
    # have we been called in error? If so, be graceful and return an error.
    return undef unless $objs && @$objs;
    # figure out which one of the objects is the reference
    my ($refobj) = grep { ref($_) &&
			      $_->isa("Bio::Annotation::Reference"); } @$objs;
    if($refobj) {
	$values->{'start'} = $refobj->start();
	$values->{'end'} = $refobj->end();
    } else {
	$self->warn("unable to figure out the Bio::Annotation::Reference ".
		    "object to associate with something, expect problems");
    }
    # pass on to the inherited impl.
    return $self->SUPER::add_association(@args);
}

=head1 Internal methods

 These are mostly private or 'protected.' Methods which are in the
 latter class have this explicitly stated in their
 documentation. 'Protected' means you may call these from derived
 classes, but not from outside.

=cut

=head2 _dbxref_adaptor

 Title   : _dbxref_adaptor
 Usage   : $obj->_dbxref_adaptor($newval)
 Function: Get/set cached persistence adaptor for a bioperl DBLink object.

           In OO speak, consider the access class of this method protected.
           I.e., call from descendants, but not from outside.
 Example : 
 Returns : value of _dbxref_adaptor (a Bio::DB::PersistenceAdaptorI
	   instance)
 Args    : new value (a Bio::DB::PersistenceAdaptorI instance, optional)


=cut

sub _dbxref_adaptor{
    my ($self,$adp) = @_;
    if( defined $adp) {
	$self->{'_dbxref_adaptor'} = $adp;
    }
    if(! exists($self->{'_dbxref_adaptor'})) {
	$self->{'_dbxref_adaptor'} =
	    $self->db()->get_object_adaptor("Bio::Annotation::DBLink");
    }
    return $self->{'_dbxref_adaptor'};
}

=head2 _dblink_fk

 Title   : _dblink_fk
 Usage   : $fk_dbl = $obj->_dblink_fk()
 Function: Get the L<Bio::Annotation::DBLink> object representing 
           the foreign key of references to their db_xref, if there
           is a medline ID.
 Example : 
 Returns : A persistent Bio::Annotation::DBLink object
 Args    : The Bio::Annotation::Reference object for which to emulate
           the foreign key object


=cut

sub _dblink_fk{
    my $self = shift;
    my $obj = shift;
    my ($db,$id,$dbl);

    if($obj->medline()) {
	$db = "MEDLINE"; $id = $obj->medline();
    } elsif($obj->pubmed()) {
	$db = "PUBMED"; $id = $obj->pubmed();
    }
    if($db) {
	$dbl = Bio::Annotation::DBLink->new(-database => $db,
					    -primary_id => $id);
	$dbl = $self->_dbxref_adaptor->create_persistent($dbl);
    }
    return $dbl;
}

=head2 _crc64

 Title   : _crc64
 Usage   :
 Function: Computes and returns the CRC64 checksum for a given
           reference object.

           The method uses the reference's authors, title, and
           location properties.

 Example :
 Returns : the CRC64 as a string
 Args    : the Bio::Annotation::Reference object for which to compute
           the CRC


=cut

sub _crc64{
    my $self = shift;
    my $obj = shift;

    my $str =
	(defined($obj->authors) ? $obj->authors : "<undef>") .
	(defined($obj->title) ? $obj->title : "<undef>") .
	(defined($obj->location) ? $obj->location : "<undef>");	
    
    return 'CRC-'.$self->crc64($str);
      
}

1;
