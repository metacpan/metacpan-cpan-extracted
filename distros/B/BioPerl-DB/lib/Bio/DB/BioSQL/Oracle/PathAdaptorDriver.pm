# $Id$
#
# BioPerl module for Bio::DB::BioSQL::Oracle::PathAdaptorDriver
#
# Please direct questions and support issues to <bioperl-l@bioperl.org> 
#
# Cared for by Hilmar Lapp <hlapp at gmx.net>
#
# Copyright Hilmar Lapp
#

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

Bio::DB::BioSQL::Oracle::PathAdaptorDriver - DESCRIPTION of Object

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


package Bio::DB::BioSQL::Oracle::PathAdaptorDriver;
use vars qw(@ISA);
use strict;

# Object preamble - inherits from Bio::Root::Root

use Bio::DB::BioSQL::Oracle::BasePersistenceAdaptorDriver;


@ISA = qw(Bio::DB::BioSQL::Oracle::BasePersistenceAdaptorDriver);


=head2 compute_transitive_closure

 Title   : compute_transitive_closure
 Usage   :
 Function: Compute the transitive closure over a given ontology
           and populate the respective path table in the relational
           schema.

 Example :
 Returns : TRUE on success, and FALSE otherwise
 Args    : The calling adaptor.

           The ontology to compute the transitive closure over (a
           persistent Bio::Ontology::OntologyI compliant object).

           The predicate indicating identity between a term and
           itself, to be used as the predicate for the paths of
           distance zero between a term and itself. If undef the zero
           distance paths will not be created.

           A scalar that if evaluating to TRUE means truncate the
           paths for the respective ontology first (optional;
           even though the default is FALSE this parameter should
           usually be given as TRUE unless you know what you are
           doing).


=cut

