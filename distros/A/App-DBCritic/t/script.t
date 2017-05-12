#!perl

use Test::More tests => 2;
use Test::Script;
use DBICx::TestDatabase;
use Path::Class;
use FindBin;
use local::lib dir( $FindBin::Bin, 'schema' )->stringify();

my $script = 'bin/dbcritic';
script_compiles($script);

my $schema = DBICx::TestDatabase->new('MySchema');
my $dbh    = $schema->storage->dbh;
script_runs(
    [   $script => (
            '--dsn',
            join q{:} => 'dbi',
            $dbh->{Driver}{Name}, $dbh->{Name},
        ),
    ],
);
