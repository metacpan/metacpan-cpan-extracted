# $Id$
#
# BioPerl module for Bio::DB::DBI.pm
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

Bio::DB::DBI.pm - DESCRIPTION of Interface

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

package Bio::DB::DBI;
use vars qw(@ISA);
use strict;
use Carp;
use Bio::Root::RootI;

@ISA = qw( Bio::Root::RootI);

=head2 next_id_value

 Title   : next_id_value
 Usage   : $pk = $obj->next_id_value("bioentry");
 Function: Returns the next unique primary key value. Depending on the
           argument and the driver, the value may not be unique
           between tables.

 Example :
 Returns : a value suitable for use as a primary key
 Args    : The database connection handle to use for retrieving the
           next primary key value.

           Optionally, the name of the primary key generating
           sequence. The driver is not required to honor the argument
           if present.


=cut

sub next_id_value{
   my ($self,@args) = @_;

   $self->throw_not_implemented();
}

=head2 last_id_value

 Title   : last_id_value
 Usage   :
 Function: Returns the last unique primary key value
           allocated. Depending on the argument and the driver, the
           value may be specific to a table, or independent of the
           table.

 Example :
 Returns : a value suitable for use as a primary key
 Args    : The database connection handle to use for retrieving the
           primary key from the last insert. An individual driver may
           allow this argument to be omitted if next_id_value() was
           called before for obtaining the primary key value.

           Optionally, the name of the primary key generating
           sequence. The driver is not required to honor the argument
           if present.

=cut

sub last_id_value{
   my ($self,@args) = @_;

   $self->throw_not_implemented();
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


=head2 get_connection

 Title   : get_connection
 Usage   :
 Function: Obtains a connection handle to the database represented by
           the the DBContextI object, passing additional args to the
           DBI->connect() method if a new connection is created.

           Contrary to new_connection(), this method may return shared
           connections from a pool. The implementation should make
           sure though that the returned handle was opened with the
           given parameters.

           In addition, the caller must not disconnect the obtained
           handle deliberately. Instead, the implementing object will
           disconnect and dispose of open handles once it is being
           garbage collected, or once disconnect() is called with the
           same or no parameters.

 Example :
 Returns : an open DBI database handle
 Args    : A Bio::DB::DBContextI implementing object. Additional hashref
           parameter to be passed to DBI->connect() in case of a new
           connection.


=cut

sub get_connection{
    my ($self,$dbc,@args) = @_;
    $self->throw_not_implemented();
}

=head2 new_connection

 Title   : new_connection
 Usage   :
 Function: Obtains a new connection handle to the database represented by the
           the DBContextI object, passing additional args to the DBI->connect()
           method.

           This method is supposed to always open a new
           connection. Also, the implementing class is expected to
           release proper disconnection of the handle entirely to the
           caller.

 Example :
 Returns : an open DBI database handle
 Args    : A Bio::DB::DBContextI implementing object. Additional hashref
           parameter to pass to DBI->connect().


=cut

sub new_connection{
    my ($self,$dbc,@args) = @_;
    $self->throw_not_implemented();
}

=head2 disconnect

 Title   : disconnect
 Usage   :
 Function: Disconnects all or a certain number of connections matching the
           parameters. The connections affected are those previously obtained
           through get_connection() (shared connections from a pool).
 Example :
 Returns : none
 Args    : Optionally, a Bio::DB::DBContextI implementing object. 
           Additional hashref parameter with settings that were passed to
           get_connection().


=cut

sub disconnect{
    my ($self,@args) = @_;

    $self->throw_not_implemented();
}

=head2 conn_params

 Title   : conn_params
 Usage   : $dbi->conn_params($requestor, $newval)
 Function: Gets/sets connection parameters suitable for the specific driver and
           the specific requestor.

           A particular implementation may choose to ignore the
           requestor, but it may also use it to return different
           parameters, based on, e.g., which interface the requestor
           implements. Usually the caller will pass $self as the value
           for $requestor, but an implementation is is expected to
           accept a class or interface name as well.

           If an object is passed for $requestor, the implementation
           is expected to return parameters for an interface the
           object implements, or for a parent class, whichever comes
           first, and provided no parameters have been set
           specifically for the class of the passed object. This makes
           is possible, as an example, to set parameters for
           Bio::DB::PersistenceAdaptorI, and have those returned for
           every object that implements that interface.

 Example : 
 Returns : a hashref to be passed to get_connection() or new_connection()
           (which would pass it on to DBI->connect()).
 Args    : The requesting object, or alternatively its class name or interface.
           Optionally, on set the new value (which must be undef or a hashref).


=cut

sub conn_params{
    my ($self,$value) = @_;
    $self->throw_not_implemented();
}

1;
