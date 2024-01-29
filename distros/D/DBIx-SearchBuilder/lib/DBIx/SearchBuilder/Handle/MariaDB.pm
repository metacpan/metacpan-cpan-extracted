package DBIx::SearchBuilder::Handle::MariaDB;

use strict;
use warnings;
use version;

use base qw(DBIx::SearchBuilder::Handle);

=head1 NAME

  DBIx::SearchBuilder::Handle::MariaDB - A MariaDB specific Handle object

=head1 SYNOPSIS


=head1 DESCRIPTION

This module provides a subclass of DBIx::SearchBuilder::Handle that
compensates for some of the idiosyncrasies of MySQL.

=head1 METHODS

=head2 Insert

Takes a table name as the first argument and assumes that the rest of the arguments are an array of key-value pairs to be inserted.

If the insert succeeds, returns the id of the insert, otherwise, returns
a Class::ReturnValue object with the error reported.

=cut

sub Insert  {
    my $self = shift;

    my $sth = $self->SUPER::Insert(@_);
    if (!$sth) {
        return ($sth);
    }

    # Follow the advice in the docs and use last_insert_id rather than
    # {'mariadb_insertid'}.
    #
    # https://metacpan.org/dist/DBD-MariaDB/view/lib/DBD/MariaDB.pod#mariadb_insertid

    $self->{'id'} = $self->dbh->last_insert_id();

    # Docs say last_insert_id could still return undef, so keeping this code
    unless ( $self->{'id'} ) {
        $self->{'id'} = $self->FetchResult('SELECT LAST_INSERT_ID()');
    }
    warn "$self no row id returned on row creation" unless ($self->{'id'});

    return( $self->{'id'}); #Add Succeded. return the id
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

=cut

sub BLOBParams {
    my $self = shift;
    my $field = shift;
    my $type = shift;

    if ( $type =~ /^(blob|longblob)$/i ) {
        # Don't assign to key 'value' as it is defined later.
        return ( { TYPE => 'SQL_BLOB', } );
    }
    else {
        # Normal handling for these, so no hashref
        return;
    }
}


=head2 SimpleUpdateFromSelect

Customization of L<DBIx::SearchBuilder::Handle/SimpleUpdateFromSelect>.
Mysql doesn't support update with subqueries when those fetch data from
the table that is updated.

=cut

sub SimpleUpdateFromSelect {
    my ($self, $table, $values, $query, @query_binds) = @_;

    return $self->SUPER::SimpleUpdateFromSelect(
        $table, $values, $query, @query_binds
    ) unless $query =~ /\b\Q$table\E\b/i;

    my $sth = $self->SimpleQuery( $query, @query_binds );
    return $sth unless $sth;

    my (@binds, @columns);
    for my $k (sort keys %$values) {
        push @columns, $k;
        push @binds, $values->{$k};
    }

    $table = $self->QuoteName($table) if $self->{'QuoteTableNames'};
    my $update_query = "UPDATE $table SET "
        . join( ', ', map "$_ = ?", @columns )
        .' WHERE ID IN ';

    return $self->SimpleMassChangeFromSelect(
        $update_query, \@binds,
        $query, @query_binds
    );
}


sub DeleteFromSelect {
    my ($self, $table, $query, @query_binds) = @_;

    return $self->SUPER::DeleteFromSelect(
        $table, $query, @query_binds
    ) unless $query =~ /\b\Q$table\E\b/i;

    $table = $self->QuoteName($table) if $self->{'QuoteTableNames'};
    return $self->SimpleMassChangeFromSelect(
        "DELETE FROM $table WHERE id IN ", [],
        $query, @query_binds
    );
}

sub SimpleMassChangeFromSelect {
    my ($self, $update_query, $update_binds, $search, @search_binds) = @_;

    my $sth = $self->SimpleQuery( $search, @search_binds );
    return $sth unless $sth;


    # tried TEMPORARY tables, much slower than fetching and delete
    # also size of ENGINE=MEMORY is limitted by option, on disk
    # tables more slower than in memory
    my $res = 0;

    my @ids;
    while ( my $id = ($sth->fetchrow_array)[0] ) {
        push @ids, $id;
        next if @ids < 1000;

        my $q = $update_query .'('. join( ',', ('?')x@ids ) .')';
        my $sth = $self->SimpleQuery( $q, @$update_binds, splice @ids );
        return $sth unless $sth;

        $res += $sth->rows;
    }
    if ( @ids ) {
        my $q = $update_query .'('. join( ',', ('?')x@ids ) .')';
        my $sth = $self->SimpleQuery( $q, @$update_binds, splice @ids );
        return $sth unless $sth;

        $res += $sth->rows;
    }
    return $res == 0? '0E0': $res;
}

=head2 DatabaseVersion

Returns the MariaDB version, trimming off any -foo identifier

=cut

sub DatabaseVersion {
    my $self = shift;
    my $v = $self->SUPER::DatabaseVersion();

    $v =~ s/\-.*$//;
    return ($v);
}

=head2 CaseSensitive

Returns undef, since MariaDB's searches are not case sensitive by default

=cut

sub CaseSensitive {
    my $self = shift;
    return(undef);
}

sub DistinctQuery {
    my $self = shift;
    my $statementref = shift;
    my $sb = shift;

    return $self->SUPER::DistinctQuery( $statementref, $sb, @_ )
        if $sb->_OrderClause !~ /(?<!main)\./;

    if ( substr($self->DatabaseVersion, 0, 1) == 4 ) {
        local $sb->{'group_by'} = [{FIELD => 'id'}];

        my ($idx, @tmp, @specials) = (0, ());
        foreach ( @{$sb->{'order_by'}} ) {
            if ( !exists $_->{'ALIAS'} || ($_->{'ALIAS'}||'') eq "main" ) {
                push @tmp, $_; next;
            }

            push @specials,
                ((($_->{'ORDER'}||'') =~ /^des/i)?'MAX':'MIN')
                ."(". $_->{'ALIAS'} .".". $_->{'FIELD'} .")"
                ." __special_sort_$idx";
            push @tmp, { ALIAS => '', FIELD => "__special_sort_$idx", ORDER => $_->{'ORDER'} };
            $idx++;
        }

        local $sb->{'order_by'} = \@tmp;
        $$statementref = "SELECT ". join( ", ", 'main.*', @specials ) ." FROM $$statementref";
        $$statementref .= $sb->_GroupClause;
        $$statementref .= $sb->_OrderClause;
    } else {
        local $sb->{'group_by'} = [{FIELD => 'id'}];
        local $sb->{'order_by'} = [
            map {
                ($_->{'ALIAS'}||'') ne "main"
                ? { %{$_}, FIELD => ((($_->{'ORDER'}||'') =~ /^des/i)?'MAX':'MIN') ."(".$_->{FIELD}.")" }
                : $_
            }
            @{$sb->{'order_by'}}
        ];
        $$statementref = "SELECT main.* FROM $$statementref";
        $$statementref .= $sb->_GroupClause;
        $$statementref .= $sb->_OrderClause;
    }
}

sub Fields {
    my $self  = shift;
    my $table = shift;

    my $cache = \%DBIx::SearchBuilder::Handle::FIELDS_IN_TABLE;
    unless ( $cache->{ lc $table } ) {
        my $sth = $self->dbh->column_info( undef, undef, $table, '%' )
            or return ();
        my $info = $sth->fetchall_arrayref({});
        foreach my $e ( sort {$a->{'ORDINAL_POSITION'} <=> $b->{'ORDINAL_POSITION'}} @$info ) {
            push @{ $cache->{ lc $e->{'TABLE_NAME'} } ||= [] }, lc $e->{'COLUMN_NAME'};
        }
    }
    return @{ $cache->{ lc $table } || [] };
}

=head2 SimpleDateTimeFunctions

Returns hash reference with specific date time functions of this
database for L<DBIx::SearchBuilder::Handle/DateTimeFunction>.

=cut

sub SimpleDateTimeFunctions {
    my $self = shift;
    return $self->{'_simple_date_time_functions'} ||= {
        %{ $self->SUPER::SimpleDateTimeFunctions(@_) },
        datetime   => '?',
        time       => 'TIME(?)',

        hourly     => "DATE_FORMAT(?, '%Y-%m-%d %H')",
        hour       => 'HOUR(?)',

        date       => 'DATE(?)',
        daily      => 'DATE(?)',

        day        => 'DAYOFMONTH(?)',
        dayofmonth => 'DAYOFMONTH(?)',

        monthly    => "DATE_FORMAT(?, '%Y-%m')",
        month      => 'MONTH(?)',

        annually   => 'YEAR(?)',
        year       => 'YEAR(?)',

        dayofweek  => "DAYOFWEEK(?) - 1", # 1-7, 1 - Sunday
        dayofyear  => "DAYOFYEAR(?)", # 1-366
        weekofyear => "WEEK(?)", # skip mode argument, so it can be controlled in MariaDB config
    };
}


=head2 ConvertTimezoneFunction

Custom implementation of L<DBIx::SearchBuilder::Handle/ConvertTimezoneFunction>.

Use the following query to get list of timezones:

    SELECT Name FROM mysql.time_zone_name;

See also details on how MariaDB works with mysql timezone tables

    https://mariadb.com/kb/en/time-zones/

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
    return "CONVERT_TZ( $args{'Field'}, $args{'From'}, $args{'To'} )";
}

