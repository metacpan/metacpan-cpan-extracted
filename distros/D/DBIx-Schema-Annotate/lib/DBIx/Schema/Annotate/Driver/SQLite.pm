package DBIx::Schema::Annotate::Driver::SQLite;
use parent 'DBIx::Schema::Annotate::Driver::Base';
use strict;
use warnings;
use Smart::Args;

sub table_ddl {
    args(
        my $self,
        my $table_name => 'Str',
    );

    my $schema_row = do {
        my $sth = $self->{dbh}->prepare(q! SELECT * FROM sqlite_master WHERE type='table' and name = ? !);
        $sth->execute($table_name);
        $sth->fetchrow_hashref;
    };
    my $index_rows = do {
        my $sth = $self->{dbh}->prepare(q! SELECT * FROM sqlite_master WHERE type='index' and tbl_name = ? !);
        $sth->execute($table_name);
        $sth->fetchall_hashref('sql');
    };
    
    return $schema_row->{sql} unless scalar keys %$index_rows;
    return join("\n", $schema_row->{sql}, sort keys %$index_rows);
}

1;

