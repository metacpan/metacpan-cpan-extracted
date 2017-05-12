# $Id$
#
# BioPerl module for Bio::DB::BioSQL::BasePersistenceAdaptor
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

Bio::DB::BioSQL::BasePersistenceAdaptor - DESCRIPTION of Object

=head1 SYNOPSIS

Give standard usage here

=head1 DESCRIPTION

Describe the object here

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

=head1 CONTRIBUTORS

Additional contributors names and emails here

=head1 APPENDIX

The rest of the documentation details each of the object methods.
Internal methods are usually preceded with a _

=cut


# Let the code begin...


package Bio::DB::BioSQL::BasePersistenceAdaptor;
use vars qw(@ISA);
use strict;
use Scalar::Util qw(blessed refaddr reftype);

# Object preamble - inherits from Bio::Root::Root

use Bio::Root::Root;
use Bio::DB::PersistenceAdaptorI;
use Bio::DB::PersistentObjectI;
use Bio::DB::Persistent::PersistentObject;
use Bio::DB::Query::BioQuery;
use Bio::DB::Query::DBQueryResult;
use Bio::DB::Query::SqlGenerator;
use Bio::DB::Query::PrebuiltResult;
use Bio::DB::DBI::Transaction;

@ISA = qw(Bio::Root::Root Bio::DB::PersistenceAdaptorI);

=head2 new

 Title   : new
 Usage   : my $obj = Bio::DB::BioSQL::BasePersistenceAdaptor->new();
 Function: Builds a new Bio::DB::BioSQL::BasePersistenceAdaptor object 
 Returns : an instance of Bio::DB::BioSQL::BasePersistenceAdaptor
 Args    :

=cut

sub new {
    my($class,@args) = @_;

    my $self = $class->SUPER::new(@args);
    my ($dbc, $do_cache) = $self->_rearrange([qw(DBCONTEXT
						 CACHE_OBJECTS)
					      ], @args);

    $self->caching_mode($do_cache);
    $self->{'_pers_recurs_cache'} = {};    
    $self->dbcontext($dbc) if $dbc;

    return $self;
}

=head1 Methods for managing persistence

This comprises of creating an object in the database (equivalent to an
insert), storing an object in the database (equivalent to an update),
removing an object from the database (equivalent to a delete), and
adding and removing associations between objects when the underlying
schema supports such associations.

=cut

=head2 create

 Title   : create
 Usage   : $objectstoreadp->create($obj, @params)
 Function: Creates the object as a persistent object in the datastore. This
           is equivalent to an insert.
 Example :
 Returns : A Bio::DB::PersistentObjectI implementing object wrapping the
           inserted object.
 Args    : The object to be inserted, and optionally additional (named) 
           parameters. A common parameter will
           be -fkobjs, with a reference to an array of foreign key objects
           that are not retrievable from the persistent object itself.

=cut

sub create{
    my ($self,$obj,@args) = @_;
    my $skip_children; # at some point we may want to introduce an
                       # argument that allows you to supply this

    # If the object wasn't a PersistentObjectI already it needs to become
    # one now. We do this always to make sure the children etc are persistent,
    # too. Note that Bio::DB::PersistentObjectI objects remain the same
    # reference.
    $obj = $self->create_persistent($obj);
    # obtain foreign key objects either from arguments or from object
    my @fkobjs = $self->get_foreign_key_objects($obj, @args);
    # make sure the foreign key objects are all persistent objects and have
    # been stored already
    foreach (@fkobjs) {
	next unless ref($_);
	if(! $_->isa("Bio::DB::PersistentObjectI")) {
	    $self->throw("All foreign key objects must implement ".
			 "Bio::DB::PersistentObjectI. This one doesn't: ".
			 ref($_));
	}
	# no cascading updates of FK objects through create()
	$_->create() unless $_->primary_key();
    }
    # The object may already exist, and we don't want to duplicate it.
    # We'll rely on the RDBMS to catch UK violations unless this adaptor
    # caches objects, in which case we'll do a query by UK first. The idea
    # is that this will save many failing INSERTs for objects of a finite
    # number (as the adaptors for those will have caching enabled hopefully),
    # and save many unnecessary UK look-ups for objects of unlimited number,
    # because those will be new in most cases.
    #
    # Note that since foreign keys may be part of the unique key, we can
    # do this only now (i.e., after having stored the parent rows).
    my $foundobj;
    if($self->caching_mode() &&
       ($foundobj = $self->find_by_unique_key($obj, @args))) {
	$obj->primary_key($foundobj->primary_key);
	# Should we return right here instead of storing children? Not sure.
	#
	# My take is that we shouldn't store the children for found objects,
	# because it essentially would amount to updating dependent
	# information, which is inconsistent with the fact that we don't
	# update the object itself. So, leave it to the caller to physically
	# trigger an update (which will cascade through to the children)
	# instead of doing possibly unwanted magic here.
	# 
	$skip_children = 1 unless defined($skip_children);
    } else {
	# either caching disabled or not found in cache
	#
	# insert and obtain primary key
	my $pk = $self->dbd()->insert_object($self, $obj, \@fkobjs);
	# if no primary key, it may be due to a UK violation (provided that
	# caching is disabled)
	if(! (defined($pk) || $self->caching_mode())) {
	    $foundobj = $self->find_by_unique_key($obj, @args);
	    $pk = $foundobj->primary_key() if $foundobj;
	}
	if(! defined($pk)) {
	    $self->throw("create: object (". ref($obj->obj) .
			 ") failed to insert or to be found by unique key");
	}
	# store primary key
	$obj->primary_key($pk);
    }
    # insert child records if any
    my $ok = $skip_children ? 1 : $self->store_children($obj, \@fkobjs);
    if((! defined($ok)) || ($ok <= 0)) {
	$self->warn("failed to store ".
		    ($ok ? -$ok : "one or more").
		    " child objects for an instance of class ".
		    ref($obj->obj()). " (PK=".$obj->primary_key().")");
    } else {
	# mark it as clean - it's fresh from the press
	$obj->is_dirty(0);
    }
    # done
    return $obj;
}

=head2 store

 Title   : store
 Usage   : $objectstoreadp->store($persistent_obj,@params)
 Function: Updates the given persistent object in the datastore.
 Example :
 Returns : TRUE on success and FALSE otherwise
 Args    : The object to be updated, and optionally additional (named) 
           parameters. A common parameter will
           be -fkobjs, with a reference to an array of foreign key objects
           that are not retrievable from the persistent object itself.

=cut

sub store{
    my ($self,$obj,@args) = @_;

    $self->throw("Object of class ".ref($obj)." does not implement ".
		 "Bio::DB::PersistentObjectI. Bad, cannot store.")
	if ! $obj->isa("Bio::DB::PersistentObjectI");

    # if there's no primary key, we need to create() the record(s) instead
    # of update
    return $self->create($obj, @args) if(! $obj->primary_key());
    # We do this always to make sure the children etc are all persistent, too.
    $self->create_persistent($obj);
    # obtain foreign key objects either from arguments or from object
    my @fkobjs = $self->get_foreign_key_objects($obj, @args);
    # make sure the foreign key objects are all persistent objects and have
    # a primary key
    foreach (@fkobjs) {
	next unless ref($_);
	if(! $_->isa("Bio::DB::PersistentObjectI")) {
	    $self->throw("All foreign key objects must implement ".
			 "Bio::DB::PersistentObjectI. This one doesn't: ".
			 ref($_));
	}
	# no cascading updates of FK objects - only create()
	$_->create() unless $_->primary_key();
    }
    # update (if necessary)
    my $rv = $obj->is_dirty() > 0 ?
	$self->dbd()->update_object($self, $obj, \@fkobjs) : 1;
    # update children
    $rv = $self->store_children($obj, \@fkobjs);
    if((! defined($rv)) || ($rv <= 0)) {
	$self->warn("failed to store ".
		    ($rv ? -$rv : "one or more").
		    " child objects for an instance of class ".
		    ref($obj->obj()). " (PK=".$obj->primary_key().")");
    }
    # done
    return $rv;
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
    my ($self,$obj,@args) = @_;

    $self->throw("Object of class ".ref($obj)." does not implement ".
		 "Bio::DB::PersistentObjectI. Bad, cannot remove.")
	unless $obj->isa("Bio::DB::PersistentObjectI");
    # first off, delete from cache
    $self->_remove_from_obj_cache($obj);
    # obtain primary key
    my $pk = $obj->primary_key();
    $self->throw("Object of class ".ref($obj)." does not have ".
		 "a primary key.  Have you used \$pobj->create()?") if !defined $pk;
    # prepared delete statement cached?
    my $cache_key = 'DELETE '.ref($obj->obj());
    my $sth = $self->sth($cache_key);
    if(! $sth) {
	# need to create one
	$sth = $self->dbd()->prepare_delete_sth($self, @args);
	# and cache
	$self->sth($cache_key, $sth);
    }
    # execute
    my ($rv, $rv2);
    $self->debug("DELETING ".ref($obj->obj())." object (pk=$pk)\n");
    $rv = $sth->execute($pk);
    # we may need to cascade in software -- ugly
    $rv2 = $self->dbd()->cascade_delete($self->dbcontext(), $obj) if $rv;
    # the caller should commit if necessary
    #
    # take care of the children (do this before undefining the primary key
    # as something might have children that need this to locate them)
    $rv = $self->remove_children($obj,@args) ? $rv : 0;
    # undefine the objects primary key - it doesn't exist in the datastore any
    # longer
    $obj->primary_key(undef);
    # done
    return $rv;
}

