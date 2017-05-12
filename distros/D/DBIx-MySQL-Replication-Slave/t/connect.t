#!perl

use strict;
use warnings;

=head1 SYNOPSIS

In order to run these tests, you'll need to set your MySQL slave access
credentials in %ENV.

For example:

export SLAVE_DSN="dbi:mysql:database=my_database;host=my_db_hostname"
export SLAVE_USER=replication_user
export SLAVE_PASS=seekrit

Be aware that these tests will stop and start your slave machine.  If you're
not comfortable with this, you can skip this test or comment out the tests
which you don't like.

=cut

use Data::Dump qw( dump );
use Test::More tests => 16;

require_ok( 'DBD::mysql' );
require_ok( 'DBIx::MySQL::Replication::Slave' );

SKIP: {
    skip "connection vars need to be set in %ENV", 14
        unless exists $ENV{'SLAVE_DSN'} && $ENV{'SLAVE_DSN'};

    my $dbh = DBI->connect( $ENV{'SLAVE_DSN'}, $ENV{'SLAVE_USER'},
        $ENV{'SLAVE_PASS'} );
    ok( $dbh, "got a database handle" );
    isa_ok( $dbh, 'DBI::db' );

    my $slave = DBIx::MySQL::Replication::Slave->new( dbh => $dbh );
    ok( $slave, "got a slave object" );

    diag( "slave running? " . $slave->is_running );
    diag( "status: " . dump $slave->status );

    ok( $slave->status,                "status returned something" );
    ok( $slave->status->{master_user}, "master_user is set" );
    ok( $slave->refresh_status,        "refresh status returns something" );

    $slave->stop;

    ok( $slave->is_stopped, "slave is stopped" );

    ok( $slave->start,      "starting slave" );
    ok( $slave->is_running, "slave is running" );
    ok( $slave->stop,       "stopping slave" );
    ok( $slave->start,      "starting slave back up" );

    ok( $slave->slave_ok, "slave seems to be healthy enough" );

    $slave->lc( 0 );    # turning lower case off
    ok( $slave->refresh_status, "refreshing status" );

    diag( "status: " . dump $slave->status );

    ok( $slave->status->{Master_User}, "Master_User is set" );

}
