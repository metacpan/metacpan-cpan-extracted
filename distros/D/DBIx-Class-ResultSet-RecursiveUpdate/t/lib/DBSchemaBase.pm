package DBSchemaBase;
use strict;
use warnings;

use base 'DBIx::Class::Schema';

sub tables_exist {
    my $dbh = shift;
    # assume that all tables exist if table dvd is found
    return $dbh->tables( '%', '%', 'dvd' );
}

sub get_test_schema {
    my ( $class, $dsn, $user, $pass, $opts ) = @_;
    $dsn ||= 'dbi:SQLite:dbname=:memory:';
    warn "testing $dsn\n";
    my $schema = $class->connect( $dsn, $user, $pass, $opts || {} );
    my $deploy_attrs;
    $deploy_attrs->{add_drop_table} = 1 if tables_exist( $schema->storage->dbh );
    $schema->deploy( $deploy_attrs );
    $schema->populate('Personality', [
        [ qw/user_id / ],
        [ '1'],
        [ '2' ],
        [ '3'],
        ]
    );
    $schema->populate('User', [
        [ qw/username name password / ],
        [ 'jgda', 'Jonas Alves', ''],
        [ 'isa' , 'Isa', '', ],
        [ 'zby' , 'Zbyszek Lukasiak', ''],
        ]
    );
    $schema->populate('Tag', [
        [ qw/name file / ],
        [ 'comedy', '' ],
        [ 'dramat', '' ],
        [ 'australian', '' ],
        ]
    );
    $schema->populate('Dvd', [
        [ qw/name imdb_id owner current_borrower creation_date alter_date / ],
        [ 'Picnick under the Hanging Rock', 123, 1, 3, '2003-01-16 23:12:01', undef ],
        [ 'The Deerhunter', 1234, 1, 1, undef, undef ],
        [ 'Rejs', 1235, 3, 1, undef, undef ],
        [ 'Seksmisja', 1236, 3, 1, undef, undef ],
        ]
    );
    $schema->populate( 'Dvdtag', [
        [ qw/ dvd tag / ],
        [ 1, 2 ],
        [ 1, 3 ],
        [ 3, 1 ],
        [ 4, 1 ],
        ]
    );
    return $schema;
}

1;
