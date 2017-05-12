# $Id$
#
# BioPerl module for Bio::DB::Persistent::PersistentObject
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

Bio::DB::Persistent::PersistentObject - makes a given object persistent

=head1 SYNOPSIS

    # obtain a PersistentObject somehow, e.g.
    $pobj = $dbadaptor->create_persistent("Bio::Seq");

    # manipulate and query as if it were the wrapped object itself
    print $pobj->isa("Bio::PrimarySeqI"), "\n";
    $pobj->display_id("O238356");
    $pobj->seq("ATCATCGACTGACAGGCAGTATCGACTAGCA");
    $fea = Bio::SeqFeature::Generic->new(-start => 3, -end => 15);
    $fea->attach_seq($pobj);
    # and so on and so forth

    # and, finally, or whenever suitable, make it persistent in the datastore
    $pobj->create();
    # change it
    $pobj->desc("not a useful description");
    # and update it in the datastore
    $pobj->store();

    # you may also want it to disappear
    $pobj->remove();

=head1 DESCRIPTION

This class takes any Bioperl object for which an adaptor exists for a certain
datastore and makes it implement Bio::DB::PersistentObjectI.

There is one single caveat though. The wrapped object must not use any of the
method names defined in Bio::DB::PersistentObjectI, nor obj() or adaptor().
If it does, calls of these methods will never get routed to the wrapped object.

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


package Bio::DB::Persistent::PersistentObject;
use vars qw(@ISA);
use strict;
use Scalar::Util qw(refaddr);

# Object preamble - inherits from Bio::Root::Root

use Bio::Root::Root;
use Bio::DB::PersistentObjectI;

@ISA = qw(Bio::Root::Root Bio::DB::PersistentObjectI);

our $AUTOLOAD;
our %wrapper_class_map = ();

=head2 new

 Title   : new
 Usage   : my $obj = Bio::DB::Persistent::PersistentObject->new();
 Function: Builds a new Bio::DB::Persistent::PersistentObject object 
 Returns : an instance of Bio::DB::Persistent::PersistentObject
 Args    : -object => $obj_to_be_wrapped (mandatory)
           -adaptor => $adaptor_for_obj (optional, may be set later)


=cut

sub new {
    my ($class,@args) = @_;

    $class = ref($class) if ref($class);

    my %params = @args;
    # obtain object to be wrapped and adaptor for datastore
    my $obj = $params{'-object'};
    $obj = $params{'-OBJECT'} unless defined($obj);

    # if this package then try to load a specialized wrapper if one available
    if(defined($obj) && $class eq "Bio::DB::Persistent::PersistentObject") {
	my $wclass = $class->_load_persistence_wrapper(ref($obj) || $obj,
						      "Bio::DB::Persistent::");
	return $wclass->new(@args) if $wclass;
    }
    # else instantiate here
    my $self = $class->SUPER::new(@args);
    # obtain adaptor for datastore
    my $adp = $params{'-adaptor'} || $params{'-ADAPTOR'};

    $self->obj($obj) if defined($obj);
    $self->adaptor($adp) if defined($adp);
    $self->is_dirty(1);

    # success - we hope
    return $self;
}

