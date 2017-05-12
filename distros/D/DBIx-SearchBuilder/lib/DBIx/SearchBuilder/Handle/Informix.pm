# $Header:  $

package DBIx::SearchBuilder::Handle::Informix;

use strict;
use warnings;

use base qw(DBIx::SearchBuilder::Handle);

=head1 NAME

  DBIx::SearchBuilder::Handle::Informix - An Informix specific Handle object

=head1 SYNOPSIS


=head1 DESCRIPTION

This module provides a subclass of DBIx::SearchBuilder::Handle that 
compensates for some of the idiosyncrasies of Informix.

=head1 METHODS

=cut


=head2 Insert

Takes a table name as the first argument and assumes that the rest of the arguments are an array of key-value pairs to be inserted.

If the insert succeeds, returns the id of the insert, otherwise, returns
a Class::ReturnValue object with the error reported.

=cut

sub Insert  {
    my $self = shift;

    my $sth = $self->SUPER::Insert(@_);
    if (!$sth) {
            print "no sth! (".$self->dbh->{ix_sqlerrd}[1].")\n";
	    return ($sth);
     }


    $self->{id}=$self->dbh->{ix_sqlerrd}[1];
    warn "$self no row id returned on row creation" unless ($self->{'id'});
    return( $self->{'id'}); #Add Succeded. return the id
  }


=head2 CaseSensitive 

Returns 1, since Informix's searches are case sensitive by default 

=cut

sub CaseSensitive {
    my $self = shift;
    return(1);
}


=head2 BuildDSN

Builder for Informix DSNs.

=cut

sub BuildDSN {
    my $self = shift;
  my %args = ( Driver => undef,
               Database => undef,
               Host => undef,
               Port => undef,
           SID => undef,
               RequireSSL => undef,
               @_);

  my $dsn = "dbi:$args{'Driver'}:";

  $dsn .= "$args{'Database'}" if (defined $args{'Database'} && $args{'Database'});

  $self->{'dsn'}= $dsn;
}


=head2 ApplyLimits STATEMENTREF ROWS_PER_PAGE FIRST_ROW

takes an SQL SELECT statement and massages it to return ROWS_PER_PAGE starting with FIRST_ROW;


=cut

sub ApplyLimits {
    my $self = shift;
    my $statementref = shift;
    my $per_page = shift;
    my $first = shift;

    # XXX TODO THIS only works on the FIRST page of results. that's a bug
    if ($per_page) {
	$$statementref =~ s[^\s*SELECT][SELECT FIRST $per_page]i;
    }
}


sub Disconnect  {
  my $self = shift;
  if ($self->dbh) {
      my $status = $self->dbh->disconnect();
      $self->dbh( undef);
      return $status;
  } else {
      return;
  }
}


=head2 DistinctQuery STATEMENTREF

takes an incomplete SQL SELECT statement and massages it to return a DISTINCT result set.


=cut

sub DistinctQuery {
    my $self = shift;
    my $statementref = shift;
    my $sb = shift;
    my $table = $sb->Table;

    if ($sb->_OrderClause =~ /(?<!main)\./) {
        # Don't know how to do ORDER BY when the DISTINCT is in a subquery
        warn "Query will contain duplicate rows; don't how how to ORDER BY across DISTINCT";
        $$statementref = "SELECT main.* FROM $$statementref";
    } else {
        # Wrapper select query in a subselect as Informix doesn't allow
        # DISTINCT against CLOB/BLOB column types.
        $$statementref = "SELECT * FROM $table main WHERE id IN ( SELECT DISTINCT main.id FROM $$statementref )";
    }
    $$statementref .= $sb->_GroupClause;
    $$statementref .= $sb->_OrderClause;
}


1;

__END__

=head1 AUTHOR

Oliver Tappe, oliver@akso.de

=head1 SEE ALSO

perl(1), DBIx::SearchBuilder

=cut
