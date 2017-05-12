#!perl

use DBIx::Class::Fixtures;
use Test::More;
use lib qw(t/lib);
use DBICTest;
use Path::Class;
use Data::Dumper; 
use Test::TempDir::Tiny;
use IO::All;

my $tempdir = tempdir;
use if $^O eq 'MSWin32','Devel::Confess';
plan tests => 18;

# set up and populate schema
ok(my $schema = DBICTest->init_schema(db_dir => $tempdir, ), 'got schema');

my $config_dir = io->catfile(qw't var configs')->name;
my $fixture_dir = $tempdir;

# do dump
{
    ok(my $fixtures = DBIx::Class::Fixtures->new({ config_dir => $config_dir, debug => 0 }), 'object created with correct config dir');
    ok($fixtures->dump({ all => 1, schema => $schema, directory => $fixture_dir }), 'fetch dump executed okay');

    foreach my $source ($schema->sources) {
            my $rs = $schema->resultset($source);
            my $dir =  dir($fixture_dir, ref $rs->result_source->name ? $rs->result_source->source_name : $rs->result_source->name);
            my @children = $dir->children;
            is (scalar(@children), $rs->count, 'all objects from $source dumped');
    }
}

# do dump with excludes
{
    ok(my $fixtures = DBIx::Class::Fixtures->new({ config_dir => $config_dir, debug => 0 }), 'object created with correct config dir');
    ok(
        $fixtures->dump(
            {
                all       => 1,
                schema    => $schema,
                excludes  => ['Tag'],
                directory => io->catfile( $fixture_dir, 'excludes' )->name
            }
        ),
        'fetch dump executed okay'
    );

    foreach my $source ($schema->sources) {
            my $rs = $schema->resultset($source);
            next if $rs->result_source->from eq 'tags';
            my $dir =  dir(io->catfile($fixture_dir,"excludes")->name, ref $rs->result_source->name ? $rs->result_source->source_name : $rs->result_source->name);
            my @children = $dir->children;
            is (scalar(@children), $rs->count, 'all objects from $source dumped');
    }
}
