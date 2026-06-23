use strict;
use warnings;

use Test::More;
use Test::Warn;
use DBIO::Test;

{
  package DBIO::Test::ArtistRS;
  use strict;
  use warnings;
  use base qw/DBIO::ResultSet/;
}

my $schema = DBIO::Test->init_schema(no_deploy => 1);
my $artist_source = $schema->source('Artist');

my $new_source = DBIO::ResultSource::Table->new({
  %$artist_source,
  name            => 'artist_preview',
  resultset_class => 'DBIO::Test::ArtistRS',
  _relationships  => {}, # copying them as-is is bad taste
});
$new_source->add_column('other_col' => { data_type => 'integer', default_value => 1 });

{
  $schema->register_extra_source( 'artist->extra' => $new_source );

  my $primary_source = $schema->source('DBIO::Test::Schema::Artist');
  is($primary_source->source_name, 'Artist', 'original source still primary source');
  ok(! $primary_source->has_column('other_col'), 'column definition did not leak to original source');
  isa_ok($schema->resultset ('artist->extra'), 'DBIO::Test::ArtistRS');
}

warnings_are (sub {
  my $source = $schema->source('DBIO::Test::Schema::Artist');
  $schema->register_source($source->source_name, $source);
}, [], 're-registering an existing source under the same name causes no warnings' );

warnings_like (
  sub {
    my $new_source_name = 'Artist->preview(artist_preview)';
    $schema->register_source( $new_source_name => $new_source );

    my $primary_source = $schema->source('DBIO::Test::Schema::Artist');
    is($primary_source->source_name, $new_source_name, 'new source is primary source');
    ok($primary_source->has_column('other_col'), 'column correctly defined on new source');

    isa_ok ($schema->resultset ($new_source_name), 'DBIO::Test::ArtistRS');

    my $original_source = $schema->source('Artist');
    ok(! $original_source->has_column('other_col'), 'column definition did not leak to original source');
    isa_ok ($original_source->resultset, 'DBIO::ResultSet');
    isa_ok ($schema->resultset('Artist'), 'DBIO::ResultSet');
  },
  [
    qr/DBIO::Test::Schema::Artist already had a registered source which was replaced by this call/
  ],
  'registering source to an existing result warns'
);

done_testing;
