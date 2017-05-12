# $Id$
#
# BioPerl module for Bio::DB::BioSQL::BaseDriver
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

Bio::DB::BioSQL::BaseDriver - DESCRIPTION of Object

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


package Bio::DB::BioSQL::BaseDriver;
use vars qw(@ISA);
use strict;

# Object preamble - inherits from Bio::Root::Root

use Bio::Root::Root;
use Bio::DB::DBD;

@ISA = qw(Bio::Root::Root Bio::DB::DBD);


#
# here goes our entire object-relational mapping
#
my %object_entity_map = (
		"Bio::BioEntry"                       => "bioentry",
		"Bio::PrimarySeqI"                    => "bioentry",
		"Bio::DB::BioSQL::PrimarySeqAdaptor"  => "bioentry",
		"Bio::SeqI"                           => "bioentry",
		"Bio::DB::BioSQL::SeqAdaptor"         => "bioentry",
		"Bio::IdentifiableI"                  => "bioentry",
		"Bio::ClusterI"                       => "bioentry",
		"Bio::DB::BioSQL::ClusterAdaptor"     => "bioentry",
		"Bio::DB::BioSQL::BiosequenceAdaptor" => "biosequence",
		"Bio::SeqFeatureI"                    => "seqfeature",
		"Bio::DB::BioSQL::SeqFeatureAdaptor"  => "seqfeature",
		"Bio::Species"                        => "taxon_name",
		"Bio::DB::BioSQL::SpeciesAdaptor"     => "taxon_name",
		# TaxonNode is a hack: there is no such object, but we need it
		# to distinguish between the node and the name table
		"TaxonNode"                           => "taxon",
		"Bio::LocationI"                      => "location",
		"Bio::DB::BioSQL::LocationAdaptor"    => "location",
		"Bio::DB::BioSQL::BioNamespaceAdaptor"=> "biodatabase",
		"Bio::DB::Persistent::BioNamespace"   => "biodatabase",
		"Bio::Annotation::DBLink"             => "dbxref",
		"Bio::DB::BioSQL::DBLinkAdaptor"      => "dbxref",
		"Bio::Annotation::Comment"            => "comment",
		"Bio::DB::BioSQL::CommentAdaptor"     => "comment",
		"Bio::Annotation::Reference"          => "reference",
		"Bio::DB::BioSQL::ReferenceAdaptor"   => "reference",
		"Bio::Annotation::SimpleValue"        => "term",
		"Bio::DB::BioSQL::SimpleValueAdaptor" => "term",
		"Bio::Annotation::OntologyTerm"       => "term",
		"Bio::Ontology::TermI"                => "term",
		"Bio::DB::BioSQL::TermAdaptor"        => "term",
		"Bio::Ontology::RelationshipI"        => "term_relationship",
		"Bio::DB::BioSQL::RelationshipAdaptor"=> "term_relationship",
		"Bio::Ontology::PathI"                => "term_path",
		"Bio::Ontology::Path"                 => "term_path",
		"Bio::DB::BioSQL::PathAdaptor"        => "term_path",
        "Bio::Ontology::OntologyI"            => "ontology",
		"Bio::DB::BioSQL::OntologyAdaptor"    => "ontology",
		# TermSynonym is a hack - there is no such object
		"TermSynonym"                         => "term_synonym",
		   );
my %association_entity_map = (
	 "bioentry" => {
	     "dbxref"         => "bioentry_dbxref",
	     "reference"      => "bioentry_reference",
	     "term"           => "bioentry_qualifier_value",
	     "bioentry"       => {
		 "term"       => "bioentry_relationship",
	     }
	 },
	 "ontology" => {
	     "term"           => {
		 "term"       => {
		     "term"   => "term_relationship",
		 },
	     },
	 },
	 "seqfeature" => {
	     "term"           => "seqfeature_qualifier_value",
	     "dbxref"         => "seqfeature_dbxref",
	     "reference"      => undef,
	     "seqfeature"     => {
		 "term"       => "seqfeature_relationship",
	     }
	 },
	 "dbxref"   => {
	     "bioentry"       => "bioentry_dbxref",
	     "seqfeature"     => "seqfeature_dbxref",
	     "term"           => "dbxref_qualifier_value",
	 },
	 "reference"   => {
	     "bioentry"       => "bioentry_reference",
	     "seqfeature"     => undef,
	 },
	 "term" => {
	     "bioentry"       => "bioentry_qualifier_value",
	     "dbxref"         => "term_dbxref",
	     "seqfeature"     => "seqfeature_qualifier_value",
	     "term"           => {
		 "term"       => {
		     "ontology" => "term_relationship",
		 },
		 "ontology"   => {
		     "term"   => "term_relationship",
		 }
	     },
	     "ontology"       => {
		 "term"       => {
		     "term"   => "term_relationship",
		 }
	     }
	 },
			       );
