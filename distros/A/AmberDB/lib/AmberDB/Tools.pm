package AmberDB::Tools;

use 5.016;
use warnings;
use strict;
use Carp qw(croak cluck);
use File::Spec;

use AmberDB::Tools::Index;
use AmberDB::Tools::Maintain;
use AmberDB::Tools::Update;

use parent qw(
    AmberDB::Tools::Index
    AmberDB::Tools::Maintain
    AmberDB::Tools::Update
);

our $VERSION = '5.26.0';
my $CREATED = '2018-10-08';

# Constructor
# my $tools = AmberDB::Tools->new($adb, %options);
# my $tools = AmberDB::Tools->new(%options); # creates a new AmberDB instance
# ------------------------------------------------
sub new {

    my $class = shift;
    my $self  = {};

    require AmberDB;

    my ( $adb, %inputs );

    if ( ref( $_[0] ) ) {
        $adb    = shift;
        %inputs = @_;
    }
    else {
        %inputs = @_;
        $adb    = AmberDB->new(%inputs);
    }

    $self->{_adb} = $adb;

    foreach my $in ( keys %inputs ) {
        $self->{ uc($in) } = $inputs{$in};
    }
    $self->{say} = "";

    bless $self, $class;
    return $self;
}

1;

__END__

=head1 NAME

AmberDB::Tools - Database maintenance, CLI reindexing, migrations, and bulk conversion toolset

=head1 SYNOPSIS

  use AmberDB;
  use AmberDB::Tools;

  my $adb   = AmberDB->new(path => { dbase_dir => "/path/to/dbstore" });
  my $tools = AmberDB::Tools->new($adb);

  # 1. Create portable .amberdb database backup archive
  my $archive = $tools->dump();

  # 2. Restore database archive with integrity validation and reindexing
  my $result  = $tools->restore(file => "backup.amberdb", force => 1);

  # 3. Rebuild all indexes for a single table (.inx, .src, .fld, .fac)
  $tools->set_index("catalog_product");

  # 4. Rebuild only specific index components
  $tools->set_search("catalog_product");  # Rebuild full-text search index
  $tools->set_fields("catalog_product");  # Rebuild field exact match index
  $tools->set_filters("catalog_product"); # Rebuild facet forward filter index
  $tools->set_sort("catalog_product");    # Rebuild binary pre-sorted sequences in .inx

  # 5. Batch reindex / convert all tables in database directory
  my $report = $tools->convert_tables();

  # 6. Database storage & engine migrations
  $tools->update_storage(force => 0);     # Migrate scheme/->schema/, tables/->table/, TSV->ABR v5
  $tools->update_version(check => 1);     # Check MetaCPAN for latest release

=head1 DESCRIPTION

C<AmberDB::Tools> provides maintenance, native disaster recovery archiving (C<dump>/C<restore>), batch utility functions for rebuilding indexes, populating full-text search inverted files, compiling forward facet filter dictionaries, generating binary sort matrices, and running automated database-wide index and storage migrations.

Functionality is organized into focused sub-modules:

=over 4

=item * B<AmberDB::Tools::Index>: Index generation routines (C<set_index>, C<set_readall>, C<set_search>, C<set_fields>, C<set_filters>, C<set_rwlnkall>, C<set_sort>, C<index_alltables>, C<check_readall>, C<check_search>).

=item * B<AmberDB::Tools::Maintain>: Maintenance, export/import, and backup routines (C<dump>, C<restore>, C<vacuum>, C<del_table>, C<tie2csv>, C<csv2tie>, C<dir_tables>, C<all_tables>).

=item * B<AmberDB::Tools::Update>: Table format conversions, storage upgrades, and engine updating (C<update_table>, C<update_all>, C<replace_tablename>, C<replace_blockdata>, C<db_simple>, C<convert_tables>, C<update_storage>, C<update_version>).

=back

All operations can also be invoked directly from the terminal via C<amberdb> CLI (e.g. C<amberdb update storage>, C<amberdb update version>, C<amberdb reindex products>).

=head1 CONSTRUCTOR

=head2 new($adb, [%options])

Creates an C<AmberDB::Tools> instance associated with an active C<AmberDB> object handle.

  my $tools = AmberDB::Tools->new($adb);

=head1 METHODS

=head2 dump([%options])

