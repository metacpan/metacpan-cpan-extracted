use Test::Most;

# allow_destroy on a SINGLE (might_have / belongs_to) relationship: a nested
# { _delete => 1 } must delete the related row when the parent declares
# accept_nested_for($rel, { allow_destroy => 1 }), exactly as it does for
# has_many relationships.

{
  package SRD1::Schema::Result::Bio;

  use base 'DBIx::Class::Core';

  __PACKAGE__->load_components('Valiant::Result');
  __PACKAGE__->table("bio");
  __PACKAGE__->resultset_class('SRD1::Schema::ResultSet');
  __PACKAGE__->add_columns(
    id => { data_type => 'integer', is_nullable => 0, is_auto_increment => 1 },
    artist_id => { data_type => 'integer', is_nullable => 0 },
    text => { data_type => 'varchar', is_nullable => 0, size => 96 },
  );
  __PACKAGE__->set_primary_key("id");
  __PACKAGE__->belongs_to(artist => 'SRD1::Schema::Result::Artist', { 'foreign.id' => 'self.artist_id' });
  __PACKAGE__->validates(text => (presence => 1, length => [2, 96]));

  package SRD1::Schema::Result::Artist;

  use base 'DBIx::Class::Core';

  __PACKAGE__->load_components('Valiant::Result');
  __PACKAGE__->table("artist");
  __PACKAGE__->resultset_class('SRD1::Schema::ResultSet');
  __PACKAGE__->add_columns(
    id => { data_type => 'integer', is_nullable => 0, is_auto_increment => 1 },
    name => { data_type => 'varchar', is_nullable => 0, size => 48 },
  );
  __PACKAGE__->set_primary_key("id");
  __PACKAGE__->might_have(bio => 'SRD1::Schema::Result::Bio', { 'foreign.artist_id' => 'self.id' });
  __PACKAGE__->validates(name => (presence => 1));
  __PACKAGE__->accept_nested_for(bio => { allow_destroy => 1 });

  package SRD1::Schema::ResultSet;

  use base 'DBIx::Class::ResultSet';

  __PACKAGE__->load_components('Valiant::ResultSet');

  package SRD1::Schema;

  use base 'DBIx::Class::Schema';

  __PACKAGE__->register_class(Artist => 'SRD1::Schema::Result::Artist');
  __PACKAGE__->register_class(Bio => 'SRD1::Schema::Result::Bio');
}

ok my $schema = SRD1::Schema->connect('dbi:SQLite:dbname=:memory:', '', '', { RaiseError => 1 });
$schema->deploy;

ok my $artist = $schema->resultset('Artist')->create({
  name => 'Nirvana',
  bio => { text => 'grunge legends' },
}), 'created artist with nested bio';
ok $artist->valid, 'fixture graph valid';
is $schema->resultset('Bio')->count, 1, 'bio row persisted';

ok $artist = $schema->resultset('Artist')->find({ 'me.id' => $artist->id }, { prefetch => 'bio' }),
  'refetched artist with prefetched bio';
ok my $bio_id = $artist->bio->id, 'have bio id';

$artist->update({ bio => { id => $bio_id, _delete => 1 } });
ok $artist->valid, 'update had no validation errors';

ok !$schema->resultset('Bio')->find($bio_id), 'bio row deleted via nested _delete under allow_destroy';
is $schema->resultset('Bio')->count, 0, 'no bio rows remain';
ok $schema->resultset('Artist')->find($artist->id), 'artist itself untouched';

done_testing;
