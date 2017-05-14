#!/usr/bin/env perl -w

use strict;
use warnings;

#modules
use Test::Exception;
use Test::More 'no_plan';
use Test::MockModule;
#add local lib to path
use FindBin;
use lib "$FindBin::Bin/../lib";

my $CLASS;
BEGIN {
    $CLASS = 'DBIx::Retry';
    use_ok $CLASS or die;
}

my ($t,$v) = (3,0);
ok my $conn = $CLASS->new('dbi::dummy', '', '', {retry_time => $t, verbose => $v}),  'Get a connection';
dies_ok { $conn->run(sub {}) } 'run method dies after timeout without db connection';

#Mock a dummy db connection
my $module = new Test::MockModule($CLASS);
ok $conn = $CLASS->new('dbi:ExampleP:dummy', '', '', {retry_time => $t, verbose => $v}),  'Get a dummy connection';
# Test with no existing dbh
$module->mock( _connect => sub {
    pass '_connect should be called';
    $module->original('_connect')->(@_);
});
# Test with instantiated dbh.
ok my $dbh = $conn->dbh, 'Fetch the dbh';
lives_ok { $conn->run(sub {}) } 'run method OK with db connection';
