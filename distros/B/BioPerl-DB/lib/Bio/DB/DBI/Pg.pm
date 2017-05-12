# $Id$
#
# BioPerl module for Bio::DB::DBI::Pg
#
# Created by Yves Bastide <ybastide at irisa.fr>
#
# Copyright INRIA
#
# You may distribute this module under the same terms as perl itself

#
# (c) INRIA, 2002.
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

Bio::DB::DBI::Pg - DESCRIPTION of Object

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


package Bio::DB::DBI::Pg;
use vars qw(@ISA);
use strict;
use Bio::DB::DBI;
use Bio::DB::DBI::base;

@ISA = qw(Bio::DB::DBI::base);

=head2 new

 Title   : new
 Usage   : my $obj = Bio::DB::DBI::Pg->new();
 Function: Builds a new Bio::DB::DBI::Pg object using the passed named 
           parameters.
 Returns : an instance of Bio::DB::DBI::Pg
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
 Usage   : $pk = $obj->next_id_value();
 Function: 
 Example :
 Returns : a value suitable for use as a primary key
 Args    : The database connection handle to use for retrieving the
           next primary key value.

           Optionally, the name of the primary key generating
           sequence. If omitted, the value returned by sequence_name()
           will be used.


=cut

sub next_id_value{
    my ($self, $dbh, $seq) = @_;

    if(! $dbh) {
	$self->throw("no database handle supplied to next_id_value() --".
		     "last_id and next_id operations are connection-specific");
    }
    # we need to construct the sql statement
    $seq = $self->sequence_name() unless $seq;
    # use a cached (prepared) statement for this, and if for any
    # reason it is still active when we request it, it fill be
    # finish()ed first.
    my $sth = $dbh->prepare_cached("SELECT nextval('$seq')", undef, 1);
    my $row = $dbh->selectrow_arrayref($sth);
    my $dbid;
    if (! ($row && ($dbid = $row->[0]))) {
	$self->throw("Does sequence '$seq' exist? -- ".
		     "Probably internal error: ".$sth->errstr);
    }
    return $dbid;
}

=head2 last_id_value

 Title   : last_id_value
 Usage   :
 Function: Returns the last unique primary key value
           allocated. Depending on the argument and the driver, the
           value may be specific to a table, or independent of the
           table.

           This implementation does not need to know the table.
 Example :
 Returns : a value suitable for use as a primary key
 Args    : The database connection handle to use for retrieving the primary
           key from the last insert.

           Optionally, the name of the primary key generating
           sequence. If omitted, the value returned by sequence_name()
           will be used.

=cut

sub last_id_value{
    my ($self, $dbh, $seq) = @_;

    if(! $dbh) {
	$self->throw("no database handle supplied to last_id_value() --".
		     "last_id and next_id operations are connection-specific");
    }
    # we need to construct the sql statement
    $seq = $self->sequence_name() unless $seq;
    # use a cached (prepared) statement for this, and if for any
    # reason it is still active when we request it, it fill be
    # finish()ed first.
    my $sth = $dbh->prepare_cached("SELECT currval('$seq')", undef, 1);
    my $row = $dbh->selectrow_arrayref($sth);
    my $dbid;
    if (! ($row && ($dbid = $row->[0]))) {
	$self->throw("no record inserted or wrong database handle -- ".
		     "probably internal error: ".$sth->errstr);
    }
    return $dbid;
}

=head2 ifnull_sqlfunc

 Title   : ifnull_sqlfunc
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

*ifnull_sqlfunc = sub { 'COALESCE'; };

=head2 build_dsn

 Title   : build_dsn
 Usage   :
 Function: Constructs the DSN string from the DBContextI object. Since this
           may be driver-specific, specific implementations may need to
           override this method.
 Example :
 Returns : a string (the DSN)
 Args    : a Bio::DB::DBContextI implementing object


=cut

sub build_dsn{
    my ($self,$dbc) = @_;

    my $dsn = $dbc->dsn();
    if (! defined($dsn)) {
        $dsn = "dbi:" . $dbc->driver() . ":";
        $dsn .= "dbname=" . $dbc->dbname();
        $dsn .= ";host=" . $dbc->host() if $dbc->host();
        $dsn .= ";port=" . $dbc->port() if $dbc->port();
    }
    return $dsn;
}

=head2 new_connection

 Title   : new_connection
 Usage   :
 Function: Obtains a new connection handle to the database represented by the
           the DBContextI object, passing additional args to the DBI->connect()
           method.

           We need to override this here in order to support setting a
           schema for PostgreSQL.

 Example :
 Returns : an open DBI database handle
 Args    : A Bio::DB::DBContextI implementing object. Additional hashref
           parameter to pass to DBI->connect().


=cut

sub new_connection{
    my $self = shift;
    my ($dbc) = @_; # we don't need the parameter hash here

    my $dbh = $self->SUPER::new_connection(@_);
    if ($dbc->schema) {
        my $rv = $dbh->do("SET search_path TO ".$dbc->schema().", public");
        if (!$rv) {
            $self->warn("Failed to add schema '".$dbc->schema()
                        ."' to search path; is the server < v7.4?");
        }
    }
    return $dbh;
}

1;
