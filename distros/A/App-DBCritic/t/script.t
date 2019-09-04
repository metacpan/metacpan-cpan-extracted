#!/usr/bin/env perl

use Test::More tests => 1;
use Test::Script::Run;
use DBICx::TestDatabase;
use Path::Class;
use FindBin;
use local::lib dir( $FindBin::Bin, 'schema' )->stringify();

my $script = 'bin/dbcritic';

my $schema = DBICx::TestDatabase->new('MySchema');
my $dbh    = $schema->storage->dbh;
run_ok(
    $script => [
        '--dsn',
        join q{:} => 'dbi',
        $dbh->{Driver}{Name}, $dbh->{Name},
    ],
);