=head2 add_association

 Title   : add_assocation
 Usage   :
 Function: Stores the association between given objects in the datastore.
 Example :
 Returns : TRUE on success and FALSE otherwise
 Args    : Named parameters. At least the following must be recognized:
               -objs   a reference to an array of objects to be
                       associated with each other
               -values a reference to a hash the keys of which are
                       abstract column names and the values are values
                       of those columns.  These columns are generally
                       those other than the ones for foreign keys to
                       the entities to be associated
               -contexts optional; if given it denotes a reference
                       to an array of context keys (strings), which
                       allow the foreign key name to be determined
                       through the slot-to-column map rather than through
                       foreign_key_name().  This may be necessary if
                       more than one object of the same type takes
                       part in the association. The array must be in
                       the same order as -objs, and have the same
                       number of elements. Put undef for objects
                       for which there are no multiple contexts.
  Caveats: Make sure you *always* give the objects to be associated in the
           same order.


=cut

sub add_association{
    my ($self,@args) = @_;
    my ($i);

    # get arguments
    my ($objs, $values) =
	$self->_rearrange([qw(OBJS VALUES)], @args);
    # have we been called in error? If so, be graceful and return an error.
    return undef unless $objs && @$objs;
    # construct key for cached statement
    my $cache_key = "INSERT ASSOC [" .
	($values ? scalar(keys %$values) : 0) . "] " .
	join(";", map {
	    $_->isa("Bio::DB::PersistentObjectI") ? ref($_->obj) : ref($_);
	} @$objs);
    # statement cached?
    my $sth = $self->sth($cache_key);
    if(! $sth) {
	# no, we need to get this one from the driver
	$sth = $self->dbd()->prepare_insert_association_sth($self, @args);
	# and cache for future use
	$self->sth($cache_key, $sth);
    }
    # bind columns: first objects
    $i = 1;
    foreach my $obj (@$objs) {
	$self->debug(substr(ref($self),rindex(ref($self),"::")+2).
		     "::add_assoc: ".
		     "binding column $i to \"".$obj->primary_key().
		     "\" (FK to ".ref($obj->obj()).")\n");
        # we cheat a few microseconds here by not routing the call
        # through the persistence driver, but there really shouldn't
        # be any special treatment needed for primary keys
	$sth->bind_param($i, $obj->primary_key());
	$i++;
    }
    # then values if any, but be careful not to bind values for columns
    # that the schema actually doesn't support
    my $columnmap;
    if($values) {
	my $dbd = $self->dbd();
	$columnmap = $dbd->slot_attribute_map(
					$dbd->association_table_name($objs));
	foreach my $valkey (keys %$values) {
	    if($columnmap->{$valkey}) {
		$self->debug(substr(ref($self),rindex(ref($self),"::")+2).
			     "::add_assoc: ".
			     "binding column $i to \"",
			     $values->{$valkey}, "\" ($valkey)\n");
		$dbd->bind_param($sth, $i, $values->{$valkey});
		$i++;
	    }
	}
    }
    # execute
    my $rv = $sth->execute();
    # report unexpected error, also the bind values if not reported before
    if(! ($rv || ($sth->errstr =~ /unique|duplicate entry/i))) {
	my $msg = substr(ref($self),rindex(ref($self),"::")+2).
	    "::add_assoc: unexpected failure of statement execution: ".
	    $sth->errstr."\n\tname: $cache_key";
	# remove sth from cache in order not to trip up obscure 
	# driver-specific bugs, for instance DBD::Oracle after certain
	# errors can't execute the statement again
	$sth->finish();
	$self->sth($cache_key, undef);
	# if verbose is on the values have already been reported
	if($self->verbose <= 0){
	    my @bindprms = map {
		'FK['.ref($_->obj).']:'.$_->primary_key;
	    } @$objs;
	    if($values) {
		push(@bindprms,
		     map {
			 "$_:\"".$values->{$_}.'"';
		     } grep { $columnmap->{$_}; } keys %$values);
	    }
	    $msg .= "\n\tvalues: ".join(", ",@bindprms);
	}
	$self->warn($msg);
    }
    # and return result
    return $rv;    
}

=head2 remove_association

 Title   : remove_assocation
 Usage   :
 Function: Removes the association between the given objects in
           the datastore.
 Example :
 Returns : TRUE on success and FALSE otherwise
 Args    : Named parameters. At least the following must be recognized:
               -objs   a reference to an array of objects the association
                       between which is to be removed
               -values a reference to a hash the keys of which are
                       abstract column names and the values are values
                       of those columns.  These columns are generally
                       those other than the ones for foreign keys to
                       the entities to be associated. Supplying this
                       is only necessary if those columns participate
                       in a unique key by which to find those
                       associations to be removed.
               -contexts optional; if given it denotes a reference
                       to an array of context keys (strings), which
                       allow the foreign key name to be determined
                       through the slot-to-column map rather than through
                       foreign_key_name().  This may be necessary if
                       more than one object of the same type takes
                       part in the association. The array must be in
                       the same order as -objs, and have the same
                       number of elements. Put undef for objects
                       for which there are no multiple contexts.
  Caveats: Make sure you *always* give the objects to be associated in the
           same order.


=cut

sub remove_association{
    my ($self,@args) = @_;
    my ($i);

    # get arguments
    my ($objs, $values) =
	$self->_rearrange([qw(OBJS VALUES)], @args);
    # have we been called in error? If so, be graceful and return an error.
    return undef unless $objs && @$objs;
    # construct key for cached statement
    my $cache_key = "DELETE ASSOC [" .
	($values ? scalar(keys %$values) : 0) . "] " .
	join(";", map {
	    ref($_) ? "OBJ=".
		($_->isa("Bio::DB::PersistentObjectI") ?
		 ref($_->obj) : ref($_)) :
		 $_;
	} @$objs);
    # statement cached?
    my $sth = $self->sth($cache_key);
    if(! $sth) {
	# no, we need to get this one from the driver
	$sth = $self->dbd()->prepare_delete_association_sth($self, @args);
	# and cache for future use
	$self->sth($cache_key, $sth);
    }
    # bind columns: first objects
    $i = 1;
    foreach my $obj (@$objs) {
	if(ref($obj) && $obj->isa("Bio::DB::PersistentObjectI")) {
	    $self->debug(substr(ref($self),rindex(ref($self),"::")+2).
			 "::remove_assoc: ".
			 "binding column $i to \"".$obj->primary_key().
			 "\" (FK to ".ref($obj->obj()).")\n");
            # we cheat a few microseconds here by not routing the call
            # through the persistence driver, but there really shouldn't
            # be any special treatment needed for primary keys
	    $sth->bind_param($i, $obj->primary_key());
	    $i++;
	}
    }
    # then values if any, but be careful not to bind values for columns
    # that the schema actually doesn't support
    if($values) {
	my $dbd = $self->dbd();
	my $columnmap = $dbd->slot_attribute_map(
				         $dbd->association_table_name($objs));
	foreach my $valkey (keys %$values) {
	    if($columnmap->{$valkey}) {
		$self->debug(substr(ref($self),rindex(ref($self),"::")+2).
			     "::remove_assoc: ".
			     "binding column $i to \"",
			     $values->{$valkey}, "\" ($valkey)\n");
		$dbd->bind_param($sth, $i, $values->{$valkey});
		$i++;
	    }
	}
    }
    # execute
    my $rv = $sth->execute();
    # and return result
    return $rv;    
}

