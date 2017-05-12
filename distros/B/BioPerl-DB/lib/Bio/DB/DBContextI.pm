# $Id$

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

Bio::DB::DBContextI - Interface for a class implementing a database context

=head1 SYNOPSIS

    # obtain a DBContextI implementing object somehow, usually through
    # a factory, for example
    use Bio::DB::BioDB;

    $dbcontext = Bio::DB::BioDB->new(
			-database => 'biosql'
                        -user     => 'root',
                        -pass     => 'mypasswd',
                        -dbname   => 'pog',
                        -host     => 'caldy',
			-port     => 3306,    # optional
                        -driver   => 'mysql',
	    );

    # obtain other adaptors as needed
    $dbadp = $dbc->dbadaptor();
    $seq_adaptor = $dbadp->get_adaptor('Bio::PrimarySeqI');

=head1 DESCRIPTION

This object represents the context of a database that is implemented somehow.

=head1 CONTACT

    Hilmar Lapp, hlapp at gmx.net

=head1 APPENDIX

The rest of the documentation details each of the object methods. Internal 
methods are usually preceded with a _

=cut


# Let the code begin...


package Bio::DB::DBContextI;

use vars qw(@ISA);
use strict;

use Bio::Root::RootI;

@ISA = qw(Bio::Root::RootI);


=head2 dsn

 Title   : dsn
 Usage   : $obj->dsn($newval)
 Function: Get/set the DSN for the database connection. 

           The DSN typically contains all non-credential information
           necessary to connect to the database, like driver, database
           or instance name, host, etc. Therefore, setting the DSN
           overrides any other individual properties set before. An
           implementation should make an attempt to parse those
           properties out of the DSN string but is not mandated to do
           so. Modules that use a DBContextI compliant object to
           construct a DSN should instead use the value of this
           property verbatim for connecting to the database, if it is
           defined.

           I.e., if you set this property, setting any other
           individual properties will not alter the DSN used for
           connecting to the database. If you query the property, a
           value will not be automatically constructed if only
           individual properties have been set. This is so because
           constructing the proper DSN from individual properties is
           driver-specific, and therefore cannot be done in a
           driver-neutral module.

 Example : 
 Returns : value of dsn (a scalar)
 Args    : on set, new value (a scalar or undef, optional)


=cut

sub dsn{
    my ($self) = @_;
    $self->throw_not_implemented();
}

=head2 dbname

 Title   : dbname
 Usage   : $obj->dbname($newval)
 Function: 
 Example : 
 Returns : value of dbname (a scalar)
 Args    : new value (a scalar, optional)


=cut

sub dbname{
    my ($self) = @_;
    $self->throw_not_implemented();
}

=head2 driver

 Title   : driver
 Usage   : $obj->driver($newval)
 Function: 
 Example : 
 Returns : value of driver (a scalar)
 Args    : new value (a scalar, optional)


=cut

sub driver{
    my ($self) = @_;
    $self->throw_not_implemented();
}

=head2 username

 Title   : username
 Usage   : $obj->username($newval)
 Function: 
 Example : 
 Returns : value of username (a scalar)
 Args    : new value (a scalar, optional)


=cut

sub username {
    my ($self) = @_;
    $self->throw_not_implemented();
}

=head2 password

 Title   : password
 Usage   : $obj->password($newval)
 Function: 
 Example : 
 Returns : value of password (a scalar)
 Args    : new value (a scalar, optional)


=cut

sub password{
    my ($self,$value) = @_;
    $self->throw_not_implemented();
}

=head2 host

 Title   : host
 Usage   : $obj->host($newval)
 Function: 
 Example : 
 Returns : value of host (a scalar)
 Args    : new value (a scalar, optional)


=cut

sub host {
    my ($self) = @_;
    $self->throw_not_implemented();
}

=head2 port

 Title   : port
 Usage   : $obj->port($newval)
 Function: 
 Example : 
 Returns : value of port (a scalar)
 Args    : new value (a scalar, optional)


=cut

sub port{
    my ($self,$value) = @_;
    $self->throw_not_implemented();
}

=head2 dbadaptor

 Title   : dbadaptor
 Usage   : $dbadp = $dbc->dbadaptor();
 Function:
 Example :
 Returns : An Bio::DB::DBAdaptorI implementing object (an object adaptor
           factory).
 Args    : Optionally, on set an Bio::DB::DBAdaptorI implementing object (to
           be used as the object adaptor factory for the respective database)


=cut

sub dbadaptor{
    my ($self) = @_;
    $self->throw_not_implemented();
}

=head2 dbi

 Title   : dbi
 Usage   :
 Function:
 Example :
 Returns : A Bio::DB::DBI implementing object
 Args    : Optionally, on set a Bio::DB::DBI implementing object


=cut

sub dbi{
    my ($self,@args) = @_;
    $self->throw_not_implemented();
}

=head2 schema

 Title   : schema
 Usage   : $dbc->schema($newval)
 Function: Get/set the schema in which the database tables reside.

           A schema is typically equivalent to a namespace for a
           collection of tables within a database. In Oracle, the
           notion of a schema is synonymous with that of the user (all
           database objects of a user belong to the schema of the same
           name as the user) and hence can be omitted. In PostgreSQL,
           since v7.4 schemas can delineate collections of tables
           within a database (which in concept is more similar to a
           user in Oracle).

           For most drivers and database instances this will not be
           needed.

 Example : 
 Returns : value of schema (a scalar)
 Args    : on set, new value (a scalar or undef, optional)


=cut

sub schema{
    my ($self,@args) = @_;
    $self->throw_not_implemented();
}

1;
