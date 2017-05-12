# $Id$
#
# BioPerl module for Bio::DB::BioSQL::SpeciesAdaptor
#
# Please direct questions and support issues to <bioperl-l@bioperl.org> 
#
# Cared for by Ewan Birney <birney@ebi.ac.uk>
#
# Copyright Ewan Birney
#
# You may distribute this module under the same terms as perl itself

# 
# Completely rewritten by Hilmar Lapp, hlapp at gmx.net
#
# Version 1.13 and beyond is also
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

Bio::DB::BioSQL::SpeciesAdaptor - DESCRIPTION of Object

=head1 SYNOPSIS

Give standard usage here

=head1 DESCRIPTION

Species DB adaptor 

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

=head1 AUTHOR - Ewan Birney, Hilmar Lapp

Email birney@ebi.ac.uk
Email hlapp at gmx.net

=head1 APPENDIX

The rest of the documentation details each of the object methods. Internal methods are usually preceded with a _

=cut


# Let the code begin...


package Bio::DB::BioSQL::SpeciesAdaptor;
use vars qw(@ISA);
use strict;

# Object preamble 

use Bio::DB::BioSQL::BasePersistenceAdaptor;
use Bio::DB::PersistentObjectI;
use Bio::Species;

@ISA = qw(Bio::DB::BioSQL::BasePersistenceAdaptor);

# We do not store the variant nor subspecies etc in the species
# object's classification array, so we need to sort those out. This
# table maps from NCBI taxon node rank to the Bio::Species method that
# accepts the respective node name. Ranks that do map into the
# classification array should not be mapped here.
my %rank_attr_map = ("no rank"    => "variant",
		     "subspecies" => "sub_species",
		     "varietas"   => "variant",
		     "tribe"      => "variant",
		     "subtribe"   => "variant");


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

    return ("common_name", "classification",
	    "ncbi_taxid", "binomial", "variant");
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
    my @vals = ($obj->common_name(),
		join(":", $obj->classification()),
		$obj->ncbi_taxid(),
		$obj->binomial('full'),
		$obj->variant() ? $obj->variant() : "-"
		);
    return \@vals;
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
	    $obj = Bio::Species->new();
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
    my ($self,$obj,$rows) = @_;

    if(! ref($obj)) {
	$self->throw("\"$obj\" is not an object. Probably internal error.");
    }
    if($rows && @$rows) {
	$obj->common_name($rows->[1]) if $rows->[1];
	$obj->ncbi_taxid($rows->[3]) if $rows->[3];
	# get the classification array in a separate query
	my $clf = $self->get_classification($rows->[0]);
	if($clf && ref $clf eq 'ARRAY') {
        
	    # for the species object we do not maintain the nodes that don't
	    # correspond to a standard rank, so remove them (e.g., 'root')
	    while($clf->[0]->[1] && ($clf->[0]->[1] eq "no rank")) {
		shift(@$clf);
	    }
	    # in the species object we store the species element without the
	    # genus, and similarly for the sub-species and variant
        
        # Commented out: 8-24-09 cjfields, re: bug 2092
        # explanation : Bio::Species (and BioPerl after 1.5.2) don't munge
        # the genus/species names if at all possible
        
	#    for(my $i = scalar(@$clf)-2; $i >= 0; $i--) {
	#	# if this node's name matches the start of the previous one,
	#	# remove this portion from the previous one's name
	#	if(index($clf->[$i+1]->[0], $clf->[$i]->[0]) == 0) {
	#	    $clf->[$i+1]->[0] = substr($clf->[$i+1]->[0],
	#				       length($clf->[$i]->[0])+1);
	#	}
	#	# don't do this stuff beyond genus and species
	#	last if $clf->[$i]->[1] eq "genus";
	#    }
        
	    # we do not store the variant nor subspecies etc in the species
	    # object's classification array, so we need to sort those out
        
        # TODO: this needs to be clarified in re: to the new behavior of
        # Bio::Species -- cjfields 8-24-09
        
	    my $rank = $clf->[scalar(@$clf)-1]->[1];
	    while(grep { $rank eq $_; } keys %rank_attr_map) {
		my $meth = $rank_attr_map{$rank};
		$obj->$meth($clf->[scalar(@$clf)-1]->[0]);
		pop(@$clf);
		$rank = $clf->[scalar(@$clf)-1]->[1];
	    }
	    # done massaging, store away
	    $obj->classification([reverse(map { $_->[0]; } @$clf)], "FORCE");
	}
    # cases where no node is found (or taxonomy isn't loaded)
    
    # TODO: do we still do the following based on current Species behavior?
    # -- cjfields 8/24/09
	if($rows->[4] && (! $obj->classification)) {
	    # poor man's binomial
	    my @clf = split(' ',$rows->[4]);
	    $obj->classification([$clf[1],$clf[0]], "FORCE");
	    # remove genus and species
	    splice(@clf,0,2);
	    # what remains goes under variant
	    $obj->variant(join(" ",@clf)) if @clf;
	}
	# an explicit variant overwrites
	$obj->variant($rows->[5]) if $rows->[5] && ($rows->[5] ne "-");
	# check for common name if not already in the result
	if(! $obj->common_name()) {
	    my $cname = $self->get_common_name($rows->[0]);
	    $obj->common_name($cname) if $cname;
	}
	# primary key
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

    # UKs for species are full binomial with variant, and ncbi_taxid
    if($obj->ncbi_taxid()) {
	$uk_h->{'ncbi_taxid'} = $obj->ncbi_taxid();
	$uk_h->{'name_class'} = "scientific name";
    } elsif($obj->binomial()) {
	$uk_h->{'binomial'} = $obj->binomial('full');
	$uk_h->{'binomial'} .= " ".$obj->variant() if $obj->variant();
	$uk_h->{'name_class'} = "scientific name";
    }
    
    return $uk_h;
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

=head2 get_classification

 Title   : get_classification
 Usage   :
 Function: Returns the classification array for a taxon as identified by
           its primary key.
 Example :
 Returns : a reference to an array of two-element arrays, where the first
           element contains the name of the node and the second element
           denotes its rank
 Args    : the primary key of the taxon


=cut

sub get_classification{
    my $self = shift;
    return $self->dbd->get_classification($self,@_);
}

=head2 get_common_name

 Title   : get_common_name
 Usage   :
 Function: Get the common name for a taxon as identified by its primary
           key.
 Example :
 Returns : a string denoting the common name
 Args    : the primary key of the taxon


=cut

sub get_common_name{
    my $self = shift;
    return $self->dbd->get_common_name($self,@_);
}

1;
