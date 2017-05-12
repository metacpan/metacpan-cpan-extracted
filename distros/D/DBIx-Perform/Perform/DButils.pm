package DBIx::Perform::DButils;
use strict;
use base 'Exporter';

our $VERSION   = '0.692';
our @EXPORT_OK = qw(&open_db);

use DBI;

our %DB_MARKERS = (
    Pg => {
        stanza1 => 'dbi:' . 'PG:',
        stanza2 => 'dbname=' . $ENV{DB_NAME} . ":",
        stanza3 => 'host=' . $ENV{DB_HOST} . ";",
    },
    mysql => {
        stanza1 => 'DBI:' . "mysql:",
        stanza2 => 'database=' . $ENV{DB_NAME} . ";",
        stanza3 => 'host=' . $ENV{DB_HOST},
    },
    Oracle => {
        stanza1 => 'dbi:' . "Oracle:",
        stanza2 => 'host=' . $ENV{DB_HOST} . ";",
        stanza3 => 'sid=' . $ENV{DB_NAME},
    },
    Informix => {
        stanza1 => 'dbi:' . "Informix:",
        stanza2 => $ENV{DB_NAME},
        stanza3 => undef,
    },
);

sub open_db {
    my $dbname = shift;    # May be a connect arg.

    my $connect_arg = $dbname;
    my $dbtype      = $ENV{DB_CLASS} || 'Informix';
    my $dbuser      = $ENV{DB_USER};
    my $dbpass      = $ENV{DB_PASSWORD};

    if ( uc($connect_arg) !~ /^DBI:/ ) {    # not already a DBI connect-arg...
        my $specifics = $DB_MARKERS{$dbtype};
        $connect_arg =
            $$specifics{'stanza1'}
          . $$specifics{'stanza2'}
          . $$specifics{'stanza3'};
    }

#warn "connecting - user: $dbuser, password: $dbpass connect string: $connect_arg";
    my $dbh =
      DBI->connect( $connect_arg, $dbuser, $dbpass, { PrintError => 0 } )
      or die "Unable to connect to '$connect_arg' as user '$dbuser'";
    return $dbh;
}

1;
