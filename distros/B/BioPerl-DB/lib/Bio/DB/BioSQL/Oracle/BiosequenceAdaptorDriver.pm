# $Id$
#
# BioPerl module for Bio::DB::BioSQL::Oracle::BiosequenceAdaptorDriver
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

Bio::DB::BioSQL::Oracle::BiosequenceAdaptorDriver - DESCRIPTION of Object

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

Describe contact details here

=head1 CONTRIBUTORS

Additional contributors names and emails here

=head1 APPENDIX

The rest of the documentation details each of the object methods.
Internal methods are usually preceded with a _

=cut


# Let the code begin...


package Bio::DB::BioSQL::Oracle::BiosequenceAdaptorDriver;
use vars qw(@ISA);
use strict;

# Object preamble - inherits from Bio::Root::Root

use Bio::DB::BioSQL::Oracle::BasePersistenceAdaptorDriver;
use DBD::Oracle qw(:ora_types);

@ISA = qw(Bio::DB::BioSQL::Oracle::BasePersistenceAdaptorDriver);

# new() is inherited

=head2 insert_object

 Title   : insert_object
 Usage   :
 Function: We override this here in order to omit the insert if there are
           no values. This is because this entity basically represents a
           derived class, and we may simply be dealing with the base class.

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
    my $self = shift;
    my ($adp,$obj,$fkobjs,$isdef) = @_;
    
    # this may come precomputed from the update_object() method below
    if(!defined($isdef)) {
	# no, not precomputed
	# obtain the object's slot values to be serialized
	my $slotvals = $adp->get_persistent_slot_values($obj, $fkobjs);
	# any value present?
	foreach (@$slotvals) { $isdef ||= $_; last if $isdef; }
    }
    return $self->SUPER::insert_object(@_) if $isdef;
    return -1;
}

=head2 update_object

 Title   : update_object
 Usage   :
 Function: See parent class. We need to override this here because
           there is no Biosequence object separate from PrimarySeq
           that would hold a primary key. Hence, store()s cannot
           recognize when the Biosequence for a Bioentry already
           exists and needs to be updated, or when it needs to be
           created. The way the code is currently wired, the presence
           of the primary key (stemming from the bioentry) will always
           trigger an update.

           So, what we need to do here is check whether the entry already
           exists and if not delegate to insert_object().
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

    # see whether there are any values defined at all
    my $slotvals = $adp->get_persistent_slot_values($obj, $fkobjs);
    my $isdef = 0;
    foreach (@$slotvals) { $isdef ||= $_; last if $isdef; }
    # in the majority of cases this actually will be an update indeed - so
    # let's just go ahead and try if there are any values to update
    my $rv = -1;
    if($isdef) {
	$rv = $self->SUPER::update_object($adp,$obj,$fkobjs);
	# if the number of affected rows was zero, then it needs to be
	# an insert
	if($rv && ($rv == 0)) {
	    # pass on the pre-computed $isdef (see the implementation above)
	    $rv = $self->insert_object($adp,$obj,$fkobjs,$isdef);
	}
    }
    # done
    return $rv;
}

=head2 get_biosequence

 Title   : get_biosequence
 Usage   :
 Function: Returns the actual sequence for a bioentry, or a substring of it.
 Example :
 Returns : A string (the sequence or subsequence)
 Args    : The calling persistence adaptor.
           The primary key of the bioentry for which to obtain the sequence.
           Optionally, start and end position if only a subsequence is to be
           returned (for long sequences, obtaining the subsequence from the
           database may be much faster than obtaining it from the complete
           in-memory string, because the latter has to be retrieved first).


=cut

sub get_biosequence{
    my ($self,$adp,$bioentryid,$start,$end) = @_;
    my ($sth, $cache_key, $row);
    my $seqstr;

    if(defined($start)) {
	# statement cached?
	$cache_key = "SELECT BIOSEQ SUBSTR".$adp.(defined($end) ?" 2POS":"");
	$sth = $adp->sth($cache_key);
	if(! $sth) {
	    # we need to create this
	    my $table = $self->table_name($adp);
	    my $seqcol = $self->slot_attribute_map($table)->{"seq"};
	    if(! $seqcol) {
		$self->throw("no mapping for column seq in table $table");
	    }
	    my $ukname = $self->foreign_key_name("Bio::PrimarySeqI");
	    my $sql = "SELECT DBMS_LOB.SUBSTR($seqcol, ";
	    if(defined($end)) {
		$sql .= "?, ?";
	    } else {
		$sql .= "DBMS_LOB.GETLENGTH($seqcol) - ?, ?";
	    }
	    $sql .= ") FROM $table WHERE $ukname = ?";
	    $adp->debug("preparing SELECT statement: $sql\n");
	    $sth = $adp->dbh()->prepare($sql);
	    # and cache it
	    $adp->sth($cache_key, $sth);
	}
	# bind parameters
	if(defined($end)) {
	    $sth->bind_param(1, $end-$start+1);
	} else {
	    $sth->bind_param(1, $start-1);
	}
	$sth->bind_param(2, $start);
	$sth->bind_param(3, $bioentryid);
    } else {
	# statement cached?
	$cache_key = "SELECT BIOSEQ ".$adp;
	$sth = $adp->sth($cache_key);
	if(! $sth) {
	    # we need to create this
	    my $table = $self->table_name($adp);
	    my $seqcol = $self->slot_attribute_map($table)->{"seq"};
	    if(! $seqcol) {
		$self->throw("no mapping for column seq in table $table");
	    }
	    my $ukname = $self->foreign_key_name("Bio::PrimarySeqI");
	    my $sql = "SELECT $seqcol FROM $table WHERE $ukname = ?";
	    $adp->debug("preparing SELECT statement: $sql\n");
	    $sth = $adp->dbh()->prepare($sql);
	    # and cache it
	    $adp->sth($cache_key, $sth);
	}
	# bind parameters
	$sth->bind_param(1, $bioentryid);
    }
    # execute and fetch
    if (! $sth->execute()) {
        $self->throw("error while executing query $cache_key with values ("
                     .(defined($start) ? "$start;" : "")
                     .(defined($end) ? ($end-$start+1).";" : "")
                     .$bioentryid."):\n"
                     .$sth->errstr." (".$sth->state.")");
    }
    $row = $sth->fetchall_arrayref();
    return (@$row ? $row->[0]->[0] : undef);
}

