use Test::Most;

# Rails-parity omission semantics: nested collection updates no longer
# implicitly delete rows omitted from the update arguments.  Deletion now
# requires either an explicit '_delete' request (under allow_destroy) or the
# new accept_nested_for option 'delete_omitted', which restores the old
# replace-the-whole-set behavior as a deliberate opt-in.
#
# Three parent classes share the same physical 'artist'/'album' tables (the
# mapping-several-result-classes-to-one-table pattern is also used in the
# DBIO::Valiant distribution): ArtistAD (allow_destroy only), ArtistDO
# (delete_omitted only), ArtistBoth (both).  A fourth, ArtistDOCode, covers
# delete_omitted as a coderef.

{
  package DO1::Album::AD;

  use base 'DBIx::Class::Core';

  __PACKAGE__->load_components('Valiant::Result');
  __PACKAGE__->table("album");
  __PACKAGE__->resultset_class('DO1::ResultSet');
  __PACKAGE__->add_columns(
    id => { data_type => 'integer', is_nullable => 0, is_auto_increment => 1 },
    artist_id => { data_type => 'integer', is_nullable => 0, is_foreign_key => 1 },
    title => { data_type => 'varchar', is_nullable => 0, size => 48 },
  );
  __PACKAGE__->set_primary_key("id");
  __PACKAGE__->belongs_to(artist => 'DO1::Artist::AD', { 'foreign.id' => 'self.artist_id' });
  __PACKAGE__->validates(title => (presence => 1, length => [2, 48]));

  package DO1::Artist::AD;

  use base 'DBIx::Class::Core';

  __PACKAGE__->load_components('Valiant::Result');
  __PACKAGE__->table("artist");
  __PACKAGE__->resultset_class('DO1::ResultSet');
  __PACKAGE__->add_columns(
    id => { data_type => 'integer', is_nullable => 0, is_auto_increment => 1 },
    name => { data_type => 'varchar', is_nullable => 0, size => 48 },
  );
  __PACKAGE__->set_primary_key("id");
  __PACKAGE__->has_many(albums => 'DO1::Album::AD', { 'foreign.artist_id' => 'self.id' });
  __PACKAGE__->validates(name => (presence => 1, length => [2, 48]));
  __PACKAGE__->accept_nested_for(albums => { allow_destroy => 1 });

  package DO1::Album::DO;

  use base 'DBIx::Class::Core';

  __PACKAGE__->load_components('Valiant::Result');
  __PACKAGE__->table("album");
  __PACKAGE__->resultset_class('DO1::ResultSet');
  __PACKAGE__->add_columns(
    id => { data_type => 'integer', is_nullable => 0, is_auto_increment => 1 },
    artist_id => { data_type => 'integer', is_nullable => 0, is_foreign_key => 1 },
    title => { data_type => 'varchar', is_nullable => 0, size => 48 },
  );
  __PACKAGE__->set_primary_key("id");
  __PACKAGE__->belongs_to(artist => 'DO1::Artist::DO', { 'foreign.id' => 'self.artist_id' });
  __PACKAGE__->validates(title => (presence => 1, length => [2, 48]));

  package DO1::Artist::DO;

  use base 'DBIx::Class::Core';

  __PACKAGE__->load_components('Valiant::Result');
  __PACKAGE__->table("artist");
  __PACKAGE__->resultset_class('DO1::ResultSet');
  __PACKAGE__->add_columns(
    id => { data_type => 'integer', is_nullable => 0, is_auto_increment => 1 },
    name => { data_type => 'varchar', is_nullable => 0, size => 48 },
  );
  __PACKAGE__->set_primary_key("id");
  __PACKAGE__->has_many(albums => 'DO1::Album::DO', { 'foreign.artist_id' => 'self.id' });
  __PACKAGE__->validates(name => (presence => 1, length => [2, 48]));
  __PACKAGE__->accept_nested_for(albums => { delete_omitted => 1 });

  package DO1::Album::Both;

  use base 'DBIx::Class::Core';

  __PACKAGE__->load_components('Valiant::Result');
  __PACKAGE__->table("album");
  __PACKAGE__->resultset_class('DO1::ResultSet');
  __PACKAGE__->add_columns(
    id => { data_type => 'integer', is_nullable => 0, is_auto_increment => 1 },
    artist_id => { data_type => 'integer', is_nullable => 0, is_foreign_key => 1 },
    title => { data_type => 'varchar', is_nullable => 0, size => 48 },
  );
  __PACKAGE__->set_primary_key("id");
  __PACKAGE__->belongs_to(artist => 'DO1::Artist::Both', { 'foreign.id' => 'self.artist_id' });
  __PACKAGE__->validates(title => (presence => 1, length => [2, 48]));

  package DO1::Artist::Both;

  use base 'DBIx::Class::Core';

  __PACKAGE__->load_components('Valiant::Result');
  __PACKAGE__->table("artist");
  __PACKAGE__->resultset_class('DO1::ResultSet');
  __PACKAGE__->add_columns(
    id => { data_type => 'integer', is_nullable => 0, is_auto_increment => 1 },
    name => { data_type => 'varchar', is_nullable => 0, size => 48 },
  );
  __PACKAGE__->set_primary_key("id");
  __PACKAGE__->has_many(albums => 'DO1::Album::Both', { 'foreign.artist_id' => 'self.id' });
  __PACKAGE__->validates(name => (presence => 1, length => [2, 48]));
  __PACKAGE__->accept_nested_for(albums => { allow_destroy => 1, delete_omitted => 1 });

  package DO1::Album::DOCode;

  use base 'DBIx::Class::Core';

  __PACKAGE__->load_components('Valiant::Result');
  __PACKAGE__->table("album");
  __PACKAGE__->resultset_class('DO1::ResultSet');
  __PACKAGE__->add_columns(
    id => { data_type => 'integer', is_nullable => 0, is_auto_increment => 1 },
    artist_id => { data_type => 'integer', is_nullable => 0, is_foreign_key => 1 },
    title => { data_type => 'varchar', is_nullable => 0, size => 48 },
  );
  __PACKAGE__->set_primary_key("id");
  __PACKAGE__->belongs_to(artist => 'DO1::Artist::DOCode', { 'foreign.id' => 'self.artist_id' });
  __PACKAGE__->validates(title => (presence => 1, length => [2, 48]));

  package DO1::Artist::DOCode;

  use base 'DBIx::Class::Core';

  __PACKAGE__->load_components('Valiant::Result');
  __PACKAGE__->table("artist");
  __PACKAGE__->resultset_class('DO1::ResultSet');
  __PACKAGE__->add_columns(
    id => { data_type => 'integer', is_nullable => 0, is_auto_increment => 1 },
    name => { data_type => 'varchar', is_nullable => 0, size => 48 },
  );
  __PACKAGE__->set_primary_key("id");
  __PACKAGE__->has_many(albums => 'DO1::Album::DOCode', { 'foreign.artist_id' => 'self.id' });
  __PACKAGE__->validates(name => (presence => 1, length => [2, 48]));
  __PACKAGE__->accept_nested_for(albums => {
    delete_omitted => sub { my $self = shift; 1 },
  });

  package DO1::ResultSet;

  use base 'DBIx::Class::ResultSet';

  __PACKAGE__->load_components('Valiant::ResultSet');

  package DO1::Schema;

  use base 'DBIx::Class::Schema';

  __PACKAGE__->register_class(ArtistAD => 'DO1::Artist::AD');
  __PACKAGE__->register_class(AlbumAD => 'DO1::Album::AD');
  __PACKAGE__->register_class(ArtistDO => 'DO1::Artist::DO');
  __PACKAGE__->register_class(AlbumDO => 'DO1::Album::DO');
  __PACKAGE__->register_class(ArtistBoth => 'DO1::Artist::Both');
  __PACKAGE__->register_class(AlbumBoth => 'DO1::Album::Both');
  __PACKAGE__->register_class(ArtistDOCode => 'DO1::Artist::DOCode');
  __PACKAGE__->register_class(AlbumDOCode => 'DO1::Album::DOCode');
}

