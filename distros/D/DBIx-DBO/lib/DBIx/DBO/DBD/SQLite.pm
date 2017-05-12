use strict;
use warnings;
use DBD::SQLite 1.31;

BEGIN { die 'DBD::SQLite version 1.31 required (but not version 1.38_01)' if $DBD::SQLite::VERSION eq '1.38_01' }

package # hide from PAUSE
    DBIx::DBO::DBD::SQLite;
use Carp 'croak';

sub _get_table_schema {
    my($class, $me, $schema, $table) = @_;

    my $q_schema = $schema;
    my $q_table = $table;
    $q_schema =~ s/([\\_%])/\\$1/g if defined $q_schema;
    $q_table =~ s/([\\_%])/\\$1/g;

    # Try just these types
    my $info = $me->rdbh->table_info(undef, $q_schema, $q_table,
        'TABLE,VIEW,GLOBAL TEMPORARY,LOCAL TEMPORARY,SYSTEM TABLE', {Escape => '\\'})->fetchall_arrayref;
    croak 'Invalid table: '.$class->_qi($me, $schema, $table) unless $info and @$info == 1 and $info->[0][2] eq $table;
    return $info->[0][1];
}

sub _save_last_insert_id {
    my($class, $me, $sth) = @_;
    $sth->{Database}->last_insert_id(undef, @$me{qw(Schema Name)}, undef);
}

1;