sub _load_persistence_wrapper{
    my ($self,$class,$prefix,$suffix) = @_;
    my $pmod;

    $prefix = "" unless defined($prefix);
    $suffix = "" unless defined($suffix);

    # if not yet attempted to load the appropriate module
    if(! exists($wrapper_class_map{$class})) {
	# build persistence module name
	$pmod = $class;
	$pmod =~ s/.*://; # keep only first component
	my @mods = ($pmod);
	# try with and without capital I (interface)
	if($pmod =~ s/^(.*)I$/$1/) {
	    push(@mods,$pmod);
	}
	foreach $pmod (map { $prefix . $_ . $suffix; } @mods) {
	    $self->debug("attempting to load class $pmod\n");
	    #print STDERR "attempting to load class $pmod\n";
	    eval {
		$self->_load_module($pmod);
	    };
	    # mark success if success
	    if(! $@) {
		$wrapper_class_map{$class} = $pmod;
		last;
	    }
	}
    }
    # return if success (now or previously)
    return $wrapper_class_map{$class} if exists($wrapper_class_map{$class});
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
    $pmod = undef;
    foreach my $ancestor (@ancestors) {
	$pmod = $self->_load_persistence_wrapper($ancestor,
						 $prefix, $suffix);
	last if $pmod;
    }
    $wrapper_class_map{$class} = $pmod; # may be undef and hence mark failure
    # we don't throw an exception here -- not finding a class is perfectly
    # legal
    return $pmod;
}

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
   
    my $adp = $self->adaptor();
    $self->throw("unable to carry out database operation without an adaptor")
	unless $adp;
    my $obj = $adp->create($self, @args);
    $self->is_dirty(-1) if $obj && $obj->primary_key();
    return $obj;
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

    my $adp = $self->adaptor();
    $self->throw("unable to carry out database operation without an adaptor")
	unless $adp;
    my $rv = 1;
    $rv = $adp->store($self, @args);
    $self->is_dirty(-1) if $rv;
    return $rv;
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

    my $adp = $self->adaptor();
    $self->throw("unable to carry out database operation without an adaptor")
	unless $adp;
    return $adp->remove($self, @args);
}

=head2 primary_key

 Title   : primary_key
 Usage   : $obj->primary_key($newval)
 Function: Get the primary key of the persistent object in the datastore.

           Note that this implementation does not permit changing the
           primary key once it has been set. This is for sanity
           reasons, and may or may not be relaxed in the future. The
           only exception is changing it to undef.

 Example : 
 Returns : value of primary_key (a scalar)
 Args    : new value (a scalar, optional)


=cut

sub primary_key{
    my ($self,$value) = @_;

    if((scalar(@_) == 2) && (! $value)) {
	delete $self->{"_pk"};
    } elsif($value) {
	if(exists($self->{'_pk'}) && ($self->{'_pk'} != $value)) {
	    $self->throw("must not change primary_key() once it is set");
	}
	$self->{"_pk"} = $value;
    }
    return $self->{"_pk"};
}

=head2 obj

 Title   : obj
 Usage   : $obj->obj()
 Function: Get/set the object that is made persistent through this adaptor.

           Note that this implementation does not allow to change the
           value once it has been set. This is for sanity reasons, and
           may or may not be relaxed in the future.

 Example : 
 Returns : The object made persistent through this adaptor
 Args    : On set, the new value. Read above for caveat.


=cut

sub obj{
    my $self = shift;
    my $obj = $self->{"_obj"};

    if (@_) {
        $obj = shift;
	if (exists($self->{'_obj'})
            && (refaddr($obj) != refaddr($self->{'_obj'}))) {
	    $self->throw("must not change obj() once it is set");
	}
	$self->{"_obj"} = $obj;
    }
    # we must have the object to be wrapped
    $self->throw("you must set the object to be wrapped before using it")
	unless ref($obj);
    return $obj;
}

=head2 adaptor

 Title   : adaptor
 Usage   : $obj->adaptor($newval)
 Function: Get/set of the PersistenceAdaptorI compliant object that actually
           implements persistence for this object
 Example : 
 Returns : A Bio::DB::PersistenceAdaptorI compliant object
 Args    : Optionally, on set a Bio::DB::PersistenceAdaptorI compliant object


=cut

sub adaptor{
    my $self = shift;

    return $self->{'_adaptor'} = shift if @_;
    return $self->{'_adaptor'};
}

=head2 is_dirty

 Title   : is_dirty
 Usage   : $obj->is_dirty($newval)
 Function: Get/set whether this persistent object is to be considered
           dirty.

           An object is considered dirty if one or more of it's
           properties has been altered since it was last obtained
           from, stored in, or created in the database, or if the
           create() (insert) or the last store() (update) hasn't been
           committed or rolled back yet.

           There are currently 3 known states of this attribute. A
           value of zero (or false) means the object has not been
           modified since it either came from the database, or since
           the changes have been serialized (via store()) and
           committed (via commit()). A negative value means changes
           have been serialized, but not yet committed. A positive
           value means there have been unserialized changes on the
           object.

 Example : 
 Returns : value of is_dirty (a scalar)
 Args    : on set, new value (a scalar or undef, optional)


