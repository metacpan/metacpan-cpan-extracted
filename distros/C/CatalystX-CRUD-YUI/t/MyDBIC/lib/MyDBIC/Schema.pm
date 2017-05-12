package MyDBIC::Schema;

use strict;
use warnings;

use base 'DBIx::Class::Schema';

__PACKAGE__->load_classes();

# so each Schema class knows how to connect to db.
# This is analogous to init_db() in RDBO

# allow for app to be run from tests or test server

use Carp;
use FindBin;
use Path::Class::File;

sub init_connect_info {
    my $db;
    my $sql;
    my $base_path;

    for my $path ( "$FindBin::Bin/../..", "$FindBin::Bin" ) {
        if ( -s Path::Class::File->new( $path, "yui.sql" ) ) {
            $base_path = $path;
        }
    }

    if ( !$base_path ) {
        croak "can't locate base path using FindBin $FindBin::Bin";
    }

    $sql = Path::Class::File->new( $base_path, 'yui.sql' );
    $db  = Path::Class::File->new( $base_path, 'yui.db' );

    # create the db if it does not yet exist
    if ( !-s $db ) {
        system("sqlite3 $db < $sql") and die "can't create $db with $sql: $!";
    }

    if ( !$db or !-s $db ) {
        croak "can't locate yui.db";
    }

    return 'dbi:SQLite:' . $db;
}

1;