=head1 Making persistent objects

The DBAdaptorI factory mandates this operation, but it will in most
cases conduct the operation by first finding the appropriate
persistence adaptor and then asking the adaptor to do the
operation. Hence, here is where the real stuff happens.

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
    my $pobj = $obj;
    
    return undef unless defined($obj);
    # default for persistence wrapper class is
    # Bio::DB::Persistent::PersistentObjct
    $pwrapper = "Bio::DB::Persistent::PersistentObject" unless $pwrapper;
    # if the base object is not yet persistent, make it so
    if(! $obj->isa("Bio::DB::PersistentObjectI")) {
	$pobj = $pwrapper->new(-object => $obj, -adaptor => $self);
    }
    # now we have to go for all children that are eligible for persistence.
    $self->_create_persistent($pobj->obj, $pwrapper);
    # done (hopefully)
    return $pobj;
}

=head2 _create_persistent

 Title   : _create_persistent
 Usage   :
 Function: Calling this method recursively replaces all eligible
           children of the object, i.e., all slots that are objects
           themselves and for which an adaptor exists, with instances
           of Bio::DB::PersistentObjectI.

           This is an internal method. Do not call from outside.
 Example :
 Returns : The first argument.
 Args    :  - A Bio::DB::PersistentObjectI implementing object, the
              class of which is suitable for this adaptor (unless on a
              recursive call).
            - Optionally, the class which actually implements wrapping
              the object to become a PersistentObjectI.

=cut

sub _create_persistent {
    my ($self, $obj, $pwrapper) = @_;

    # loop over children first and replace each one with the recursively
    # made persistent object (depth-first traversal)
    # some operations are different for blessed refs than for unblessed
    my $is_blessed = blessed($obj);
    my $class = ref($obj);
    # we only alter references
    if($class &&
       # but not references to scalars, code, or symbols, which basically
       # leaves arrays, hashes, and blessed references
       ($is_blessed || ($class eq "HASH") || ($class eq "ARRAY"))) {
	# loop over the elements and process each element
	if (reftype($obj) eq "HASH") {
	    foreach my $key (keys %$obj) {
		my $child = $obj->{$key};
		next unless ref($child); # omit non-refs
		$obj->{$key} = $self->_process_child($child, $pwrapper);
	    }
	} elsif (reftype($obj) eq "ARRAY") {
	    my $i = 0;
	    while($i < @$obj) {
		my $child = $obj->[$i];
		# omit non-refs
		if (ref($child)) {
		    $obj->[$i] = $self->_process_child($child, $pwrapper);
		}
		$i++;
	    }
	}
    }
    # done -- I hope
    return $obj;
}

sub _process_child{
    my ($self,$obj,$pwrapper) = @_;

    # some operations are different for blessed refs than for unblessed
    if (blessed($obj)) {
	# if this is a PersistentObjectI, its adaptor needs to do the job
	if($obj->isa("Bio::DB::PersistentObjectI")) {
	    # if the wrapped object is persistent too, we assume the object
	    # knows what it's doing and terminate this recursion
	    return $obj if $obj->obj->isa("Bio::DB::PersistentObjectI");
	    # otherwise we let the persistence adaptor do the job
	    return $obj->adaptor->create_persistent($obj);
	} elsif($obj->isa("Bio::DB::PersistenceAdaptorI")) {
	    # likewise, we don't try to locate an adaptor for an adaptor
	    return $obj;
	} 
	# if we can find a persistence adaptor for it, let that one
	# do the recursive work
	my $objadp;
	eval {
	    $objadp = $self->db->get_object_adaptor($obj);
	};
	if($objadp) {
	    # yeah, found someone to do the work
	    #
	    # cache this recursion to prevent infinite loops if we
	    # meet it again
            my $key = refaddr($obj);
	    if(! $self->{'_pers_recurs_cache'}->{$key}) {		
		$self->{'_pers_recurs_cache'}->{$key} = 1;
		$obj = $objadp->create_persistent($obj, $pwrapper);
		delete $self->{'_pers_recurs_cache'}->{$key};
	    } else {
		$self->warn("recursion detected for ".ref($obj).
			    " object");
	    }
	} else {
	    $self->debug("no adaptor found for class ".ref($obj)."\n");
	    # we won't venture into something we don't have an
	    # adaptor for, meaning we do nothing in this case
	}
	return $obj;
    } else { 
	# a reference, but not a blessed object: we can do that ourselves
	return $self->_create_persistent($obj,$pwrapper);
    }	
}

=head1 Finding objects by some property

This comprises of finding by primary key, finding by unique key
(alternative key), finding by association, and finding by query.

=cut

=head2 find_by_primary_key

 Title   : find_by_primary_key
 Usage   : $objectstoreadp->find_by_primary_key($pk)
 Function: Locates the entry associated with the given primary key and
           initializes a persistent object with that entry.

           By default this implementation caches all objects by primary key
           if caching is enabled. Note that by default caching is disabled.
           Provide -cache_objects => 1 to the constructor in order to enable
           it.
 Example :
 Returns : An instance of the class this adaptor adapts, represented by an
           object implementing Bio::DB::PersistentObjectI, or undef if no
           matching entry was found.
 Args    : The primary key.
           Optionally, the Bio::Factory::ObjectFactoryI compliant object
           factory to be used for instantiating the proper class. If the object
           does not implement Bio::Factory::ObjectFactoryI, it is assumed to
           be the object to be populated with the query results.


=cut

sub find_by_primary_key{
    my ($self,$dbid,$fact) = @_;
    my $obj;

    # is it cached?
    $obj = $self->obj_cache($dbid);
    return $obj if defined($obj);
    # Object is not cached
    #
    # Gather the foreign key slots; we'll need that in any case.
    my @fkslots = $self->get_foreign_key_objects();
    # Prepared statement cached?
    my $cache_key = "SELECT PK ".ref($self);
    my $sth = $self->sth($cache_key);
    if(! $sth) {
	# not cached, get from driver peer
	$sth = $self->dbd()->prepare_findbypk_sth($self,\@fkslots);
	# and cache
	$self->sth($cache_key, $sth);
    }
    # bind primary key and execute
    if($self->verbose > 0) {
	$self->debug(substr(ref($self),rindex(ref($self),"::")+2).
		     ": binding PK column to \"$dbid\"\n");
    }
    if(! $sth->execute($dbid)) {
	# The subsequent exception may be caught. Remove sth from cache
	# in order not to trip up obscure driver-specific bugs.
	my $err = $sth->errstr;
	$sth->finish();
	$self->sth($cache_key, undef);
	$self->throw("error while executing statement in ".ref($self).
		     "::find_by_primary_key: ".$err);
    }
    # fetch row, instantiate and populate object
    my $rows = $sth->fetchall_arrayref();
    # any rows returned?
    if(@$rows) {
	# create (or populate) the object with what we found
	$obj = $self->_build_object(-obj => $obj,
				    -num_fks => scalar(@fkslots),
				    -row => $rows->[0],
				    -pk => $dbid,
				    -obj_factory => $fact);
	# cache the object, but don't cache if the object was not
	# instantiated inside of this method
	if((! $fact) || ($fact->isa("Bio::Factory::ObjectFactoryI"))) {
	    $self->obj_cache($dbid, $obj);
	}
    }
    # and return the result
    return $obj;
}

