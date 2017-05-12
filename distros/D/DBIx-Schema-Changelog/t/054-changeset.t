use Test::Requires qw(DBI DBD::SQLite);
use Test::More tests => 12;

use strict;
use warnings;
use FindBin;
use File::Spec;
use File::Path qw(remove_tree);
use lib File::Spec->catfile( $FindBin::Bin, '..', 'lib' );
use DBI;
use DBIx::Schema::Changelog;

require_ok('DBI');
use_ok 'DBI';

require_ok('FindBin');
use_ok 'FindBin';

require_ok('File::Spec');
use_ok 'File::Spec';

require_ok('File::Path');
use_ok 'File::Path';

require_ok('DBIx::Schema::Changelog');
use_ok 'DBIx::Schema::Changelog';

require_ok('DBIx::Schema::Changelog::Command::Changeset');
use_ok 'DBIx::Schema::Changelog::Command::Changeset';

my $path = File::Spec->catfile( $FindBin::Bin, '..', '.tmp' );

my $insert = { dir => $path, file_type => 'Yaml' };
DBIx::Schema::Changelog::Command::Changeset->new($insert)->make();

my $file = File::Spec->catfile( $path, 'changeset.sqlite' );
my $dbh = DBI->connect("dbi:SQLite:database=$file")
  or plan skip_all => $DBI::errstr;
DBIx::Schema::Changelog->new( dbh => $dbh )
  ->read( File::Spec->catfile( $path, 'changelog' ) );
$dbh->disconnect();

remove_tree $path or warn "Could not remove $path: $!";
