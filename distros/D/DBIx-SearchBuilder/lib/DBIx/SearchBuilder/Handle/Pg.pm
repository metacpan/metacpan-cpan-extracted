#$Header: /home/jesse/DBIx-SearchBuilder/history/SearchBuilder/Handle/Pg.pm,v 1.8 2001/07/27 05:23:29 jesse Exp $
# Copyright 1999-2001 Jesse Vincent <jesse@fsck.com>

package DBIx::SearchBuilder::Handle::Pg;

use strict;
use warnings;

use base qw(DBIx::SearchBuilder::Handle);

use Want qw(howmany);

=head1 NAME

  DBIx::SearchBuilder::Handle::Pg - A Postgres specific Handle object

=head1 SYNOPSIS


=head1 DESCRIPTION

This module provides a subclass of DBIx::SearchBuilder::Handle that 
compensates for some of the idiosyncrasies of Postgres.

=head1 METHODS

=cut


=head2 Connect

Connect takes a hashref and passes it off to SUPER::Connect;
Forces the timezone to GMT
it returns a database handle.

=cut
  
sub Connect {
    my $self = shift;
    
    my $rv = $self->SUPER::Connect(@_);
    $self->SimpleQuery("SET TIME ZONE 'GMT'");
    $self->SimpleQuery("SET DATESTYLE TO 'ISO'");
    $self->AutoCommit(1);
    return ($rv); 
}


=head2 Insert

Takes a table name as the first argument and assumes
that the rest of the arguments are an array of key-value
pairs to be inserted.

In case of insert failure, returns a L<Class::ReturnValue>
object preloaded with error info.

=cut


sub Insert {
    my $self  = shift;
    my $table = shift;
    my %args  = (@_);

    my $sth = $self->SUPER::Insert( $table, %args );
    return $sth unless $sth;

    if ( $args{'id'} || $args{'Id'} ) {
        $self->{'id'} = $args{'id'} || $args{'Id'};
        return ( $self->{'id'} );
    }

    my $sequence_name = $self->IdSequenceName($table);
    unless ($sequence_name) { return ($sequence_name) }   # Class::ReturnValue
    my $seqsth = $self->dbh->prepare(
        qq{SELECT CURRVAL('} . $sequence_name . qq{')} );
    $seqsth->execute;
    $self->{'id'} = $seqsth->fetchrow_array();

    return ( $self->{'id'} );
}

=head2 InsertQueryString

Postgres sepcific overriding method for
L<DBIx::SearchBuilder::Handle/InsertQueryString>.

=cut

sub InsertQueryString {
    my $self = shift;
    my ($query_string, @bind) = $self->SUPER::InsertQueryString( @_ );
    $query_string =~ s/\(\s*\)\s+VALUES\s+\(\s*\)\s*$/DEFAULT VALUES/;
    return ($query_string, @bind);
}

=head2 IdSequenceName TABLE

Takes a TABLE name and returns the name of the  sequence of the primary key for that table.

=cut

sub IdSequenceName {
    my $self  = shift;
    my $table = shift;

    return $self->{'_sequences'}{$table} if (exists $self->{'_sequences'}{$table});
    #Lets get the id of that row we just inserted
    my $seq;
    my $colinfosth = $self->dbh->column_info( undef, undef, lc($table), '%' );
    while ( my $foo = $colinfosth->fetchrow_hashref ) {

        # Regexp from DBIx::Class's Pg handle. Thanks to Marcus Ramberg
        if ( defined $foo->{'COLUMN_DEF'}
            && $foo->{'COLUMN_DEF'}
            =~ m!^nextval\(+'"?([^"']+)"?'(::(?:text|regclass)\))+!i )

        {
            return $self->{'_sequences'}{$table} = $1;
        }

    }
            my $ret = Class::ReturnValue->new();
            $ret->as_error(
                errno   => '-1',
                message => "Found no sequence for $table",
                do_backtrace => undef
            );
            return ( $ret->return_value );

}



=head2 BinarySafeBLOBs

Return undef, as no current version of postgres supports binary-safe blobs

=cut

sub BinarySafeBLOBs {
    my $self = shift;
    return(undef);
}


=head2 ApplyLimits STATEMENTREF ROWS_PER_PAGE FIRST_ROW

takes an SQL SELECT statement and massages it to return ROWS_PER_PAGE starting with FIRST_ROW;


=cut

sub ApplyLimits {
    my $self = shift;
    my $statementref = shift;
    my $per_page = shift;
    my $first = shift;

    my $limit_clause = '';

    if ( $per_page) {
        $limit_clause = " LIMIT ";
        $limit_clause .= $per_page;
        if ( $first && $first != 0 ) {
            $limit_clause .= " OFFSET $first";
        }
    }

   $$statementref .= $limit_clause; 

}


=head2 _MakeClauseCaseInsensitive FIELD OPERATOR VALUE

