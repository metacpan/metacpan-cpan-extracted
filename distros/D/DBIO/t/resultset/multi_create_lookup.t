use strict;
use warnings;

use Test::More;
use Test::Exception;

use DBIO::Test;

# The lookup of the find_or_* / update_or_* helpers and of multi-create
# (ADR 0070, 0071) names a row by the columns of a unique constraint. What is
# not a column of it takes no part in the lookup: the alias of a key
# (me.title is title), and the lists under relationship names, which are the
# data of rows created along with the row.
#
# Everything runs on the mock storage -- no real DB.

my $schema  = DBIO::Test->init_schema(no_deploy => 1);
my $storage = $schema->storage;

sub ops {
  my ($op, $table) = @_;
  return grep {
    $_->{op} eq $op and $_->{sql} =~ /\b(?:FROM|INTO|UPDATE)\s+"?\Q$table\E"?/i
  } $storage->captured_queries;
}

sub fresh { $storage->clear_mocks; $storage->reset_captured }

# --- a list under a relationship name in a find_or_create ---------------------
fresh();
my $artist;
lives_ok {
  $artist = $schema->resultset('Artist')->find_or_create({
    name => 'Fred 3',
    cds  => [ { title => 'Noah Act', year => 2007 } ],
  });
} 'find_or_create with the cds of the artist as data lives';

my ($select) = ops(select => 'artist');
like $select->{sql}, qr/"name" = \?/, 'the artist is looked up by name';
unlike $select->{sql}, qr/cds/, 'the list is no part of the lookup';
is scalar(ops(insert => 'artist')), 1, 'the artist was created';
is scalar(ops(insert => 'cd')), 1, 'its cd was created along';

# --- a related row that is in the middle of a multi-create chain --------------
# the track belongs to a cd that carries tracks of its own
fresh();
lives_ok {
  $schema->resultset('CD')->create({
    title => 'Equinoxe', year => 1978,
    artist => { name => 'JMJ' },
    single_track => {
      title => 'o1',
      cd => {
        title => 'Oxygene', year => 1976,
        artist => { name => 'JMJ' },
        tracks => [ { title => 'o2', position => 2 } ],
      },
    },
  });
} 'multi-create through a belongs_to row that carries a list of rows lives';
is scalar(ops(insert => 'track')), 2, 'both tracks were created';

# --- alias-qualified keys -------------------------------------------------------
fresh();
$storage->mock_persistent(qr/FROM "artist"/i, [[ 7, 'Seven', 13, undef ]]);
my $seven = $schema->resultset('Artist')->first;
fresh();
$storage->mock_persistent(qr/FROM "?cd"? "?me"?/i, [[ 1, 7, 'Something Else', '2006', undef, undef ]]);

my $found;
lives_ok {
  $found = $seven->search_related('cds')->find_or_create({
    'me.title' => 'Something Else',
    'me.year'  => 2006,
  });
} 'find_or_create with alias-qualified keys lives';
ok $found && $found->in_storage, 'the existing cd was found';
is scalar(ops(insert => 'cd')), 0, 'no cd was created';
like( ( ops(select => 'cd') )[0]{sql}, qr/"me"\."title" = \?/, 'the lookup names the title' );

fresh();
lives_ok {
  $seven->search_related('cds')->find_or_new({ 'me.title' => 'Another', 'me.year' => 2006 });
} 'find_or_new with alias-qualified keys lives';

done_testing;
