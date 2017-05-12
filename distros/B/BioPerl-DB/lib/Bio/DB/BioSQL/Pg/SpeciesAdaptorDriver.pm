# $Id$
#
# BioPerl module for Bio::DB::BioSQL::Pg::SpeciesAdaptorDriver
#
# Please direct questions and support issues to <bioperl-l@bioperl.org> 
#
# Cared for by Hilmar Lapp <hlapp at gmx.net>
#
# Copyright Hilmar Lapp
#
# You may distribute this module under the same terms as perl itself

#
# (c) Hilmar Lapp, hlapp at gmx.net, 2003.
# (c) GNF, Genomics Institute of the Novartis Research Foundation, 2003.
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

Bio::DB::BioSQL::Pg::SpeciesAdaptorDriver - DESCRIPTION of Object

=head1 SYNOPSIS

    #

=head1 DESCRIPTION

 This is basically a copy-and-paste job from the mysql-specific file
 of the very same name.

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


package Bio::DB::BioSQL::Pg::SpeciesAdaptorDriver;
use vars qw(@ISA);
use strict;

# Object preamble - inherits from BasePersistenceAdaptorDriver

use Bio::DB::BioSQL::Pg::BasePersistenceAdaptorDriver;

@ISA = qw(Bio::DB::BioSQL::Pg::BasePersistenceAdaptorDriver);


=head2 new

 Title   : new
 Usage   : my $obj = Bio::DB::BioSQL::Pg::SpeciesAdaptorDriver->new();
 Function: Builds a new Bio::DB::BioSQL::Pg::SpeciesAdaptorDriver object 
 Returns : an instance of Bio::DB::BioSQL::Pg::SpeciesAdaptorDriver
 Args    :


=cut