my %slot_attribute_map = (
	 "biodatabase" => {
	     "name"           => "name",
	     "namespace"      => "name",
	     "authority"      => "authority",
	 },
	 "taxon_name" => {
	     "classification" => undef,
	     "common_name"    => undef,
	     "ncbi_taxid"     => "ncbi_taxon_id",
	     "binomial"       => "name",
	     "variant"        => undef,
	     # the following are hacks: there is no such thing on
	     # the object model. The sole reason they are here is so that you
	     # can set the physical column name of your taxon_name table.
	     # You MUST have these columns on the taxon node table, NOT the
	     # taxon name table.
	     "name_class"     => "name_class",
	     "node_rank"      => "node_rank",
	     "parent_taxon"   => "parent_taxon_id",
	 },
	 "taxon" => {
	     "ncbi_taxid"     => "ncbi_taxon_id",
	     # the following are hacks, see taxon_name mapping
	     "name_class"     => "name_class",
	     "node_rank"      => "node_rank",
	     "parent_taxon"   => "parent_taxon_id",
	 },
	 "bioentry" => {
	     "display_id"     => "name",
	     "primary_id"     => "identifier",
	     "accession_number" => "accession",
	     "desc"           => "description",
	     "description"    => "description",
	     "version"        => "version",
	     "division"       => "division",
	     "bionamespace"   => "biodatabase_id",
	     "namespace"      => "biodatabase_id",
	     # these are for context-sensitive FK name resolution
	     "object"         => "object_bioentry_id",
	     "subject"        => "subject_bioentry_id",
	     # parent and child are for backwards compatibility
	     "parent"         => "object_bioentry_id",
	     "child"          => "subject_bioentry_id",
	 },
	 "bioentry_relationship" => {
	     "object"         => "object_bioentry_id",
	     "subject"        => "subject_bioentry_id",
	     "rank"           => "rank",
	     # parent and child are for backwards compatibility
	     "parent"         => "object_bioentry_id",
	     "child"          => "subject_bioentry_id",
	 },
	 "biosequence" => {
	     "seq_version"    => "version",
	     "length"         => "length",
	     "seq"            => "seq",
	     "alphabet"       => "alphabet",
	     "primary_seq"    => "bioentry_id",
             # NOTE: change undef to the name of the CRC column to
             # enable having CRC64s computed for sequences automatically,
             # or set to undef to disable
             "crc"            => undef,
	 },
	 "dbxref" => {
	     "database"       => "dbname",
	     "primary_id"     => "accession",
	     "version"        => "version",
             "rank"           => "=>{bioentry_dbxref,seqfeature_dbxref,term_dbxref}.rank",
	 },
	 "bioentry_dbxref" => {
	     "rank"           => "rank",
	 },
	 "term_dbxref" => {
	     "rank"           => "rank",
	 },
	 "reference" => {
	     "authors"        => "authors",
	     "title"          => "title",
	     "location"       => "location",
	     "medline"        => "dbxref_id",
	     "pubmed"         => "dbxref_id",
	     "doc_id"         => "crc",
	     "start"          => "=>bioentry_reference.start",
	     "end"            => "=>bioentry_reference.end",
	     "rank"           => "=>bioentry_reference.rank",
	 },
	 "bioentry_reference" => {
	     "start"          => "start_pos",
	     "end"            => "end_pos",
	     "rank"           => "rank",
	 },
	 "comment" => {
	     "text"           => "comment_text",
	     "rank"           => "rank",
	     "Bio::DB::BioSQL::SeqFeatureAdaptor" => undef,
	 },
         "term" => {
	     "identifier"     => "identifier",
             "name"           => "name",
	     "tagname"        => "name",
	     "is_obsolete"    => "is_obsolete",
             "definition"     => "definition",
	     "value"          => "=>{bioentry_qualifier_value,seqfeature_qualifier_value}.value",
	     "rank"           => "=>{bioentry_qualifier_value,seqfeature_qualifier_value}.rank",
	     "ontology"       => "ontology_id",
	     # these are for context-sensitive FK name resolution
             # term relationships:
	     "subject"        => "subject_term_id",
	     "predicate"      => "predicate_term_id",
	     "object"         => "object_term_id",
             # seqfeatures:
             "primary_tag"    => "type_term_id",
             "source_tag"     => "source_term_id",             
	 },
	 # term_synonym is more a hack - it doesn't correspond to an object
	 # in bioperl, but this does let you specify your column naming
	 "term_synonym" => {
	     "synonym"        => "synonym",
	     "term"           => "term_id"
	 },
	 "term_relationship" => {
	     "subject"        => "subject_term_id",
	     "predicate"      => "predicate_term_id",
	     "object"         => "object_term_id",
	     "ontology"       => "ontology_id",
	 },
	 "term_path" => {
	     "distance"       => "distance",
	     "subject"        => "subject_term_id",
	     "predicate"      => "predicate_term_id",
	     "object"         => "object_term_id",
	     "ontology"       => "ontology_id",
	 },
         "ontology" => {
             "name"           => "name",
             "definition"     => "definition",
	 },
         "bioentry_qualifier_value" => {
	     "value"          => "value",
	     "rank"           => "rank",
	 },
	 "seqfeature" => {
	     "display_name"   => "display_name",
	     "rank"           => "rank",
	     "primary_tag"    => "type_term_id",
	     "source_tag"     => "source_term_id",
	     "entire_seq"     => "bioentry_id",
	     # these are for context-sensitive FK name resolution
	     "object"         => "object_seqfeature_id",
	     "subject"        => "subject_seqfeature_id",
	     # parent and child are for backwards compatibility
	     "parent"         => "parent_seqfeature_id",
	     "child"          => "child_seqfeature_id",
	 },
	 "seqfeature_dbxref" => {
	     "rank"           => "rank",
	 },
	 "location" => {
	     "start"          => "start_pos",
	     "end"            => "end_pos",
	     "strand"         => "strand",
	     "rank"           => "rank",
	 },
	 "seqfeature_qualifier_value" => {
	     "value"          => "value",
	     "rank"           => "rank",
	 },
	 "seqfeature_relationship" => {
	     "object"         => "object_seqfeature_id",
	     "subject"        => "subject_seqfeature_id",
	     "rank"           => "rank",
	     # parent and child are for backwards compatibility
	     "parent"         => "parent_seqfeature_id",
	     "child"          => "child_seqfeature_id",
	 },
			   );
my %dont_select_attrs = (
	 "biosequence.seq" => 1,
			);

=head2 new

 Title   : new
 Usage   : my $obj = Bio::DB::BioSQL::BaseDriver->new();
 Function: Builds a new Bio::DB::BioSQL::BaseDriver object 
 Returns : an instance of Bio::DB::BioSQL::BaseDriver
 Args    :

=cut

sub new {
    my($class,@args) = @_;

    my $self = $class->SUPER::new(@args);

    # copy the static mapping tables into our private hashs
    # you may then change individual mappings in your derived adaptor driver
    $self->objrel_map(\%object_entity_map);
    $self->slot_attribute_map(\%slot_attribute_map);
    $self->not_select_attrs(\%dont_select_attrs);
    $self->association_entity_map(\%association_entity_map);

    return $self;
}

=head2 prepare_delete_sth

 Title   : prepare_delete_sth
 Usage   :
 Function: Creates a prepared statement with one placeholder variable
           suitable to delete one row from the respective table the
           given class maps to.

           The method may throw an exception, or the database handle
           methods involved may throw an exception.

 Example :
 Returns : A DBI statement handle for a prepared statement with one placeholder
 Args    : The calling adaptor (basically, it needs to implement dbh()).
           Optionally, additional arguments.


=cut

sub prepare_delete_sth{
    my ($self, $adp) = @_;

    # default is a simple DELETE statement
    #
    # we need the table name and the name of the primary key
    my $tbl = $self->table_name($adp);
    my $pkname = $self->primary_key_name($tbl);
    # straightforward SQL:
    my $sql = "DELETE FROM $tbl WHERE $pkname = ?";
    $adp->debug("preparing DELETE statement: $sql\n");
    my $sth = $self->prepare($adp->dbh(),$sql);
    # done
    return $sth;
}

=head2 prepare_findbypk_sth

 Title   : prepare_findbypk_sth
 Usage   :
 Function: Prepares and returns a DBI statement handle with one placeholder for
           the primary key. The statement is expected to return the primary key
           as the first and then as many columns as 
           $adp->get_persistent_slots() returns, and in that order.

 Example :
 Returns : A DBI prepared statement handle with one placeholder
 Args    : The Bio::DB::BioSQL::BasePersistenceAdaptor derived object 
           (basically, it needs to implement dbh() and get_persistent_slots()).
           A reference to an array of foreign key slots (class names).


=cut

sub prepare_findbypk_sth{
    my ($self,$adp,$fkslots) = @_;

    # get table name and the primary key name
    my $table = $self->table_name($adp);
    my $pkname = $self->primary_key_name($table);
    # gather attributes
    my @attrs = $self->_build_select_list($adp,$fkslots);
    # create the sql statement
    my $sql = "SELECT " .
	join(", ", @attrs) . " FROM $table WHERE $pkname = ?";
    $adp->debug("preparing PK select statement: $sql\n");
    # prepare statement and return
    return $self->prepare($adp->dbh(),$sql);
}

