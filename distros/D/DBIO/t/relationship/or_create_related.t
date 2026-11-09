use strict;
use warnings;

use Test::More;
use Test::Exception;

use DBIO::Test;

# ADR 0070 section 3: find_or_new_related and find_or_create_related run the
# helpers of the related resultset. The data identifies the row by the columns
# of the one unique constraint it covers (the foreign key the resultset holds
# counts), the other values are the data of the row to create.
#
# Everything runs on the mock storage -- no real DB.

my $schema  = DBIO::Test->init_schema(no_deploy => 1);
my $storage = $schema->storage;

# the text of a refused create names the column, never a value (ADR 0071)
sub values_absent {
  my $text = "$@";
  unlike $text, qr/\b\Q$_\E\b/, "the text holds no $_" for @_;
}

sub ops {
  my ($op, $table) = @_;
  return grep {
    $_->{op} eq $op and $_->{sql} =~ /\b(?:FROM|INTO|UPDATE)\s+"?\Q$table\E"?/i
  } $storage->captured_queries;
}

sub fresh { $storage->clear_mocks; $storage->reset_captured }

$storage->mock_persistent(qr/FROM "artist"/i, [[ 7, 'Seven', 13, undef ]]);
my $artist = $schema->resultset('Artist')->first;

my $existing = [[ 1, 7, 'Known', '1999', undef, undef ]];

for my $method (qw(find_or_create_related find_or_new_related)) {
  # the row exists: found by artist and title, the year is no part of the lookup
  fresh();
  $storage->mock_persistent(qr/FROM "?cd"? "?me"?/i, $existing);

  my $cd = $artist->$method('cds', { title => 'Known', year => 2020 }, { key => 'cd_artist_title' });
  ok $cd->in_storage, "$method: the existing row is found";
  is $cd->year, '1999', "$method: the year of the data does not restrict the lookup";
  unlike( ( ops(select => 'cd') )[0]{sql}, qr/"year" = \?/, "$method: the year is not in the query" );
  is scalar(ops(insert => 'cd')), 0, "$method: nothing is created";

  # no such row: the other values are the data of the new row
  fresh();
  $cd = $artist->$method('cds', { title => 'New', year => 2020 }, { key => 'cd_artist_title' });
  is $cd->year, 2020, "$method: the new row has the data";
  is $cd->get_column('artist'), 7, "$method: the new row has the foreign key";
  is $cd->in_storage ? 1 : 0, $method eq 'find_or_create_related' ? 1 : 0,
    "$method: created or only built";

  # data that covers no constraint
  throws_ok { $artist->$method('cds', { year => 2020 }) }
    qr/needs a condition that gives every column of one unique constraint/,
    "$method: data covering no constraint throws";
}

# the data of the row to create are checked against the foreign key of the resultset
fresh();
throws_ok { $artist->find_or_create_related('cds', { artist => 999, title => 'Other' }) }
  qr/'artist' is fixed to a value by the condition, got another value/,
  'find_or_create_related: a foreign key against the parent throws';
values_absent(7, 999);

# a belongs_to whose key is NULL holds IS NULL for the related primary key:
# creating the related row with a key of its own contradicts it
fresh();
$storage->mock_persistent(qr/FROM "?cd"? "?me"?/i, [[ 1, 7, 'Known', '1999', undef, undef ]]);
my $cd = $schema->resultset('CD')->first;
$cd->artist(undef);
throws_ok {
  $cd->find_or_new_related('artist', { name => 'Random Boy Band Two', artistid => 200 }, { key => 'primary' })
} qr/'artistid' is fixed to NULL by the condition, got a value/,
  'find_or_new_related over a belongs_to with a NULL key: a key of the caller against IS NULL throws';
values_absent(200);

# an odd list of search arguments is refused without quoting them
delete $artist->{related_resultsets};
throws_ok { $artist->related_resultset('cds', 'secret-one', 'secret-two', 'secret-three') }
  qr/Invalid query: an odd number of arguments/,
  'related_resultset with an odd argument list throws';
unlike "$@", qr/secret/, '... and the text holds none of the arguments';

done_testing;