ok my $schema = DO1::Schema->connect('dbi:SQLite:dbname=:memory:', '', '', { RaiseError => 1 });
$schema->deploy;

# --- allow_destroy only: omission leaves rows survive ---

{
  # prefetched
  ok my $artist = $schema->resultset('ArtistAD')->create({
    name => 'AD Prefetch',
    albums => [ map { +{ title => $_ } } qw(one two three) ],
  }), 'created AD artist with three albums';
  ok $artist->valid, 'AD fixture valid';
  my %ids = map { $_->title => $_->id } $artist->albums->all;

  ok my $pre = $schema->resultset('ArtistAD')->find({ 'me.id' => $artist->id }, { prefetch => 'albums' }),
    'refetched with prefetch';
  $pre->update({ albums => [ { id => $ids{one}, title => 'one' } ] });
  ok $pre->valid, 'AD prefetch update valid';
  is $schema->resultset('AlbumAD')->search({ artist_id => $artist->id })->count, 3,
    'AD: allow_destroy alone does not delete omitted rows (prefetched)';
  is_deeply [ sort map { $_->title } $schema->resultset('AlbumAD')->search({ artist_id => $artist->id })->all ],
    ['one', 'three', 'two'], 'AD: all three titles survive (prefetched)';
}

{
  # without prefetch
  ok my $artist = $schema->resultset('ArtistAD')->create({
    name => 'AD NoPrefetch',
    albums => [ map { +{ title => $_ } } qw(one two three) ],
  }), 'created AD artist with three albums';
  ok $artist->valid, 'AD fixture valid';
  my %ids = map { $_->title => $_->id } $artist->albums->all;

  ok my $plain = $schema->resultset('ArtistAD')->find($artist->id), 'refetched without prefetch';
  $plain->update({ albums => [ { id => $ids{one}, title => 'one' } ] });
  ok $plain->valid, 'AD no-prefetch update valid';
  is $schema->resultset('AlbumAD')->search({ artist_id => $artist->id })->count, 3,
    'AD: allow_destroy alone does not delete omitted rows (no prefetch)';
}