=head2 prepare_findbyuk_sth

 Title   : prepare_findbyuk_sth
 Usage   :
 Function: Prepares and returns a DBI SELECT statement handle with as many
           placeholders as necessary for the given unique key.

           The statement is expected to return the primary key as the first and
           then as many columns as $adp->get_persistent_slots() returns, and in
           that order.
 Example :
 Returns : A DBI prepared statement handle with as many placeholders as 
           necessary for the given unique key
 Args    : The calling Bio::DB::BioSQL::BasePersistenceAdaptor derived object 
           (basically, it needs to implement dbh() and get_persistent_slots()).
           A reference to a hash with the names of the object''s slots in the
           unique key as keys and their values as values.
           A reference to an array of foreign key objects or slots 
           (class names if slot).

=cut

sub prepare_findbyuk_sth{
    my ($self,$adp,$ukval_h,$fkslots) = @_;

    # get the slots for which we need columns
    my @slots = $adp->get_persistent_slots();
    # get the slot/attribute map
    my $table = $self->table_name($adp);
    my $slotmap = $self->slot_attribute_map($table);
    # SELECT columns
    my @attrs = $self->_build_select_list($adp,$fkslots);
    # WHERE clause constraints
    my @cattrs = ();
    foreach (keys %$ukval_h) {
	my $col;
	if(exists($slotmap->{$_})) {
	    $col = $slotmap->{$_};
	} else {
	    # try it as a foreign key
	    $col = $self->foreign_key_name($_);
	}
	push(@cattrs, $col || "NULL");
	if(! $col) {
	    $self->warn("slot $_ is in unique key, but can't be mapped to ".
			"an entity column: you won't find anything");
	}
    }
    # create the sql statement
    my $sql = "SELECT " . join(", ", @attrs) .
	" FROM $table WHERE ".
	join(" AND ", map { "$_ = ?"; } @cattrs);
    $adp->debug("preparing UK select statement: $sql\n");
    # prepare statement and return
    return $self->prepare($adp->dbh(),$sql);
}

=head2 prepare_insert_association_sth

 Title   : prepare_insert_association_sth
 Usage   :
 Function: Prepares a DBI statement handle suitable for inserting the
           association between the two entities that correspond to the
           given objects.
 Example :
 Returns : the DBI statement handle
 Args    : The calling adaptor.
           Named parameters. Currently recognized are:
               -objs   a reference to an array of objects to be
                       associated with each other
               -values a reference to a hash the keys of which are
                       column names and the values are values of
                       columns other than the ones for foreign keys to
                       the entities to be associated
               -contexts optional; if given it denotes a reference
                       to an array of context keys (strings), which
                       allow the foreign key name to be determined
                       through the association map rather than through
                       foreign_key_name().  This may be necessary if
                       more than one object of the same type takes
                       part in the association. The array must be in
                       the same order as -objs, and have the same
                       number of elements. Put undef for objects
                       for which there are no multiple contexts.

  Caveats: Make sure you *always* give the objects to be associated in the
           same order.


=cut

sub prepare_insert_association_sth{
    my ($self,$adp,@args) = @_;
    my ($i);

    # get arguments
    my ($objs, $values, $contexts) =
	$self->_rearrange([qw(OBJS VALUES CONTEXTS)], @args);
    # obtain column map for non-fk columns
    my $table = $self->association_table_name($objs);
    if(! $table) {
	$self->throw("no object-relational map for association between ".
		     "classes (".
		     join(",", map { $_->isa("Bio::DB::PersistentObjectI") ?
					 ref($_->obj()) : ref($_);
				 } @$objs) .
		     ")");
    }
    my $columnmap = $self->slot_attribute_map($table);
    my $attr;
    my @attrs = ();
    my @plchldrs = ();
    # first, gather the foreign key names
    $i = 0;
    while($i < @$objs) {
	my $fktable = $self->table_name($objs->[$i]);
	if(! $fktable) {
	    $self->throw("no object-relational map for class ".
			 ref($objs->[$i]));
	}
	if($contexts && $contexts->[$i]) {
	    $attr = $columnmap->{$contexts->[$i]};
	} else {
	    $attr = $self->foreign_key_name($objs->[$i]);
	}
	if(! $attr) {
	    $self->throw("unable to determine column for FK to class ".
			 ref($objs->[$i]));
	}
	push(@attrs, $attr);
	push(@plchldrs, "?");
	$i++;
    }
    # now add the columns for values if any
    if($values) {
	foreach my $colkey (keys %$values) {
	    $self->throw("unmapped association column $colkey")
		unless exists($columnmap->{$colkey});
	    $attr = $columnmap->{$colkey};
	    if($attr) {
		push(@attrs, $attr);
		push(@plchldrs, "?");
	    }
	}
    }
    # construct SQL straightforwardly
    my $sql = "INSERT INTO $table (".
	join(", ", @attrs) . ") VALUES (".
	join(", ", @plchldrs) . ")";
    $adp->debug("preparing INSERT statement: $sql\n");
    # prepare sth and return
    return $self->prepare($adp->dbh(),$sql);
}

=head2 prepare_delete_association_sth

 Title   : prepare_delete_association_sth
 Usage   :
 Function: Prepares a DBI statement handle suitable for deleting the
           association between the two entities that correspond to the
           given objects.
 Example :
 Returns : the DBI statement handle
 Args    : The calling adaptor.
           Named parameters. Currently recognized are:
               -objs   a reference to an array of objects the association
                       between which is to be deleted
               -values a reference to a hash the keys of which are
                       column names and the values are values of
                       columns other than the ones for foreign keys to
                       the entities to be associated
               -contexts optional; if given it denotes a reference
                       to an array of context keys (strings), which
                       allow the foreign key name to be determined
                       through the association map rather than through
                       foreign_key_name().  This may be necessary if
                       more than one object of the same type takes
                       part in the association. The array must be in
                       the same order as -objs, and have the same
                       number of elements. Put undef for objects
                       for which there are no multiple contexts.

  Caveats: Make sure you *always* give the objects to be associated in the
           same order.


=cut

sub prepare_delete_association_sth{
    my ($self,$adp,@args) = @_;
    my ($i);

    # get arguments
    my ($objs, $values, $contexts) =
	$self->_rearrange([qw(OBJS VALUES CONTEXTS)], @args);
    # obtain column map for non-fk columns
    my $table = $self->association_table_name($objs);
    if(! $table) {
	$self->throw("no object-relational map for association between ".
		     "classes (".
		     join(",", map {
			 ref($_) ?
			     ($_->isa("Bio::DB::PersistentObjectI") ?
			      ref($_->obj()) : ref($_)) :
			      $_;
		     } @$objs) .
		     ")");
    }
    my $columnmap = $self->slot_attribute_map($table);
    my $attr;
    my @attrs = ();
    # first, gather the foreign key names
    $i = 0;
    while($i < @$objs) {
	my $obj = $objs->[$i];
	if(ref($obj) && $obj->isa("Bio::DB::PersistentObjectI")) {
	    my $fktable = $self->table_name($obj);
	    if(! $fktable) {
		$self->throw("no object-relational map for class ".
			     ref($obj));
	    }
	    if($contexts && $contexts->[$i]) {
		$attr = $columnmap->{$contexts->[$i]};
	    } else {
		$attr = $self->foreign_key_name($obj);
	    }
	    if(! $attr) {
		$self->throw("unable to determine column for FK to class ".
			     ref($obj));
	    }
	    push(@attrs, $attr);
	}
	$i++;
    }
    # now add the columns for values if any
    if($values) {
	foreach my $colkey (keys %$values) {
	    $self->throw("unmapped association column $colkey")
		unless exists($columnmap->{$colkey});
	    $attr = $columnmap->{$colkey};
	    push(@attrs, $attr) if $attr;
	}
    }
    # construct SQL straightforwardly
    my $sql = "DELETE FROM $table WHERE ".
	join(" AND ", map { $_ . " = ?"; } @attrs);
    $adp->debug("preparing DELETE ASSOC statement: $sql\n");
    # prepare sth and return
    return $self->prepare($adp->dbh(),$sql);
}

