# $Id$
#
# BioPerl module for Bio::DB::Persistent::BioNamespace
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

Bio::DB::Persistent::BioNamespace - DESCRIPTION of Object

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


package Bio::DB::Persistent::BioNamespace;
use vars qw(@ISA);
use strict;

# Object preamble - inherits from Bio::Root::Root

use Bio::DB::Persistent::PersistentObject;
use Bio::IdentifiableI;

@ISA = qw(Bio::DB::Persistent::PersistentObject Bio::IdentifiableI);

=head2 new

 Title   : new
 Usage   : my $obj = Bio::DB::Persistent::BioNamespace->new();
 Function: Builds a new Bio::DB::Persistent::BioNamespace object 
 Returns : an instance of Bio::DB::Persistent::BioNamespace
 Args    :


=cut

sub new {
    my($class,@args) = @_;

    my $self = $class->SUPER::new(@args);
    my ($identifiable) = $self->_rearrange([qw(IDENTIFIABLE)], @args);

    $self->identifiable($identifiable) if $identifiable;

    return $self;
}

=head2 obj

 Title   : obj
 Usage   : $obj->obj()
 Function: Get the object that is made persistent through this adaptor.

           Note that this implementation does not allow setting the object.
 Example : 
 Returns : The object made persistent through this adaptor
 Args    : None (set not supported)


=cut

sub obj{
    # we always point to ourselves
    return shift;
}

=head2 identifiable

 Title   : identifiable
 Usage   : $obj->identifiable($newval)
 Function: Get/set the Bio::IdentifiableI compliant object from which to obtain
           namespace and authority, and to which to forward all IdentifiableI
           calls.
 Example : 
 Returns : a Bio::IdentifiableI compliant object
 Args    : Optionally on set, a Bio::IdentifiableI compliant object


=cut

sub identifiable{
    my ($self,$value) = @_;
    if( defined $value) {
	$self->throw("Object of class ".ref($value)." does not implement ".
		     "Bio::IdentifiableI. Too bad.")
	    unless $value->isa("Bio::IdentifiableI");
	$self->{'identifiable'} = $value;
	$self->is_dirty(1);
    }
    return $self->{'identifiable'};
}

=head1 Methods for Bio::IdentifiableI compliance

=head2 object_id

 Title   : object_id
 Usage   : $string    = $obj->object_id()
 Function: a string which represents the stable primary identifier
           in this namespace of this object. For DNA sequences this
           is its accession_number, similarly for protein sequences

 Returns : A scalar


=cut

sub object_id {
    my ($self, @args) = @_;
    $self->is_dirty(1) if @args;
    return $self->identifiable()->object_id(@args);
}

=head2 version

 Title   : version
 Usage   : $version    = $obj->version()
 Function: a number which differentiates between versions of
           the same object. Higher numbers are considered to be
           later and more relevant, but a single object described
           the same identifier should represent the same concept

 Returns : A number

=cut

sub version{
    my ($self,@args) = @_;
    $self->is_dirty(1) if @args;
    return $self->identifiable()->version(@args);
}


=head2 authority

 Title   : authority
 Usage   : $authority    = $obj->authority()
 Function: a string which represents the organisation which
           granted the namespace, written as the DNS name for  
           organisation (eg, wormbase.org)

 Returns : A scalar

=cut

sub authority {
    my ($self,@args) = @_;
    $self->is_dirty(1) if @args;
    return $self->identifiable()->authority(@args);
}

=head2 namespace

 Title   : namespace
 Usage   : $string    = $obj->namespace()
 Function: A string representing the name space this identifier
           is valid in, often the database name or the name
           describing the collection 

 Returns : A scalar


=cut

sub namespace{
    my ($self,@args) = @_;
    $self->is_dirty(1) if @args;
    return $self->identifiable()->namespace(@args);
}


1;
