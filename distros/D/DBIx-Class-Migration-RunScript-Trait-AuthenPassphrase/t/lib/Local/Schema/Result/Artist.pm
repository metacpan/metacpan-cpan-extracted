package Local::Schema::Result::Artist;
use base qw/DBIx::Class::Core/;

__PACKAGE__->load_components(qw(PassphraseColumn));
__PACKAGE__->table('artist');

__PACKAGE__->add_columns(
  artist_id => {
    data_type => 'integer',
    is_auto_increment => 1,
  },
  country_fk => {
    data_type => 'integer',
    is_foreign_key => 1,
  },
  name => {
    data_type => 'varchar',
    size => '96',
  },
  passphrase => {
    data_type => 'text',
    passphrase => 'rfc2307',
    passphrase_class => 'SaltedDigest',
    passphrase_args  => {
      algorithm   => 'SHA-1',
      salt_random => 20,
    },
    passphrase_check_method => 'check_passphrase',
  });

__PACKAGE__->set_primary_key('artist_id');

__PACKAGE__->has_many(
  'artist_cd_rs' => 'Local::Schema::Result::ArtistCd',
  {'foreign.artist_fk'=>'self.artist_id'});

__PACKAGE__->many_to_many(artist_cds => artist_cd_rs => 'cd');

__PACKAGE__->belongs_to(
  'has_country' => 'Local::Schema::Result::Country',
  {'foreign.country_id'=>'self.country_fk'});

1;
