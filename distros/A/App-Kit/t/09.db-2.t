use Test::More;
use Class::Unload;

use App::Kit;

diag("Testing db() for App::Kit $App::Kit::VERSION");

my $app = App::Kit->new();

my $dir = $app->fs->tmpdir();
my $sqlite = $app->fs->spec->catdir( $dir, 'db' );

ok( !exists $INC{'DBI.pm'}, 'Sanity: DBI not loaded before dbh()' );
my $m_dbh = $app->db->dbh( { 'database' => $sqlite, 'dbd_driver' => 'SQLite' } );    # Perl::DependList-IS_DEP(DBD::SQLite)
ok( exists $INC{'DBI.pm'}, 'DBI lazy loaded on initial dbh()' );
isa_ok( $m_dbh, 'DBI::db', 'dbh() meth returns dbh' );
is( $m_dbh, $app->db->dbh(), 'dbh() returns same object' );

my $f_dbh = $app->db->dbh( { 'database' => $sqlite, 'dbd_driver' => 'SQLite', '_force_new' => 1 } );    # Perl::DependList-IS_DEP(DBD::SQLite)
isa_ok( $f_dbh, 'DBI::db', '_force_new returns DBD obj' );
is( $f_dbh->{Driver}{Name}, 'SQLite', '_force_new respects config via hash' );
isnt( $m_dbh, $f_dbh, '_force_new gave a new object' );
ok( !$m_dbh->ping, '_force_new disconnected the previous obj' );

done_testing;