sub new {
    my($class,@args) = @_;

    my $self = $class->SUPER::new(@args);

    return $self;
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
           The name class for the taxon name table (default is
           'scientific name').


=cut

sub prepare_findbypk_sth{
    my ($self,$adp,$fkslots,$nameclass) = @_;

    # defaults
    $nameclass = "scientific name" unless $nameclass;
    # get table name and the primary key name
    my $table = $self->table_name($adp);
    my $node_table = $self->table_name("TaxonNode");
    my $pkname = $self->primary_key_name($table);
    my $fkname = $self->foreign_key_name("TaxonNode");
    my $slotmap = $self->slot_attribute_map($table);
    # gather attributes
    my @attrs = $self->_build_select_list($adp,$fkslots);
    # create the sql statement
    my $sql = "SELECT " .
	join(", ", @attrs) .
	" FROM $node_table, $table".
	" WHERE".
	" $node_table.$pkname = $table.$fkname".
	" AND $table.".$slotmap->{"name_class"}." = '$nameclass'".
	" AND $node_table.$pkname = ?";
    $adp->debug("preparing PK select statement: $sql\n");
    # prepare statement and return
    return $adp->dbh()->prepare($sql);
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

    # get the slot/attribute map
    my $table = $self->table_name($adp);
    my $node_table = $self->table_name("TaxonNode");
    my $pkname = $self->primary_key_name($node_table);
    my $fkname = $self->foreign_key_name("TaxonNode");
    my $slotmap = $self->slot_attribute_map($table);
    # SELECT columns
    my @attrs = $self->_build_select_list($adp,$fkslots);
    # WHERE clause constraints
    my @cattrs = ();
    foreach (keys %$ukval_h) {
	my $col;
	if(exists($slotmap->{$_})) {
	    $col = $slotmap->{$_};
	}
	push(@cattrs, $col || "NULL");
	$self->warn("slot $_ is in unique key, but can't be mapped to ".
		    "an entity column: you won't find anything")
	    unless $col;
    }
    # create the sql statement
    my $sql = "SELECT " . join(", ", @attrs) .
	" FROM $node_table, $table".
	" WHERE $node_table.$pkname = $table.$fkname AND ".
	join(" AND ", map { "$_ = ?"; } @cattrs);
    $adp->debug("preparing UK select statement: $sql\n");
    # prepare statement and return
    return $adp->dbh()->prepare($sql);
}

=head2 prepare_delete_sth

 Title   : prepare_delete_sth
 Usage   :
 Function: Creates a prepared statement with one placeholder variable suitable
           to delete one row from the respective table the given class maps to.

           We override this here in order to delete from the taxon
           node table, not the taxon name table. The node table will
           cascade to the name table.

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
    my $tbl = $self->table_name("TaxonNode");
    my $pkname = $self->primary_key_name($tbl);
    # straightforward SQL:
    my $sql = "DELETE FROM $tbl WHERE $pkname = ?";
    $adp->debug("preparing DELETE statement: $sql\n");
    my $sth = $adp->dbh()->prepare($sql);
    # done
    return $sth;
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
    
    # get the INSERT statements: we need one for the taxon node and one for
    # the taxon name table
    my $cache_key_t = 'INSERT taxon '.ref($obj);
    my $cache_key_tn = 'INSERT taxname '.ref($obj);
    my $sth_t = $adp->sth($cache_key_t);
    my $sth_tn = $adp->sth($cache_key_tn);
    my $sth_max = $adp->sth("SELECT MAX TAXON SETID");
    # we need the slot map regardless of whether we need to construct the
    # SQL or not, because we need to know which slots do not map to a column
    # (indicated by them being mapped to undef)
    my $table = $self->table_name($adp);
    my $node_table = $self->table_name("TaxonNode");
    my $fkname = $self->foreign_key_name("TaxonNode");
    my $slotmap = $self->slot_attribute_map($table);
    $self->throw("no slot/attribute map for table $table") unless $slotmap;
    # we'll need the db handle in any case
    my $dbh = $adp->dbh();
    # if not cached, create SQL and prepare statement
    if(! $sth_tn) {
	# Prepare the taxon insert statement first. There is really not a
	# lot room for being generic here. Also, I'm afraid we need to mandate
	# that there is a column mapping to ncbi_taxid, parent, and node rank.
	my $sql = "INSERT INTO $node_table (".
	    join(", ",($slotmap->{"parent_taxon"},
		       $slotmap->{"ncbi_taxid"},
		       $slotmap->{"node_rank"},
		       "left_value","right_value")).
	    ") VALUES (?, ?, ?, ?, ?)";
	$adp->debug("preparing INSERT taxon: $sql\n");
	$sth_t = $dbh->prepare($sql);
	$adp->sth($cache_key_t, $sth_t);
	# now prepare the taxon_name insert statement
	my @attrs = ($fkname,
		     $slotmap->{"binomial"},
		     $slotmap->{"name_class"});
	$sql = "INSERT INTO " . $table . " (" . join(", ", @attrs) .
	    ") VALUES (?, ?, ?)";
	$adp->debug("preparing INSERT taxon_name statement: $sql\n");
	$sth_tn = $dbh->prepare($sql);
	# and cache
	$adp->sth($cache_key_tn, $sth_tn);
    }
    # prepare the classification tree: we may have subspecies and variant
    my @clf = map { [$_,undef]; } $obj->classification();
    # the only thing that's hopefully relatively reliable is that species
    # and genus are the first two elements
    $clf[0]->[1] = "species";
    $clf[1]->[1] = "genus";
    # also, convention is species to equal the binomial, not just first name
    $clf[0]->[0] = $obj->binomial();
    # sub-species and variant are to be prepended, also as full names
    if($obj->sub_species) {
	unshift(@clf, [$obj->binomial() ." ". $obj->sub_species(),
		       "subspecies"]);
    }
    if($obj->variant) {
	# note that this is not guaranteed to be the "varietas" rank: it
	# might also be a strain for instance
	unshift(@clf, [$obj->binomial() ." ". $obj->variant(), "no rank"]);
    }
    # the most specific rank gets the NCBI taxon ID assigned (if provided)
    my $taxid_rank = $clf[0]->[1];
    # reverse the whole thing before proceeding (Bio::Species stores the
    # classification array in reverse order)
    @clf = reverse(@clf);
    # to avoid unique key clashes, we need to know the largest existing
    # number
    my $sth = $dbh->prepare("SELECT max(right_value) FROM $node_table");
    $sth->execute() || return undef;
    my ($maxsetid) = $sth->fetchrow_array() || (0);
    my $setid = $maxsetid+1;
    # for each element in the array store node and name
    my ($pk,$rv);
    foreach my $node (@clf) {
	# set ncbi taxon id
	my $ncbi_taxid = defined($node->[1]) && ($node->[1] eq $taxid_rank) ?
	    $obj->ncbi_taxid : undef;
	# log and insert
	if($adp->verbose > 0) {
	    $adp->debug(substr(ref($adp),rindex(ref($adp),"::")+2).
			"::insert: ".
			"binding columns 1;2;3;4;5 to \"",
			join(";",
			     $pk || "<NULL>",
			     $ncbi_taxid || "<NULL>", $node->[1] || "<NULL>",
			     $setid,
			     2*($maxsetid+scalar(@clf))-$setid+1),
			"\" (parent_taxon,ncbi_taxid,node_rank,left,right)\n");
	}
	$rv = $sth_t->execute($pk,$ncbi_taxid,$node->[1],
			      $setid, 2*($maxsetid+scalar(@clf))-$setid+1);
	$setid++;
	last unless $rv;
	# we need the newly assigned primary key
	$pk = $adp->dbcontext->dbi->last_id_value($dbh,
					    $self->sequence_name($node_table));
	# now insert name of node into the taxon name table
	if($adp->verbose > 0) {
	    $adp->debug(substr(ref($adp),rindex(ref($adp),"::")+2).
			"::insert: ".
			"binding columns 1;2;3 to \"",
			join(";",$pk,$node->[0],"scientific name"),
			"\" ($fkname, name, name_class)\n");
	}
	$rv = $sth_tn->execute($pk, $node->[0], "scientific name");
	last unless $rv;
    }
    # upon exit the value of $pk is the primary key for the node that got
    # the NCBI taxon ID assigned - which is exactly what we need as the
    # foreign key of the species for subsequent reference

    # if defined insert common_name into the taxon name table
    if($rv && $obj->common_name) {
	if($adp->verbose > 0) {
	    $adp->debug(substr(ref($adp),rindex(ref($adp),"::")+2).
			"::insert: ".
			"binding columns 1;2;3 to \"",
			join(";",$pk,$obj->common_name,"common name"),
			"\" ($fkname, name, name_class)\n");
	}
	$rv = $sth_tn->execute($pk, $obj->common_name(), "common name");
    }
    # done, return
    return $rv ? $pk : undef;
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

    $self->throw_not_implemented();

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

    my @attrs = $self->SUPER::_build_select_list($adp,$fkobjs,$entitymap);
    # we need to massage the attribute list ...
    for(my $i = 0; $i < @attrs; $i++) {
	if($attrs[$i] =~ /ncbi_taxon_id/i) {
	    my $name_table = $self->table_name("Bio::Species");
	    my $node_table = $self->table_name("TaxonNode");
	    $attrs[$i] =~ s/$name_table/$node_table/;
	}
    }
    return @attrs;
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
 Args    : the calling adaptor, the primary key of the taxon


=cut

sub get_classification{
    my ($self,$adp,$pk) = @_;
    my @clf = ();

    # try to obtain statement handle from cache
    my $cache_key = "SELECT taxon classification";
    my $sth = $adp->sth($cache_key);
    if(! $sth) {
	# we need to build this one
	
	# get table names, primary and foreign key names, slot/attribute map
	my $name_table = $self->table_name($adp);
	my $node_table = $self->table_name("TaxonNode");
	my $pkname = $self->primary_key_name($node_table);
	my $fkname = $self->foreign_key_name("TaxonNode");
	my $slotmap = $self->slot_attribute_map($name_table);
	# we set up the sql without any fancy:
	my $sql =
	    "SELECT name.".$slotmap->{"binomial"}.
	    ", node.".$slotmap->{"node_rank"}.
	    " FROM $node_table node, $node_table taxon, $name_table name".
	    " WHERE name.$fkname = node.$pkname AND".
	    " taxon.left_value BETWEEN node.left_value AND node.right_value".
	    " AND taxon.$pkname = ?".
	    " AND name.".$slotmap->{"name_class"}." = 'scientific name'".
	    " ORDER BY node.left_value";
	$adp->debug("prepare SELECT CLASSIFICATION: $sql\n");
	# prepare the query
	$sth = $adp->dbh->prepare($sql);
	# and cache it
	$adp->sth($cache_key, $sth);
    }
    # execute with the given primary key
    my $rv = $sth->execute($pk);
    if($rv) {
	while(my $row = $sth->fetchrow_arrayref()) {
	    push(@clf, [@$row]);
	}
    }
    return \@clf;
}

=head2 get_common_name

 Title   : get_common_name
 Usage   :
 Function: Get the common name for a taxon as identified by its primary
           key.
 Example :
 Returns : a string denoting the common name
 Args    : the calling adaptor, and the primary key of the taxon


=cut

sub get_common_name{
    my ($self,$adp,$pk) = @_;

    # statement cached?
    my $cache_key = "SELECT COMMON_NAME ".ref($adp);
    my $sth = $adp->sth($cache_key);
    # if not cached we have to build it
    if(! $sth) {
	# get table names, primary and foreign key names, slot/attribute map
	my $name_table = $self->table_name($adp);
	my $fkname = $self->foreign_key_name("TaxonNode");
	my $slotmap = $self->slot_attribute_map($name_table);
	# prepare sql
	my $sql =
	    "SELECT $name_table.".$slotmap->{"binomial"}.
	    " FROM $name_table".
	    " WHERE $name_table.$fkname = ?".
	    " AND $name_table.".$slotmap->{"name_class"}." = 'common_name'";
	$adp->debug("preparing SELECT COMMON_NAME: ",$sql,"\n");
	$sth = $adp->dbh->prepare($sql);
	# and cache
	$adp->sth($cache_key, $sth);
    }
    my $rv = $sth->execute($pk);
    my $cname;
    if($rv) {
	while(my $row = $sth->fetchrow_arrayref()) {
	    # the last one overwrites
	    $cname = $row->[0];
	}
    }
    return $cname;
}

1;
