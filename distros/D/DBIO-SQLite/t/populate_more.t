use strict;
use warnings;

use Test::More;
use Test::Exception;
{
  package PopulateMoreTest::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components(qw/Schema::PopulateMore/);
  __PACKAGE__->register_class('Artist' => 'DBIO::Test::Schema::Artist');
  __PACKAGE__->register_class('CD' => 'DBIO::Test::Schema::CD');
  __PACKAGE__->register_class('Genre' => 'DBIO::Test::Schema::Genre');
}

use DBIO::SQLite::Test;
use DBIO::Util qw(file_path parent_dir);

# Deploy with our own schema class
my $db_file = ':memory:';
my $schema = PopulateMoreTest::Schema->connect("dbi:SQLite:$db_file", '', '', { AutoCommit => 1 });

# Deploy the tables we need
$schema->storage->dbh_do(sub {
  my ($storage, $dbh) = @_;
  my $sql_file = file_path(parent_dir(__FILE__), 'lib', 'sqlite.sql');
  my $sql = do { local (@ARGV, $/) = $sql_file; <> };
  for my $chunk (split(/;\s*\n+/, $sql)) {
    if ($chunk =~ /^\s*(?!--\s*)\S/m) {
      eval { $dbh->do($chunk) };
    }
  }
});

# Test basic populate_more with cross-source references
lives_ok {
  $schema->populate_more([
    { Genre => {
        fields => [qw/genreid name/],
        data => {
          emo => [1, 'emo'],
        }}},
    { Artist => {
        fields => [qw/artistid name/],
        data => {
          caterwauler => [1, 'Caterwauler McCrae'],
          random      => [2, 'Random Boy Band'],
        }}},
    { CD => {
        fields => [qw/cdid artist title year genreid/],
        data => {
          spoonful => [1, '!Index:Artist.caterwauler', 'Spoonful of bees', 1999, '!Index:Genre.emo'],
          forkful  => [2, '!Index:Artist.caterwauler', 'Forkful of bees', 2001],
        }}},
  ]);
} 'populate_more with Index references succeeds';

# Verify the data was inserted correctly
is($schema->resultset('Artist')->count, 2, 'Two artists inserted');
is($schema->resultset('CD')->count, 2, 'Two CDs inserted');

my $cd = $schema->resultset('CD')->find(1);
is($cd->title, 'Spoonful of bees', 'CD title correct');
is($cd->artist->name, 'Caterwauler McCrae', 'CD artist relationship resolved via Index');

# Test flat hash syntax (non-arrayref)
lives_ok {
  $schema->populate_more(
    Artist => {
      fields => [qw/artistid name/],
      data => {
        goth => [3, 'We Are Goth'],
      }},
  );
} 'populate_more with flat hash syntax works';

is($schema->resultset('Artist')->count, 3, 'Third artist inserted via flat syntax');

# Test single-field shorthand (string instead of arrayref)
lives_ok {
  $schema->populate_more([
    { Genre => {
        fields => 'name',
        data => {
          rock => 'rock',
        }}},
  ]);
} 'populate_more with single field string works';

my $rock = $schema->resultset('Genre')->search({ name => 'rock' })->first;
ok($rock, 'Genre with single field inserted');

# Test !Env inflator
$ENV{TEST_POPULATE_MORE_NAME} = 'Env Artist';
lives_ok {
  $schema->populate_more([
    { Artist => {
        fields => [qw/artistid name/],
        data => {
          env_artist => [4, '!Env:TEST_POPULATE_MORE_NAME'],
        }}},
  ]);
} 'populate_more with Env inflator works';

my $env_artist = $schema->resultset('Artist')->find(4);
is($env_artist->name, 'Env Artist', 'Env inflator substituted correctly');

# Test !Find inflator
lives_ok {
  $schema->populate_more([
    { CD => {
        fields => [qw/cdid artist title year/],
        data => {
          found_cd => [3, '!Find:Artist.[artistid=2]', 'Found CD', 2020],
        }}},
  ]);
} 'populate_more with Find inflator works';

my $found_cd = $schema->resultset('CD')->find(3);
is($found_cd->artist->name, 'Random Boy Band', 'Find inflator resolved correctly');

# Test bad Index throws
throws_ok {
  $schema->populate_more([
    { CD => {
        fields => [qw/cdid artist title year/],
        data => {
          bad => [99, '!Index:Artist.nonexistent', 'Bad', 2020],
        }}},
  ]);
} qr/Bad Index/, 'Bad Index reference throws exception';

# Test unknown inflator throws
throws_ok {
  $schema->populate_more([
    { Artist => {
        fields => [qw/artistid name/],
        data => {
          bad => [99, '!Bogus:whatever'],
        }}},
  ]);
} qr/Unknown inflator/, 'Unknown inflator throws exception';

# Disconnect to avoid leak tracker complaints
$schema->storage->disconnect;
undef $schema;

done_testing;