{
  # => [] leaves all rows
  ok my $artist = $schema->resultset('ArtistAD')->create({
    name => 'AD Empty',
    albums => [ map { +{ title => $_ } } qw(one two) ],
  }), 'created AD artist with two albums';
  ok $artist->valid, 'AD fixture valid';

  ok my $pre = $schema->resultset('ArtistAD')->find({ 'me.id' => $artist->id }, { prefetch => 'albums' });
  $pre->update({ albums => [] });
  ok $pre->valid, 'AD empty-array update valid';
  is $schema->resultset('AlbumAD')->search({ artist_id => $artist->id })->count, 2,
    'AD: albums => [] does not wipe the collection without delete_omitted';
}

{
  # explicit _delete => 1 still deletes
  ok my $artist = $schema->resultset('ArtistAD')->create({
    name => 'AD Explicit',
    albums => [ map { +{ title => $_ } } qw(keep drop) ],
  }), 'created AD artist with two albums';
  ok $artist->valid, 'AD fixture valid';
  my %ids = map { $_->title => $_->id } $artist->albums->all;

  ok my $pre = $schema->resultset('ArtistAD')->find({ 'me.id' => $artist->id }, { prefetch => 'albums' });
  $pre->update({ albums => [
    { id => $ids{keep}, title => 'keep' },
    { id => $ids{drop}, _delete => 1 },
  ] });
  ok $pre->valid, 'AD explicit-delete update valid';
  is $schema->resultset('AlbumAD')->search({ artist_id => $artist->id })->count, 1,
    'AD: explicit _delete under allow_destroy still deletes';
  ok $schema->resultset('AlbumAD')->find($ids{keep}), 'AD: kept row survives';
  ok !$schema->resultset('AlbumAD')->find($ids{drop}), 'AD: explicitly-deleted row gone';
}

# --- delete_omitted only: omission deletes ---

{
  # prefetched
  ok my $artist = $schema->resultset('ArtistDO')->create({
    name => 'DO Prefetch',
    albums => [ map { +{ title => $_ } } qw(one two three) ],
  }), 'created DO artist with three albums';
  ok $artist->valid, 'DO fixture valid';
  my %ids = map { $_->title => $_->id } $artist->albums->all;

  ok my $pre = $schema->resultset('ArtistDO')->find({ 'me.id' => $artist->id }, { prefetch => 'albums' });
  $pre->update({ albums => [ { id => $ids{one}, title => 'one' } ] });
  ok $pre->valid, 'DO prefetch update valid';
  is $schema->resultset('AlbumDO')->search({ artist_id => $artist->id })->count, 1,
    'DO: delete_omitted alone deletes omitted rows (prefetched)';
  is $schema->resultset('AlbumDO')->find($ids{one})->title, 'one', 'DO: survivor is the kept row';
}

{
  # without prefetch
  ok my $artist = $schema->resultset('ArtistDO')->create({
    name => 'DO NoPrefetch',
    albums => [ map { +{ title => $_ } } qw(one two three) ],
  }), 'created DO artist with three albums';
  ok $artist->valid, 'DO fixture valid';
  my %ids = map { $_->title => $_->id } $artist->albums->all;

  ok my $plain = $schema->resultset('ArtistDO')->find($artist->id), 'refetched without prefetch';
  $plain->update({ albums => [ { id => $ids{one}, title => 'one' } ] });
  ok $plain->valid, 'DO no-prefetch update valid';
  is $schema->resultset('AlbumDO')->search({ artist_id => $artist->id })->count, 1,
    'DO: delete_omitted alone deletes omitted rows (no prefetch)';
}

