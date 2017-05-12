# $Id$
#
# BioPerl module for SimpleDBContext
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

Bio::DB::SimpleDBContext - a base implementation of Bio::DB::DBContextI

=head1 SYNOPSIS

       # See Bio::DB::DBContextI.

=head1 DESCRIPTION

See Bio::DB::DBContextI.

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


package Bio::DB::SimpleDBContext;
use vars qw(@ISA);
use strict;

# Object preamble - inherits from Bio::Root::Root

use Bio::Root::Root;
use Bio::DB::DBContextI;
use Bio::DB::DBI;

@ISA = qw(Bio::Root::Root Bio::DB::DBContextI);

=head2 new

 Title   : new
 Usage   : my $obj = Bio::DB::SimpleDBContext->new();
 Function: Builds a new Bio::DB::SimpleDBContext object 
 Returns : an instance of Bio::DB::SimpleDBContext
 Args    : Named parameters. Currently recognized are
             -dbname    the name of the schema
             -host      the database host (to which to connect)
             -port      the port on the host to which to connect (optional)
             -driver    the DBI driver name for the RDBMS (e.g., mysql,
                        oracle, or Pg)
             -user      the username for connecting
             -pass      the password for the user
             -dsn       the DSN string to use verbatim for connecting;
                        if supplied, other parameters will not change
                        or add to the value (see method dsn())
             -schema    the schema under which the database tables
                        reside, if the driver needs this (for example,
                        for PostgreSQL)

=cut

sub new {
    my($class,@args) = @_;

    my $self = $class->SUPER::new(@args);
    my ($dsn,
        $db,
        $host,
        $driver,
        $user,
        $password,
        $port,
        $schema,
        ) = $self->_rearrange([qw(DSN
                                  DBNAME
				  HOST
				  DRIVER
				  USER
				  PASS
				  PORT
                                  SCHEMA
				  )],@args);

    $self->dsn($dsn) if $dsn;
    $self->username( $user );
    $self->host( $host ) if defined($host);
    $self->dbname( $db ) if defined($db);
    $self->driver($driver || "mysql") unless $self->driver();
    $self->password($password) if defined($password);
    $self->port($port) if defined($port);
    $self->schema($schema) if defined($schema);
    return $self;
}

=head2 dsn

 Title   : dsn
 Usage   : $obj->dsn($newval)
 Function: Get/set the DSN for the database connection. 

           The DSN typically contains all non-credential information
           necessary to connect to the database, like driver, database
           or instance name, host, etc. Therefore, setting the DSN
           overrides any other individual properties set before. We
           make an attempt to parse those properties out of the DSN
           string, but, in accordance with the interface contract,
           advise any client to use the dsn verbatim for connecting if
           set and not try to rebuild it from the parsed out
           properties.

           I.e., if you set this property, setting any other
           individual properties will not alter the DSN used for
           connecting to the database. If you query the property, a
           value will not be automatically constructed if only
           individual properties have been set.

 Example : 
 Returns : value of dsn (a scalar)
 Args    : on set, new value (a scalar or undef, optional)


=cut

sub dsn{
    my $self = shift;

    if (@_) {
        my $dsn = shift;        
        $self->{'dsn'} = $dsn;
        if ($dsn) {
            my @elts = split(/:/,$dsn);
            shift(@elts);                # first element is dbi or DBI
            $self->driver(shift(@elts)); # second is the driver
                                         # the rest is less predictable ...
            if (@elts && ($elts[0] =~ /^\w+$/)) { # just a plain dbname or sid?
                $self->dbname(shift(@elts));
            }
            my @params = split(/;/,join(':',@elts));
            foreach my $param (@params) {
                # check for dbname
                if ($param =~ /^(dbname|database|sid)=(.+)/) {
                    $self->dbname($2);
                    next;
                }
                # check for host
                if ($param =~ /^(host=|hostname=|\@)(.+)/) {
                    $self->host($2);
                    next;
                }
                # check for port
                if ($param =~ /^(port=|:)(\d+)/) {
                    $self->port($2);
                }
                # anything else we could check for?
            }
        }
    }
    return $self->{'dsn'};
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
    my $self = shift;

    return $self->{'dbname'} = shift if @_;
    return $self->{'dbname'};
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
    my $self = shift;

    return $self->{'driver'} = shift if @_;
    return $self->{'driver'};
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
    my $self = shift;

    return $self->{'username'} = shift if @_;
    return $self->{'username'};
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
    my $self = shift;

    return $self->{'password'} = shift if @_;
    return $self->{'password'};
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
    my $self = shift;

    return $self->{'host'} = shift if @_;
    return $self->{'host'};
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
    my $self = shift;

    return $self->{'port'} = shift if @_;
    return $self->{'port'};
}

=head2 dbadaptor

 Title   : get_adaptor
 Usage   : $dbadp = $dbc->dbadaptor();
 Function:
 Example :
 Returns : An Bio::DB::DBAdaptorI implementing object (an object adaptor
           factory).
 Args    : Optionally, on set an Bio::DB::DBAdaptorI implementing object (to
           be used as the object adaptor factory for the respective database)


=cut

sub dbadaptor{
    my $self = shift;

    return $self->{'dbadaptor'} = shift if @_;
    return $self->{'dbadaptor'};
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
    my ($self,$value) = @_;
    if( defined $value) {
	$self->{'dbi'} = $value;
    }
    if(! exists($self->{'dbi'})) {
	my $dbimod = "Bio::DB::DBI::".$self->driver();
	$self->_load_module($dbimod);
	$self->{'dbi'} = $dbimod->new(-dbcontext => $self);
    }
    return $self->{'dbi'};
}

=head2 schema

 Title   : schema
 Usage   : $dbc->schema($newval)
 Function: Get/set the schema in which the database tables reside.
 Example : 
 Returns : value of schema (a scalar)
 Args    : on set, new value (a scalar or undef, optional)


=cut

sub schema{
    my $self = shift;

    return $self->{'schema'} = shift if @_;
    return $self->{'schema'};
}

1;
