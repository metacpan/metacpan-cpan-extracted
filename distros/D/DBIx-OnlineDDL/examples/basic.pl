#!/usr/bin/perl

use v5.10;
use strict;
use warnings;

use Path::Class 'file';

my $root;
BEGIN {
    $root = file(__FILE__)->dir->parent;
    unshift( @INC, $root->subdir('lib')->stringify, $root->subdir(qw<t lib>)->stringify );
};

use DBIx::OnlineDDL;
use CDTest;

############################################################

$| = 1;

my $db_file = $root->file('examples', 'example.db');

$ENV{CDTEST_MASS_POPULATE} //= 3;
unless ($ENV{CDTEST_DSN}) {
    # Use a real file, so that the operation actually takes some human-measurable span of
    # time.
    $ENV{CDTEST_DSN}    = "dbi:SQLite:dbname=$db_file";
    $ENV{CDTEST_DBUSER} = '';
    $ENV{CDTEST_DBPASS} = '';
}

print "Initializing schema...";
my $cd_schema  = CDTest->init_schema;
my $track_rsrc = $cd_schema->source('Track');
say "done!";

# Constructor
DBIx::OnlineDDL->construct_and_execute(
    rsrc          => $track_rsrc,
    progress_name => 'Adding test_column to track',
    coderef_hooks => {
        before_triggers => sub {
            my $oddl = shift;
            my $dbh  = $oddl->dbh;
            my $name = $oddl->new_table_name;

            my $qname = $dbh->quote_identifier($name);
            my $qcol  = $dbh->quote_identifier('test_column');

            $oddl->dbh_runner_do("ALTER TABLE $qname ADD COLUMN $qcol VARCHAR(100) NULL");
        },
    },

    copy_opts => {
        chunk_size => 5000,
    },
);

$db_file->remove if -e $db_file;
