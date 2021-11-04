package Test::OnlineDDL;

use strict;
use warnings;

use Test2::Bundle::More;
use Test2::Tools::Compare;
use Test2::Tools::Exception;
use Test2::Tools::Explain;

use DBI;
use DBIx::BatchChunker;
use DBIx::OnlineDDL;
use CDTest;

use Import::Into;
use Path::Class 'file';

use Env qw< ONLINEDDL_TEST_DEBUG ONLINEDDL_NO_ACTIVITY_TEST CDTEST_MASS_POPULATE CDTEST_DSN CDTEST_DBUSER CDTEST_DBPASS >;

use parent 'Exporter';

our @EXPORT = qw< onlineddl_test >;

############################################################

my $FILE = file(__FILE__);
my $root = $FILE->dir->parent->parent->parent;
my $db_file = $root->file('t', $FILE->basename.'.db');

# Enforce a real file SQLite DB if default
unless ($CDTEST_DSN) {
    $CDTEST_DSN    = "dbi:SQLite:dbname=$db_file";
    $CDTEST_DBUSER = '';
    $CDTEST_DBPASS = '';
    unlink $db_file if -e $db_file;
}

my $CHUNK_SIZE = $CDTEST_MASS_POPULATE ? 5000 : 3;
my $dbms_name  = CDTest->dbms_name;

END {
    unlink $db_file if -e $db_file;
};

############################################################

sub import {
    my $class  = shift;
    my $target = caller;

    $_->import::into($target) for qw<
        Test2::Bundle::More
        Test2::Tools::Compare
        Test2::Tools::Exception
        Test2::Tools::Explain

        DBI
        DBIx::BatchChunker
        DBIx::OnlineDDL
        CDTest
    >;

    Env->import::into($target, qw<
        ONLINEDDL_TEST_DEBUG ONLINEDDL_NO_ACTIVITY_TEST CDTEST_MASS_POPULATE CDTEST_DSN CDTEST_DBUSER CDTEST_DBPASS
    >);

    $class->export_to_level(1, @EXPORT);
}

