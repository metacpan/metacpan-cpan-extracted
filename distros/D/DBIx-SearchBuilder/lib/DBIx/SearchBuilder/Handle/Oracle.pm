# $Header: /home/jesse/DBIx-SearchBuilder/history/SearchBuilder/Handle/Oracle.pm,v 1.14 2002/01/28 06:11:37 jesse Exp $

package DBIx::SearchBuilder::Handle::Oracle;

use strict;
use warnings;

use base qw/DBIx::SearchBuilder::Handle/;

use DBD::Oracle qw(:ora_types ORA_OCI);
         
=head1 NAME

  DBIx::SearchBuilder::Handle::Oracle - An oracle specific Handle object

=head1 SYNOPSIS


=head1 DESCRIPTION

This module provides a subclass of DBIx::SearchBuilder::Handle that 
compensates for some of the idiosyncrasies of Oracle.

=head1 METHODS

=cut


=head2 Connect PARAMHASH: Driver, Database, Host, User, Password

Takes a paramhash and connects to your DBI datasource. 

=cut

sub Connect  {
  my $self = shift;
  
  my %args = ( Driver => undef,
	       Database => undef,
	       User => undef,
	       Password => undef, 
	       SID => undef,
	       Host => undef,
	       @_);
  
    my $rv = $self->SUPER::Connect(%args);
    
    $self->dbh->{LongTruncOk}=1;
    $self->dbh->{LongReadLen}=8000;

    foreach my $setting (qw(DATE TIMESTAMP TIMESTAMP_TZ)) {
        $self->SimpleQuery(
            "ALTER SESSION set NLS_${setting}_FORMAT = 'YYYY-MM-DD HH24:MI:SS'"
        );
    }
    
    return ($rv); 
}

=head2 BuildDSN

Customized version of L<DBIx::SearchBuilder::Handle/BuildDSN> method.

Takes additional argument SID. Database argument used unless SID provided.
Two forms of DSN are generated depending on whether Host defined or not:

    dbi:Oracle:sid=<SID>;host=...[;port=...]
    dbi:Oracle:<SID>

Read details in documentation for L<DBD::Oracle> module.

=cut

sub BuildDSN {
    my $self = shift;
    my %args = (
        Driver     => undef,
        Database   => undef,
        Host       => undef,
        Port       => undef,
        SID        => undef,
        @_
    );
    $args{'Driver'} ||= 'Oracle';

# read DBD::Oracle for details, but basicly it supports
# either 'dbi:Oracle:SID' or 'dbi:Oracle:sid=SID;host=...;[port=...;]'
# and tests shows that 'dbi:Oracle:SID' != 'dbi:Oracle:sid=SID'

    $args{'SID'} ||= $args{'Database'};
    my $dsn = "dbi:$args{'Driver'}:";
    if ( $args{'Host'} ) {
        $dsn .= "sid=$args{'SID'}"    if $args{'SID'};
        $dsn .= ";host=$args{'Host'}";
        $dsn .= ";port=$args{'Port'}" if $args{'Port'};
    }
    else {
        $dsn .= $args{'SID'} if $args{'SID'};
        $dsn .= ";port=$args{'Port'}" if $args{'Port'};
    }

    return $self->{'dsn'} = $dsn;
}


=head2 Insert

Takes a table name as the first argument and assumes that the rest of the arguments
are an array of key-value pairs to be inserted.

=cut

sub Insert  {
	my $self = shift;
	my $table = shift;
    my ($sth);



  # Oracle Hack to replace non-supported mysql_rowid call

    my %attribs = @_;
    my ($unique_id, $QueryString);

    if ($attribs{'Id'} || $attribs{'id'}) {
        $unique_id = ($attribs{'Id'} ? $attribs{'Id'} : $attribs{'id'} );
    }
    else {
 
    $QueryString = "SELECT ".$table."_seq.nextval FROM DUAL";
 
    $sth = $self->SimpleQuery($QueryString);
    if (!$sth) {
       if ($main::debug) {
    	die "Error with $QueryString";
      }
       else {
	 return (undef);
       }
     }

     #needs error checking
    my @row = $sth->fetchrow_array;

    $unique_id = $row[0];

    }

    #TODO: don't hardcode this to id pull it from somewhere else
    #call super::Insert with the new column id.

    $attribs{'id'} = $unique_id;
    delete $attribs{'Id'};
    $sth =  $self->SUPER::Insert( $table, %attribs);

   unless ($sth) {
     if ($main::debug) {
        die "Error with $QueryString: ". $self->dbh->errstr;
    }
     else {
         return (undef);
     }
   }

    $self->{'id'} = $unique_id;
    return( $self->{'id'}); #Add Succeded. return the id
  }