=head2 find_by_unique_key

 Title   : find_by_unique_key
 Usage   :
 Function: Locates the entry matching the unique key attributes as set
           in the passed object, and populates a persistent object
           with this entry.

           This method will ask get_unique_key_query() for the actual
           alternative key(s) by which to search. It can handle
           multiple alternative keys returned by
           get_unique_key_query(). So the knowledge about which
           properties of an object constitute an alternative key, and
           how to retrieve the values for those properties, is with
           get_unique_key_query() which therefore must be overridden
           by every adaptor.

           Multiple keys will be semantically ORed with short-cut
           evaluation, meaning the method will loop over all
           alternative keys and terminate the loop as soon as a match
           is found. Thus, the order of multiple keys returned by
           get_unique_key_query() does matter.

 Example :
 Returns : A Bio::DB::PersistentObjectI implementing object, with the
           attributes populated with values provided by the entry in the
           datastore, or undef if no matching entry was found. If one was
           found, the object returned will be the first argument if that
           implemented Bio::DB::PersistentObjectI already, and a new
           persistent object otherwise.
 Args    : The object with those attributes set that constitute the chosen
           unique key (note that the class of the object must be suitable for
           the adaptor).

           Additional attributes and values if required, passed as named
           parameters. Specifically noteworthy are

            -fkobjs   a reference to an array holding foreign key
                      objects if those can't be retrieved from the
                      object itself (e.g., a Comment object will need
                      the Seq object passed with this argument)

            -obj_factory the object factory to use to create new
                      objects when a matching row is found. If not
                      specified, the passed object will be populated
                      rather than creating a new object.

            -flat_only do not retrieve and attach children (objects
                       having a foreign key to the entity handled by
                       this adaptor) if value evaluates to true
                       (default: false)

=cut

sub find_by_unique_key{
    my ($self,$obj,@args) = @_;
    my $match;

    # first gather the foreign objects
    my @fkobjs = $self->get_foreign_key_objects($obj,@args);
    # get slots and their values for the most appropriate UK
    my @ukqueries = $self->get_unique_key_query($obj,\@fkobjs);
    # We need to retrieve additional parameters here in order to
    # pass them on to the wrapped method. 
    my ($fact, $flatonly) = 
        $self->_rearrange([qw(OBJ_FACTORY FLAT_ONLY)], @args);
    # now loop over all queries, and terminate once a match is found
    foreach my $ukquery (@ukqueries) {
	# is this a meaningful query?
	next unless $ukquery && %$ukquery;
	# pass on to the single-query method to do the work
	$match = $self->_find_by_unique_key($obj, $ukquery, \@fkobjs,
                                            $fact, $flatonly);
	# terminate if found
	last if $match;
    }
    # done
    return $match;
}

=head2 _find_by_unique_key

 Title   : _find_by_unique_key
 Usage   :
 Function: Locates the entry matching the unique key attributes as 
           set in the passed object, and populates a persistent
           object with this entry.

           This is the protected version of find_by_unique_key. Since
           it requires more upfront work to pass the right parameters
           in the right order, you should not call it from outside,
           but there may be situations where you want to call this
           method from a derived class.

 Example :
 Returns : A Bio::DB::PersistentObjectI implementing object, with the
           attributes populated with values provided by the entry in the
           datastore, or undef if no matching entry was found. If one was
           found, the object returned will be the first argument if that
           implemented Bio::DB::PersistentObjectI already, and a new
           persistent object otherwise.
 Args    : 

           - The object with those attributes set that constitute the
             chosen unique key (note that the class of the object must
             be suitable for the adaptor).

           - The query as an anonymous hash with keys being properties
             in the unique key. See get_unique_key_query() for a more
             detailed description on what the expected structure is.

           - A reference to an array of foreign key objects if
             applicable (undef if the entity doesn't have any foreign
             keys).

           - The object factory to use to create a new object if a
             matching row is found. Optional; if not specified the
             passed object will be populated with the found values
             rather than a new object created.

           - A flag indicating whether not to retrieve and attach
             children (objects having a foreign key to the object to
             build). Defaults to false if omitted, meaning children
             will be attached.


=cut

sub _find_by_unique_key{
    my ($self,$obj,$query_h,$fkobjs,$fact,$flatonly) = @_;

    # matching object cached? 
    my $obj_key = join("|", map { defined($_) ? $_ : ""; } %$query_h);
    my $cobj = $self->obj_cache($obj_key);
    return $cobj if $cobj;
    # no, we'll have to fetch this one
    #
    # construct key for statement cache -- we'll just use the concatenated keys
    my $cache_key = "SELECT UK ".ref($self).join(";", sort (keys %$query_h));
    # statement cached?
    my $sth = $self->sth($cache_key);
    if(! $sth) {
	# not cached, get from driver peer
	$sth = $self->dbd()->prepare_findbyuk_sth($self, $query_h, $fkobjs);
	# and cache
	$self->sth($cache_key, $sth);
    }
    # bind values in proper order
    my $i;
    if($self->verbose > 0) {
	$i = 0;
	$self->debug(join("", map {
	    substr(ref($self),rindex(ref($self),"::")+2).
	    ": binding UK column ".(++$i)." to \"".$query_h->{$_}."\" ($_)\n";
	} keys %$query_h));
    }
    my $dbd = $self->dbd();
    $i = 0;
    foreach (keys %$query_h) {
	$dbd->bind_param($sth, ++$i, $query_h->{$_});
    }
    # execute and check for error
    if(! $sth->execute()) {
	# The subsequent exception may be caught. Remove sth from cache
	# in order not to trip up obscure driver-specific bugs.
	my $err = $sth->errstr;
	$sth->finish();
	$self->sth($cache_key, undef);
	$self->throw("error while executing statement in ".ref($self).
		     "::find_by_unique_key: ".$err);
    }
    # fetch rows
    my $rows = $sth->fetchall_arrayref();
    # any rows returned?
    if(@$rows) {
	# there should be only one row since it's a unique key
	if(@$rows > 1) {
	    $self->throw("Unique key query in ".ref($self).
			 " returned ".scalar(@$rows)." rows instead of 1. ".
			 "Query was [".
			 join(",",
			      map { "$_=\"".$query_h->{$_}."\""; }
			      keys %$query_h).
			 "]");
	}
	# factory provided? If so, treat it as being forced to create
	# a new object.
	$obj = $fact->create_object() if $fact;
	# convert into a persistent object if necessary
	if(! $obj->isa("Bio::DB::PersistentObjectI")) {
	    $obj = $self->create_persistent($obj);
	}
	# populate the object with what we found
	$obj = $self->_build_object(-obj => $obj,
				    -num_fks => scalar(@$fkobjs),
				    -row => $rows->[0],
                                    -flat_only => $flatonly);
	# cache it unless it was obtained flat
	$self->obj_cache($obj_key, $obj) unless $flatonly;
	# and return the result
	return $obj;
    }
    # nothing found
    return undef;
}

=head2 find_by_association

 Title   : find_by_association
 Usage   :
 Function: Locates those records associated between a number of objects. The
           focus object (the type to be instantiated) depends on the adaptor
           class that inherited from this class.
 Example :
 Returns : A Bio::DB::Query::QueryResultI implementing object 
 Args    : Named parameters. At least the following must be recognized:
               -objs   a reference to an array of objects to be associated with
                       each other
               -contexts optional; if given it denotes a reference
                       to an array of context keys (strings), which
                       allow the foreign key name to be determined
                       through the slot-to-column map rather than through
                       foreign_key_name().  This may be necessary if
                       more than one object of the same type takes
                       part in the association. The array must be in
                       the same order as -objs, and have the same
                       number of elements. Put undef for objects
                       for which there are no multiple contexts.
               -obj_factory the factory to use for instantiating object from
                       the found rows
               -constraints  a reference to an array of additional
                       L<Bio::DB::Query::QueryConstraint> objects
               -values  the values to bind to the constraint clauses,
                       as a hash reference keyed by the constraints
  Caveats: Make sure you *always* give the objects to be associated in the
           same order.


=cut