=cut

sub is_dirty{
    my $self = shift;

    return $self->{'is_dirty'} = shift if @_;
    return $self->{'is_dirty'};
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
    my $self = shift;

    my $rv = $self->adaptor->commit(@_);
    $self->is_dirty(0) if ($self->is_dirty() < 0) && $rv;
    return $rv;
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

    my $rv = $self->adaptor->rollback(@_);
    $self->is_dirty(1) if ($self->is_dirty() < 0) && $rv;
    return $rv;
}

=head1 Methods to mimic the wrapped object

=cut

=head2 isa

 Title   : isa
 Usage   :
 Function: This is a standard perl object method. We override it here in order
           to generically claim we implement everything that the wrapped
           object does.
 Example :
 Returns : TRUE if this object is an instance of the given class, or inherits
           from the given class, and FALSE otherwise
 Args    : the class to query for (a scalar string)


=cut

sub isa{
    my ($self,@args) = @_;

    my $ans = $self->SUPER::isa(@args);
    if(! $ans) {
	# try the wrapped object, too, but not if it's self
	my $obj = $self->obj();
	$ans = $obj->isa(@args) unless refaddr($obj) == refaddr($self);
    }
    return $ans;
}

=head2 can

 Title   : can
 Usage   :
 Function: This is a standard perl object method. We override it here in order
           to generically claim we 'can' everything that the wrapped
           object does.
 Example :
 Returns : TRUE if this object is has the named method, and FALSE otherwise
 Args    : the method to query for (a scalar string)


=cut

sub can{
    my ($self,@args) = @_;

    my $ans = $self->SUPER::can(@args);
    if(! $ans) {
	# try the wrapped object, too, but not if it's self
	my $obj = $self->obj();
	$ans = $obj->can(@args) unless refaddr($obj) == refaddr($self);
    }
    return $ans;
}

#
# This is private and does the magic in implementing the wrapped object's
# methods: it simply delegates all unresolved invocations to the wrapped
# object.
#
sub AUTOLOAD {
    my ($self,@args) = @_;
    # the method to call:
    my $meth = $AUTOLOAD;
    $meth =~ s/.*://;
    # sanity check
    if (! $self->isa("Bio::DB::Persistent::PersistentObject")) {
        $self->throw("I'm an instance of ".ref($self)
                     .", not a persistent object instance! "
                     ."(resolving $AUTOLOAD)");
    }
    # the object to delegate to:
    my $obj = $self->obj();
    # is the object set to which we delegate?
    if ((!defined($obj)) || (refaddr($obj) == refaddr($self))) {
        $self->throw("Can't locate object method \"$meth\" via package ".
                     ref($self));
    }
    # by default, we consider any arguments as a calling a setter and hence
    # the object becomes dirty
    $self->is_dirty(1) if @args;
    # execute the method by delegation
    return $obj->$meth(@args);
}

=head1 Implementation of the decorating methods

See L<Bio::DB::PersistentObjectI> for further documentation of the
methods.

=cut

=head2 rank

 Title   : rank
 Usage   : $obj->rank($newval)
 Function: Get/set the rank of this persistent object in a 1:n or n:n
           relationship.

 Example : 
 Returns : value of rank (a scalar)
 Args    : new value (a scalar or undef, optional)


=cut

sub rank{
    my $self = shift;

    return $self->{'rank'} = shift if @_;
    return $self->{'rank'};
}

=head2 foreign_key_slot

 Title   : foreign_key_slot
 Usage   : $obj->foreign_key_slot($newval)
 Function: Get/set of the slot name that is referring to this persistent
           object as a foreign key.

 Example : 
 Returns : value of foreign_key_slot (a scalar)
 Args    : new value (a scalar or undef, optional)


=cut

sub foreign_key_slot{
    my $self = shift;

    return $self->{'_foreign_key_slot'} = shift if @_;
    return $self->{'_foreign_key_slot'};
}

1;
