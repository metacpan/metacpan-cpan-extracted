#!perl

use strict;
use warnings;
use 5.010;
no warnings 'uninitialized'; # I would use common::sense but I don't want to increase the requirement list :-)

use Test::More;
use English '-no_match_vars';
use lib 't/lib/';

use DBICx::Backend::Move::Test::Schema::TestTools;
my $error = DBICx::Backend::Move::Test::Schema::TestTools::setup_db('t/fixtures/testdb.yml', 'dbi:SQLite:dbname=t/from.sqlite');
die $error if $error;
unlink 't/to.sqlite';

# command line handling works differently on Windows. Deactivate 
TODO: {
        local $TODO = "Command line handling works differently on Windows." if $^O eq 'MSWin32';

        my @call = ("$EXECUTABLE_NAME -Ilib -It/lib bin/dbicx-backend-move");
        push @call, "-vv";      # verbose output
        push @call, "--schema='DBICx::Backend::Move::Test::Schema'"; # schema to use
        push @call, "--from_dsn='dbi:SQLite:dbname=t/from.sqlite'"; # source database
        push @call, "--from_user ''"; # user for source database
        push @call, "--to_dsn=dbi:SQLite:dbname=t/to.sqlite"; # destination database
        push @call, "--to_user ''"; # user for destination database
        push @call, "2>&1";         # capture stderr too
        my $call = join " ", @call;

        my $result = qx($call);
        is($result, "Transfer: Owner => ..done.
Transfer: Host => .done.
Transfer: ViewOwner => ViewOwner is a view. Skipped.
", 'Two data sets transfered for table owner');
}
done_testing();
