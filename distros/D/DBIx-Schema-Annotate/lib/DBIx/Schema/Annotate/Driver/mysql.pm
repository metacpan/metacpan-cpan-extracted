package DBIx::Schema::Annotate::Driver::mysql;
use strict;
use warnings;
use parent 'DBIx::Schema::Annotate::Driver::Base';
use Smart::Args;
use DBIx::Inspector;

sub table_ddl {
    args(
        my $self,
        my $table_name => 'Str',
    );

    my $inspector = DBIx::Inspector->new(dbh => $self->{dbh});
    $inspector->table($table_name) or die 'unknown table name: ', $table_name;

    my $row = $self->{dbh}->selectrow_hashref(qq!SHOW CREATE TABLE $table_name!);
    return $row->{'Create Table'};
}


1;