=head2 prepare_delete_query_sth

 Title   : prepare_delete_query_sth
 Usage   :
 Function: Prepares a DBI statement handle suitable for deleting rows
           from a table that match a number of attributes.
 Example :
 Returns : the DBI statement handle
 Args    : The calling adaptor.

           Named parameters. Currently recognized are:

               -fkobjs optional; a reference to an array of foreign
                       key objects by which to constrain; this is
                       complementary to -values

               -contexts optional; if given it denotes a reference
                       to an array of context keys (strings), which
                       allow the foreign key name to be determined
                       through the association map rather than through
                       foreign_key_name().  This may be necessary if
                       an entity has more than one foreign key to the
                       same entity. The array must be in the same
                       order as -fkobjs, and have the same number of
                       elements. Put undef for objects for which there
                       are no multiple contexts.

               -values optional; a reference to a hash the keys of
                       which are attribute names by which to constrain
                       the query


=cut

sub prepare_delete_query_sth{
    my ($self,$adp,@args) = @_;
    my ($i);

    # get arguments
    my ($fkobjs, $values, $contexts) =
	$self->_rearrange([qw(FKOBJS VALUES CONTEXTS)], @args);
    # obtain column map for attributes
    my $table = $self->table_name($adp);
    my $columnmap = $self->slot_attribute_map($table);
    my @attrs = ();
    my $attr;
    # add the query constraint columns for foreign key columns if any
    if($fkobjs && @$fkobjs) {
	foreach my $obj (@$fkobjs) {
	    my $fktable = $self->table_name($obj);
	    if(! $fktable) {
		$self->throw("no object-relational map for class ".
			     (ref($obj) ? ref($obj) : $obj));
	    }
	    if($contexts && $contexts->[$i]) {
		$attr = $columnmap->{$contexts->[$i]};
	    } else {
		$attr = $self->foreign_key_name($obj);
	    }
	    if(! $attr) {
		$self->throw("unable to determine column for FK to class ".
			     (ref($obj) ? ref($obj) : $obj));
	    }
	    push(@attrs, $attr);
	}
    }
    # add any other query constraint columns
    if($values) {
	foreach my $colkey (keys %$values) {
	    $self->throw("unmapped association column $colkey")
		unless exists($columnmap->{$colkey});
	    $attr = $columnmap->{$colkey};
	    push(@attrs, $attr) if $attr;
	}
    }
    # construct SQL straightforwardly
    my $sql = "DELETE FROM $table";
    if(@attrs) {
	$sql .= " WHERE " . join(" AND ", map { $_ . " = ?"; } @attrs);
    }
    $adp->debug("preparing DELETE QUERY statement: $sql\n");
    # prepare sth and return
    return $self->prepare($adp->dbh(),$sql);
}

=head2 prepare_insert_sth

 Title   : prepare_insert_sth
 Usage   :
 Function: Prepares a DBI statement handles suitable for inserting
           a row (as values of the slots of an object) into a table.
 Example :
 Returns : the DBI statement handle
 Args    : the calling adaptor (a Bio::DB::PersistenceAdaptorI object)
           a reference to an array of object slot names
           a reference to an array of foreign key objects (optional)


=cut

sub prepare_insert_sth{
    my ($self,$adp,$slots,$fkobjs) = @_;

    # obtain table and object slot map
    my $table = $self->table_name($adp);
    my $slotmap = $self->slot_attribute_map($table);
    $self->throw("no slot/attribute map for table $table") unless $slotmap;
    # construct INSERT statement as straightforward SQL with placeholders
    my @attrs = ();
    my @plchlds = ();
    foreach my $slot (@$slots) {
	if( ! exists($slotmap->{$slot})) {
	    $self->throw("no mapping for slot $slot in slot-attribute map");
	}
	# we don't add a column nor a placeholder for unmapped slots
	if($slotmap->{$slot} &&
	   (substr($slotmap->{$slot},0,2) ne '=>')) {
	    push(@attrs, $slotmap->{$slot});
	    push(@plchlds, "?");
	}
    }
    # foreign keys
    if($fkobjs) {
	foreach (@$fkobjs) {
	    my $fkattr = $self->foreign_key_name($_);
	    push(@attrs, $fkattr);
	    push(@plchlds, "?");
	}
    }
    my $sql = "INSERT INTO " . $table . " (" .
	join(", ", @attrs) .
	") VALUES (" .
	join(", ", @plchlds) . ")";
    $adp->debug("preparing INSERT statement: $sql\n");
    return $self->prepare($adp->dbh, $sql);
}

=head2 prepare_update_sth

 Title   : prepare_update_sth
 Usage   :
 Function: Prepares a DBI statement handle suitable for updating 
           a row in a table where the row is identified by its
           primary key.
 Example :
 Returns : the DBI statement handle
 Args    : the calling adaptor (a Bio::DB::PersistenceAdaptorI object)
           a reference to an array of object slot names
           a reference to an array of foreign key objects (optional)


=cut

sub prepare_update_sth{
    my ($self,$adp,$slots,$fkobjs) = @_;

    # obtain the table name and corresponding slot map
    my $table = $self->table_name($adp);
    my $slotmap = $self->slot_attribute_map($table);
    $self->throw("no slot/attribute map for table $table") unless $slotmap;
    # construct UPDATE statement as straightforward SQL
    my @attrs = ();
    foreach my $slot (@$slots) {
	if(! exists($slotmap->{$slot})) {
	    $self->throw("no mapping for slot $_ in slot-attribute map");
	}
	# we don't add a column nor a placeholder for unmapped slots
	if($slotmap->{$slot} &&
	   (substr($slotmap->{$slot},0,2) ne '=>')) {
	    push(@attrs, $slotmap->{$slot});
	}
    }
    # foreign keys
    if($fkobjs) {
	foreach (@$fkobjs) {
	    my $fkattr = $self->foreign_key_name($_);
	    push(@attrs, $fkattr);
	}
    }
    my $ifnull = $adp->dbcontext->dbi->ifnull_sqlfunc();
    my $sql = "UPDATE $table SET " .
	join(", ", map {"$_ = $ifnull\(?,$_\)";} @attrs) .
	" WHERE " . $self->primary_key_name($table) . " = ?";
    $adp->debug("preparing UPDATE statement: $sql\n");
    return $self->prepare($adp->dbh(),$sql);
}

