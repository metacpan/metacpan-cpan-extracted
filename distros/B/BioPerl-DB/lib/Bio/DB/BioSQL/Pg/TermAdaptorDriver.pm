# $Id$
#
# BioPerl module for Bio::DB::BioSQL::Pg::TermAdaptorDriver
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

Bio::DB::BioSQL::Pg::TermAdaptorDriver - DESCRIPTION of Object

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


package Bio::DB::BioSQL::Pg::TermAdaptorDriver;
use vars qw(@ISA);
use strict;

use Bio::DB::BioSQL::Pg::BasePersistenceAdaptorDriver;

@ISA = qw(Bio::DB::BioSQL::Pg::BasePersistenceAdaptorDriver);


=head2 remove_synonyms

 Title   : remove_synonyms
 Usage   :
 Function: Removes all synonyms for an ontology term.
 Example :
 Returns : TRUE on success, and FALSE otherwise.
 Args    : The calling persistence adaptor.

           The persistent term object for which to remove the synonyms
           (a Bio::DB::PersistentObjectI compliant object with defined
           primary key).


=cut

sub remove_synonyms{
    my ($self,$adp,$obj) = @_;

    # delete statement cached?
    my $cachekey = "DELETE SYNONYMS";
    my $sth = $adp->sth($cachekey);
    # if not we need to build it
    if(! $sth) {
	# we need table name and foreign key
	my $table = $self->table_name("TermSynonym");
	my $fkname = $self->foreign_key_name($obj->obj);
	# build, prepare, and cache the SQL statement
	$sth = $self->_build_sth($adp, $cachekey,
                                 "DELETE FROM $table WHERE $fkname = ?");
    }
    # bind parameters and execute insert
    my $dbgmsg = "executing with values (".
	$obj->primary_key().") (FK to ".ref($obj->obj).")";
    $adp->debug("$cachekey: $dbgmsg\n");
    my $rv = $sth->execute($obj->primary_key());
    if(! $rv) {
        $self->warn("failed to remove term synonyms (".ref($adp)
                    .") with values (".$obj->primary_key()
                    .") (FK to ".ref($obj->obj)."):\n".$sth->errstr());
    }
    return $rv;
}

=head2 store_synonym

 Title   : store_synonym
 Usage   :
 Function: Stores a synonym for an ontology term.
 Example :
 Returns : TRUE on success, and FALSE otherwise.
 Args    : The calling persistence adaptor.

           The persistent term object for which to store the synonym
           (a Bio::DB::PersistentObjectI compliant object with defined
           primary key).

           The synonym to store (a scalar). 


=cut

sub store_synonym{
    my ($self,$adp,$obj,$syn) = @_;

    # insert and look-up statements cached?
    my $icachekey = "INSERT SYNONYM";
    my $isth = $adp->sth($icachekey);
    # if not we need to build them
    if(! $isth) {
	# we need table name, foreign key, and slot map
	my $table = $self->table_name("TermSynonym");
	my $fkname = $self->foreign_key_name($obj->obj);
	my $colmap = $self->slot_attribute_map($table);
	# build, prepare, and cache the SQL statements
	$isth = $self->_build_sth($adp, $icachekey,
				  "INSERT INTO $table (".
				  join(", ", $colmap->{'synonym'}, $fkname).
				  ") VALUES (?, ?)");
    }
    # bind parameters and execute insert
    my $dbgmsg = "executing with values ($syn, ".
	$obj->primary_key().") (synonym, FK to ".ref($obj->obj).")";
    $adp->debug("$icachekey: $dbgmsg\n");
    my $rv = $isth->execute($syn, $obj->primary_key());
    # in PostgreSQL, the UK failure is caught through a rule already,
    # so if $rv evaluates to FALSE it must be the statement being bad
    if (! $rv) {
        $self->warn("failed to store term synonym (".ref($adp)
                    .") with values ($syn) (FK ".$obj->primary_key()
                    ." to ".ref($obj->obj)."):\n"
                    .$isth->errstr());
    }
    return $rv;
}

sub _build_sth{
    my ($self,$adp,$cachekey,$sql) = @_;
    # prepare and cache
    $adp->debug("$cachekey: preparing: $sql\n");
    my $sth = $adp->dbh->prepare($sql);
    $self->throw("failed to prepare \"$sql\": ".$adp->dbh->errstr)
	unless $sth;
    $adp->sth($cachekey,$sth);
    return $sth;
}

=head2 get_synonyms

 Title   : get_synonyms
 Usage   :
 Function: Retrieves the synonyms for an ontology term and adds them
           the term's synonyms.
 Example :
 Returns : TRUE on success, and FALSE otherwise.
 Args    : The calling persistence adaptor.

           The persistent term object for which to retrieve the
           synonyms (a Bio::DB::PersistentObjectI compliant object
           with defined primary key).


=cut

sub get_synonyms{
    my ($self,$adp,$obj) = @_;

    # insert and look-up statements cached?
    my $cachekey = "SELECT SYNONYMS";
    my $sth = $adp->sth($cachekey);
    # if not we need to build it
    if(! $sth) {
	# we need table name, foreign key, and slot map
	my $table = $self->table_name("TermSynonym");
	my $fkname = $self->foreign_key_name($obj->obj);
	my $colmap = $self->slot_attribute_map($table);
	# build, prepare, and cache the SQL statement
	$sth = $self->_build_sth($adp, $cachekey,
				 "SELECT ".$colmap->{'synonym'}.
				 " FROM $table WHERE $fkname = ?");
    }
    # bind parameters and execute select
    my $dbgmsg = "executing with values (".
	$obj->primary_key().") (FK to ".ref($obj->obj).")";
    $adp->debug("$cachekey: $dbgmsg\n");
    my $rv = $sth->execute($obj->primary_key());
    $self->warn("failed to execute $cachekey: ".$sth->errstr) unless $rv;
    while(my $row = $sth->fetchrow_arrayref()) {
	$obj->add_synonym($row->[0]);
    }
    return $rv;
}

1;
