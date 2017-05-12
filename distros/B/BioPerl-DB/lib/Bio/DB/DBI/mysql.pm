# $Id$
#
# BioPerl module for Bio::DB::DBI::mysql
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

Bio::DB::DBI::mysql - DESCRIPTION of Object

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

Describe contact details here

=head1 CONTRIBUTORS

Additional contributors names and emails here

=head1 APPENDIX

The rest of the documentation details each of the object methods.
Internal methods are usually preceded with a _

=cut


# Let the code begin...


package Bio::DB::DBI::mysql;
use vars qw(@ISA);
use strict;
use Bio::DB::DBI;
use Bio::DB::DBI::base;

@ISA = qw(Bio::DB::DBI::base);

=head2 new

 Title   : new
 Usage   : my $obj = Bio::DB::DBI::mysql->new();
 Function: Builds a new Bio::DB::DBI::mysql object using the passed named 
           parameters.
 Returns : an instance of Bio::DB::DBI::mysql
 Args    : named parameters with tags -dbcontext (a Bio::DB::DBContextI
           implementing object) and -sequence_name (the name of the sequence
           for PK generation)


=cut

sub new {
    my($class,@args) = @_;
    
    my $self = $class->SUPER::new(@args);
    return $self;
}

=head2 next_id_value

 Title   : next_id_value
 Usage   : $pk = $obj->next_id_value("bioentry");
 Function: This implementation uses standard MySQL only and hence cannot
           implement this method. It will throw an exception if called.
 Example :
 Returns : a value suitable for use as a primary key
 Args    : The database connection handle to use for retrieving the next primary
           key value.
           Optionally, the name of the table. The driver is not required to
           honor the argument if present.


=cut

sub next_id_value{
    my ($self, $table) = @_;

    $self->throw("plain MySQL does not provide SQL sequences - ".
		 "next_id_value() is not available with this driver");
}

=head2 last_id_value

 Title   : last_id_value
 Usage   :
 Function: Returns the last unique primary key value
           allocated. Depending on the argument and the driver, the
           value may be specific to a table, or independent of the
           table.

           This implementation will ignore the table.
 Example :
 Returns : a value suitable for use as a primary key
 Args    : The database connection handle to use for retrieving the primary
           key from the last insert.


=cut

sub last_id_value{
    my ($self, $dbh) = @_;

    if(! $dbh) {
	$self->throw("no database handle supplied to last_id_value() --".
		     "last_id and currval operations are connection-specific");
    }
    return $dbh->{'mysql_insertid'};
}

=head2 ifnull_sqlfunc

 Title   : nvl_sqlfunc
 Usage   :
 Function: Get the name of the SQL function that takes two arguments
           and returns the first if it is not null, and the second
           otherwise.

           Most RDBMSs will have such a function, but unfortunately
           the naming is different between them. E.g., in MySQL the
           name is IFNULL(), whereas in Oracle it is NVL().

 Example :
 Returns : the name of the function as a string, without parentheses
 Args    : none


=cut

*ifnull_sqlfunc = sub { 'IFNULL'; };

1;