=head2 InsertFromSelect

Customization of L<DBIx::SearchBuilder::Handle/InsertFromSelect>.

Unlike other DBs Oracle needs:

=over 4

=item * id generated from sequences for every new record.

=item * query wrapping in parens.

=back

B<NOTE> that on Oracle there is a limitation on the query. Every
column in the result should have unique name or alias, for example the
following query would generate "ORA-00918: column ambiguously defined"
error:

    SELECT g.id, u.id FROM ...

Solve with aliases:

    SELECT g.id AS group_id, u.id AS user_id FROM ...

=cut

sub InsertFromSelect {
    my ($self, $table, $columns, $query, @binds) = @_;
    if ( $columns && !grep lc($_) eq 'id', @$columns ) {
        unshift @$columns, 'id';
        $query = "SELECT ${table}_seq.nextval, insert_from.* FROM ($query) insert_from";
    }
    return $self->SUPER::InsertFromSelect( $table, $columns, "($query)", @binds);
}

=head2 KnowsBLOBs     

Returns 1 if the current database supports inserts of BLOBs automatically.      
Returns undef if the current database must be informed of BLOBs for inserts.    

=cut

sub KnowsBLOBs {     
    my $self = shift;
    return(undef);
}



=head2 BLOBParams FIELD_NAME FIELD_TYPE

Returns a hash ref for the bind_param call to identify BLOB types used by 
the current database for a particular column type.
The current Oracle implementation only supports ORA_CLOB types (112).

=cut

sub BLOBParams { 
    my $self = shift;
    my $field = shift;
    #my $type = shift;
    # Don't assign to key 'value' as it is defined later.
    return ( { ora_field => $field, ora_type => ORA_CLOB,
});    
}



=head2 ApplyLimits STATEMENTREF ROWS_PER_PAGE FIRST_ROW

takes an SQL SELECT statement and massages it to return ROWS_PER_PAGE starting with FIRST_ROW;


=cut

