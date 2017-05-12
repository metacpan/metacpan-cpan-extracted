# $Id$
#
# BioPerl module for Bio::DB::BioSQL::Pg::AnnotationCollectionAdaptorDriver
#
# Cut&pasted by Yves Bastide <ybastide at irisa.fr> from mysql/Oracle ones
#
# Copyright INRIA
#
# You may distribute this module under the same terms as perl itself

#
# Original:
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

Bio::DB::BioSQL::Pg::AnnotationCollectionAdaptorDriver - DESCRIPTION of Object

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

=head1 AUTHOR - Yves Bastide

Email ybastide at irisa.fr

Describe contact details here

=head1 CONTRIBUTORS

Additional contributors names and emails here

=head1 APPENDIX

The rest of the documentation details each of the object methods.
Internal methods are usually preceded with a _

=cut


# Let the code begin...


package Bio::DB::BioSQL::Pg::AnnotationCollectionAdaptorDriver;
use vars qw(@ISA);
use strict;

# Object preamble - inherits from Bio::Root::Root

use Bio::DB::BioSQL::Pg::BasePersistenceAdaptorDriver;

@ISA = qw(Bio::DB::BioSQL::Pg::BasePersistenceAdaptorDriver);

# new() is inherited

=head2 insert_object

 Title   : insert_object
 Usage   :
 Function: See parent class. We override this here because
           AnnotationCollection in the Pg biosql schema doesn''t
           really correspond to its own entity. I.e., we do (almost)
           nothing here.

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

    # return a virtual PK
    return -1;
}

=head2 update_object

 Title   : update_object
 Usage   :
 Function: See parent class. We override this here to not do anything in
           particular, as AnnotationCollection is only a virtual entity.

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

    return 1;
}


1;
