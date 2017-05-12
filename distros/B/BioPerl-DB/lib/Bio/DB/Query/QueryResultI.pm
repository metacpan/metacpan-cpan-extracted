# $Id$
#
# BioPerl module for Bio::DB::Query::QueryResultI
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

Bio::DB::Query::QueryResultI - DESCRIPTION of Interface

=head1 SYNOPSIS

Give standard usage here

=head1 DESCRIPTION

This outlines the basic interface for a query result that returns objects,
not rows. Basically, it is a stream of objects, similarly in spirit to the
other Bioperl streaming interfaces like, e.g., Bio::SeqIO.

There is no specific notion here of a schema or database. 

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


package Bio::DB::Query::QueryResultI;
use vars qw(@ISA);
use strict;
use Bio::Root::RootI;

@ISA = qw( Bio::Root::RootI );

=head2 next_object

 Title   : next_object
 Usage   :
 Function: Obtain the next object from the result stream and return it.
 Example :
 Returns : A Bioperl object (implementing at least Bio::Root::RootI)
 Args    : none


=cut

sub next_object{
    shift->throw_not_implemented();
}

=head2 each_Object

 Title   : each_Object
 Usage   :
 Function: This is primarily a convenience method and in most implementations
           will just loop over next_object() and return an array of all
           objects.
 Example :
 Returns : A reference to an array of objects.
 Args    : Optionally, an anonymous function for filtering objects. If given,
           the function is passed one argument, the object to evaluate.
           The object will be included in the returned array if the function
           returns TRUE, and rejected otherwise.


=cut

sub each_Object{
    shift->throw_not_implemented();
}

=head2 finish

 Title   : finish
 Usage   :
 Function: Indicate being finished with this result so that possibly used
           system resources can be released.
 Example :
 Returns : none
 Args    : none


=cut

sub finish{
    shift->throw_not_implemented();
}

1;