=head2 cascade_delete

 Title   : cascade_delete
 Usage   :
 Function: Removes all persistent objects dependent from the given persistent
           object from the database (foreign key integrity).

           This implementation assumes that the underlying schema and RDBMS
           support cascading deletes, and hence does nothing other than 
           returning TRUE.
 Example :
 Returns : TRUE on success, and FALSE otherwise
 Args    : The DBContextI implementing object for the database.
           The object for which the dependent rows shall be deleted. 
           Optionally, additional (named) arguments.


=cut

sub cascade_delete{
    # our default assumption is that the RDBMS does support cascading deletes
    return 1;
}

=head2 insert_object

 Title   : insert_object
 Usage   :
 Function:
 Example :
 Returns : The primary key of the newly inserted record.
 Args    : A Bio::DB::BioSQL::BasePersistenceAdaptor derived object
           (basically, it needs to implement dbh(), sth($key, $sth),
	    dbcontext(), and get_persistent_slots()).
	   The object to be inserted.
           A reference to an array of foreign key objects; if any of those
           foreign key values is NULL (some foreign keys may be nullable),
           then give the class name.


=cut

sub insert_object{
    my ($self,$adp,$obj,$fkobjs) = @_;
    
    # obtain the object's slots to be serialized
    my @slots = $adp->get_persistent_slots($obj);
    # get the INSERT statement 
    # is it cached?
    my $cache_key = 'INSERT '.ref($obj).' '.join(';',@slots);
    my $sth = $self->get_sth($adp,$obj,$fkobjs,$cache_key,'insert_object');
    # we need the slot map regardless of whether we need to construct the
    # SQL or not, because we need to know which slots do not map to a column
    # (indicated by them being mapped to undef)
    my $table = $self->table_name($adp);
    my $slotmap = $self->slot_attribute_map($table);
    $self->throw("no slot/attribute map for table $table") unless $slotmap;
    # we'll need the db handle in any case
    my $dbh = $adp->dbh();
    # if not cached, create SQL and prepare statement
    if(! $sth) {
	$sth = $self->prepare_insert_sth($adp, \@slots, $fkobjs);
	# and cache
	$adp->sth($cache_key, $sth);
	# and give interceptors a chance to do their work
	$sth = $self->get_sth($adp,$obj,$fkobjs,$cache_key,'insert_object');
    }
    # the implementation here is a post-insert primary-key retrieval, so
    # just go ahead and bind the attributes, no a-priori pk retrieval
    my $slotvals = $adp->get_persistent_slot_values($obj, $fkobjs);
    if(@$slotvals != @slots) {
	$self->throw("number of slots must equal the number of values ".
		     "(slots: ".
		     join(";",@slots).") (values: \"".
		     join("\";\"",@$slotvals).")");
    }
    my $i = 0; # slots and slot values index
    my $j = 1; # column index
    while($i < @slots) {
	if($slotmap->{$slots[$i]} &&
	   (substr($slotmap->{$slots[$i]},0,2) ne '=>')) {
	    if($adp->verbose > 0) {
		$adp->debug(substr(ref($adp),rindex(ref($adp),"::")+2).
			    "::insert: ".
			    "binding column $j to \"", $slotvals->[$i],
			    "\" ($slots[$i])\n");
	    }
	    $self->bind_param($sth, $j, $slotvals->[$i]);
	    $j++;
	}
	$i++;
    }
    # bind foreign key values
    if($fkobjs) {
	foreach my $o (@$fkobjs) {
	    # If it's an object, the value to bind is the primary key.
	    # Otherwise bind undef.
	    my $fk = $o && ref($o) ? $o->primary_key() : undef;
	    if($adp->verbose > 0) {
		$adp->debug(substr(ref($adp),rindex(ref($adp),"::")+2).
			    "::insert: ".
			    "binding column $j to \"", $fk,
			    "\" (FK to ",
			    ($o ?
			     (ref($o) ? ref($o->obj()) : $o) : "<unknown>"),
			    ")\n");
	    }
	    $self->bind_param($sth, $j, $fk);
	    $j++;
	}
    }
    # execute
    my $rv = $sth->execute();
    my $pk;
    # Note: $rv may be 0E0 (evaluates to TRUE as a string) to indicate 
    # success, but zero rows affected, which means no row was inserted.
    # This may be (hopefully will be) due to an RDBMS having internally
    # (by means of triggers [Oracle, Pg] or rules [Pg]) encapsulated and
    # caught the already-exists condition.
    if($rv && ($rv != 0)) {
	# get the primary key that was just inserted
	$pk = $adp->dbcontext()->dbi()->last_id_value(
					   $dbh, $self->sequence_name($table));
    } elsif(! $rv) { # note this is *not* equivalent to $rv == 0 !
	# the statement failed
	$self->report_execute_failure(-sth => $sth, -adaptor => $adp,
				      -op => 'insert',
				      -vals => $slotvals, -fkobjs => $fkobjs);
    }
    # done, return
    return $pk;
}

=head2 update_object

 Title   : update_object
 Usage   :
 Function:
 Example :
 Returns : The number of updated rows
 Args    : A Bio::DB::BioSQL::BasePersistenceAdaptor derived object
           (basically, it needs to implement dbh(), sth($key, $sth),
	    dbcontext(), and get_persistent_slots()).
	   The object to be updated.
           A reference to an array of foreign key objects; if any of those
           foreign key values is NULL (some foreign keys may be nullable),
           then give the class name.


=cut

sub update_object{
    my ($self,$adp,$obj,$fkobjs) = @_;
    
    # obtain the object's slots to be serialized
    my @slots = $adp->get_persistent_slots($obj);
    # get the UPDATE statement 
    # is it cached?
    my $cache_key = 'UPDATE '.ref($adp).' '.join(';',@slots);
    my $sth = $self->get_sth($adp,$obj,$fkobjs,$cache_key,'update_object');
    # we need the slot map regardless of whether we need to construct the
    # SQL or not, because we need to know which slots do not map to a column
    # (indicated by them being mapped to undef)
    my $table = $self->table_name($adp);
    my $slotmap = $self->slot_attribute_map($table);
    $self->throw("no slot/attribute map for table $table") unless $slotmap;
    # if not cached, create SQL and prepare statement
    if(! $sth) {
	$sth = $self->prepare_update_sth($adp, \@slots, $fkobjs);
	# and cache
	$adp->sth($cache_key, $sth);
	# and give interceptors a chance to do their work
	$sth = $self->get_sth($adp,$obj,$fkobjs,$cache_key,'update_object');
    }
    # bind paramater values
    my $slotvals = $adp->get_persistent_slot_values($obj, $fkobjs);
    if(@$slotvals != @slots) {
	$self->throw("number of slots must equal the number of values");
    }
    my $i = 0; # slots and slot values index
    my $j = 1; # column index
    while($i < @slots) {
	if($slotmap->{$slots[$i]} &&
	   (substr($slotmap->{$slots[$i]},0,2) ne '=>')) {
	    if($adp->verbose > 0) {
		$adp->debug(sprintf("%s::update: binding column %d to \"%s\"(%s)\n",
                        substr(ref($adp),rindex(ref($adp),"::")+2),
                        $j,
                        $slotvals->[$i] || '',
                        ($slots[$i])));
	    }
	    $self->bind_param($sth, $j, $slotvals->[$i]);
	    $j++;
	}
	$i++;
    }
    # bind foreign key values
    if($fkobjs) {
	foreach my $o (@$fkobjs) {
	    # If it's an object, the value to bind is the primary key. If it's
	    # numeric, the value is the number. Otherwise bind undef.
	    my $fk = ref($o) ?
		$o->primary_key() :
		$o =~ /^\d+$/ ? $o : undef;
	    if($adp->verbose > 0) {
		$adp->debug(substr(ref($adp),rindex(ref($adp),"::")+2).
			    "::update: ".
			    "binding column $j to \"$fk\" (FK to ".
			    $self->table_name($o) . ")\n");
	    }
	    $self->bind_param($sth, $j, $fk);
	    $j++;
	}
    }
    # bind the primary key (which is in the WHERE clause and hence the last)
    $self->bind_param($sth, $j, $obj->primary_key());
    # execute
    my $rv = $sth->execute();
    if(! $rv) {
	$self->report_execute_failure(-sth => $sth, 
				      -adaptor => $adp, -op => 'update',
				      -vals => $slotvals, -fkobjs => $fkobjs);
    }
    # done, return
    return $rv;
}

