#!/usr/bin/env perl
BEGIN { $ENV{PERL_STRICTURES_EXTRA} = 0 }
use strictures 2;
use Test2::V0;

use lib 't/lib';
use MyApp::Service::DB;

my $db = myapp_db('main');
$db->dbh->do('CREATE TABLE foo (bar)');

$db->run(sub{
    $_->do('INSERT INTO foo (bar) VALUES (32)');
});

my ($bar) = $db->run(sub{
    $_->selectrow_array('SELECT bar FROM foo');
});

is(
    $bar, 32,
    'works',
);

done_testing;
