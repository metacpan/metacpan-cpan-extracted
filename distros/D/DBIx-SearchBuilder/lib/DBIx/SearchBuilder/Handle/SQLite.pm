
package DBIx::SearchBuilder::Handle::SQLite;

use strict;
use warnings;

use base qw(DBIx::SearchBuilder::Handle);

=head1 NAME

  DBIx::SearchBuilder::Handle::SQLite -- A SQLite specific Handle object

=head1 SYNOPSIS


=head1 DESCRIPTION

This module provides a subclass of DBIx::SearchBuilder::Handle that 
compensates for some of the idiosyncrasies of SQLite.

=head1 METHODS

=head2 DatabaseVersion

Returns the version of the SQLite library which is used, e.g., "2.8.0".
SQLite can only return short variant.

=cut

sub DatabaseVersion {
    my $self = shift;
    return '' unless $self->dbh;
    return $self->dbh->{sqlite_version} || '';
}

=head2 Insert

Takes a table name as the first argument and assumes that the rest of the arguments
are an array of key-value pairs to be inserted.

If the insert succeeds, returns the id of the insert, otherwise, returns
a Class::ReturnValue object with the error reported.

=cut

sub _last_insert_rowid {
    my $self = shift;
    my $table = shift;

    return $self->dbh->func('last_insert_rowid');

    # XXX: this is workaround nesty sqlite problem that
    # last_insert_rowid in transaction is inaccurrate with multiple
    # inserts.

    return $self->dbh->func('last_insert_rowid')
        unless $self->TransactionDepth;

    # XXX: is the name of the column always id ?

    my $ret = $self->FetchResult("select max(id) from $table");
    return $ret;
}

sub Insert  {
    my $self = shift;
    my $table = shift;

    my %args = ( id => undef, @_);
    # We really don't want an empty id

    my $sth = $self->SUPER::Insert($table, %args);
    return unless $sth;

    # If we have set an id, then we want to use that, otherwise, we want to lookup the last _new_ rowid
    $self->{'id'}= $args{'id'} || $self->_last_insert_rowid($table);

    warn "$self no row id returned on row creation" unless ($self->{'id'});
    return( $self->{'id'}); #Add Succeded. return the id
  }



=head2 CaseSensitive 

Returns undef, since SQLite's searches are not case sensitive by default 

=cut

sub CaseSensitive {
    my $self = shift;
    return(1);
}

sub BinarySafeBLOBs { 
    return undef;
}

sub DistinctQuery {
    my $self = shift;
    my $statementref = shift;
    my $sb = shift;

    return $self->SUPER::DistinctQuery( $statementref, $sb, @_ )
        if $sb->_OrderClause !~ /(?<!main)\./;

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

=head2 DistinctCount STATEMENTREF

takes an incomplete SQL SELECT statement and massages it to return a DISTINCT result count


=cut

sub DistinctCount {
    my $self = shift;
    my $statementref = shift;
    my $sb = shift;

    $$statementref = "SELECT count(*) FROM (SELECT DISTINCT main.id FROM $$statementref )";
}

sub Fields {
    my $self  = shift;
    my $table = shift;

    my $cache = \%DBIx::SearchBuilder::Handle::FIELDS_IN_TABLE;
    unless ( $cache->{lc $table} ) {
        my $info = $self->dbh->selectall_arrayref("PRAGMA table_info('$table')")
            or return ();

        foreach my $e ( @$info ) {
            push @{ $cache->{ lc $table } ||= [] }, lc $e->[1];
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
        datetime   => 'datetime(?)',
        time       => 'time(?)',

        hourly     => "strftime('%Y-%m-%d %H', ?)",
        hour       => "strftime('%H', ?)",

        date       => 'date(?)',
        daily      => 'date(?)',

        day        => "strftime('%d', ?)",
        dayofmonth => "strftime('%d', ?)",

        monthly    => "strftime('%Y-%m', ?)",
        month      => "strftime('%m', ?)",

        annually   => "strftime('%Y', ?)",
        year       => "strftime('%Y', ?)",

        dayofweek  => "strftime('%w', ?)",
        dayofyear  => "strftime('%j', ?)",
        weekofyear => "strftime('%W', ?)",
    };
}

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

    my $res;
    if ( lc($args{'To'}||'') eq 'utc' ) {
        $res = "datetime($args{'Field'}, 'utc')";
    }
    elsif ( lc($args{'From'}||'') eq 'utc' ) {
        $res = "datetime($args{'Field'}, 'localtime')";
    }
    else {
        warn "SQLite only supports TZ convesion from UTC or to UTC";
        $res = $args{'Field'};
    }
    return $res;
}

sub _DateTimeIntervalFunction {
    my $self = shift;
    my %args = ( From => undef, To => undef, @_ );

    return "strftime('%s',$args{'To'}) - strftime('%s',$args{'From'})";
}

1;

__END__

=head1 AUTHOR

Jesse Vincent, jesse@fsck.com

=head1 SEE ALSO

perl(1), DBIx::SearchBuilder

=cut