=head2 get_sth

 Title   : get_sth
 Usage   :
 Function: Retrieves the (prepared) statement handle to bind
           parameters for and to execute for the given operation.

           By default this will use the supplied key to retrieve the
           statement from the cache.

           This method is here to provide an opportunity for
           inheriting drivers to intercept the cached statement
           retrieval in order to on-the-fly redirect the statement
           execution to use a different statement than it would have
           used by default.

           This method may return undef if for instance there is no
           appropriate statement handle in the cache. Returning undef
           will trigger the calling method to construct a statement
           from scratch.

 Example :
 Returns : a prepared statement handle if one is exists for the query,
           and undef otherwise
 Args    : - the calling adaptor (a Bio::DB::BioSQL::BasePersistenceAdaptor
             derived object
	   - the object for the persistence operation
           - a reference to an array of foreign key objects; if any of
             those foreign key values is NULL then the class name
           - the key to the cache of the adaptor
           - the operation requesting a cache key (a scalar basically
             representing the name of the method)


=cut

sub get_sth{
    my ($self,$adp,$obj,$fkobjs,$key,$op) = @_;

    return $adp->sth($key);
}

=head2 translate_query

 Title   : translate_query
 Usage   :
 Function: Translates the given query as represented by the query object
           from objects and class names and slot names to tables and column
           names.
 Example :
 Returns : An object of the same class as the input query, but representing
           the translated query, and also with the SELECT fields properly set
           to facilitate object construction.
 Args    : The calling adaptor.
           The query as a Bio::DB::Query::BioQuery or derived object.
           A reference to an array of foreign key objects.


=cut

sub translate_query{
    my ($self,$adp,$query,$fkobjs) = @_;

    # the query object can itself translate the datacollections and
    # slot names to column names (all it needs is a obj-rel mapper, which
    # is us)
    my %entitymap = ();
    my $tquery = $query->translate_query($self, \%entitymap);
    # build the SELECT list
    my @selattrs = $self->_build_select_list($adp,$fkobjs,\%entitymap);
    # set as the SELECT elements of the query
    $tquery->selectelts(\@selattrs);
    # done
    return $tquery;
}

=head2 _build_select_list

 Title   : _build_select_list
 Usage   :
 Function: Builds and returns the select list for an object query. The list
           contains those columns, in the right order, that are necessary to
           populate the object.
 Example :
 Returns : An array of strings (column names, not prefixed)
 Args    : The calling persistence adaptor.
           A reference to an array of foreign key entities (objects, class
           names, or adaptors) the object must attach.
           A reference to a hash table mapping entity names to aliases (if
           omitted, aliases will not be used, and SELECT columns can only be
           from one table)


=cut

sub _build_select_list{
    my ($self,$adp,$fkobjs,$entitymap) = @_;

    # get the persistent slots
    my @slots = $adp->get_persistent_slots();
    # get the slot/attribute map
    my $table = $self->table_name($adp);
    my $slotmap = $self->slot_attribute_map();
    # get the map of columns excluded from SELECTs
    my $dont_select_attrs = $self->not_select_attrs();
    # default the entity-alias map if not provided
    if(! $entitymap) {
	$entitymap = {};
	$entitymap->{$table} = [$table];
    }
    # Alias for the table. We'll use the first one if the table is in the
    # FROM list with different aliases. Also note that the alias may come
    # with context, which we need to strip off.
    my ($alias) = split(/::/, $entitymap->{$table}->[0]);
    # get the primary key name
    my $pkname = $self->primary_key_name($table);
    # SELECT columns
    my @attrs = ($alias .".". $pkname);
    foreach (@slots) {
	$self->throw("no mapping for slot $_ in slot-attribute map")
	    if ! exists($slotmap->{$table}->{$_});
	my $attr = $slotmap->{$table}->{$_};
	my $tbl = $table;
	# is this attribute actually mapped to one or more other tables?
	if($attr && (substr($attr,0,2) eq '=>')) {
	    # yes, figure out to which attribute
	    ($tbl,$attr) = split(/\./, substr($attr,2));
	    # is this mapped to multiple tables?
	    if($tbl =~ /^\{(.*)\}$/) {
		# yes, figure out which one we have in the entity map
		foreach (split(/[,\s]+/, $1)) {
		    # we just grab the first one
		    if($entitymap->{$_}) {
			$tbl = $_;
			last;
		    }
		}
	    }
	    $attr = $slotmap->{$tbl}->{$attr};
	}
	if((! $attr) || (! $entitymap->{$tbl}) ||
	   $dont_select_attrs->{$tbl .".". $attr}) {
	    push(@attrs, "NULL");
	} else {
	    # same caveats as for the alias of the 'main' table
	    my ($tblalias) = split(/::/, $entitymap->{$tbl}->[0]);
	    push(@attrs, $tblalias .".". $attr);
	}
    }
    # add foreign key attributes
    if($fkobjs) {
	foreach (@$fkobjs) {
	    my $fkattr = $self->foreign_key_name($_);
	    $self->throw("no mapping for foreign key to $_") unless $fkattr;
	    push(@attrs, $alias .".". $fkattr);
	}
    }
    return @attrs;
}

=head2 table_name

 Title   : table_name
 Usage   :
 Function: Obtain the name of the table in the relational schema
           corresponding to the given class name, object, or
           persistence adaptor.

           This implementation uses a object-relational hash map keyed
           by class to obtain the table name.

 Example :
 Returns : the name of the table (a string), or undef if the table cannot be
           determined
 Args    : The referenced object, class name, or the persistence
           adaptor for it.


=cut

sub table_name{
   my ($self,$obj) = @_;

   # if this is an array ref, the caller is asking for an association table
   if(ref($obj) && (ref($obj) eq "ARRAY")) {
       return $self->association_table_name($obj);
   }
   # directly mapped?
   my $objrel_map = $self->objrel_map();
   my $tbl = $objrel_map->{ref($obj) || $obj};
   if(! $tbl) {
       # if not, and it's an object
       if(ref($obj)) {
	   # if it's a persistent object, see whether the adaptor is mapped
	   if($obj->isa("Bio::DB::PersistentObjectI")) {
	       $tbl = $objrel_map->{ref($obj->adaptor())};
	   }
	   # if still no success, and it's not an adaptor, see which key it 
	   # implements
	   if(! ($tbl || $obj->isa("Bio::DB::PersistenceAdaptorI"))) {
	       my (@classes) = grep { $obj->isa($_); } keys %$objrel_map;
	       if(@classes) {
		   @classes = &_order_classes_by_inheritance($obj,@classes);
		   $tbl = $objrel_map->{$classes[0]};
	       }
	   }
       } else {
	   # it's not an object
	   #
	   # look up by `last name' only, provided that maps uniquely
	   my @class = grep { /(^|::)$obj$/; } keys %$objrel_map;
	   $tbl = $objrel_map->{$class[0]} if(@class == 1);
	   if(! $tbl) {
	       # We may have a context appended. Strip the last component
	       # and try to start over.
	       #
	       # Well, would be nice if we could do that. However, currently
	       # context is appended with a '::' separator, so we can't tell
	       # right away whether we'd be stripping off context or the module
	       # from the path. In the absence of a method to determine what is
	       # context and what is not, we can't go this route.
	       #
	       #@class = split(/::/, $obj);
	       #pop(@class);
	       #$tbl = $self->table_name(join('::', @class)) if @class;
	   }
       }
   }
   return $tbl;
}

sub _order_classes_by_inheritance{
    my ($obj, @classes) = @_;
    my $class = ref($obj) || $obj;
    my @sorted = ();

    # recursion termination condition: an array of one or less elements
    # is sorted already
    return @classes if @classes <= 1;

    # if there is a class equal to the class by which to order, that one
    # moves to the top
    my ($i) = grep { $classes[$_] eq $class; } (0..@classes-1);
    if(defined($i)) {
	splice(@classes,$i,1);
	push(@sorted,$class);
    }
    # try to sort the rest
    my $aryname = "${class}::ISA"; # this is a soft reference
    # hence, allow soft refs
    no strict "refs";
    my @ancestors = @$aryname;
    # and disallow again
    use strict "refs";
    # now loop over all ancestors in the order they are in the list of
    # ancestors to sort the array
    foreach my $ancestor (@ancestors) {
	my @res = &_order_classes_by_inheritance($ancestor,@classes);
	if(@res) {
	    # remove those that are sorted and add to the list of sorted
	    push(@sorted,@res);
	    for($i = 0; $i < @res; $i++) {
		@classes = grep { $_ ne $res[$i]; } @classes;
	    }
	}
	last unless @classes > 0;
    }
    return @sorted;
}

=head2 association_table_name

 Title   : association_table_name
 Usage   :
 Function: Obtain the name of the table in the relational schema
           corresponding to the association of entities as represented
           by their corresponding class names, objects, or persistence
           adaptors.

           This implementation will use table_name() and the map
           returned by association_entity_map().

           This method will throw an exception if the association is
           not mapped (not to be confused with the association being
           unsupported).

 Example :
 Returns : the name of the table (a string, or undef if the association is not
           supported by the schema)
 Args    : A reference to an array of objects, class names, or persistence
           adaptors. The array may freely mix types.


=cut

sub association_table_name{
    my ($self,$objs) = @_;
    my ($tbl);

    # retrieve the map
    my $assocmap = $self->association_entity_map();
    # descend the tree as we encounter the objects
    foreach my $obj (@$objs) {
	$tbl = $self->table_name($obj);
	$assocmap = defined($tbl) ? $assocmap->{$tbl} : $tbl;
	last if(! ref($assocmap));
    }
    # not mapped?
    if(ref($assocmap)) {
	$self->throw("association table for classes (".
		     join(",",
			  map { ref($_) ?
				    ($_->isa("Bio::DB::PersistentObjectI") ?
				     ref($_->obj()) : ref($_)) :
				    $_;
			    } @$objs) .
		     ") not mapped");
    }
    # ended at a scalar (supposedly the table name)
    return $assocmap;
}

=head2 primary_key_name

 Title   : primary_key_name
 Usage   :
 Function: Obtain the name of the primary key attribute for the given table in
           the relational schema.

           This implementation just appends _id to the table name,
           which yields correct results for at least the MySQL version
           of the BioSQL schema. Override it for your own schema if
           necessary.

 Example :
 Returns : The name of the primary key (a string)
 Args    : The name of the table (a string)


=cut

sub primary_key_name{
    my ($self,$table) = @_;

    return $table."_id";
}

=head2 foreign_key_name

 Title   : foreign_key_name
 Usage   :
 Function: Obtain the foreign key name for referencing an object, as 
           represented by object, class name, or the persistence adaptor.
 Example :
 Returns : the name of the foreign key (a string)
 Args    : The referenced object, class name, or the persistence adaptor for
           it. 


=cut

sub foreign_key_name{
    my ($self,$obj) = @_;
    my ($table,$fk);

    # if the object is a persistent object and has the foreign_key_slot value
    # set, we start from there
    if(ref($obj) &&
       $obj->isa("Bio::DB::PersistentObjectI") &&
       $obj->foreign_key_slot()) {
	$obj = $obj->foreign_key_slot();
    }
    # default is to get the primary key of the respective table
    $table = $self->table_name($obj);
    if($table) {
	$fk = $self->_build_foreign_key_name($table);
    } elsif(! ref($obj)) {
	# If the object or class name didn't map to a table it may be due
	# to a context being provided as a slot of a class. To try this,
	# remove the last component, see whether the rest maps to a table,
	# and if so, look up the slot in its attribute map.
	my @comps = split(/::/, $obj);
	my $slot = pop(@comps);
	$table = $self->table_name(join("::",@comps));
	if($table) {
	    my $slotmap = $self->slot_attribute_map($table);
	    if($slotmap) {
		$fk = $slotmap->{$slot};
	    }
	}
    }
    return $fk;
}

=head2 _build_foreign_key_name

 Title   : _build_foreign_key_name
 Usage   :
 Function: Build the column name for a foreign key to the given table.

           The default implementation here retrieves the primary key
           for the given table.

           This is called by foreign_key_name() once it has determined
           the table name. If a particular driver wants to build the
           foreign key name in a specific or generally different way
           than the default implementation here, this is the method to
           override (unless you also want to change the way the table
           is determined; in that case you would override
           foreign_key_name()).

 Example :
 Returns : The name of the foreign key column as a string
 Args    : The table name as a string


=cut

sub _build_foreign_key_name{
    my $self = shift;
    my $table = shift;

    return $self->primary_key_name($table);
}

=head2 sequence_name

 Title   : sequence_name
 Usage   :
 Function: Returns the name of the primary key generator (SQL sequence)
           for the given table.

           The value returned is passed as the second argument to the
           L<Bio::DB:DBI>::last_id_value as implemented by the
           driver. Because the parameter is not required irregardless
           of driver, it is perfectly legal for this method to return
           undef. If the L<Bio::DB::DBI> driver does need this
           parameter, this method should be overridden by the matching
           adaptor driver.

           The default we assume here is we dont need this value.

 Example :
 Returns : the name of the sequence (a string)
 Args    : The name of the table.


=cut

sub sequence_name{
    return undef;
}

=head2 objrel_map

 Title   : objrel_map
 Usage   :
 Function: Get/set the object-relational map from classes to entities.
 Example :
 Returns : A reference to a hash map where object interfaces are the keys
 Args    : Optional, on set a reference to the respective hash map


=cut

sub objrel_map{
    my ($self, $value) = @_;

    if($value) {
	$self->{'_objrel_map'} = $value;
    }
    return $self->{'_objrel_map'};
}

=head2 slot_attribute_map

 Title   : slot_attribute_map
 Usage   :
 Function: Get/set the mapping for each entity from object slot names
           to column names.

 Example :
 Returns : A reference to a hash map with entity names being the keys,
           if no key (entity name, object, or adaptor) was
           provided. Otherwise, a hash reference with the slot names
           being keys to their corresponding column names.

 Args    : Optionally, the object, adaptor, or entity for which to
           obtain the map.

           Optionally, on set a reference to a hash map satisfying the
           features of the returned value.


=cut

sub slot_attribute_map{
    my ($self,$tablekey,$map) = @_;

    if($tablekey) {
	# this might actually be the overall map on set
	if((ref($tablekey) eq "HASH") && (! $map)) {
	    $map = $tablekey;
	    $tablekey = undef;
	    $self->{'_slot_attr_map'} = $map;
	} else {
	    # make sure the hash exists before we query it with a key
	    if(! exists($self->{'_slot_attr_map'})) {
		$self->{'_slot_attr_map'} = {};
	    }
	    # see whether we need to transform it into an entity name
	    if(ref($tablekey)) {
		$tablekey = $self->table_name($tablekey);
	    }
	    # set/get the individual map
	    if($map) {
		$self->{'_slot_attr_map'}->{$tablekey} = $map;
	    } else {
		$map = $self->{'_slot_attr_map'}->{$tablekey};
	    }
	}
    } else {
	# return the overall map
	$map = $self->{'_slot_attr_map'};
    }
    return $map;
}

=head2 not_select_attrs

 Title   : not_select_attrs
 Usage   : $obj->not_select_attrs($newval)
 Function: Get/set a map of all columns that should not be included in
           SELECT lists.
 Example : 
 Returns : value of not_select_attrs (a reference to a hash map)
 Args    : new value (a reference to a hash map, optional)


=cut

sub not_select_attrs{
    my ($self,$value) = @_;
    if( defined $value) {
	$self->{'not_select_attrs'} = $value;
    }
    return $self->{'not_select_attrs'};
}

=head2 association_entity_map

 Title   : association_entity_map
 Usage   : $obj->association_entity_map($newval)
 Function: Get/set the association entity map. The map is an anonymous
           hash with entities that participate in associations being
           keys. The values are hash refs themselves, with the other
           participating entity being the key, and the value being
           either the name of the respective association entity, or
           another hash ref with the same structure if more entities
           participate in the association.

           The hash map must be commutative. I.e., the association
           entity must be locatable irregardless with which of the
           participating entities one starts.

 Example : 
 Returns : value of association_entity_map (a hash ref of hash refs)
 Args    : new value (a hash ref of hash refs, optional)


=cut

sub association_entity_map{
    my ($self,$value) = @_;
    if( defined $value) {
	$self->{'association_entity_map'} = $value;
    }
    return $self->{'association_entity_map'};
}

=head1 DBI calls for possible interception

These will usually delegate straightforward DBI calls on the supplied
handle, but can also be used by an inheriting adaptor driver to
intercept the call and add additional parameters, for example a hash
reference with named parameters.

=cut

=head2 commit

 Title   : commit
 Usage   :
 Function: Commits the current transaction, if the underlying driver
           supports transactions.
 Example :
 Returns : TRUE
 Args    : The database connection handle for which to commit.


=cut

sub commit{
    my ($self, $dbh) = @_;
    return $dbh->commit();
}

=head2 rollback

 Title   : rollback
 Usage   :
 Function: Triggers a rollback of the current transaction, if the
           underlying driver supports transactions.
 Example :
 Returns : TRUE
 Args    : The database connection for which to rollback.


=cut

sub rollback{
    my ($self, $dbh) = @_;
    return $dbh->rollback();
}

=head2 bind_param

 Title   : bind_param
 Usage   :
 Function: Binds a parameter value to a prepared statement.

           The reason this method is here is to give RDBMS-specific
           drivers a chance to intercept the parameter binding and
           perform additional actions, or add additional parameters to
           the call, like data type. Certain drivers need to be helped
           for certain types, for example DBD::Oracle for LOB
           parameters.

 Example :
 Returns : the return value of the DBI::bind_param() call
 Args    : the DBI statement handle to bind to
           the index of the column
           the value to bind
           additional arguments to be passed to the sth->bind_param call


=cut

sub bind_param{
    my ($self,$sth,$i,$val,@bindargs) = @_;
    
    return $sth->bind_param($i,$val,@bindargs);
}

=head2 prepare

 Title   : prepare
 Usage   :
 Function: Prepares a SQL statement and returns a statement handle.

           The reason this method is here is the same as for
           bind_param.

 Example :
 Returns : the return value of the DBI::prepare() call
 Args    : the DBI database handle for preparing the statement
           the SQL statement to prepare (a scalar)
           additional arguments to be passed to the dbh->prepare call


=cut

sub prepare{
    my ($self,$dbh,$sql,@args) = @_;
    
    return $dbh->prepare($sql,@args);
}

=head1 Utility methods

=cut

=head2 report_execute_failure

 Title   : report_execute_failure
 Usage   :
 Function: Report the failure to execute a SQL statement.

           The reporting by default uses warn() but may be requested
           to throw().

 Example : 
 Returns : 
 Args    : Named paramaters. Currently recognized are
           -sth     the statement handle whose execution failed
           -adaptor the calling adaptor 
                    (a Bio::DB::PersistenceAdaptorI object)
           -op      the type of operation that failed ('insert',
                    'update',...)
           -vals    a reference to an array of values that were bound
           -fkobjs  a reference to an array of foreign key objects
                    that were bound (optional)
           -report_func the name of the method to call for reporting
                    the message (optional, default is 'warn')


=cut

sub report_execute_failure{
    my $self = shift;
    my ($sth,$adp,$op,$slotvals,$fkobjs,$reportfunc) =
	$self->_rearrange([qw(STH
			      ADAPTOR
			      OP
			      VALS
			      FKOBJS
			      REPORT_FUNC
			      )], @_);

    $reportfunc = "warn" unless $reportfunc;
    my $msg = "$op in ".ref($adp)." (driver) failed, values were (\"".
	join("\",\"",@$slotvals)."\")";
    if($fkobjs) {
	$msg .= " FKs (" . join(",", map { 
	    $_ && ref($_) ? $_->primary_key() : "<NULL>";
	} @$fkobjs) . ")";
    }
    $self->$reportfunc("$msg\n".$sth->errstr);
}

1;