=head2 prepare

 Title   : prepare
 Usage   :
 Function: Prepares a SQL statement and returns a statement handle.

           We override this here in order to intercept the row update
           statement. We'll edit the statement to replace the table
           name with the fully qualified table the former points to if
           it is in fact a synonym, not a real table. The reason is
           that otherwise LOB support doesn't work properly if the LOB
           parameter is wrapped in a call to NVL() (which it is) and
           the table is only a synonym, not a physical table.

 Example :
 Returns : the return value of the DBI::prepare() call
 Args    : the DBI database handle for preparing the statement
           the SQL statement to prepare (a scalar)
           additional arguments to be passed to the dbh->prepare call


=cut

sub prepare{
    my ($self,$dbh,$sql,@args) = @_;
    
    # we need to intercept the 'UPDATE biosequence' or whatever the table
    # is called here, so in order not to hardcode the table name let's
    # ask for it
    my $table = uc($self->table_name("Bio::DB::BioSQL::BiosequenceAdaptor"));
    # now is it the UPDATE we're interested in messing with?
    if($sql =~ /^update\s+$table/i) {
	# yes it is.
	#
	# copy the sql and edit to remove the NVL() for the SEQ column
	my $sql2 = $sql;
	$sql2 =~ s/seq\s+=\s+nvl\(\s*\?\s*,\s*seq\s*\)/seq = \?/i;
        # In the third version we edit away the NVL clause and replace
        # it with a CONCAT clause. This is to be used if the parameter
        # is NULL; concatenating NULL to an existing CLOB doesn't
        # change it, and the return type of CONCAT preserves the type
        # of the first argument.
        my $sql3 = $sql;
        $sql3 =~ s/seq\s+=\s+nvl\(\s*\?\s*,\s*seq\s*\)/seq = CONCAT(seq, \?)/i;
        # prepare both and cache for later use
        $self->debug("first alternative UPDATE biosequence: $sql2\n");
        $self->debug("second alternative UPDATE biosequence: $sql3\n");
	$self->_upd_sth2($dbh->prepare($sql2));
	$self->_upd_sth3($dbh->prepare($sql3));
    }
    return $dbh->prepare($sql,@args);
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
    my ($sth,$meth);

    # check whether we have to return the statement here for the edited
    # update statement
    if ($op eq "update_object") {
        my $vals = $adp->get_persistent_slot_values($obj, $fkobjs);
        my @cols = $adp->get_persistent_slots($obj, $fkobjs);
        # we need both (new) seq(uence) and (original) length in
        # order to determine whether either old or new sequence is
        # longer than 4000 chars
        my @i = 0..(scalar(@cols)-1);
        my ($i_l) = grep { $cols[$_] eq "length"; } @i;
        my ($i_s) = grep { $cols[$_] eq "seq"; } @i;
        if (defined($vals->[$i_s]) && (length($vals->[$i_s]) > 4000)) {
            $key .= " clob-compat";
            $meth = "_upd_sth2";
            $adp->debug("UPDATE biosequence: using first alternative\n");
        } elsif ((!defined($vals->[$i_s])) && ($vals->[$i_l] > 4000)) {
            $key .= " clob-compat2";
            $meth = "_upd_sth3";
            $adp->debug("UPDATE biosequence: using second alternative\n");
        }
    }
    $sth = $adp->sth($key);
    $sth = $adp->sth($key, $self->$meth) unless $sth || !defined($meth);
    return $sth;
}

=head2 _upd_sth2

 Title   : _upd_sth2
 Usage   : $obj->_upd_sth2($newval)
 Function: Get/set the second version of the update row statement
           as a prepared statement handle.

           The 'second version' differs from the default in that the
           set parameter for the SEQ column is not wrapped in a NVL()
           call. This is needed to make it work for LOB values (values
           longer than 4000 chars). However, this statement should
           only be executed if the value is defined in order to
           prevent unwanted un-sets of the value in the database.

           This is a private method. Do not use from outside.

 Example : 
 Returns : value of _upd_sth2 (a DBI statement handle)
 Args    : on set, new value (a DBI statement handle or undef, optional)


=cut

sub _upd_sth2{
    my $self = shift;

    return $self->{'_upd_sth2'} = shift if @_;
    return $self->{'_upd_sth2'};
}

=head2 _upd_sth3

 Title   : _upd_sth3
 Usage   : $obj->_upd_sth3($newval)
 Function: Get/set the third version of the update row statement
           as a prepared statement handle.

           The 'third version' differs from the default in that the
           parameter for the SEQ column is not used for updating at
           all, but instead is placed into the WHERE-section as a
           dummy clause that always evaluates to true. This is needed
           to protect existing LOB values longer than 4000 chars from
           being updated to NULL, due to a bug in NVL().

           This is a private method. Do not use from outside.

 Example : 
 Returns : value of _upd_sth3 (a DBI statement handle)
 Args    : on set, new value (a DBI statement handle or undef, optional)


=cut

sub _upd_sth3{
    my $self = shift;

    return $self->{'_upd_sth3'} = shift if @_;
    return $self->{'_upd_sth3'};
}

1;
