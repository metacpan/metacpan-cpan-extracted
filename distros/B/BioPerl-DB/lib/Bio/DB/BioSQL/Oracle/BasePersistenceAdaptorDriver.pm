# $Id$
#
# BioPerl module for Bio::DB::BioSQL::Oracle::BasePersistenceAdaptorDriver
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

Bio::DB::BioSQL::Oracle::BasePersistenceAdaptorDriver - DESCRIPTION of Object

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
email or the web:

  bioperl-bugs@bioperl.org
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


package Bio::DB::BioSQL::Oracle::BasePersistenceAdaptorDriver;
use vars qw(@ISA);
use strict;
use DBD::Oracle qw(:ora_types);

# Object preamble - inherits from Bio::Root::Root

use Bio::DB::BioSQL::BaseDriver;

@ISA = qw(Bio::DB::BioSQL::BaseDriver);

#
# we only put those attributes here that differ from the default one, and then
# specifically stick those into the global map in the contructor such that
# they override the default
#
my %object_entity_map = (
		"Bio::Annotation::Comment"            => "anncomment",
		"Bio::DB::BioSQL::CommentAdaptor"     => "anncomment",
		   );
my %slot_attribute_map = (
	 "taxon_name" => {
	     # the following are hacks: there is no such thing on
	     # the object model. The sole reason they are here is so that you
	     # can set the physical column name of your taxon_name table.
	     # You MUST have these columns on the taxon node table, NOT the
	     # taxon name table.
	     "parent_taxon"   => "tax_oid",
	 },
	 "taxon" => {
	     # the following are hacks, see taxon_name mapping
	     "parent_taxon"   => "tax_oid",
	 },
	 "bioentry" => {
	     "bionamespace"   => "db_oid",
	     "namespace"      => "db_oid",
	     # these are for context-sensitive FK name resolution
	     "object"         => "obj_ent_oid",
	     "subject"        => "subj_ent_oid",
	     # parent and child are for backwards compatibility
	     "parent"         => "obj_ent_oid",
	     "child"          => "subj_ent_oid",
	 },
	 "bioentry_relationship" => {
	     "object"         => "obj_ent_oid",
	     "subject"        => "subj_ent_oid",
	     # parent and child are for backwards compatibility
	     "parent"         => "obj_ent_oid",
	     "child"          => "subj_ent_oid",
	 },
	 "biosequence" => {
	     "primary_seq"    => "ent_oid",
             # NOTE: change undef to the name of the CRC column to
             # enable having CRC64s computed for sequences automatically,
             # or set to undef to disable
             "crc"            => "crc",
	 },
	 "reference" => {
	     "medline"        => "dbx_oid",
	     "pubmed"         => "dbx_oid",
	 },
         "term" => {
	     "ontology"       => "ont_oid",
	     # these are for context-sensitive FK name resolution
             # term relationships:
	     "subject"        => "subj_trm_oid",
	     "predicate"      => "pred_trm_oid",
	     "object"         => "obj_trm_oid",
             # seqfeatures:
             "primary_tag"    => "type_trm_oid",
             "source_tag"     => "source_trm_oid",
	 },
	 # term_synonym is more a hack - it doesn't correspond to an object
	 # in bioperl, but this does let you specify your column naming
	 "term_synonym" => {
	     "synonym"        => "name",
	     "term"           => "trm_oid"
	 },
	 "term_relationship" => {
	     "subject"        => "subj_trm_oid",
	     "predicate"      => "pred_trm_oid",
	     "object"         => "obj_trm_oid",
	     "ontology"       => "ont_oid",
	 },
	 "term_path" => {
	     "subject"        => "subj_trm_oid",
	     "predicate"      => "pred_trm_oid",
	     "object"         => "obj_trm_oid",
	     "ontology"       => "ont_oid",
	 },
	 "seqfeature" => {
	     "primary_tag"    => "type_trm_oid",
	     "source_tag"     => "source_trm_oid",
	     "entire_seq"     => "ent_oid",
	     # these are for context-sensitive FK name resolution
	     "object"         => "obj_fea_oid",
	     "subject"        => "subj_fea_oid",
	     # parent and child are for backwards compatibility
	     "parent"         => "parent_fea_oid",
	     "child"          => "child_feat_oid",
	 },
	 "seqfeature_relationship" => {
	     "object"         => "obj_fea_oid",
	     "subject"        => "subj_fea_oid",
	     # parent and child are for backwards compatibility
	     "parent"         => "parent_fea_oid",
	     "child"          => "child_fea_oid",
	 },
			   );
my %acronym_map = (
    "biodatabase"                => "db",
    "taxon_name"                 => "tax",
    "taxon"                      => "tax",
    "bioentry"                   => "ent",
    "bioentry_relationship"      => "enta",
    "biosequence"                => "seq",
    "dbxref"                     => "dbx",
    "bioentry_dbxref"            => "dbxenta",
    "reference"                  => "ref",
    "bioentry_reference"         => "entrefa",
    "anncomment"                 => "cmt",
    "term"                       => "trm",
    "term_dbxref"                => "trmdbxa",
    "term_synonym"               => "syn",
    "ontology"                   => "ont",
    "bioentry_qualifier_value"   => "enttrma",
    "seqfeature"                 => "fea",
    "seqfeature_relationship"    => "feaa",
    "seqfeature_dbxref"          => "dbxfeaa",
    "location"                   => "loc",
    "seqfeature_qualifier_value" => "featrma",
);
	 

