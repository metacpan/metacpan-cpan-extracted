# $Id$
#
# BioPerl module for Bio::DB::BioSQL::Pg::BasePersistenceAdaptorDriver
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

Bio::DB::BioSQL::Pg::BasePersistenceAdaptorDriver - DESCRIPTION of Object

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

=head1 AUTHOR - Yves Bastide

Email ybastide at irisa.fr

=head1 CONTRIBUTORS

 Hilmar Lapp, hlapp at gmx.net

=head1 APPENDIX

The rest of the documentation details each of the object methods.
Internal methods are usually preceded with a _

=cut


# Let the code begin...


package Bio::DB::BioSQL::Pg::BasePersistenceAdaptorDriver;
use vars qw(@ISA);
use strict;

# Object preamble - inherits from Bio::Root::Root

use Bio::DB::BioSQL::BaseDriver;

@ISA = qw(Bio::DB::BioSQL::BaseDriver);


=head2 new

 Title   : new
 Usage   : my $obj = Bio::DB::BioSQL::Pg::BasePersistenceAdaptorDriver->new();
 Function: Builds a new Bio::DB::BioSQL::Pg::BasePersistenceAdaptorDriver object 
 Returns : an instance of Bio::DB::BioSQL::Pg::BasePersistenceAdaptorDriver
 Args    :


=cut

sub new {
    my($class,@args) = @_;

    my $self = $class->SUPER::new(@args);

    # the table, association, and column mappings for mySQL are identical
    # to the default ones, so no changes necessary here
    
    return $self;
}

=head2 primary_key_name

 Title   : primary_key_name
 Usage   :
 Function: Obtain the name of the primary key attribute for the given table in
           the relational schema.

           This implementation overrides the default for certain tables that
           do not have their own primary key.
 Example :
 Returns : The name of the primary key (a string)
 Args    : The name of the table (a string)


=cut

sub primary_key_name{
    my ($self,$table) = @_;

    if($table eq "biosequence") {
	$table = $self->table_name("Bio::BioEntry");
    } elsif($table eq "taxon_name") {
	$table = $self->table_name("TaxonNode");
    }
    return $self->SUPER::primary_key_name($table);
}

=head2 sequence_name

 Title   : sequence_name
 Usage   :
 Function: Returns the name of the primary key generator (SQL sequence)
           for the given table.

 Example :
 Returns : the name of the sequence (a string)
 Args    : The name of the table.


=cut

sub sequence_name{
    my ($self,$table) = @_;

    if($table eq "biosequence") {
	$table = $self->table_name("Bio::BioEntry");
    } elsif($table eq "taxon_name") {
	$table = $self->table_name("TaxonNode");
    }
    return $table . "_pk_seq";
}

1;
