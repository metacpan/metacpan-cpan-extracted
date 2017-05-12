# $Header: /home/jesse/DBIx-SearchBuilder/history/SearchBuilder/Handle/Sybase.pm,v 1.8 2001/10/12 05:27:05 jesse Exp $

package DBIx::SearchBuilder::Handle::Sybase;

use strict;
use warnings;

use base qw(DBIx::SearchBuilder::Handle);

=head1 NAME

  DBIx::SearchBuilder::Handle::Sybase -- a Sybase specific Handle object

=head1 SYNOPSIS


=head1 DESCRIPTION

This module provides a subclass of DBIx::SearchBuilder::Handle that 
compensates for some of the idiosyncrasies of Sybase.

=head1 METHODS

=cut


=head2 Insert

Takes a table name as the first argument and assumes that the rest of the arguments
are an array of key-value pairs to be inserted.

If the insert succeeds, returns the id of the insert, otherwise, returns
a Class::ReturnValue object with the error reported.

=cut

sub Insert {
    my $self  = shift;

    my $table = shift;
    my %pairs = @_;
    my $sth   = $self->SUPER::Insert( $table, %pairs );
    if ( !$sth ) {
        return ($sth);
    }
    
    # Can't select identity column if we're inserting the id by hand.
    unless ($pairs{'id'}) {
        my @row = $self->FetchResult('SELECT @@identity');

        # TODO: Propagate Class::ReturnValue up here.
        unless ( $row[0] ) {
            return (undef);
        }
        $self->{'id'} = $row[0];
    }
    return ( $self->{'id'} );
}





=head2 DatabaseVersion

return the database version, trimming off any -foo identifier

=cut

sub DatabaseVersion {
    my $self = shift;
    my $v = $self->SUPER::DatabaseVersion();

   $v =~ s/\-(.*)$//;
   return ($v);

}

=head2 CaseSensitive 

Returns undef, since Sybase's searches are not case sensitive by default 

=cut

sub CaseSensitive {
    my $self = shift;
    return(1);
}




sub ApplyLimits {
    my $self = shift;
    my $statementref = shift;
    my $per_page = shift;
    my $first = shift;

}


=head2 DistinctQuery STATEMENTREFtakes an incomplete SQL SELECT statement and massages it to return a DISTINCT result set.


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
        # Wrapper select query in a subselect as Sybase doesn't allow
        # DISTINCT against CLOB/BLOB column types.
        $$statementref = "SELECT main.* FROM ( SELECT DISTINCT main.id FROM $$statementref ) distinctquery, $table main WHERE (main.id = distinctquery.id) ";
    }
    $$statementref .= $sb->_GroupClause;
    $$statementref .= $sb->_OrderClause;
}


=head2 BinarySafeBLOBs

Return undef, as Oracle doesn't support binary-safe CLOBS


=cut

sub BinarySafeBLOBs {
    my $self = shift;
    return(undef);
}



1;

__END__

=head1 AUTHOR

Jesse Vincent, jesse@fsck.com

=head1 SEE ALSO

DBIx::SearchBuilder, DBIx::SearchBuilder::Handle

=cut
