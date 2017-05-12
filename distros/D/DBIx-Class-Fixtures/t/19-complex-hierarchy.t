#!perl

use DBIx::Class::Fixtures;
use Test::More tests => 7;
use lib qw(t/lib);
use DBICTest;
use Path::Class;
use Data::Dumper;
use IO::All;

use if $^O eq 'MSWin32','Devel::Confess';
# set up and populate schema
ok(my $schema = DBICTest->init_schema(), 'got schema');

my $config_dir = io->catfile(qw't var configs')->name;

# Add washedup

ok my $artist = $schema->resultset("Artist")->find(1);
ok my $washed_up = $artist->create_related('washed_up', +{});
ok $washed_up->fk_artistid;


ok(my $fixtures = DBIx::Class::Fixtures->new({ config_dir => $config_dir, debug => 0 }), 'object created with correct config dir');
ok($fixtures->dump({
        config => {
            "might_have" => {
                "fetch" => 0
            },
            "has_many" => {
                "fetch" => 0
            },
            "sets" => [{
                "class" => "Artist::WashedUp",
                "quantity" => 1
            }]
        },
        schema => $schema, 
        directory => io->catfile(qw't var fixtures')->name,
    }), 'simple dump executed okay');

ok(
  $fixtures->dump({
    config => 'washed-up.json',
    schema => $schema, 
    directory => io->catfile(qw't var fixtures')->name,
  }));


