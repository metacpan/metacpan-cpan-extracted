=head1 NAME

Data::Downloader::DB

=head1 DESCRIPTION

Controls the location of the data downloader cache database.

The database file is located in $HOME/.data_downloader.db
by default.  This may be overridden by setting the
DATA_DOWNLOADER_DATABASE environment variable.

=head1 METHODS

=over

=cut

package Data::Downloader::DB;

use strict;
use warnings;

use DBIx::Simple;
use File::Spec::Functions qw(catfile tmpdir);

use base "Rose::DB";

__PACKAGE__->register_db(
    domain   => "test",
    type     => "main",
    driver   => "sqlite",
    database => ( $ENV{DATA_DOWNLOADER_TESTDB} || ':memory:' ),
    connect_options => {
        PrintError => ($ENV{DD_PRINT_DB_ERRORS} ? 1 : 0),
        RaiseError => 0,
        sqlite_use_immediate_transaction =>
            ($ENV{DATA_DOWNLOADER_IMMEDIATE_TRANSACTION} ? 1 : 0)
    }
);

__PACKAGE__->register_db(
    domain   => "live",
    type     => "main",
    driver   => "sqlite",
    database => ( $ENV{DATA_DOWNLOADER_DATABASE} ||
                  catfile($ENV{HOME}, '.data_downloader.db') ),
    connect_options => {
        sqlite_use_immediate_transaction =>
            ($ENV{DATA_DOWNLOADER_IMMEDIATE_TRANSACTION} ? 1 : 0)
    }
);

__PACKAGE__->default_domain($ENV{HARNESS_ACTIVE} ? "test" : "live");
__PACKAGE__->default_type("main");

=item dbi_connect

Override to use connect_cached and do sqlite-specific setup.

=cut

sub dbi_connect {
    my $class = shift;
    # See Rose::DB -- this is the recommended way to cache db handles.
    my $dbh = DBI->connect_cached(@_);
    $dbh->do("PRAGMA synchronous = OFF");
    $dbh->do("PRAGMA foreign_keys = ON") unless $ENV{DATA_DOWNLOADER_BULK_DOWNLOAD};
    $dbh->do("PRAGMA count_changes = OFF");
    if (my $mode = $ENV{DATA_DOWNLOADER_JOURNAL_MODE}) {
	$dbh->do("PRAGMA journal_mode = $mode")
	    if (grep $_ eq $mode, qw(DELETE TRUNCATE PERSIST MEMORY WAL OFF));
    }
    $dbh->sqlite_busy_timeout(1000*300);  # wait up to 5 minutes if it is locked
    return $dbh;
}

=item simple

Returns a L<DBIx::Simple|DBIx::Simple> object, for when the ORM is not enough.

=cut

sub simple {
    return DBIx::Simple->new(shift->dbh);
}

=back

=head1 SEE ALSO

L<Rose::DB>

L<Data::Downloader>

=cut

1;

