
BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for testing by the author');
  }
}

use strict;
use warnings;

use Test::Database::Migrator;
use Test::More 0.88;

use Database::Migrator::mysql;

{
    package Test::Database::Migrator::mysql;

    use Moose;
    extends 'Test::Database::Migrator';

    sub _tables {
        my $self = shift;

        my @tables;

        my $sth = $self->_dbh()->table_info( undef, undef, undef, undef );
        while ( my $table = $sth->fetchrow_hashref() ) {
            push @tables, $table->{TABLE_NAME};
        }

        return sort @tables;
    }

    sub _indexes_on {
        my $self = shift;
        my $table = shift;

        my @indexes;

        my $dbh = $self->_dbh();
        local $dbh->{FetchHashKeyName} = 'NAME_lc';

        my $sth = $dbh->prepare("SHOW KEYS FROM $table");
        $sth->execute();

        while ( my $index = $sth->fetchrow_hashref() ) {
            next if $index->{key_name} eq 'PRIMARY';

            push @indexes, $index->{key_name};
        }

        return sort @indexes;
    }
}

Test::Database::Migrator::mysql->new(
    class => 'Database::Migrator::mysql',
)->run_tests();

done_testing();
