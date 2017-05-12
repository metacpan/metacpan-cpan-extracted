# $Id$
#
# BioPerl module for Bio::BioEntry
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

Bio::BioEntry - DESCRIPTION of Object

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


package Bio::BioEntry;
use vars qw(@ISA);
use strict;

# Object preamble - inherits from Bio::Root::Root

use Bio::Root::Root;
use Bio::IdentifiableI;
use Bio::DescribableI;

@ISA = qw(Bio::Root::Root Bio::IdentifiableI Bio::DescribableI);

=head2 new

 Title   : new
 Usage   : my $obj = Bio::BioEntry->new();
 Function: Builds a new Bio::BioEntry object 
 Returns : an instance of Bio::BioEntry
 Args    :


=cut

sub new {
  my($class,@args) = @_;

  my $self = $class->SUPER::new(@args);
  my ($objid, $ns, $auth, $v, $display_id, $desc) =
      $self->_rearrange([qw(OBJECT_ID
			    NAMESPACE
			    AUTHORITY
			    VERSION
			    DISPLAY_ID
			    DESCRIPTION)
			 ],
			@args);

  $self->object_id($objid) if $objid;
  $self->namespace($ns) if $ns;
  $self->authority($auth) if $auth;
  $self->version($v) if $v;
  $self->display_name($display_id) if $display_id;
  $self->description($desc) if $desc;

  return $self;
}

=head1 Methods for Bio::IdentifiableI compliance

=head2 object_id

 Title   : object_id
 Usage   : $string    = $obj->object_id()
 Function: a string which represents the stable primary identifier
           in this namespace of this object. For DNA sequences this
           is its accession_number, similarly for protein sequences

           This is aliased to accession_number().
 Returns : A scalar


=cut

sub object_id {
    my ($self, $value) = @_;

    if( defined $value) {
	$self->{'object_id'} = $value;
    }
    return $self->{'object_id'};    
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
    my ($self,$value) = @_;
    if( defined $value) {
	$self->{'_version'} = $value;
    }
    return $self->{'_version'};
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
    my ($obj,$value) = @_;
    if( defined $value) {
	$obj->{'authority'} = $value;
    }
    return $obj->{'authority'};
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
    my ($self,$value) = @_;
    if( defined $value) {
	$self->{'namespace'} = $value;
    }
    return $self->{'namespace'} || "";
}

=head1 Methods for Bio::DescribableI compliance

=head2 display_name

 Title   : display_name
 Usage   : $string    = $obj->display_name()
 Function: A string which is what should be displayed to the user
           the string should have no spaces (ideally, though a cautious
           user of this interface would not assumme this) and should be
           less than thirty characters (though again, double checking 
           this is a good idea)

           This is aliased to display_id().
 Returns : A scalar

=cut

sub display_name {
    my ($self,$value) = @_;
    if( defined $value) {
	$self->{'_display_name'} = $value;
    }
    return $self->{'_display_name'};
}

=head2 description

 Title   : description
 Usage   : $string    = $obj->description()
 Function: A text string suitable for displaying to the user a 
           description. This string is likely to have spaces, but
           should not have any newlines or formatting - just plain
           text. The string should not be greater than 255 characters
           and clients can feel justified at truncating strings at 255
           characters for the purposes of display

           This is aliased to desc().
 Returns : A scalar

=cut

sub description {
    my ($self,$value) = @_;
    
    if( defined $value) {
	$self->{'_description'} = $value;
    }
    return $self->{'_description'};
}


1;