sub _DateTimeIntervalFunction {
    my $self = shift;
    my %args = ( From => undef, To => undef, @_ );

    return "TIMESTAMPDIFF(SECOND, $args{'From'}, $args{'To'})";
}


=head2 QuoteName

Quote table or column name to avoid reserved word errors.

=cut

# over-rides inherited method
sub QuoteName {
    my ($self, $name) = @_;
    # use dbi built in quoting if we have a connection,
    if ($self->dbh) {
        return $self->SUPER::QuoteName($name);
    }

    return sprintf('`%s`', $name);
}

sub DequoteName {
    my ($self, $name) = @_;

    # If we have a handle, the base class can do it for us
    if ($self->dbh) {
        return $self->SUPER::DequoteName($name);
    }

    if ($name =~ /^`(.*)`$/) {
        return $1;
    }
    return $name;
}

sub _ExtractBindValues {
    my $self  = shift;
    my $value = shift;
    return $self->SUPER::_ExtractBindValues( $value, '\\' );
}

sub _IsMariaDB {
    my $self = shift;

    # We override DatabaseVersion to chop off "-MariaDB-whatever", so
    # call super here to get the original version
    my $v = $self->SUPER::DatabaseVersion();

    return ($v =~ /mariadb/i);
}

sub _RequireQuotedTables {
    my $self = shift;

    # MariaDB version does not match mysql, and hasn't added new reserved words
    # like "groups".
    return 0;
}

=head2 HasSupportForCombineSearchAndCount

MariaDB 10.2+ supports this.

=cut

sub HasSupportForCombineSearchAndCount {
    my $self = shift;
    my ($version) = $self->DatabaseVersion =~ /^(\d+\.\d+)/;

    return (version->parse('v'.$version) >= version->parse('v10.2')) ? 1 : 0;
}

sub CastAsDecimal {
    my $self  = shift;
    my $field = shift or return;

    # CAST($field AS DECIMAL) rounds values to integers by default. It supports
    # specific precisions like CAST($field AS DECIMAL(5,2)), but we don't know
    # the precisions in advance. +0 works like other dbs.
    return "($field+0)";
}

1;
