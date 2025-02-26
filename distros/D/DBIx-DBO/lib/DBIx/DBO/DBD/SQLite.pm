use 5.014;
use warnings;
use DBD::SQLite 1.31;

BEGIN { die 'DBD::SQLite version 1.31 required (but not version 1.38_01)' if $DBD::SQLite::VERSION eq '1.38_01' }

package # hide from PAUSE
    DBIx::DBO::DBD::SQLite;
use Carp 'croak';

sub _get_table_schema {
    my($class, $me, $table) = @_;

    my $q_table = $table =~ s/([\\_%])/\\$1/gr;

    # Try just these types
    my $info = $me->rdbh->table_info(undef, undef, $q_table,
        'TABLE,VIEW,GLOBAL TEMPORARY,LOCAL TEMPORARY,SYSTEM TABLE', {Escape => '\\'})->fetchall_arrayref;
    croak 'Invalid table: '.$class->_qi($me, $table) unless $info and @$info == 1 and $info->[0][2] eq $table;
    return $info->[0][1];
}

sub _save_last_insert_id {
    my($class, $me, $sth) = @_;
    $sth->{Database}->last_insert_id(undef, @$me{qw(Schema Name)}, undef);
}

sub _build_limit {
    my($class, $me) = @_;
    my $h = $me->_build_data;
    return '' unless defined $h->{limit};
    my $sql = 'LIMIT ';
    $sql .= $h->{limit}[0] >= 0 ? $h->{limit}[0] : -1;
    $sql .= ' OFFSET '.$h->{limit}[1] if $h->{limit}[1];
    return $sql;
}

1;
