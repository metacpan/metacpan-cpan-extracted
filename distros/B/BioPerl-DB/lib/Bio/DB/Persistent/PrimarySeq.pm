# $Id$
#
# BioPerl module for Bio::DB::Persistent::PrimarySeq
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

Bio::DB::Persistent::PrimarySeq - Proxy object for database PrimarySeq 
                                  representations 

=head1 SYNOPSIS

Give standard usage here

=head1 DESCRIPTION

This is a proxy object which will ferry calls to/from database for the
heavy stuff (sequence data) while it stores the simple attributes in
memory.  This object is obtained from a DBAdaptor.


=head1 FEEDBACK

=head2 Mailing Lists

User feedback is an integral part of the evolution of this and other
Bioperl modules. Send your comments and suggestions preferably to one
of the Bioperl mailing lists.  Your participation is much appreciated.

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
the bugs and their resolution.  Bug reports can be submitted via email
or the web:

  bioperl-bugs@bio.perl.org
  http://redmine.open-bio.org/projects/bioperl/

=head1 AUTHOR - Hilmar Lapp, Ewan Birney

Email hlapp at gmx.net
Based in idea largely on Bio::DB::PrimarySeq by Ewan Birney.

Describe contact details here

=head1 APPENDIX

The rest of the documentation details each of the object methods. Internal methods are usually preceded with a _

=cut


# Let the code begin...


package Bio::DB::Persistent::PrimarySeq;
use vars qw(@ISA);
use strict;

use Bio::PrimarySeqI;
use Bio::DB::Persistent::PersistentObject;

@ISA = qw(Bio::DB::Persistent::PersistentObject);


sub new {
    my ($class,@args) = @_;

    my $self = $class->SUPER::new(@args);

    my $has_seq = $self->obj()->seq() ? 1 : 0;
    # initially, the seq is always `dirty'
    $self->seq_has_changed($has_seq);
    $self->_seq_is_fetched(0);

    # success - we hope
    return $self;
}

=head2 seq

 Title   : seq
 Usage   :
 Function: Overridden from Bio::PrimarySeq::seq to allow for lazy loading.
 Example :
 Returns : 
 Args    :


=cut

sub seq{
    my $self = shift;
    my $value;

    # We do cache sequences, as fetching them is potentially quite expensive.
    if(@_) {
	# we allow set
	$value = $self->obj()->seq(@_);
	$self->seq_has_changed(1);
	# we don't need to fetch any more
	$self->_seq_is_fetched(1);
	$self->is_dirty(1);
    } else {
	# does the object have it pre-set?
        $value = $self->obj()->seq();
	if((! $value) &&
	   (! $self->_seq_is_fetched()) && $self->primary_key()) {
	    # no, but we can retrieve it from the datastore (and we
	    # haven't done so yet)
	    $value = $self->adaptor()->get_biosequence($self->primary_key());
	    $self->obj()->seq($value) if defined($value) || $self->alphabet();
	    $self->seq_has_changed(0);
	    # we only fetch once -- if sequences change frequently in the
	    # datastore, this will disconnect us from that
	    $self->_seq_is_fetched(1);
	}
    }
    return $value;
}

=head2 subseq

 Title   : subseq
 Usage   :
 Function: Overridden from Bio::PrimarySeq::subseq to allow for intelligent
           database queries or delegation to the sequence object.
 Example :
 Returns : 
 Args    :


=cut

sub subseq{
    my ($self,$start,$end,$replace) = @_;

    if($self->_seq_is_fetched() ||
       defined($self->obj()->seq()) || (! $self->primary_key())) {
	# the sequence or its latest version is in the object or we don't know
	# yet how to find ourselves in the database -- delegate the call
	$self->seq_has_changed(1) if $replace;
	return $self->obj()->subseq($start,$end,$replace);
    } elsif(ref($start) && $start->isa("Bio::LocationI")) {
	# recursively call for every sublocation
	my $loc = $start;
	$replace = $end; # do we really use this anywhere? scary. HL
	my $seq = "";
	foreach my $subloc ($loc->each_Location()) {
	    my $piece = $self->subseq($subloc->start(),
				      $subloc->end(), $replace);
	    if($subloc->strand() < 0) {
		$piece = Bio::PrimarySeq->new('-seq'=>$piece)->revcom()->seq();
	    }
	    $seq .= $piece;
	}
	return $seq;
    } else {
	if($replace) {
	    $self->throw("replacing (with [$replace]) in subseq not supported".
			 " in datastore connection");
	}
	return $self->adaptor()->get_biosequence($self->primary_key(),
						 $start, $end);
    }
}

=head2 seq_has_changed

 Title   : seq_has_changed
 Usage   : $obj->seq_has_changed($newval)
 Function: 
 Example : 
 Returns : TRUE or FALSE
 Args    : new value (TRUE or FALSE, optional)


=cut

sub seq_has_changed{
    my ($self,$value) = @_;
    if( defined $value) {
	$self->{'_seq_has_changed'} = $value;
    }
    return $self->{'_seq_has_changed'};
}

=head2 _seq_is_fetched

 Title   : _seq_is_fetched
 Usage   : $obj->_seq_is_fetched($newval)
 Function: 
 Example : 
 Returns : TRUE or FALSE
 Args    : new value (TRUE or FALSE, optional)


=cut

sub _seq_is_fetched{
    my ($self,$value) = @_;
    if( defined $value) {
	$self->{'_seq_is_fetched'} = $value;
    }
    return $self->{'_seq_is_fetched'};
}

1;
