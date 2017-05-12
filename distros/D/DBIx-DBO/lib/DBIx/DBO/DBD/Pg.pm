use strict;
use warnings;

package # hide from PAUSE
    DBIx::DBO::DBD::Pg;
use Carp 'croak';

sub _get_table_schema {
    my($class, $me, $schema, $table) = @_;

    my $q_schema = $schema;
    my $q_table = $table;
    $q_schema =~ s/([\\_%])/\\$1/g if defined $q_schema;
    $q_table =~ s/([\\_%])/\\$1/g;

    # First try just these types
    my $info = $me->rdbh->table_info(undef, $q_schema, $q_table,
        'TABLE,VIEW,GLOBAL TEMPORARY,LOCAL TEMPORARY,SYSTEM TABLE')->fetchall_arrayref({});
    # Then if we found nothing, try any type
    $info = $me->rdbh->table_info(undef, $q_schema, $q_table)->fetchall_arrayref({}) if $info and @$info == 0;
    croak 'Invalid table: '.$class->_qi($me, $schema, $table) unless $info and @$info == 1 and $info->[0]{pg_table} eq $table;
    return $info->[0]{pg_schema};
}

sub _get_column_info {
    my($class, $me, $schema, $table) = @_;

    my $q_schema = $schema;
    my $q_table = $table;
    $q_schema =~ s/([\\_%])/\\$1/g if defined $q_schema;
    $q_table =~ s/([\\_%])/\\$1/g;

    my $cols = $me->rdbh->column_info(undef, $q_schema, $q_table, '%')->fetchall_arrayref({});
    croak 'Invalid table: '.$class->_qi($me, $schema, $table) unless @$cols;

    map { $_->{pg_column} => $_->{ORDINAL_POSITION} } @$cols;
}

sub _set_table_key_info {
    my($class, $me, $schema, $table, $h) = @_;

    if (my $keys = $me->rdbh->primary_key_info(undef, $schema, $table)) {
        # In Pg the KEY_SEQ is actually the column index! Rows returned are in key seq order
        # And the column names are quoted so we use the pg_column names instead
        $h->{PrimaryKeys} = [ map $h->{Columns}[$_->{KEY_SEQ} - 1], @{$keys->fetchall_arrayref({})} ];
    }
}

sub _save_last_insert_id {
    my($class, $me, $sth) = @_;

    return $sth->{Database}->last_insert_id(undef, @$me{qw(Schema Name)}, undef);
}

# Pg doesn't allow the use of aliases in the WHERE, GROUP BY or HAVING clause
sub _alias_preference {
    my($class, $me, $method) = @_;
    $method ||= ((caller(2))[3] =~ /\b(\w+)$/);
    return 0 if $method eq 'join_on' or $method eq 'where' or $method eq 'group_by' or $method eq 'having';
    return 1;
}

sub _bulk_insert {
    shift->_fast_bulk_insert(@_);
}

1;
