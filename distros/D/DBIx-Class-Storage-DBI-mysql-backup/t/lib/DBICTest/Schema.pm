package #
    DBICTest::Schema;

use strict;
use warnings;

use base qw/DBIx::Class::Schema/;
use FindBin;

our $VERSION = '1.0';

__PACKAGE__->load_namespaces;
__PACKAGE__->load_classes;
__PACKAGE__->load_components(qw/
    Schema::Versioned
    Storage::DBI::mysql::backup
/);

__PACKAGE__->upgrade_directory("$FindBin::RealBin/var/upgrade");
__PACKAGE__->backup_directory("$FindBin::RealBin/var/backup");


1