# $Id$
#
# BioPerl module for Bio::DB::Persistent::PersistentObjectFactory
#
# Please direct questions and support issues to <bioperl-l@bioperl.org> 
#
# Cared for by Hilmar Lapp <hlapp at gmx.net>
#
# Copyright Hilmar Lapp
#
# You may distribute this module under the same terms as perl itself

# POD documentation - main docs before the code

=head1 NAME

Bio::DB::Persistent::PersistentObjectFactory - DESCRIPTION of Object

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

Describe contact details here

=head1 CONTRIBUTORS

Additional contributors names and emails here

=head1 APPENDIX

The rest of the documentation details each of the object methods.
Internal methods are usually preceded with a _

=cut


# Let the code begin...


package Bio::DB::Persistent::PersistentObjectFactory;
use vars qw(@ISA);
use strict;

# Object preamble - inherits from Bio::Root::Root

use Bio::Root::Root;
use Bio::Factory::ObjectFactoryI;

@ISA = qw(Bio::Root::Root Bio::Factory::ObjectFactoryI);

=head2 new

 Title   : new
 Usage   : my $obj = Bio::DB::Persistent::PersistentObjectFactory->new();
 Function: Builds a new Bio::DB::Persistent::PersistentObjectFactory object 
 Returns : an instance of Bio::DB::Persistent::PersistentObjectFactory
 Args    : Named parameters, specifically
             -type     the type (class name) of the objects to be created,
                       apart from them being persistent objects
             -adaptor  the persistence adaptor for the newly created objects
                       (a Bio::DB::PersistenceAdaptorI compliant object)


=cut

sub new {
    my($class,@args) = @_;
    
    my $self = $class->SUPER::new(@args);

    my ($type,$adp) = $self->_rearrange([qw(TYPE ADAPTOR)], @args);
    $self->object_type($type) if $type;
    $self->persistence_adaptor($adp) if $adp;
    
    return $self;
}

=head2 object_type

 Title   : object_type
 Usage   : $obj->object_type($newval)
 Function: Get/set the type of the objects to be created by the factory, 
           apart from them being persistent objects. The type is essentially
           the class name.
 Example : 
 Returns : value of object_type (a scalar)
 Args    : new value (a scalar, optional)


=cut

sub object_type{
    my ($self,$value) = @_;
    if( defined $value) {
	# make sure it loads, or is loaded already (this will throw an
	# exception if anything is fishy)
	$self->_load_module($value);
	# set ...
	$self->{'object_type'} = $value;
    }
    return $self->{'object_type'};
}

=head2 persistence_adaptor

 Title   : persistence_adaptor
 Usage   : $obj->persistence_adaptor($newval)
 Function: Get/set the persistence adaptor for the desired object type. If
           not set, the adaptor for the created persistent objects needs to
           be set explicitly after creation before persistence methods can be
           called on it.
 Example : 
 Returns : a Bio::DB::PersistenceAdaptorI implementing object
 Args    : new value (a Bio::DB::PersistenceAdaptorI implementing object, 
           optional)


=cut

sub persistence_adaptor{
    my ($self,$value) = @_;
    if( defined $value) {
	$self->{'persistence_adaptor'} = $value;
    }
    return $self->{'persistence_adaptor'};
}

=head1 Methods to implement Bio::Factory::ObjectFactoryI

=cut

=head2 create_object

 Title   : create_object
 Usage   :
 Function: Creates a new object and returns it (like new() on a class name).
 Example :
 Returns : a new object (which will also implement Bio::DB::PersistentObjectI)
 Args    : an array of named parameters to be passed to the class''s new()


=cut

sub create_object{
    my ($self,@args) = @_;

    # create object of desired type
    my $class = $self->object_type();
    my $obj = $class->new(@args);
    # wrap it as a persistent object
    my $pobj = Bio::DB::Persistent::PersistentObject->new(
				     -object => $obj,
				     -adaptor => $self->persistence_adaptor());
    return $pobj;
}

1;
