# $Id$

#
# (c) Hilmar Lapp, hlapp at gnf.org, 2002.
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

=head1 NAME - BioSQL-base.pm

=head1 SYNOPSIS

    # synopsis goes here

=head1 DESCRIPTION

This modules provides methods to insert and remove the parent entities
needed by many (probably all) of the different tests for child
entities.

=head1 AUTHOR Hilmar Lapp 

Email hlapp at gnf.org

=cut

package BioSQLBase;

use lib 't';

use strict;
use vars qw(@ISA $VERSION);

use Bio::Root::Root;
use DBTestHarness;

@ISA = qw(Bio::Root::Root);

=head2 store_seq

 Title   : store_seq
 Usage   : $seq = $biosql->store_seq($stream, "rodent");
 Function: Reads the next sequence from the given Bio::SeqIO stream and
           stores it under the namespace given by 2nd argument.
 Returns : The sequence object that was stored, with the PK in
           $seq->primary_id(), and undef if there was no sequence in the stream
 Args    : SeqIO stream (object) and namespace (a string)

=cut

sub store_seq {
    my ($self, $seqio, $namespace) = @_;

    my $seq = $seqio->next_seq();
    return unless $seq;
    my $biodbadaptor = $self->db()->get_BioDatabaseAdaptor;
    my $bdbid = $biodbadaptor->fetch_by_name_store_if_needed($namespace);
    my $seqadaptor = $self->db()->get_SeqAdaptor;
    my $pk = $seqadaptor->store($bdbid, $seq);
    $seq->primary_id($pk);
    return $seq;
}

=head2 delete_seq

 Title   : delete_seq
 Usage   : $ok = $biosql->delete_seq($seq);
 Function: Deletes the given sequence from the database.
 Returns : True for success and false otherwise.
 Args    : A Bio::PrimarySeqI compliant object

=cut

sub delete_seq {
    my ($self, $seq) = @_;

    my $seqadaptor = $self->db()->get_SeqAdaptor;
    return $seqadaptor->remove_by_dbID($seq->primary_id());
}

=head2 delete_biodatabase

 Title   : delete_biodatabase
 Usage   : $ok = $biosql->delete_biodatabase($biodatabase);
 Function: Deletes the given biodatabase (namespace) from the database.
 Returns : True for success and false otherwise.
 Args    : namespace (a string)

=cut

sub delete_biodatabase {
    my ($self, $namespace) = @_;

    my $biodbadaptor = $self->db()->get_BioDatabaseAdaptor;
    return $biodbadaptor->remove_by_name($namespace);
}

=head2 db

 Title   : db
 Usage   : $dbadaptor = $biosql->db();
 Function: 
 Returns : The DBAdaptor object in use to wrap the BioSQL database.
 Args    : On set (optional), the DBAdaptor object to be used.

=cut

sub db {
    my ($self, $db) = @_;

    if($db) {
	$self->{'_db'} = $db;
    }
    if(! exists($self->{'_db'})) {
	$self->{'_db'} = $self->dbharness()->get_DBAdaptor(); # we cache this!
    }
    return $self->{'_db'};
}

=head2 dbharness

 Title   : dbharness
 Usage   : $dbharness = $biosql->dbharness();
 Function: 
 Returns : The DBTestHarness object in use.
 Args    : On set (optional), the DBTestHarness object to be used.

=cut

sub dbharness {
    my ($self, $dbharness) = @_;

    if($dbharness) {
	$self->{'_dbharness'} = $dbharness;
    }
    if(! exists($self->{'_dbharness'})) {
	$self->{'_dbharness'} = DBTestHarness->new("biosql");
    }
    return $self->{'_dbharness'};
}

1;

__END__

