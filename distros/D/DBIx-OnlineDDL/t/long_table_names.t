#!/usr/bin/perl

use lib qw(t/lib);
use strict;
use warnings;

use Test2::Bundle::More;
use Test2::Tools::Compare;
use Test2::Tools::Exception;

use DBI;
use DBIx::OnlineDDL;
use CDTest;

############################################################

# This test exercises trigger name collision on long table names.
# MySQL's max identifier length is 64 chars.  A table name of 57 chars produces trigger names like
# "${table}_onlineddl_insert" (74 chars), which previously all truncated to the same 64-char prefix.

my $dbms_name = CDTest->dbms_name;

my $long_table_name = 'qr_user_vertical_established_interface_and_administration';  # 57 chars

############################################################

subtest 'Long table name no-op' => sub {
    my $cd_schema = CDTest->init_schema(
        $ENV{CDTEST_DSN} && $ENV{CDTEST_DSN} =~ /^dbi:mysql:/ ? (on_connect_call => 'set_strict_mode') : ()
    );
    my $dbh = $cd_schema->storage->dbh;

    my $quoted_long = $dbh->quote_identifier($long_table_name);

    # Create the long-named table with a simple schema
    $dbh->do("DROP TABLE IF EXISTS $quoted_long");
    $dbh->do(join ' ',
        "CREATE TABLE $quoted_long (",
        '  id INTEGER PRIMARY KEY NOT NULL,',
        '  name VARCHAR(100)',
        ')',
    );

    # Build and register a minimal result source pointing at the long table
    my $source = DBIx::Class::ResultSource::Table->new({ name => $long_table_name });
    $source->result_class('DBIx::Class::Core');
    $source->add_columns(
        id   => { data_type => 'integer', is_auto_increment => 1, is_nullable => 0 },
        name => { data_type => 'varchar', is_nullable => 1, size => 100 },
    );
    $source->set_primary_key('id');
    $cd_schema->register_source('LongTableName' => $source);

    # Populate a few rows so the copy has something to work with
    $dbh->do("INSERT INTO $quoted_long (id, name) VALUES (1, 'alpha')");
    $dbh->do("INSERT INTO $quoted_long (id, name) VALUES (2, 'bravo')");
    $dbh->do("INSERT INTO $quoted_long (id, name) VALUES (3, 'charlie')");

    my $online_ddl = DBIx::OnlineDDL->new(
        rsrc          => $cd_schema->source('LongTableName'),
        coderef_hooks => { before_triggers => sub {} },
        copy_opts     => { chunk_size => 3 },
    );

    is $online_ddl->table_name, $long_table_name, 'Figured out long table_name';

    my $err = dies { $online_ddl->execute };
    is $err, undef, 'Execute works with long table name' or diag $err;

    # Verify data survived the copy
    my ($count) = $dbh->selectrow_array("SELECT COUNT(*) FROM $quoted_long");
    is $count, 3, 'Row count preserved after OnlineDDL';

    # Cleanup
    $dbh->do("DROP TABLE IF EXISTS $quoted_long");
};

############################################################

done_testing;