sub find_by_association{
    my ($self,@args) = @_;
    my $i;

    # get arguments
    my ($objs,$contexts,$fact,$constr,$values) =
	$self->_rearrange([qw(OBJS CONTEXTS OBJ_FACTORY CONSTRAINTS VALUES)],
			  @args);
    # have we been called in error? If so, be graceful and return an error.
    return undef unless $objs && @$objs;
    # the schema may not necessarily support this association, check this
    if(! $self->dbd()->association_table_name($objs)) {
	return Bio::DB::Query::PrebuiltResult->new(-objs => []);
    }
    # get foreign key objects - we'll need at least their number in any case
    my @fkobjs = $self->get_foreign_key_objects();
    # construct key for cached statement
    my $cache_key = 'FIND BY ASSOC [' .
	($constr ? scalar(@$constr) : 0) .'] '.
	join(";", map {
	    ref($_) ?
		$_->isa("Bio::DB::PersistentObjectI")? ref($_->obj) : ref($_) :
		$_;
	} @$objs);
    # statement cached?
    my $sth = $self->sth($cache_key);
    if(! $sth) {
	# no, we need to prepare this one
	# first, translate the objects to entity names (in object space, not
	# relational space)
	my @objnames = map {
	    ref($_) ? ($_->isa("Bio::DB::PersistentObjectI") ?
		       ref($_->adaptor()) : ref($_)) :
		       $_;
	} @$objs;
	# pre-set aliases t<n> for the entities, and append context if it
	# is provided
	my @entities = ();
	for($i = 0; $i < @objnames; $i++) {
	    push(@entities,
		 $objnames[$i]." t".($i+1).
		 ($contexts && $contexts->[$i] ? "::".$contexts->[$i] : ""));
	}
	# add the association between the object entities
	push(@entities, join("<=>",@objnames));
	# now create a query object, and set object entities and associations
	my $query = Bio::DB::Query::BioQuery->new();
	$query->datacollections(\@entities);
	# set the primary key restrictions as far as possible (and hence
	# requested)
	my @constraints = ();
	for($i = 0; $i < @$objs; $i++) {
	    if(ref($objs->[$i]) &&
	       $objs->[$i]->isa("Bio::DB::PersistentObjectI")) {
		push(@constraints, "t".($i+1).".primary_key = ?");
	    }
	}
	push(@constraints, @$constr) if $constr;
	$query->where(\@constraints);
	# now have the driver translate this to a ready-to-execute query
	my $tquery = $self->dbd()->translate_query($self, $query, \@fkobjs);
	# obtain SQL generator
	my $sqlgen = $self->sql_generator();
	# obtain SQL statement from generator
	my $sql = $sqlgen->generate_sql($tquery);
	# prepare statement 
	$self->debug("preparing SELECT ASSOC query: $sql\n");
	$sth = $self->dbd->prepare($self->dbh(), $sql);
	# and cache for future use
	$self->sth($cache_key, $sth);
    }
    # bind columns for objects where primary key is given
    $i = 1;
    foreach my $obj (@$objs) {
	if(ref($obj) && $obj->isa("Bio::DB::PersistentObjectI")) {
	    if($self->verbose > 0) {
		$self->debug(substr(ref($self),rindex(ref($self),"::")+2).
			     ": binding ASSOC column $i to \"".
			     $obj->primary_key().
			     "\" (FK to ".ref($obj->obj()).")\n");
	    }
            # we cheat a few microseconds here by not routing the call
            # through the persistence driver, but there really shouldn't
            # be any special treatment needed for primary keys
	    $sth->bind_param($i, $obj->primary_key());
	    $i++;
	}
    }
    # bind values for additional constraints if any
    foreach my $constraint ($constr ? @$constr : ()) {
	if($self->verbose > 0) {
	    $self->debug(substr(ref($self),rindex(ref($self),"::")+2).
			 ": binding ASSOC column $i to \"".
			 $values->{$constraint}.
			 "\" (constraint ".$constraint->name.")\n");
	}
	$self->dbd->bind_param($sth, $i, $values->{$constraint});
	$i++;
    }
    # execute
    if(! $sth->execute()) {
	# The subsequent exception may be caught. Remove sth from cache
	# in order not to trip up obscure driver-specific bugs.
	my $err = $sth->errstr;
	$sth->finish();
	$self->sth($cache_key, undef);
	$self->throw("error while executing statement in ".ref($self).
		     "::find_by_association: ".$err);
    }
    # construct query result object
    my $qres = Bio::DB::Query::DBQueryResult->new(-sth => $sth,
						  -adaptor => $self,
						  -factory => $fact,
						  -num_fks => scalar(@fkobjs));
    # that's it -- return the result object
    return $qres;
}

=head2 find_by_query

 Title   : find_by_query
 Usage   :
 Function: Locates entries that match a particular query and returns
           the result as an array of peristent objects.

           The query is represented by an instance of
           Bio::DB::Query::AbstractQuery or a derived class. Note that
           SELECT fields will be ignored and auto-determined. Give
           tables in the query as objects, class names, or adaptor
           names, and columns as slot names or foreign key class names
           in order to be maximally independent of the exact
           underlying schema. The driver of this adaptor will
           translate the query into tables and column names.

 Example :
 Returns : A Bio::DB::Query::QueryResultI implementing object
 Args    : The query as a Bio::DB::Query::AbstractQuery or derived
           instance.  Note that the SELECT fields of that query object
           will inadvertantly be overwritten.

           Optionally additional (named) parameters. Recognized
           parameters at this time are

              -fkobjs    a reference to an array of foreign key
                         objects that are not retrievable from the
                         persistent object itself

              -obj_factory  the object factory to use for creating
                         objects for resulting rows

              -name      a unique name for the query, which will make
                         the statement be a cached prepared
                         statement, which in subsequent invocations
                         will only be re-bound with parameters values,
                         but not recreated

              -values    a reference to an array holding the values
                         to be bound, if the query is a named query

              -flat_only do not retrieve and attach children (objects
                         having a foreign key to the entity handled by
                         this adaptor) if value evaluates to true
                         (default: false)

=cut

sub find_by_query{
    my ($self,$query,@args) = @_;
    my $sth;

    # get arguments
    my ($fkargs,$fact,$qname,$qvalues,$flatonly) =
	$self->_rearrange([qw(FKOBJS OBJ_FACTORY NAME VALUES FLAT_ONLY)], 
                          @args);
    $fkargs = [] unless $fkargs;
    # first gather the foreign objects
    my @fkobjs = $self->get_foreign_key_objects(@$fkargs);
    # if it is a named query, we check the cache
    $sth = $self->sth($qname) if $qname;
    # the query might be known but disabled because it is unsupported by the
    # underlying schema
    if($sth && ($sth eq "DISABLED")) {
    	return Bio::DB::Query::PrebuiltResult->new(-objs => []);
    } elsif(! $sth) { # not in cache or not a named query
	# translate query object from objects and slots to tables and columns
	$query = $self->dbd()->translate_query($self, $query, \@fkobjs);
	# obtain SQL generator
	my $sqlgen = $self->sql_generator();
	# obtain SQL statement from generator
	my $sql = $sqlgen->generate_sql($query);
	# prepare
	$self->debug("preparing query: $sql\n");
	if($sth = $self->dbd->prepare($self->dbh(), $sql)) {
	    # cache if named query
	    $self->sth($qname, $sth) if $qname;
	} else {
	    # This is most likely due to an unsupported query. Some
	    # drivers, e.g., Oracle, do check whether column names and
	    # table names exist. So we'll disable this query.
	    $self->sth($qname, "DISABLED") if $qname;
	    return Bio::DB::Query::PrebuiltResult->new(-objs => []);
	}
    }
    # bind parameter values if any and if a named query
    if($qname && $qvalues && @$qvalues) {
        my $dbd = $self->dbd();
	for(my $i = 1; $i <= @$qvalues; $i++) {
	    $self->debug("Query $qname: binding column $i to \"".
			 $qvalues->[$i-1]."\"\n");
	    # We generally don't want to raise an exception.
	    my $rv;
	    eval { $rv = $dbd->bind_param($sth, $i, $qvalues->[$i-1]); };
	    if(! $rv) {
		# This is either due to an internal bug or to a constraint
		# column not supported by the underlying schema (i.e., mapped
		# to undef). While the first case warrants an exception, the
		# latter is perfectly legal and should go as unnoticed as
		# possible. We'll return an empty set and disable the query
		# for future use.
		$sth->finish();
		$self->sth($qname, "DISABLED") if $qname;
		return Bio::DB::Query::PrebuiltResult->new(-objs => []);
	    }
	}
    }
    # ready to execute
    if(! $sth->execute()) {
	# The subsequent exception may be caught. Remove sth from cache
	# in order not to trip up obscure driver-specific bugs.
	my $err = $sth->errstr;
	$sth->finish();
	$self->sth($qname, undef) if $qname;
	$self->throw("error while executing query ".
		     ($qname ? "$qname " : "") . "in ".ref($self).
		     "::find_by_query: ".$err);
    }
    # construct query result object
    my $qres = Bio::DB::Query::DBQueryResult->new(-sth => $sth,
						  -adaptor => $self,
						  -factory => $fact,
						  -num_fks => scalar(@fkobjs),
                                                  -flat_only => $flatonly);
    # that's it -- return the result object
    return $qres;
}

