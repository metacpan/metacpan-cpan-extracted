# $Id$
#
# BioPerl module for Bio::DB::Persistent::ObjectRelMapperI
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

Bio::DB::Persistent::ObjectRelMapperI - DESCRIPTION of Interface

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


package Bio::DB::Persistent::ObjectRellMapperI;
use vars qw(@ISA);
use strict;
use Carp;
use Bio::Root::RootI;

@ISA = qw( Bio::Root::RootI );


=head2 table_name

 Title   : table_name
 Usage   :
 Function: Obtain the name of the table in the relational schema corresponding
           to the given class name, object, or persistence adaptor.

 Example :
 Returns : the name of the table (a string), or undef if the table cannot be
           determined
 Args    : The referenced object, class name, or the persistence adaptor for
           it. 


=cut

sub table_name{
    shift->throw_not_implemented();
}

=head2 association_table_name

 Title   : association_table_name
 Usage   :
 Function: Obtain the name of the table in the relational schema corresponding
           to the association of entities as represented by their
           corresponding class names, objects, or persistence adaptors.

 Example :
 Returns : the name of the table (a string)
 Args    : A reference to an array of objects, class names, or persistence
           adaptors. The array may freely mix types.


=cut

sub association_table_name{
    shift->throw_not_implemented();
}

=head2 primary_key_name

 Title   : primary_key_name
 Usage   :
 Function: Obtain the name of the primary key attribute for the given table in
           the relational schema.

 Example :
 Returns : The name of the primary key (a string)
 Args    : The name of the table (a string)


=cut

sub primary_key_name{
    shift->throw_not_implemented();
}

=head2 foreign_key_name

 Title   : foreign_key_name
 Usage   :
 Function: Obtain the foreign key name for referencing an object, as 
           represented by object, class name, or the persistence adaptor.
 Example :
 Returns : the name of the foreign key (a string)
 Args    : The referenced object, class name, or the persistence adaptor for
           it. 


=cut

sub foreign_key_name{
    shift->throw_not_implemented();
}

=head2 slot_attribute_map

 Title   : slot_attribute_map
 Usage   :
 Function: Get/set the mapping for each entity from object slot names to column
           names.
 Example :
 Returns : A reference to a hash map with entity names being the keys, if no
           key (entity name, object, or adaptor) was provided. Otherwise,
           a hash reference with the slot names being keys to their 
           corresponding column names.
 Args    : Optionally, the object, adaptor, or entity for which to obtain
           the map.
           Optionally, on set a reference to a hash map satisfying the features
           of the returned value.


=cut

sub slot_attribute_map{
    shift->throw_not_implemented();
}

1;