Takes a field, operator and value. performs the magic necessary to make
your database treat this clause as case insensitive.

Returns a FIELD OPERATOR VALUE triple.

=cut

sub _MakeClauseCaseInsensitive {
    my $self     = shift;
    my $field    = shift;
    my $operator = shift;
    my $value    = shift;

    # we don't need to downcase numeric values and dates
    if ($value =~ /^$DBIx::SearchBuilder::Handle::RE_CASE_INSENSITIVE_CHARS+$/o) {
        	return ( $field, $operator, $value);
    }

    if ( $operator =~ /LIKE/i ) {
        $operator =~ s/LIKE/ILIKE/ig;
        return ( $field, $operator, $value );
    }
    elsif ( $operator =~ /=/ ) {
	if (howmany() >= 4) {
        	return ( "LOWER($field)", $operator, $value, "LOWER(?)"); 
	} 
	# RT 3.0.x and earlier  don't know how to cope with a "LOWER" function 
	# on the value. they only expect field, operator, value.
	# 
	else {
		return ( "LOWER($field)", $operator, lc($value));

	}
    }
    else {
        $self->SUPER::_MakeClauseCaseInsensitive( $field, $operator, $value );
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

    return $self->SUPER::DistinctQuery( $statementref, $sb, @_ )
        if $sb->_OrderClause !~ /(?<!main)\./;

    # "SELECT main.* FROM ( SELECT id FROM ... ORDER BY ... ) as dist,
    # X main WHERE (main.id = dist.id);" doesn't work in some cases.
    # It's hard to show with tests. Pg's optimizer can choose execution
    # plan not guaranting order

    my $groups;
    if ($self->DatabaseVersion =~ /^(\d+)\.(\d+)/ and ($1 > 9 or ($1 == 9 and $2 >= 1))) {
        # Pg 9.1 supports "SELECT main.foo ... GROUP BY main.id" if id is the primary key
        $groups = [ {FIELD => "id"} ];
    } else {
        # For earlier versions, we have to list out all of the columns
        $groups = [ map {+{FIELD => $_}} $self->Fields($table) ];
    }
    local $sb->{group_by} = $groups;
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
    $$statementref = "SELECT main.* FROM $$statementref $group $order";
}

=head2 SimpleDateTimeFunctions

Returns hash reference with specific date time functions of this
database for L<DBIx::SearchBuilder::Handle/DateTimeFunction>.

=cut

sub SimpleDateTimeFunctions {
    my $self = shift;
    return $self->{'_simple_date_time_functions'}
        if $self->{'_simple_date_time_functions'};

    my %res = %{ $self->SUPER::SimpleDateTimeFunctions(@_) };
    s/SUBSTR\s*\(\s*\?/SUBSTR( CAST(? AS text)/ig for values %res;

    # everything else we should implement through date_trunc that
    # does SUBSTR(?, 1, X) on a date, but leaves trailing values
    # when we don't need them

    return $self->{'_simple_date_time_functions'} ||= {
        %res,
        datetime   => '?',
        time       => 'CAST(? AS time)',

        hour       => 'EXTRACT(HOUR FROM ?)',

        date       => 'CAST(? AS date)',
        daily      => 'CAST(? AS date)',

        day        => 'EXTRACT(DAY FROM ?)',

        month      => 'EXTRACT(MONTH FROM ?)',

        annually   => 'EXTRACT(YEAR FROM ?)',
        year       => 'EXTRACT(YEAR FROM ?)',

        dayofweek  => "EXTRACT(DOW  FROM ?)", # 0-6, 0 - Sunday
        dayofyear  => "EXTRACT(DOY  FROM ?)", # 1-366
        # 1-53, 1st week January 4, week starts on Monay
        weekofyear => "EXTRACT(WEEK FROM ?)",
    };
}

=head2 ConvertTimezoneFunction

Custom implementation of L<DBIx::SearchBuilder::Handle/ConvertTimezoneFunction>.

In Pg time and timestamp data types may be "with time zone" or "without time zone".
So if Field argument is timestamp "with time zone" then From argument is not
required and is useless. Otherwise From argument identifies time zone of the Field
argument that is "without time zone".

For consistency with other DBs use timestamp columns without time zones and provide
From argument.

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
    my $res = $args{'Field'};
    $res = "TIMEZONE($_, $res)" foreach map $dbh->quote( $_ ), grep $_, @args{'From', 'To'};
    return $res;
}

sub _DateTimeIntervalFunction {
    my $self = shift;
    my %args = ( From => undef, To => undef, @_ );

    return "(EXTRACT(EPOCH FROM $args{'To'}) - EXTRACT(EPOCH FROM $args{'From'}))";
}

sub HasSupportForNullsOrder {
    return 1;
}

1;

__END__

=head1 SEE ALSO

DBIx::SearchBuilder, DBIx::SearchBuilder::Handle

=cut

