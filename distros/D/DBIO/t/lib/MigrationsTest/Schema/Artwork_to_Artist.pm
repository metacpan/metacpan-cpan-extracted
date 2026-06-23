package # hide from PAUSE
    MigrationsTest::Schema::Artwork_to_Artist;

use warnings;
use strict;

use base 'MigrationsTest::BaseResult';
use MigrationsTest::Util 'check_customcond_args';

__PACKAGE__->table('artwork_to_artist');
__PACKAGE__->add_columns(
  'artwork_cd_id' => {
    data_type => 'integer',
    is_foreign_key => 1,
  },
  'artist_id' => {
    data_type => 'integer',
    is_foreign_key => 1,
  },
);
__PACKAGE__->set_primary_key(qw/artwork_cd_id artist_id/);
__PACKAGE__->belongs_to('artwork', 'MigrationsTest::Schema::Artwork', 'artwork_cd_id');
__PACKAGE__->belongs_to('artist', 'MigrationsTest::Schema::Artist', 'artist_id');

__PACKAGE__->belongs_to('artist_test_m2m', 'MigrationsTest::Schema::Artist',
  sub {
    # This is for test purposes only. A regular user does not
    # need to sanity check the passed-in arguments, this is what
    # the tests are for :)
    my $args = &check_customcond_args;

    return (
      { "$args->{foreign_alias}.artistid" => { -ident => "$args->{self_alias}.artist_id" },
        "$args->{foreign_alias}.rank"     => { '<' => 10 },
      },
      $args->{self_result_object} && {
        "$args->{foreign_alias}.artistid" => $args->{self_result_object}->artist_id,
        "$args->{foreign_alias}.rank"   => { '<' => 10 },
      }
    );
  }
);

__PACKAGE__->belongs_to('artist_test_m2m_noopt', 'MigrationsTest::Schema::Artist',
  sub {
    # This is for test purposes only. A regular user does not
    # need to sanity check the passed-in arguments, this is what
    # the tests are for :)
    my $args = &check_customcond_args;

    return (
      { "$args->{foreign_alias}.artistid" => { -ident => "$args->{self_alias}.artist_id" },
        "$args->{foreign_alias}.rank"     => { '<' => 10 },
      }
    );
  }
);

1;