sub compute_transitive_closure{
    my ($self,$adp,$ont,$idpred,$trunc) = @_;
    
    # if we only got three arguments and the third is not a term then we
    # probably got called in the old signature
    if ((! ref($idpred)) && (@_ == 4)) {
        $trunc = $idpred;
        $idpred = undef;
    }

    # the ontology needs to be persistent (we'll need its primary key)
    if(! $ont->isa("Bio::DB::PersistentObjectI")) {
	$self->throw("Ontoogy $ont is not a persistent object. Bummer.");
    }
    # and obviously needs to have a primary key
    if(! ($ont->primary_key ||
	  ($ont = ($ont->adaptor->find_by_unique_key($ont) ||
                   $ont->adaptor->create($ont))))) {
	$self->throw("failed to look-up or insert ontology '".
		     $ont->name()."', can't continue without the foreign key");
    }

    # the identity predicate needs to be persistent too, if given 
    if (ref($idpred)) {
        if(! $idpred->isa("Bio::DB::PersistentObjectI")) {
            $idpred = $adp->db->create_persistent($idpred);
        }
        # and obviously needs to have a primary key as well
        if(! ($idpred->primary_key ||
              ($idpred = ($idpred->adaptor->find_by_unique_key($idpred) ||
                          $idpred->adaptor->create($idpred))))) {
            $self->throw("failed to look-up or insert ID predicate '".
                         $idpred->name()
                         ."', can't continue without the foreign key");
        }
    }

    # we'll need the name of the path table, and that of the relationship
    # table
    my $path_table = $self->table_name($adp);
    my $rel_table  = $self->table_name("Bio::Ontology::RelationshipI"); 
    # truncate existing path table content?
    if($trunc) {
	my $sth = $self->prepare_delete_query_sth($adp, -fkobjs => [$ont]);
	$adp->debug("DELETE $path_table: execute, binding column 1 to ".
		    $ont->primary_key().
		    " (PK to ".ref($ont->obj).")\n");
	my $rv = $sth->execute($ont->primary_key());
	if(! $rv) {
	    $self->throw("failed to execute DELETE $path_table statement ".
			 "(bound PK ".$ont->primary_key()."): ".
			 $sth->errstr);
	}
	$adp->debug("DELETE $path_table: deleted $rv rows\n");
    }
    # initialize the path table with all relationships under the ontology.
    #
    # for this we need to map a number of objects to foreign keys, so gather
    # keys, and obtain an attribute map
    my $termcl = "Bio::Ontology::TermI";
    my @fks = map {
	$self->foreign_key_name($_);
    } ($termcl."::subject", $termcl."::predicate", $termcl."::object", $ont);
    my $colmap = $self->slot_attribute_map($path_table);

    # initialize with paths of distance zero between all non-predicate
    # terms and themselves if the identity predicate was provided
    if (ref($idpred)) {
        my $term_table = $self->table_name($termcl);
        my $pkname = $self->primary_key_name($term_table);
        my $ontfkname = $self->foreign_key_name($ont);
        my $sql = "INSERT INTO $path_table ("
            . join(", ", @fks, $colmap->{"distance"}).")\n"
            . "SELECT $pkname, ".$idpred->primary_key
            . ", $pkname, $ontfkname, 0\n"
            . "FROM $term_table t WHERE $ontfkname = ?\n"
            . "AND NOT EXISTS (\n"
            . "SELECT 1 FROM $rel_table ta WHERE ta."
            . $self->foreign_key_name($termcl."::predicate")." = t.$pkname "
            . "AND ta.$ontfkname = t.$ontfkname)";
        $adp->debug("INSERT TC ONTOLOGY #0: preparing: $sql\n");
        my $sth = $adp->dbh->prepare($sql);
        $self->throw("failed to prepare statement ($sql): ".$adp->dbh->errstr)
            unless $sth;
        $adp->debug("INSERT TC ONTOLOGY #0: executing: binding column 1 to ",
                    $ont->primary_key(),
                    " (FK to ".ref($ont->obj).")\n");
        my $rv = $sth->execute($ont->primary_key());
        if($rv) {
            $adp->debug("INSERT TC ONTOLOGY #0: $rv rows inserted\n");
        } else {
            $self->throw("failed to execute statement ($sql) with parameter ".
                         $ont->primary_key()." (FK to ".ref($ont->obj)."): ".
                         $sth->errstr);
        }
    }

    # now the distance one paths as the relationships in the
    # Term_Relationship table
    my $sql = "INSERT INTO $path_table (".
	join(", ", @fks, $colmap->{"distance"}).")\n".
	"SELECT ".
	join(", ", @fks, "1")."\n".
	"FROM $rel_table WHERE ".$self->foreign_key_name($ont)." = ?";
    $adp->debug("INSERT TC ONTOLOGY #1: preparing: $sql\n");
    my $sth = $adp->dbh->prepare($sql);
    $self->throw("failed to prepare statement ($sql): ".$adp->dbh->errstr)
	unless $sth;
    $adp->debug("INSERT TC ONTOLOGY #1: executing: binding column 1 to ",
		$ont->primary_key(),
		" (FK to ".ref($ont->obj).")\n");
    my $rv = $sth->execute($ont->primary_key());
    if($rv) {
	$adp->debug("INSERT TC ONTOLOGY #1: $rv rows inserted\n");
    } else {
	$self->throw("failed to execute statement ($sql) with parameter ".
		     $ont->primary_key()." (FK to ".ref($ont->obj)."): ".
		     $sth->errstr);
    }
    # now build the transitive closure in a loop
    $sql = "INSERT INTO $path_table (".
	join(", ", @fks, $colmap->{"distance"}).")\n".
	"SELECT DISTINCT ".
	join(", ",
	     "tr.".$colmap->{"subject"}, "trp1.".$colmap->{"object"},
	     "tp.".$colmap->{"object"}, "tr.".$colmap->{"ontology"},
	     "tp.".$colmap->{"distance"}."+1")."\n".
	"FROM ".
	join(", ",
	     "$rel_table tr", "$path_table tp",
	     "$rel_table trp1", "$rel_table trp2")."\n".
	"WHERE ".
	join("\nAND ",
	     "tp.".$colmap->{"ontology"}." = tr.".$colmap->{"ontology"},
	     "tr.".$colmap->{"object"}." = tp.".$colmap->{"subject"},
	     "tr.".$colmap->{"ontology"}." = ?",
	     "tp.".$colmap->{"distance"}." = ?",
	     "trp1.".$colmap->{"subject"}." = tp.".$colmap->{"predicate"},
	     "trp2.".$colmap->{"subject"}." = tr.".$colmap->{"predicate"},
	     "trp1.".$colmap->{"object"}." = trp2.".$colmap->{"object"});
    $adp->debug("INSERT TC ONTOLOGY #2: preparing: $sql\n");
    $sth = $adp->dbh->prepare($sql);
    $self->throw("failed to prepare statement ($sql): ".$adp->dbh->errstr)
	unless $sth;
    my $dist = 0;
    $rv = 1; # dummy value in order to enter the while loop at least once
    while($rv && ($rv > 0)) {
	$dist++;
	if($adp->verbose) {
	    $adp->debug("INSERT TC ONTOLOGY #2: executing: ".
			"binding columns (".
			join(";", "FK to ".ref($ont->obj), "distance").
			") to (".
			join(";", $ont->primary_key(), $dist).
			")\n");
	}
	$rv = $sth->execute($ont->primary_key(), $dist);
	$adp->debug("INSERT TC ONTOLOGY #2: $rv rows inserted\n")
	    if $rv;
    }
    if(! $rv) {
	$self->throw("failed to execute statement ($sql) with parameters (".
		     join(";", $ont->primary_key(), $dist).
		     "): ".$sth->errstr);
    }
    # done.
    return $rv;
}

1;
