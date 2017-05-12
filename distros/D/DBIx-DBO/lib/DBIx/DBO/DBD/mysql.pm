use strict;
use warnings;

package # hide from PAUSE
    DBIx::DBO::DBD::mysql;
use Carp qw(croak);

sub _get_table_schema {
    my($class, $me, $schema, $table) = @_;

    if (defined $schema and length $schema) {
        (my $q_schema = $me->rdbh->quote($schema)) =~ s/([\\_%])/\\$1/g;
        my($got_schema) = $me->selectrow_array('SHOW DATABASES LIKE '.$q_schema);
        croak 'Invalid table: '.$class->_qi($me, $schema, $table) unless defined $got_schema;
        return $got_schema;
    }

    ($schema) = $me->selectrow_array('SELECT DATABASE()');
    croak 'Invalid table: '.$class->_qi($me, $table).' (No database selected)' unless defined $schema;
    return $schema;
}

sub _set_table_key_info {
    my($class, $me, $schema, $table, $h) = @_;

    if (my $keys = $me->rdbh->primary_key_info(undef, $schema, $table)) {
        $h->{PrimaryKeys}[$_->{KEY_SEQ} - 1] = $_->{COLUMN_NAME} for @{$keys->fetchall_arrayref({})};
    } else {
        # Support for older DBD::mysql - Simulate primary_key_info()
        local $me->rdbh->{FetchHashKeyName} = 'NAME_lc';
        my $info = $me->rdbh->selectall_arrayref('SHOW KEYS FROM '.$class->_qi($me, $schema, $table), {Columns => {}});
        $_->{key_name} eq 'PRIMARY' and $h->{PrimaryKeys}[$_->{seq_in_index} - 1] = $_->{column_name} for @$info;
    }
}

sub _unquote_table {
    $_[2] =~ /^(?:(`|"|)(.+)\1\.|)(`|"|)(.+)\3$/ or croak "Invalid table: \"$_[2]\"";
    return ($2, $4);
}

sub _save_last_insert_id {
    my($class, $me, $sth) = @_;

    return $sth->{mysql_insertid};
}

sub _get_config {
    my $class = shift;
    my $val = $class->SUPER::_get_config(@_);
    # MySQL supports LIMIT on UPDATE/DELETE by default
    ($_[0] ne 'LimitRowUpdate' and $_[0] ne 'LimitRowDelete' or defined $val) ? $val : 1;
}

# Query
sub _calc_found_rows {
    my($class, $me) = @_;
    if ($me->sql =~ / SQL_CALC_FOUND_ROWS /) {
        $me->run unless $me->_sth->{Executed};
        return $me->{Found_Rows} = ($class->_selectrow_array($me, 'SELECT FOUND_ROWS()'))[0];
    }
    $class->SUPER::_calc_found_rows($me);
}

sub _build_sql_select {
    my($class, $me) = @_;
    my $sql = $class->SUPER::_build_sql_select($me);
    $sql =~ s/SELECT /SELECT SQL_CALC_FOUND_ROWS / if $me->config('CalcFoundRows');
    return $sql;
}

# MySQL doesn't allow the use of aliases in the WHERE clause
sub _alias_preference {
    my($class, $me, $method) = @_;
    $method ||= ((caller(2))[3] =~ /\b(\w+)$/);
    return 0 if $method eq 'join_on' or $method eq 'where';
    return 1;
}

sub _bulk_insert {
    shift->_fast_bulk_insert(@_);
}

1;