{
  # => [] wipes the collection
  ok my $artist = $schema->resultset('ArtistDO')->create({
    name => 'DO Empty',
    albums => [ map { +{ title => $_ } } qw(one two) ],
  }), 'created DO artist with two albums';
  ok $artist->valid, 'DO fixture valid';

  ok my $pre = $schema->resultset('ArtistDO')->find({ 'me.id' => $artist->id }, { prefetch => 'albums' });
  $pre->update({ albums => [] });
  ok $pre->valid, 'DO empty-array update valid';
  is $schema->resultset('AlbumDO')->search({ artist_id => $artist->id })->count, 0,
    'DO: albums => [] wipes the whole collection';
}

{
  # explicit _delete => 1 does NOT delete: allow_destroy governs the explicit path
  ok my $artist = $schema->resultset('ArtistDO')->create({
    name => 'DO Explicit',
    albums => [ map { +{ title => $_ } } qw(one two) ],
  }), 'created DO artist with two albums';
  ok $artist->valid, 'DO fixture valid';
  my %ids = map { $_->title => $_->id } $artist->albums->all;

  ok my $pre = $schema->resultset('ArtistDO')->find({ 'me.id' => $artist->id }, { prefetch => 'albums' });
  # both rows are present in the update (nothing omitted), so this isolates the
  # explicit _delete flag from the omission-diff mechanism
  $pre->update({ albums => [
    { id => $ids{one}, title => 'one' },
    { id => $ids{two}, _delete => 1 },
  ] });
  ok $pre->valid, 'DO explicit-delete update valid';
  is $schema->resultset('AlbumDO')->search({ artist_id => $artist->id })->count, 2,
    'DO: explicit _delete is a no-op without allow_destroy';
  my ($marked) = grep { $_->id == $ids{two} } @{ $pre->albums->get_cache || [] };
  ok $marked, 'DO: row with _delete marker still cached';
  ok !$marked->is_marked_for_deletion, 'DO: _delete without allow_destroy did not mark the row';
}

# --- both: omission deletes AND explicit _delete deletes ---

{
  ok my $artist = $schema->resultset('ArtistBoth')->create({
    name => 'Both Combo',
    albums => [ map { +{ title => $_ } } qw(keep explicit omit) ],
  }), 'created Both artist with three albums';
  ok $artist->valid, 'Both fixture valid';
  my %ids = map { $_->title => $_->id } $artist->albums->all;

  ok my $pre = $schema->resultset('ArtistBoth')->find({ 'me.id' => $artist->id }, { prefetch => 'albums' });
  $pre->update({ albums => [
    { id => $ids{keep}, title => 'keep' },
    { id => $ids{explicit}, _delete => 1 },
    # 'omit' left out entirely
  ] });
  ok $pre->valid, 'Both combo update valid';
  is $schema->resultset('AlbumBoth')->search({ artist_id => $artist->id })->count, 1,
    'Both: only the kept row remains';
  ok $schema->resultset('AlbumBoth')->find($ids{keep}), 'Both: kept row survives';
  ok !$schema->resultset('AlbumBoth')->find($ids{explicit}), 'Both: explicit _delete row gone';
  ok !$schema->resultset('AlbumBoth')->find($ids{omit}), 'Both: omitted row also gone';
}

{
  # rel key absent from the update leaves everything untouched
  ok my $artist = $schema->resultset('ArtistBoth')->create({
    name => 'Both Untouched',
    albums => [ map { +{ title => $_ } } qw(one two) ],
  }), 'created Both artist with two albums';
  ok $artist->valid, 'Both fixture valid';

  ok my $pre = $schema->resultset('ArtistBoth')->find({ 'me.id' => $artist->id }, { prefetch => 'albums' });
  $pre->update({ name => 'Both Renamed' });
  ok $pre->valid, 'Both rename-only update valid';
  is $schema->resultset('AlbumBoth')->search({ artist_id => $artist->id })->count, 2,
    'Both: rel key absent from the update leaves rows untouched';
}

# --- delete_omitted as a coderef ---

{
  ok my $artist = $schema->resultset('ArtistDOCode')->create({
    name => 'DOCode',
    albums => [ map { +{ title => $_ } } qw(one two) ],
  }), 'created DOCode artist with two albums';
  ok $artist->valid, 'DOCode fixture valid';
  my %ids = map { $_->title => $_->id } $artist->albums->all;

  ok my $pre = $schema->resultset('ArtistDOCode')->find({ 'me.id' => $artist->id }, { prefetch => 'albums' });
  $pre->update({ albums => [ { id => $ids{one}, title => 'one' } ] });
  ok $pre->valid, 'DOCode update valid';
  is $schema->resultset('AlbumDOCode')->search({ artist_id => $artist->id })->count, 1,
    'DOCode: coderef delete_omitted deletes omitted rows, mirroring allow_destroy coderef support';
}

done_testing;