sub ApplyLimits {
    my $self = shift;
    my $statementref = shift;
    my $per_page = shift;
    my $first = shift;

    # Transform an SQL query from:
    #
    # SELECT main.* 
    #   FROM Tickets main   
    #  WHERE ((main.EffectiveId = main.id)) 
    #    AND ((main.Type = 'ticket')) 
    #    AND ( ( (main.Status = 'new')OR(main.Status = 'open') ) 
    #    AND ( (main.Queue = '1') ) )  
    #
    # to: 
    #
    # SELECT * FROM (
    #     SELECT limitquery.*,rownum limitrownum FROM (
    #             SELECT main.* 
    #               FROM Tickets main   
    #              WHERE ((main.EffectiveId = main.id)) 
    #                AND ((main.Type = 'ticket')) 
    #                AND ( ( (main.Status = 'new')OR(main.Status = 'open') ) 
    #                AND ( (main.Queue = '1') ) )  
    #     ) limitquery WHERE rownum <= 50
    # ) WHERE limitrownum >= 1
    #

    if ($per_page) {
        # Oracle orders from 1 not zero
        $first++; 
        # Make current query a sub select
        $$statementref = "SELECT * FROM ( SELECT limitquery.*,rownum limitrownum FROM ( $$statementref ) limitquery WHERE rownum <= " . ($first + $per_page - 1) . " ) WHERE limitrownum >= " . $first;
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
    my $hint = $sb->QueryHint;
    $hint = $hint ? " /* $hint */ " : " ";

    if ($sb->_OrderClause =~ /(?<!main)\./) {
        # If we are ordering by something not in 'main', we need to GROUP
        # BY and adjust the ORDER_BY accordingly
        local $sb->{group_by} = [@{$sb->{group_by} || []}, {FIELD => 'id'}];
        local $sb->{'order_by'} = [
            map {
                ($_->{'ALIAS'}||'') ne "main"
                ? { %{$_}, FIELD => ((($_->{'ORDER'}||'') =~ /^des/i)?'MAX':'MIN') ."(".$_->{FIELD}.")" }
                : $_
            }
            @{$sb->{'order_by'}}
        ];
        my $group = $sb->_GroupClause;
        my $order = $sb->_OrderClause;
        $$statementref = "SELECT" . $hint . "main.* FROM ( SELECT main.id, row_number() over( $order ) sortorder FROM $$statementref $group ) distinctquery, $table main WHERE (main.id = distinctquery.id) ORDER BY distinctquery.sortorder";
    } else {
        # Wrapp select query in a subselect as Oracle doesn't allow
        # DISTINCT against CLOB/BLOB column types.
        $$statementref = "SELECT" . $hint . " main.* FROM ( SELECT DISTINCT main.id FROM $$statementref ) distinctquery, $table main WHERE (main.id = distinctquery.id) ";
        $$statementref .= $sb->_GroupClause;
        $$statementref .= $sb->_OrderClause;
    }
}




=head2 BinarySafeBLOBs

Return undef, as Oracle doesn't support binary-safe CLOBS


=cut

sub BinarySafeBLOBs {
    my $self = shift;
    return(undef);
}

=head2 DatabaseVersion

Returns value of ORA_OCI constant, see L<DBI/Constants>.

=cut

sub DatabaseVersion {
    return ''. ORA_OCI;
}

sub Fields {
    my $self  = shift;
    my $table = shift;

    my $cache = \%DBIx::SearchBuilder::Handle::FIELDS_IN_TABLE;
    unless ( $cache->{ lc $table } ) {
        # uc(table) required as oracle stores UC names in information tables
        # and lookup clauses are case sensetive
        my $sth = $self->dbh->column_info( undef, undef, uc($table), '%' )
            or return ();
        my $info = $sth->fetchall_arrayref({});
        # TODO: not sure why results are lower case, probably NAME_ls affects it
        # we should check it out at some point
        foreach my $e ( sort {$a->{'ordinal_position'} <=> $b->{'ordinal_position'}} @$info ) {
            push @{ $cache->{ lc $e->{'table_name'} } ||= [] }, lc $e->{'column_name'};
        }
    }
    return @{ $cache->{ lc $table } || [] };
}

=head2 SimpleDateTimeFunctions

Returns hash reference with specific date time functions of this
database for L<DBIx::SearchBuilder::Handle/DateTimeFunction>.

=cut

# http://download.oracle.com/docs/cd/B14117_01/server.101/b10749/ch4datetime.htm
sub SimpleDateTimeFunctions {
    my $self = shift;
    return $self->{'_simple_date_time_functions'}
        if $self->{'_simple_date_time_functions'};

    my %res = %{ $self->SUPER::SimpleDateTimeFunctions(@_) };

    return $self->{'_simple_date_time_functions'} ||= {
        %res,
        datetime   => "?",
        time       => "TO_CHAR(?, 'HH24:MI:SS')",

        hourly     => "TO_CHAR(?, 'YYYY-MM-DD HH24')",
        hour       => "TO_CHAR(?, 'HH24')",

        date       => "TO_CHAR(?, 'YYYY-MM-DD')",
        daily      => "TO_CHAR(?, 'YYYY-MM-DD')",

        day        => "TO_CHAR(?, 'DD')",
        dayofmonth => "TO_CHAR(?, 'DD')",

        monthly    => "TO_CHAR(?, 'YYYY-MM')",
        month      => "TO_CHAR(?, 'MM')",

        annually   => "TO_CHAR(?, 'YYYY')",
        year       => "TO_CHAR(?, 'YYYY')",

        dayofweek  => "TO_CHAR(?, 'D') - 1", # 1-7, 1 - Sunday
        dayofyear  => "TO_CHAR(?, 'DDD')", # 1-366
        # no idea about props
        weekofyear => "TO_CHAR(?, 'WW')",
    };
}

=head2 ConvertTimezoneFunction

Custom implementation of L<DBIx::SearchBuilder::Handle/ConvertTimezoneFunction>.

Use the following query to get list of timezones:

    SELECT tzname FROM v$timezone_names;

Read Oracle's docs about timezone files:

    http://download.oracle.com/docs/cd/B14117_01/server.101/b10749/ch4datetime.htm#i1006667

=cut

sub ConvertTimezoneFunction {
    my $self = shift;
    my %args = (
        From  => 'UTC',
        To    => undef,
        Field => '',
        @_
    );
    return $args{'Field'} unless $args{From} && $args{'To'};
    return $args{'Field'} if lc $args{From} eq lc $args{'To'};

    my $dbh = $self->dbh;
    $_ = $dbh->quote( $_ ) foreach @args{'From', 'To'};
    return "FROM_TZ( CAST ($args{'Field'} AS TIMESTAMP), $args{'From'}) AT TIME ZONE $args{'To'}";
}

sub _DateTimeIntervalFunction {
    my $self = shift;
    my %args = ( From => undef, To => undef, @_ );

    return "ROUND(( CAST( $args{'To'} AS DATE ) - CAST( $args{'From'} AS DATE ) ) * 86400)";
}

sub HasSupportForNullsOrder {
    return 1;
}

1;

__END__

=head1 AUTHOR

Jesse Vincent, jesse@fsck.com

=head1 SEE ALSO

perl(1), DBIx::SearchBuilder

=cut
