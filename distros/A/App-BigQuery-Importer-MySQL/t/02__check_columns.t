use strict;
use Test::More 0.98;
use Test::Fatal;
use t::Util;

use DBI;
use App::BigQuery::Importer::MySQL;

my $mysqld = t::Util->start_mysqld;
my $dbh = DBI->connect($mysqld->dsn);

my @create_sqls = (
    q{
        CREATE TABLE `test_blob` (
          `id` integer unsigned NOT NULL auto_increment,
          `test_blob` blob NOT NULL,
          PRIMARY KEY (`id`)
        );
    },
    q{
        CREATE TABLE `test_text` (
          `id` integer unsigned NOT NULL auto_increment,
          `test_text` TEXT NOT NULL,
          PRIMARY KEY (`id`)
        );
    },
    q{
        CREATE TABLE `test_blob_and_text` (
          `id` integer unsigned NOT NULL auto_increment,
          `test_blob` blob NOT NULL,
            `test_text` TEXT NOT NULL,
          PRIMARY KEY (`id`)
        );
    },
    q{
        CREATE TABLE `test_no_blob_and_no_text` (
          `id` integer unsigned NOT NULL auto_increment,
          PRIMARY KEY (`id`)
        );
    },
);

$dbh->do($_) for @create_sqls;

subtest 'no allow_text_type' => sub {
    like exception {
        App::BigQuery::Importer::MySQL->_check_columns(
            +{
                dbh             => $dbh,
                src_schema      => 'test',
                src_table       => 'test_blob',
                allow_text_type => 0,
            }
        );
    }, qr/test\.test_blob has BLOB table/, "throws ok";

    like exception {
        App::BigQuery::Importer::MySQL->_check_columns(
            +{
                dbh             => $dbh,
                src_schema      => 'test',
                src_table       => 'test_text',
                allow_text_type => 0,
            }
        );
    }, qr/test\.test_text has TEXT table/, "check ok";

    like exception {
        App::BigQuery::Importer::MySQL->_check_columns(
            +{
                dbh             => $dbh,
                src_schema      => 'test',
                src_table       => 'test_blob_and_text',
                allow_text_type => 0,
            }
        );
    }, qr/test\.test_blob_and_text has BLOB table/, "throws ok";

    is exception {
        App::BigQuery::Importer::MySQL->_check_columns(
            +{
                dbh             => $dbh,
                src_schema      => 'test',
                src_table       => 'test_no_blob_and_no_text',
                allow_text_type => 0,
            }
        );
    }, undef, "check ok";
};

subtest 'allow_text_type' => sub {
    like exception {
        App::BigQuery::Importer::MySQL->_check_columns(
            +{
                dbh             => $dbh,
                src_schema      => 'test',
                src_table       => 'test_blob',
                allow_text_type => 1,
            }
        );
    }, qr/test\.test_blob has BLOB table/, "throws ok";

    is exception {
        App::BigQuery::Importer::MySQL->_check_columns(
            +{
                dbh             => $dbh,
                src_schema      => 'test',
                src_table       => 'test_text',
                allow_text_type => 1,
            }
        );
    }, undef, "check ok";

    like exception {
        App::BigQuery::Importer::MySQL->_check_columns(
            +{
                dbh             => $dbh,
                src_schema      => 'test',
                src_table       => 'test_blob_and_text',
                allow_text_type => 1,
            }
        );
    }, qr/test\.test_blob_and_text has BLOB table/, "throws ok";

    is exception {
        App::BigQuery::Importer::MySQL->_check_columns(
            +{
                dbh             => $dbh,
                src_schema      => 'test',
                src_table       => 'test_no_blob_and_no_text',
                allow_text_type => 1,
            }
        );
    }, undef, "check ok";
};



done_testing;
