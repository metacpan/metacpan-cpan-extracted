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
  http://bio.perl.org/bioperl-bugs/

=head1 AUTHOR - Hilmar Lapp, Ewan Birney

Email hlapp at gmx.net
Based in idea largely on Bio::DB::Seq by Ewan Birney.

Describe contact details here

=head1 APPENDIX

The rest of the documentation details each of the object methods. Internal methods are usually preceded with a _

=cut


# Let the code begin...


package Bio::DB::Persistent::Seq;
use vars qw(@ISA);
use strict;

use Bio::SeqI;
use Bio::DB::Persistent::PrimarySeq;

@ISA = qw(Bio::DB::Persistent::PrimarySeq);


sub new {
    my ($class,@args) = @_;

    my $self = $class->SUPER::new(@args);

    # success - we hope
    return $self;
}

=head1 Overridden methods

=cut

=head2 primary_key

 Title   : primary_key
 Usage   : $obj->primary_key($newval)
 Function: Get/set the primary key value.

           We override this here from PersistentObjectI in order to
           propagate the primary key to a possibly attached PrimarySeq
           object if PrimarySeqI is implemented by composition.

 Example : 
 Returns : value of primary_key (a scalar)
 Args    : new value (a scalar, optional)


=cut

sub primary_key{
    my ($self,@args) = @_;

    if(@args && $self->obj() && $self->obj()->can('primary_seq')) {
	my $seq = $self->primary_seq();
	if($seq && $seq->isa("Bio::DB::PersistentObjectI")) {
	    $seq->primary_key(@args);
	}
    }
    return $self->SUPER::primary_key(@args);
}


1;