=head2 _build_object

 Title   : _build_object
 Usage   :
 Function: Build and populate an object or populate a prepuilt object from
           a row from the database.

           This is a private method primarily to centralize the code
           for this task from the various find_by_XXXX methods. Don't
           call from outside unless you know what you're doing.

 Example :
 Returns : A persistent object (implements Bio::DB::PersistentObjectI)
 Args    : Named parameters. Currently supported are:
             -obj       A prebuilt object to be populated only (optional)
             -row       a reference to an array of column values (mandatory)
             -pk        the primary key to be associated with the new object
                        (optional)
             -num_fks   the number of foreign key instances which need
                        to be associated with the object to be built
                        (optional, defaults to 0)
             -obj_factory an object factory to be used for instantiating
                        the object if it needs to be created
             -flat_only do not retrieve and attach children (objects
                        having a foreign key to the object to build)
                        if value evaluates to true (default: false)

=cut

sub _build_object{
    my ($self,@args) = @_;

    # get arguments
    my ($obj,$row,$fact,$pk,$numfks,$flatonly) =
	$self->_rearrange([qw(OBJ 
                              ROW 
                              OBJ_FACTORY 
                              PK 
                              NUM_FKS
                              FLAT_ONLY)], 
                          @args);
    
    # build the object, or just populate it if it's been prebuilt
    if(ref($obj)) {
	$obj = $self->populate_from_row($obj, $row);
    } else {
	$obj = $self->instantiate_from_row($row, $fact);
    }
    # convert into a persistent object if necessary, otherwise make sure
    # the adaptor is set
    if($obj->isa("Bio::DB::PersistentObjectI")) {
	$obj->adaptor($self) unless $obj->adaptor();
    } else {
	$obj = $self->create_persistent($obj);
    }
    # make sure the primary key is stored (usually populate_from_row() should
    # have done this already)
    if(! $obj->primary_key()) {
	$obj->primary_key($pk || $row->[0]);
    }
    # attach foreign key objects (those that this entity references by
    # foreign key)
    if($numfks) {
	# copy the row to avoid possibly messing with DBIs internals
	my @cols = @$row;
	# remove all except the foreign key columns from the row
	splice(@cols, 0, @cols-$numfks);
	if(! $self->attach_foreign_key_objects($obj, \@cols)) {
	    $self->warn("failed to attach all foreign key objects (pk=".
			$obj->primary_key().")");
	}
    }
    # attach child objects (those that reference this entity as foreign
    # key)
    if (! $flatonly) {
        if(! $self->attach_children($obj)) {
            $self->warn("failed to attach all child objects (pk=".
                        $obj->primary_key().")");
        }
    }
    # mark it as clean - it's fresh from the press
    $obj->is_dirty(0);
    # done
    return $obj;
}

=head1 Transaction control methods

This comprises of rollback and commit. The point to have those here
even though they merely delegate to the driver is that the caller
doesn't need to distinguish whether the RDBMS driver supports
transactions or not. If the DBI driver doesn't then simply the adaptor
driver won't do anything.

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
    my $self = shift;
    return $self->dbd->commit($self->dbh, @_);
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
    my $self = shift;
    return $self->dbd->rollback($self->dbh, @_);
}

=head1 Database Context and Adaptor Driver

These are published attributes for convenient perusal by derived
adaptors.

=cut

=head2 dbcontext

 Title   : dbcontext
 Usage   : $obj->dbcontext($newval)
 Function: Get/set the DBContextI object representing the physical database.
 Example : 
 Returns : A Bio::DB::DBContextI implementing object
 Args    : on set, the new Bio::DB::DBContextI implementing object


=cut

sub dbcontext{
    my ($self,$value) = @_;

    if( defined $value) {
	$self->{'dbcontext'} = $value;
    }
    return $self->{'dbcontext'};
}

=head2 dbh

 Title   : dbh
 Usage   : $obj->dbh($newval)
 Function: Get/set the DBI connection handle.

           If you set this from outside, you should know exactly what
           you are doing. 

 Example : 
 Returns : value of dbh (a database handle)
 Args    : on set, the new value (a database handle, optional)


=cut

sub dbh{
    my ($self,$dbh) = @_;

    if( defined $dbh) {
	my @objlstnrs = ();
	if($self->{'_dbh'}) {
	    $self->finish();
	    # remove ourselves and all objects that use us as adaptor
	    # from the list of transaction listeners for this connection
	    my $tx =
		Bio::DB::DBI::Transaction->get_Transaction($self->{'_dbh'});
	    @objlstnrs = $tx->remove_TransactionListeners();
	    my @lstnrs = grep {
		($_ != $self) &&
		(! ($_->isa("Bio::DB::PersistentObjectI") &&
		    $_->adaptor() == $self));
	    } @objlstnrs;
	    # retain those objects that use us for listening to the 
	    # new connection
	    @objlstnrs = grep {
		($_->isa("Bio::DB::PersistentObjectI") &&
		 $_->adaptor() == $self);
	    } @objlstnrs;
	    $tx->add_TransactionListener(@lstnrs);
	}
	$self->{'_dbh'} = $dbh;
	my $tx = Bio::DB::DBI::Transaction->get_Transaction($dbh);
	$tx->add_TransactionListener(@objlstnrs);
    } elsif(! exists($self->{'_dbh'})) {
	# obtain a new connection automatically if one is requested and none
	# has been set
	# note that the way we obtain it allows for this being a shared
	# connection
	my $dbc = $self->dbcontext();
	$dbh = $dbc->dbi()->get_connection($dbc,
					   $dbc->dbi()->conn_params($self));
	$self->{'_dbh'} = $dbh;
	my $tx = Bio::DB::DBI::Transaction->get_Transaction($dbh);
	$tx->add_TransactionListener($self);
    }
    return $self->{'_dbh'};
}

=head2 dbd

 Title   : dbd
 Usage   : $obj->dbd($newval)
 Function: Get/set the driver for this adaptor.

           The driver will usually be an instance of a class derived
           from L<Bio::DB::BioSQL::BaseDriver>. It will usually also
           have to implement L<Bio::DB::Persistent::ObjectRelMapperI>.

           If you set this from outside, you should know exactly what
           you are doing. If the value is requested in get-mode but no
           value has been set yet, the driver will be auto-loaded. Most
           if not all of the adaptors will in fact use this
           auto-loading feature.

 Example : 
 Returns : value of dbd (a scalar)
 Args    : new value (a scalar, optional)


=cut

sub dbd{
    my ($self,$dbd) = @_;

    if( defined $dbd) {
	$self->{'_dbd'} = $dbd;
    } elsif(! exists($self->{'_dbd'})) {
	# dynamically load the driver and instantiate it if not provided yet
	my $dbc = $self->dbcontext();
	my $adpdriver = $self->_get_driver_class("Bio::DB::BioSQL::" .
						 $dbc->driver() . "::",
						 "Driver",
						 ref($self));
	$self->debug("Using $adpdriver as driver peer for ".ref($self)."\n");
	$self->{'_dbd'} = $adpdriver->new(-adaptor => $self,
                                          -verbose => $self->verbose());
    }
    return $self->{'_dbd'};
}

