package TreeTest::Schema;
use strict;
use warnings;

use base qw( DBIx::Class::Schema );

__PACKAGE__->load_classes();

sub connect {
    my $self = shift;

    my $db_file = 't/var/test.db';

    unlink($db_file) if -e $db_file;
    unlink($db_file . '-journal') if -e $db_file . '-journal';
    mkdir("t/var") unless -d "t/var";

    my $dsn = "dbi:SQLite:$db_file";
    my $schema = $self->next::method( $dsn );

    $schema->storage->on_connect_do([ "PRAGMA synchronous = OFF" ]);

        my $dbh = $schema->storage->dbh;
        open SQL, "t/lib/sqlite.sql";
            my $sql;
            { local $/ = undef; $sql = <SQL>; }
        close SQL;
        $dbh->do($_) for split(/\n\n/, $sql);

    $schema->storage->dbh->do("PRAGMA synchronous = OFF");

    return $schema;
}

1;
