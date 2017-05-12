package DBIx::Class::ProxyTable::AutoCreateTable::mysql;
use strict;
use warnings;

sub _get_table {
    my ($class, $rs, $new_table) = @_;

    my $base_table = $rs->result_source->schema->source_registrations->{$rs->result_source->source_name}->name;
    my $sth = $rs->result_source->schema->storage->dbh->prepare("show create table $base_table");
    $sth->execute;
    my $table = $sth->fetchrow_hashref;
    $table->{'Create Table'} =~ s/$base_table/$new_table/;
    return $table->{'Create Table'};
}
1;

__END__

=head1 NAME

DBIx::Class::ProxyTable::AutoCreateTable::mysql - auto create mysql table

=head1 METHOD

=head2 _get_table