my $schema_sequence = "BS_SEQUENCE";

=head2 new

 Title   : new
 Usage   : my $obj = Bio::DB::BioSQL::Oracle::BasePersistenceAdaptorDriver->new();
 Function: Builds a new Bio::DB::BioSQL::Oracle::BasePersistenceAdaptorDriver object 
 Returns : an instance of Bio::DB::BioSQL::Oracle::BasePersistenceAdaptorDriver
 Args    :


=cut

sub new {
    my($class,@args) = @_;

    my $self = $class->SUPER::new(@args);

    # copy the overriding keys into the slot mapping
    my $slotmap = $self->slot_attribute_map();
    foreach my $tbl (keys %slot_attribute_map) {
	foreach my $col (keys %{$slot_attribute_map{$tbl}}) {
	    $slotmap->{$tbl}->{$col} = $slot_attribute_map{$tbl}->{$col};
	}
    }
    # we need to copy the original mapping for the comment table to anncomment
    # (all caused by comment being a reserved word in Oracle)
    $slotmap->{"anncomment"} = $slotmap->{"comment"};
    # now copy the overriding parts into the object-relational mapping
    my $ormap = $self->objrel_map();
    foreach my $ent (keys %object_entity_map) {
	$ormap->{$ent} = $object_entity_map{$ent};
    }
    
    # initialize our own stuff
    $self->acronym_map(\%acronym_map);
    $self->{'schema_sequence'} = $schema_sequence;

    # we need to set LongReadLen to prevent truncation errors on LOBs
    my ($adp) = $self->_rearrange([qw(ADAPTOR)], @args);
    if($adp) {
	my $dbh = $adp->dbh();
	# set LongReadLen in the database handle if not set already
	if($dbh->{'LongReadLen'} < 0x4000) { # we want at least 16k
	    $dbh->{'LongReadLen'} = 0x20000; # if we got less we demand 128k
	}
    } else {
	$self->warn("-adaptor not supplied, unable to set LOB buffer");
    }

    return $self;
}

=head2 primary_key_name

 Title   : primary_key_name
 Usage   :
 Function: Obtain the name of the primary key attribute for the given
           table in the relational schema.

           For the oracle implementation, this is always oid (with two
           exceptions that have a virtual primary key).

 Example :
 Returns : The name of the primary key (a string)
 Args    : The name of the table (a string)


=cut

sub primary_key_name{
    my ($self,$table) = @_;

#################################################################
# use this version if you run the view-based API to the biosql  #
# naming convention - in that case foreign key and primary key  #
# names are identical to the mysql/Pg version.                  #
#################################################################
#     if($table eq "biosequence") {
# 	$table = $self->table_name("Bio::BioEntry");
#     } elsif($table eq "taxon_name") {
# 	$table = $self->table_name("TaxonNode");
#     }
#     return $self->SUPER::primary_key_name($table);
#################################################################

#################################################################
# use this version if you run the alias-based API to the biosql #
# naming convention - in that case foreign key and primary key  #
# names are different from the mysql/Pg version                 #
#################################################################
    if($table eq "biosequence") {
	return $self->foreign_key_name("Bio::BioEntry");
    } elsif($table eq "taxon_name") {
	return $self->foreign_key_name("TaxonNode");	
    }
    return "oid";
#################################################################
}

=head2 _build_foreign_key_name

 Title   : _build_foreign_key_name
 Usage   :
 Function: Build the column name for a foreign key to the given table.

           We override this here to obtain the acronym for the table
           and then append '_oid' to it. Other than that we reuse how
           the default foreign_key_name() determines the table name.

 Example :
 Returns : The name of the foreign key column as a string
 Args    : The table name as a string


=cut

sub _build_foreign_key_name{
    my $self = shift;
    my $table = shift;

    return $self->acronym_map->{$table} ."_oid";
}

=head2 sequence_name

 Title   : sequence_name
 Usage   :
 Function: Returns the name of the primary key generator (SQL sequence)
           for the given table.

 Example :
 Returns : the name of the sequence (a string)
 Args    : The name of the table.


=cut

sub sequence_name{
    my ($self,$table) = @_;
    return $table . "_pk_seq";
}

=head2 acronym_map

 Title   : acronym_map
 Usage   : $obj->acronym_map($newval)
 Function: Get/set the map of table names to acronyms (which the oracle
           build consistently uses across the panel).
 Example : 
 Returns : value of acronym_map (a hash ref)
 Args    : on set, new value (a hash ref or undef, optional)


=cut

sub acronym_map{
    my $self = shift;

    return $self->{'acronym_map'} = shift if @_;
    return $self->{'acronym_map'};
}

1;
