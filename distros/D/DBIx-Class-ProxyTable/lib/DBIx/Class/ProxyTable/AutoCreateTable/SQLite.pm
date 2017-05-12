package DBIx::Class::ProxyTable::AutoCreateTable::SQLite;
use strict;
use warnings;

sub _get_table {
    my ($class, $rs, $new_table) = @_;

    my $base_table = $rs->result_source->schema->source_registrations->{$rs->result_source->source_name}->name;
    for my $table ( @{$rs->result_source->schema->storage->dbh->selectcol_arrayref('select sql from sqlite_master')} ) {
        if ( $table =~ /^CREATE TABLE $base_table \(/ ) {
            $table =~ s/$base_table/$new_table/;
            return $table;
        }
    }
}
1;

__END__

=head1 NAME

DBIx::Class::ProxyTable::AutoCreateTable::SQLite - auto create sqlite table.

=head1 METHOD

=head2 _get_table