sub onlineddl_test ($$&) {
    my ($test_name, $source_name, $test_code) = @_;
    subtest("$source_name: $test_name", sub {
        # Initialize the schema
        my $cd_schema;
        try_ok {
            $cd_schema = CDTest->init_schema(
               # If this is MySQL, this will test the ANSI_QUOTES flag
               $CDTEST_DSN && $CDTEST_DSN =~ /^dbi:mysql:/ ? (on_connect_call => 'set_strict_mode') : ()
            );
        } 'Tables created';
        die 'Schema initialization failed!' if $@;

        my $rsrc = $cd_schema->source($source_name);
        my $rs   = $cd_schema->resultset($source_name);

        my $old_table_name = $rsrc->from;

        # One of these tests removes the PK, so use a different unique index
        my $is_drop_pk = $test_name eq 'Drop PK';
        my @alt_columns;

        my %columns_info = %{ $rsrc->columns_info };
        my %uniques      = $rsrc->unique_constraints;

        foreach my $constraint_name (sort keys %uniques) {
            next if join(',', sort $rsrc->primary_columns) eq join(',', sort @{$uniques{$constraint_name}});
            @alt_columns = @{$uniques{$constraint_name}};
            last;
        }
        $rsrc->_primaries(\@alt_columns) if $is_drop_pk && @alt_columns;

        # Acquire the total number of track rows
        my $row_count = $rs->count;

        # Figure out a list of columns to acquire for the SELECT statements
        my @select_columns;
        foreach my $column_name (sort $rsrc->columns) {
            next if grep { $_ eq $column_name } $rsrc->primary_columns, @alt_columns;

            my $column_info = $columns_info{$column_name};
            next if $column_info->{is_auto_increment};
            next if $column_info->{is_nullable};
            push @select_columns, $column_name;
        }

        # NOTE: SQLite can't actually do the table drop if there's a leftover cursor mucking
        # about.  (This is more of a SQLite problem than something wrong with OnlineDDL.)
        # MySQL will keep an old snapshot of the data, but that's not a good test of multiple
        # connections hitting the table.
        #
        # So, we are only using single row statements, instead of cursors, to find existing
        # data.
        my @id_columns = ( $is_drop_pk ? () : ($rsrc->primary_columns), @alt_columns );

        my $iu_rs = $rs->search(undef, {
            columns  => [ @id_columns, @select_columns ],
            order_by => { -desc => [ @id_columns ] },
            rows => 1,
        });
        my $del_rs = $rs->search(undef, {
            columns  => [ @id_columns, @select_columns ],
            order_by => { -asc => [ @id_columns ] },
            rows => 1,
        });

        # A sub for messing with the original table while OnlineDDL is in progress.
        my $dc_count = 0;
        my $activity_sim_sub = sub {
            my ($oddl, $dbh) = @_;

            my $row = $iu_rs->first;
            $iu_rs->reset;
            return unless $row;

            my $method = (caller(2))[3];
            $method = (caller(3))[3] if $method eq 'DBIx::OnlineDDL::Helper::Base::dbh';

            # INSERT
            foreach my $i (0, 1) {
                my %new_row_vals;

                foreach my $column_name (@alt_columns, @select_columns) {
                    my $column_info = $columns_info{$column_name};

                    $new_row_vals{$column_name} = $column_info->{is_foreign_key} ?
                        $row->get_column($column_name) :
                        autofill_column($column_info)
                    ;
                }

                next unless %new_row_vals;
                $rs->create(\%new_row_vals);
                $row_count++;
                note "During $method: Inserted ".join(', ',
                    map  { "$_ = ".$new_row_vals{$_} }
                    grep { $new_row_vals{$_} }
                    @id_columns
                ) if $ONLINEDDL_TEST_DEBUG;
            }

            # UPDATE
            my $id_str = join(', ', map { "$_ = ".($row->get_column($_) // 'NULL') } sort @id_columns);

            foreach my $column_name (@select_columns) {
                my $column_info = $columns_info{$column_name};
                next if $column_info->{is_foreign_key};

                $row->set_column( $column_name => autofill_column($column_info) );
                $row->update;
                note "During $method: Updated $id_str" if $ONLINEDDL_TEST_DEBUG;
                last;
            }

            # DELETE
            $row = $del_rs->first;
            $del_rs->reset;
            return $dbh unless $row;

            $id_str = join(', ', map { "$_ = ".($row->get_column($_) // 'NULL') } sort @id_columns);

            $row->delete;
            $row_count--;
            note "During $method: Deleted $id_str" if $ONLINEDDL_TEST_DEBUG;

            # SQLite has an odd trigger bug where an UPDATE and a DELETE on the same ID (possibly
            # within the same connection) causes the UPDATE to happen on the new table, but not
            # the DELETE.  This causes some DELETEs to just get dropped on the floor.  There's a
            # good possibility that this is from https://sqlite.org/src/info/ef360601
            my $vars = $oddl->_vars;
            my $todo;
            $todo = todo 'SQLite trigger weirdness' if
                $dbms_name eq 'SQLite' && $test_name eq 'Add column + title change' && $vars->{new_table_copied}
            ;

            # Verify the row counts
            my ($new_row_count) = $dbh->selectrow_array("SELECT COUNT(*) FROM $old_table_name");
            cmp_ok($new_row_count, '==', $row_count, "Row counts from '$old_table_name' are as expected ($method)");

            if ($vars->{new_table_copied} && !$vars->{new_table_swapped}) {
                my $table_name = $oddl->new_table_name;
                my ($new_row_count) = $dbh->selectrow_array("SELECT COUNT(*) FROM $table_name");
                cmp_ok($new_row_count, '==', $row_count, "Row counts from '$table_name' are as expected ($method)");
            }

            # Try to eliminate the connection, to simulate a flakey connection
            $dc_count++;
            unless ($method =~ /(?:BUILD|post_connection_stmts|_build_helper|current_catalog_schema)$/ || $dc_count % 3) {
                if ($dbms_name eq 'MySQL') {
                    # XXX: For reasons unknown, this breaks the ANSI quote testing, so this KILL
                    # needs to be disabled to properly test that.
                    eval { $dbh->do('KILL CONNECTION CONNECTION_ID()') };
                }
                else {
                    $dbh->disconnect;
                }
            }
        };

        # Overload $oddl->dbh, so that every time it's called, it will mess with the original
        # table.  OnlineDDL acquires the $dbh object in just about every method, so this will
        # best simulate real-time usage of the table.
        no warnings 'redefine';
        my $orig_dbh_sub = \&DBIx::OnlineDDL::dbh;
        local *DBIx::OnlineDDL::dbh = $ONLINEDDL_NO_ACTIVITY_TEST ? $orig_dbh_sub : sub {
            my $dbh = $orig_dbh_sub->(@_);
            return $dbh unless $dbh;
            my $oddl = shift;

            $activity_sim_sub->($oddl, $dbh);

            return $dbh;
        };

        # Run the tests
        eval { $test_code->($cd_schema) };
        fail 'Test died', $@ if $@;

        # Verify the row counts
        unless ($@) {
            my $todo;
            $todo = todo 'SQLite trigger weirdness' if $dbms_name eq 'SQLite' && $test_name eq 'Add column + title change';

            my $new_row_count = $rs->count;
            cmp_ok($new_row_count, '==', $row_count, 'Final row counts are as expected');
        }

        # Clean the schema
        try_ok { CDTest->clean_schema( $cd_schema ) } 'Tables dropped';
    });
}

sub autofill_column {
    my ($column_info) = @_;
    my $data_type = $column_info->{data_type};
    my $size      = $column_info->{size} || 100;

    return
        $data_type =~ /^(?:var)?char$/ ? substr( CDTest->_random_words, 0, $size ) :
        $data_type =~ /^int(eger)?$/   ? int(rand(2_000_000))+1000 :
        die "Not sure how to auto-fill for data type '$data_type'!"
    ;
}