sub _get_driver_class{
    my ($self,$prefix,$suffix,$class) = @_;
    my $driver;

    # build driver class name
    $driver = $class;
    $driver =~ s/.*://;
    $driver = $prefix . $driver . $suffix;
    # can we load the driver directly?
    $self->debug("attempting to load driver for adaptor class $class\n");
    eval {
	$self->_load_module($driver);
    };
    # return if success
    return $driver if(! $@);
    #
    # otherwise recursively and depth-first traverse inheritance tree
    #
    # we need to bring in this class here in order to have access to @ISA.
    eval {
	$self->_load_module($class);
    };
    if($@) {
	$self->throw("weird: cannot load class $class : ".$@);
    }
    my $aryname = "${class}::ISA"; # this is a soft reference
    # hence, allow soft refs
    no strict "refs";
    my @ancestors = @$aryname;
    # and disallow again
    use strict "refs";
    # loop over all ancestors; this is depth first traversal
    $driver = undef;
    foreach my $ancestor (@ancestors) {
	eval {
	    $driver = $self->_get_driver_class($prefix, $suffix, $ancestor);
	};
	last if(! $@);
    }
    return $driver if $driver;
    $self->throw("failed to load adaptor driver for class $class ".
		 "as well as parents ". join(", ", @ancestors));
}

=head2 db

 Title   : db
 Usage   : $dbadaptor = $obj->db()
 Function: This is just shorthand for $obj->dbcontext()->dbadaptor().
 Example : 
 Returns : value of db (a Bio::DB::DBAdaptorI implementing object)
 Args    : none


=cut

sub db{
    return shift->dbcontext()->dbadaptor();
}

=head2 sth

 Title   : sth
 Usage   : $obj->sth($key, $prepared_sth)
 Function: caches prepared statements
 Example : 
 Returns : a DBI statement handle cached under the key, or all statement
           handles in the cache if no key is supplied
 Args    : the key for the cached prepared statement handle, and optionally
           on set the new statement handle to be cached, or undef to
           remove the handle from the cache


=cut

sub sth{
    my $self = shift;
    my $key = shift;

    $self->{'_sth'} = {} if ! exists($self->{'_sth'});
    return $self->{'_sth'}->{$key} = shift if @_;
    return $self->{'_sth'}->{$key} if $key;
    return values %{$self->{'_sth'}};
}

=head2 sql_generator

 Title   : sql_generator
 Usage   : $obj->sql_generator($newval)
 Function: Get/set the SQL generator object to use for turning query objects
           into SQL statements.
 Example : 
 Returns : value of sql_generator (an instance of Bio::DB::Query::SqlGenerator
           or a derived object)
 Args    : new value (an instance of Bio::DB::Query::SqlGenerator
           or a derived object, optional)


=cut

sub sql_generator{
    my ($self,$value) = @_;
    if( defined $value) {
	$self->{'sql_generator'} = $value;
    } elsif(! exists($self->{'sql_generator'})) {
	$self->{'sql_generator'} = Bio::DB::Query::SqlGenerator->new();
    }
    return $self->{'sql_generator'};
}

=head2 caching_mode

 Title   : caching_mode
 Usage   : $obj->caching_mode($newval)
 Function: Get/set whether objects are cached for find_by_primary_key()
           and find_by_unique_key().

           See obj_cache() for documentation on how to use the object cache.

           If you disable caching through this method, the entire
           cache will be flushed as a side effect.

 Example : 
 Returns : TRUE if caching of objects is enabled and FALSE otherwise
 Args    : new value (a scalar, optional)


=cut

sub caching_mode{
    my ($self,$value) = @_;

    if(defined $value) {
	if($value && (! exists($self->{'_obj_cache'}))) {
	    $self->{'_obj_cache'} = {};
	} elsif(! $value) {
	    delete $self->{'_obj_cache'};
	}
    }
    return $self->{'_obj_cache'} ? 1 : 0;
}

=head2 obj_cache

 Title   : obj_cache
 Usage   :
 Function: Implements a simple cache of objects by key. Often, this will be
           used by derived classes to cache singletons, if there is only a
           limited number of certain base objects, like Species, or
           Ontology_Term.

           A derived adaptor may want to override this method to cache only
           selectively. The constructor of this class turns off caching by
           default; supply -cache_objects => 1 in order to turn it on, or
           call $adp->caching_mode(1).

 Example :
 Returns : The object cached under the key, or undef if there is no such key
 Args    : The key under which to cache the object.
           Optionally, on set the object to be cached. Pass undef to
           un-cache an object stored under the key.


=cut

sub obj_cache{
    my $self = shift;
    my $key = shift;
    my ($obj) = @_;

    return $obj unless $self->{'_obj_cache'}; # caching may be disabled
    return $self->{'_obj_cache'}->{$key} = $obj if @_;
    return $self->{'_obj_cache'}->{$key};
}

sub _remove_from_obj_cache{
    my ($self, $obj) = @_;

    return unless $self->{'_obj_cache'}; # caching may be disabled

    my ($key, $val);
    my @delkeys = ();

    while(($key, $val) = each %{$self->{'_obj_cache'}}) {
	next unless ref($val);
	push(@delkeys, $key) if $val->primary_key() == $obj->primary_key();
    }
    foreach (@delkeys) {
	delete $self->{'_obj_cache'}->{$_};
    }
}

=head2 crc64

 Title   : crc64
 Usage   :
 Function: Computes and returns the CRC64 checksum for a given string.

           This method may be called as a static method too as it
           doesn't not make any references to instance
           properties. However, it isn't really meant for outside
           consumption, but rather for derived classes as a utility
           method. At present, in fact this module itself doesn't use
           it.

           This is basically ripped out of the bioperl swissprot
           parser. Credits go to whoever contributed it there.

 Example :
 Returns : the CRC64 checksum as a string
 Args    : the string as a scalar for which to obtain the CRC64


=cut

sub crc64{
    my ($self, $str) = @_;
    my $POLY64REVh = 0xd8000000;
    my @CRCTableh;
    my @CRCTablel;
    
    if (exists($self->{'_CRCtableh'})) {
	@CRCTableh = @{$self->{'_CRCtableh'}};
	@CRCTablel = @{$self->{'_CRCtablel'}};
    } else {
	@CRCTableh = 256;
	@CRCTablel = 256;
	for (my $i=0; $i<256; $i++) {
	    my $partl = $i;
	    my $parth = 0;
	    for (my $j=0; $j<8; $j++) {
		my $rflag = $partl & 1;
		$partl >>= 1;
		$partl |= (1 << 31) if $parth & 1;
		$parth >>= 1;
		$parth ^= $POLY64REVh if $rflag;
	    }
	    $CRCTableh[$i] = $parth;
	    $CRCTablel[$i] = $partl;
	}
	$self->{'_CRCtableh'} = \@CRCTableh;
	$self->{'_CRCtablel'} = \@CRCTablel;
    }

    my $crcl = 0;
    my $crch = 0;

    foreach (split '', $str) {
	my $shr = ($crch & 0xFF) << 24;
	my $temp1h = $crch >> 8;
	my $temp1l = ($crcl >> 8) | $shr;
	my $tableindex = ($crcl ^ (unpack "C", $_)) & 0xFF;
	$crch = $temp1h ^ $CRCTableh[$tableindex];
	$crcl = $temp1l ^ $CRCTablel[$tableindex];
    }
    my $crc64 = sprintf("%08X%08X", $crch, $crcl);
        
    return $crc64;
      
}

=head1 Object Lifespan-related methods

=cut

=head2 finish

 Title   : finish
 Usage   : $objectadp->finish()
 Function: Finishes the resources used by this object. Note that this will
           not disconnect the database handle, but it will remove the reference
           to it.

           This behaviour is needed because the connection handle may be shared
           between multiple objects.

           Note that given the implementation here you may continue to use the
           adaptor after calling this method, since a new db handle will be
           obtained automatically if needed, and objects removed from the cache
           will be rebuilt.

           Basically, this method will reset the object cache if any and finish
           all cached statement handles and reset the statement handle cache.

           Note that this method will not throw an exception even if finishing
           the resources causes an error. It will issue a warning though, and
           if verbose() >= 1 warnings become exceptions.
 Example :
 Returns : none
 Args    : none


=cut

sub finish{
    my ($self) = @_;
    
    if($self->{'_dbh'}) {
	# finish all statement handles
	foreach my $sth ($self->sth()) {
	    next unless ref($sth); # some statements may be disabled
	    eval {
		$sth->finish();
	    };
	    $self->warn("error while closing statement handle: " . $@) if($@);
	}
	# remove the reference to the database handle
	$self->{'_dbh'} = undef;
    }
    # reset the cache of statement handles
    delete $self->{'_sth'};
    # reset the object cache if any
    delete $self->{'_obj_cache'} if $self->{'_obj_cache'};
    # done
}