Creates a compressed, portable C<.amberdb> archive file (gzipped tar archive) containing table and database schemas (C<schema/*.table>, C<schema/*.dbase>), native database data files (C<table/*.db>, C<table/*.del>, C<table/*.aut>, C<table/*.cnt>), and a cryptographically verified SHA-256 C<manifest.json>.

Options:

=over 4

=item * C<file>: Custom output file path (defaults to C<backup/YYYY/amberdb_YYYY-MM-DD_time.amberdb>).

=item * C<tables>: Array reference of table IDs to include (defaults to all tables in database).

=item * C<table>: Single table ID to export as a focused snapshot.

=back

  my $archive = $tools->dump();
  my $archive = $tools->dump(tables => ["catalog_product", "orders_cart"]);

=head2 restore(%options)

Restores a C<.amberdb> archive into the target database. Validates archive integrity via SHA-256 checksums in C<manifest.json>, extracts schemas and data files, and deterministically reconstructs all binary indexes (C<.inx>, C<.src>, C<.fld>, C<.fac>) via C<set_index>.

Options:

=over 4

=item * C<file>: Path to C<.amberdb> archive file (required).

=item * C<force>: Boolean (default 0). Must be set to 1 to overwrite existing tables in a non-empty database directory.

=item * C<reindex>: Boolean (default 1). Automatically executes C<set_index> for all restored tables.

=item * C<tables>: Array reference of specific table IDs to extract from the archive.

=back

  my $res = $tools->restore(file => "backup.amberdb", force => 1);

=head2 set_index($table_id, [@records])

Rebuilds all secondary and primary indexes for C<$table_id> based on its schema definition:

=over 4

=item * Primary key index (C<.inx>) via C<set_readall>

=item * Full-text search inverted indexes (C<.src>) via C<set_search>

=item * Inverted field match indexes (C<.fld>) via C<set_fields>

=item * Columnar facet filter forward indexes (C<.fac>) via C<set_filters>

=item * Monotonic binary pre-sorted record indexes (within C<.inx>) via C<set_sort>

=back

If C<@records> is omitted, reads all records from the base table automatically.

  $tools->set_index("catalog_product");

=head2 set_readall($table_id, [@ids])

Rebuilds the primary C<.inx> index file, populating C<keys> (compact binary packed list of IDs), C<count>, and C<lastid>.

  $tools->set_readall("catalog_product");

=head2 set_search($table_id, [@records])

Scans records, tokenizes text according to schema C<search_block>, and builds inverted keyword index file (C<.src>).

  $tools->set_search("catalog_product");

=head2 set_fields($table_id, [@records])

Builds inverted exact match index file (C<.fld>) for fields specified in schema C<match_block>.

  $tools->set_fields("catalog_product");

=head2 set_filters($table_id, [@records])

Builds columnar facet forward index files (C<.fac>) and bidirectional string dictionary (C<.unq>) for blocks configured in schema C<facet_block>.

  $tools->set_filters("catalog_product");

=head2 set_sort($table_id, [@records])

Builds monotonic binary pre-sorted index sequences within C<.inx> (C<$blk:keys>) according to schema C<sort_block>.

  $tools->set_sort("catalog_product");

=head2 convert_tables()

Scans the entire database directory, identifies all physical tables, and sequentially runs C<set_index> to rebuild and migrate packed binary indexes across the entire system. Returns a status hash reference.

  my $status = $tools->convert_tables();

=head2 update_table($table_id, [%options])

Scans an entire table record-by-record, detects legacy formats, creates a timestamped backup, and rewrites the table in native ABR v5 format while rebuilding indexes.

  my $res = $tools->update_table("catalog_product", force => 1);

=head2 update_storage([%options])

Migrates storage directories (C<scheme/> to C<schema/>, C<tables/> to C<table/>), converts legacy TSV tables to native ABR v5 format, rebuilds all indexes, and stamps C<config/storage_version.json>.

Options: C<check>, C<force>, C<no_backup>, C<tables>, C<target_dir>.

  $tools->update_storage(force => 1);

=head2 update_version([%options])

Queries the MetaCPAN API for newer releases of AmberDB, and optionally invokes C<cpanm> to upgrade the engine.

Options: C<check>, C<cpanm>.

  $tools->update_version(check => 1);

=head1 AUTHOR

Maruf Cetin <marufcetin@gmail.com>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2018-2026 Maruf Cetin.

This library is free software; you can redistribute it and/or modify it under the terms of the Artistic License 2.0.

=cut
