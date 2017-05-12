# $Id$
#
# BioPerl module for Bio::DB::DBD
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

Bio::DB::DBD - DESCRIPTION of Interface

=head1 SYNOPSIS

Give standard usage here

=head1 DESCRIPTION

Describe the interface here

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

Describe contact details here

=head1 CONTRIBUTORS

Additional contributors names and emails here

=head1 APPENDIX

The rest of the documentation details each of the object methods.
Internal methods are usually preceded with a _

=cut


# Let the code begin...


package Bio::DB::DBD;
use vars qw(@ISA);
use strict;
use Carp;
use Bio::Root::RootI;

@ISA = qw( Bio::Root::RootI );

=head2 prepare_delete_sth

 Title   : prepare_delete_sth
 Usage   :
 Function: Creates a prepared statement with one placeholder variable suitable
           to delete one row from the respective table the given class maps to.

           The method may throw an exception, or the database handle methods
           involved may throw an exception.
 Example :
 Returns : A DBI statement handle for a prepared statement with one placeholder
 Args    : The database handle to use for preparing the statement.
           The class of which a corresponding entry shall be deleted. 
           Optionally, additional (named) arguments.


=cut

sub prepare_delete_sth{
    my ($self,@args) = @_;

    $self->throw_not_implemented();
}

=head2 cascade_delete

 Title   : cascade_delete
 Usage   :
 Function: Removes all persistent objects dependent from the given persistent
           object from the database (foreign key integrity).

           The method may throw an exception, or the database calls
           involved may throw an exception.

           If the RDBMS supports cascading deletes, and the schema definition
           enabled FK constraints with cascading deletes, then the
           implementation won''t need to do anything.
 Example :
 Returns : TRUE on success, and FALSE otherwise
 Args    : The DBContextI implementing object for the database.
           The object for which the dependent rows shall be deleted. 
           Optionally, additional (named) arguments.


=cut

sub cascade_delete{
    my ($self,@args) = @_;

    $self->throw_not_implemented();
}

1;