=head2 DESTROY

 Title   : DESTROY
 Usage   :
 Function: We override this here to call finish().
 Example :
 Returns : 
 Args    :


=cut

sub DESTROY {
    my ($self) = @_;
    
    $self->finish();
    $self->SUPER::DESTROY();
}

=head1 Abstract Methods

    Almost all of the following methods MUST be overridden by a
    derived class.  For some methods there is an implementation here
    that assumes "no action" is the right thing, but for many adaptors
    this won't be right. There is no way this base implementation can
    make any meaningful guesses at the correct values for those.

=cut

=head2 get_persistent_slots

 Title   : get_persistent_slots
 Usage   :
 Function: Get the slots of the object that map to attributes in its
           respective entity in the datastore.

           Slot name generally refers to a method name, but is not
           required to do so, since determining the values is under
           the control of get_persistent_slot_values().

           This is a strictly abstract method. A derived class MUST
           override it to return something meaningful.

 Example :
 Returns : an array of method names constituting the serializable slots
 Args    : the object about to be inserted or updated


=cut

sub get_persistent_slots{
    shift->throw_not_implemented();
}

=head2 get_persistent_slot_values

 Title   : get_persistent_slot_values
 Usage   :
 Function: Obtain the values for the slots returned by get_persistent_slots(),
           in exactly that order.

           The reason this method is here is that sometimes the actual
           slot values need to be post-processed to yield the value
           that gets actually stored in the database. E.g., slots
           holding arrays will need some kind of join function
           applied. Another example is if the method call needs
           additional arguments. Supposedly the adaptor for a specific
           interface knows exactly what to do here.

           Since there is also populate_from_row() the adaptor has
           full control over mapping values to a version that is
           actually stored.

           This is a strictly abstract method and it MUST be
           overridden by a derived class.

 Example :
 Returns : A reference to an array of values for the persistent slots of this
           object. Individual values may be undef.
 Args    : The object about to be serialized.
           A reference to an array of foreign key objects if not retrievable 
           from the object itself.


=cut

sub get_persistent_slot_values {
    my ($self,@args) = @_;

    $self->throw_not_implemented();
}

=head2 get_foreign_key_objects

 Title   : get_foreign_key_objects
 Usage   :
 Function: Gets the objects referenced by this object, and which therefore need
           to be referenced as foreign keys in the datastore.

           Note that the objects are expected to implement
           Bio::DB::PersistentObjectI.

           An implementation may obtain the values either through the object
           to be serialized, or through the additional arguments. An
           implementation should also make sure that the order of foreign key
           objects returned is always the same.

           Note also that in order to indicate a NULL value for a nullable
           foreign key, either put an object returning undef from 
           primary_key(), or put the name of the class instead. DO NOT SIMPLY
           LEAVE IT OUT.

           This implementation assumes a default of no foreign keys and returns
           an empty array.
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
    return ();
}

=head2 attach_foreign_key_objects

 Title   : attach_foreign_key_objects
 Usage   :
 Function: Attaches foreign key objects to the given object as far as
           necessary.

           This method is called after find_by_XXX() queries, not for INSERTs
           or UPDATEs.

           This implementation assumes there are no foreign keys that need to
           be retrieved and instantiated. You MUST override this method
           in order to have foreign key objects taken care of upon SELECTs.
 Example :
 Returns : TRUE on success, and FALSE otherwise.
 Args    : The object to which to attach foreign key objects.
           A reference to an array of foreign key values, in the order of
           foreign keys returned by get_foreign_key_objects().


=cut

sub attach_foreign_key_objects{
    my ($self,$obj,$fks) = @_;
    
    if($fks && @$fks) {
	$self->warn("Foreign key values present in adaptor ".ref($self).". ".
		    "Did you forget to override attach_foreign_key_objects?");
    }
    return 1;
}

=head2 store_children

 Title   : store_children
 Usage   :
 Function: Inserts or updates the child entities of the given object in the 
           datastore.

           Usually, those child objects will reference the given object as
           a foreign key. 

           The implementation can assume that all of the child objects
           are already Bio::DB::PersistentObjectI.

           While obtaining and looping over all child objects could have been
           implemented as a generic business logic method, supplying the right
           foreign key objects is hard to accomplish in a generic fashion.

           The implementation here assumes there are no children and hence
           just returns TRUE. You MUST override it in order to have any
           children taken care of.
 Example :
 Returns : TRUE on success, and FALSE otherwise
 Args    : The Bio::DB::PersistentObjectI implementing object for which the
           child objects shall be made persistent.
           A reference to an array of foreign key values, in the order of
           foreign keys returned by get_foreign_key_objects().


=cut

sub store_children{
    return 1;
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

           This implementation will do nothing unless it is overridden. Whether
           to override it or not will depend on which of the children shall be
           loaded instantly instead of lazily.
 Example :
 Returns : TRUE on success, and FALSE otherwise.
 Args    : The object for which to find and to which to attach the child
           objects.


=cut

sub attach_children{
    return 1;
}

=head2 remove_children

 Title   : remove_children
 Usage   :
 Function: This method is to cascade deletes in maintained objects.

           Child records in the database will usually be cascaded by
           the RDBMS. In order to cascade removals to persistent child
           objects, you must override this method. Usually you will
           need to undefine the primary key of child objects, and
           possibly remove them from caches if they are cached.

           Because failure to do so may result in serious and often
           non-obvious bugs, there is no default provided here. You
           *must* override this method in a derived adaptor as
           evidence that you know what you are doing, even if all you
           do is just return TRUE.

 Example :
 Returns : TRUE on success and FALSE otherwise
 Args    : The persistent object that was just removed from the database.
           Additional (named) parameter, as passed to remove().


=cut

sub remove_children{
    shift->throw_not_implemented();
}

=head2 instantiate_from_row

 Title   : instantiate_from_row
 Usage   :
 Function: Instantiates the class this object is an adaptor for, and populates
           it with values from columns of the row.

           Usually a derived class will instantiate the proper class and pass
           it on to populate_from_row().

           This implementation assumes that the object factory is provided,
           uses it to instantiate a new object, and then passes on to
           populate_from_row(). If this is not appropriate the method must be
           overridden by a derived object.
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
	if(! $fact) {
	    $self->throw("No object factory provided. Override this method ".
			 "in ".ref($self).
			 " if you know a good default way to go.");
	}
	$obj = $fact->create_object();
	$self->populate_from_row($obj, $row);
    }
    return $obj;
}

=head2 populate_from_row

 Title   : populate_from_row
 Usage   :
 Function: Populates the given object with values from columns of the row.

           This method is strictly abstract and MUST be overridden by a
           derived object.
 Example :
 Returns : The object populated, or undef, if the row contains no values
 Args    : The object to be populated.
           A reference to an array of column values. The first column is the
           primary key, the other columns are expected to be in the order 
           returned by get_persistent_slots().


=cut

sub populate_from_row{
    my ($self,@args) = @_;

    $self->throw_not_implemented();
}

=head2 get_unique_key_query

 Title   : get_unique_key_query
 Usage   :
 Function: Obtain the suitable unique key slots and values as
           determined by the attribute values of the given object and
           the additional foreign key objects, in case foreign keys
           participate in a UK.

           This method embodies the knowledge about which properties
           constitute the alternative keys for an object (entity) and
           how to obtain the values of those properties from the
           object. Therefore, unless there is no alternative key for
           an entity, the respective (derived) adaptor must override
           this method.

           If there are multiple alternative keys for an entity, the
           overriding implementation may choose to determine at
           runtime the best alternative key given the object and then
           return only a single alternative key, or it may choose to
           return an array of (supposedly equally suitable)
           alternative keys. Note that if every alternative key
           returned will be searched for until a match is found
           (short-cut evaluation), so returning partially populated
           alternative keys is usually not wise.

           This implementation assumes there are no unique keys
           defined for the entity adapted by this class and hence
           returns an empty hash ref. Instead of overriding this
           method a derived class may choose to override
           find_by_unique_key() instead, as that one calls this
           method.

           See the documentation of find_by_unique_key() for further
           information on what the return value is used for and what
           the implications are.

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
    return {};
}

1;
