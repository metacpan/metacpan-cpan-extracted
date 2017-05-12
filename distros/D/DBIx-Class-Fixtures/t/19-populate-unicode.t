#!perl

use DBIx::Class::Fixtures;
use Test::More no_plan;
use lib qw(t/lib);
use DBICTest;
use Path::Class;
use Data::Dumper;
use IO::All;
use utf8;

# set up and populate schema
ok( my $schema = DBICTest->init_schema(), 'got schema' );
my $config_dir = io->catfile(qw't var configs')->name;

# do dump
ok(
    my $fixtures = DBIx::Class::Fixtures->new(
        {
            config_dir => $config_dir,
            debug      => 0
        }
    ),
    'object created with correct config dir'
);

DBICTest->clear_schema($schema);
DBICTest->populate_schema($schema);

ok(
    $fixtures->dump(
        {
            schema    => $schema,
            directory => io->catfile(qw't var fixtures')->name,
            config    => "unicode.json",
        }
    ),
    "unicode dump executed okay"
);

$fixtures->populate(
    {
        connection_details => [ 'dbi:SQLite:' . io->catfile(qw[ t var DBIxClass.db ])->name, '', '' ],
    	directory          => io->catfile(qw't var fixtures')->name,
        schema             => $schema,
        no_deploy          => 1,
        use_find_or_create => 1,
    }
);

my $cd = $schema->resultset('CD')->find( { cdid => 5 });

is($cd->title, "Unicode Chars ™ © • † ∑ α β « » → …", "Unicode chars found");
