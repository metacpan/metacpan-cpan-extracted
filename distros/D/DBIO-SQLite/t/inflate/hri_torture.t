use strict;
use warnings;

use Test::More;
use Test::Deep;
use DBIO::SQLite::Test;
# More tests like this in t/prefetch/manual.t

my $schema = DBIO::SQLite::Test->init_schema(no_populate => 1, quote_names => 1);
$schema->resultset('Artist')->create({ name => 'JMJ', cds => [{
  title => 'Magnetic Fields',
  year => 1981,
  genre => { name => 'electro' },
  tracks => [
    { title => 'm1' },
    { title => 'm2' },
    { title => 'm3' },
    { title => 'm4' },
  ],
} ] });


$schema->resultset('CD')->create({
  title => 'Equinoxe',
  year => 1978,
  artist => { name => 'JMJ' },
  genre => { name => 'electro' },
  tracks => [
    { title => 'e1' },
    { title => 'e2' },
    { title => 'e3' },
  ],
  single_track => {
    title => 'o1',
    cd => {
      title => 'Oxygene',
      year => 1976,
      artist => { name => 'JMJ' },
      tracks => [
        { title => 'o2', position => 2},  # the position should not be needed here, bug in MC
      ],
    },
  },
});

for (1,2) {
  $schema->resultset('CD')->create({ artist => 1, year => 1977, title => "fuzzy_$_" });
}

{
  package DBIO::Test::HRI::Subclass;
  use base 'DBIO::ResultClass::HashRefInflator';
}

{
  package DBIO::Test::HRI::Around;
  use base 'DBIO::ResultClass::HashRefInflator';

  sub inflate_result { shift->next::method(@_) }
}

for my $rs (
  $schema->resultset('CD')->search_rs({}, { result_class => 'DBIO::ResultClass::HashRefInflator' }),
  $schema->resultset('CD')->search_rs({}, { result_class => 'DBIO::Test::HRI::Subclass' }),
  $schema->resultset('CD')->search_rs({}, { result_class => 'DBIO::Test::HRI::Around' }),
) {

cmp_deeply
  [ $rs->search({}, {
    columns => {
      year                          => 'me.year',
      'single_track.cd.artist.name' => 'artist.name',
    },
    join => { single_track => { cd => 'artist' } },
    order_by => [qw/me.cdid artist.artistid/],
  })->all ],
  [
    { year => 1981, single_track => undef },
    { year => 1976, single_track => undef },
    { year => 1978, single_track => {
      cd => {
        artist => { name => "JMJ" }
      },
    }},
    { year => 1977, single_track => undef },
    { year => 1977, single_track => undef },

  ],
  'plain 1:1 descending chain ' . $rs->result_class
;

cmp_deeply
  [ $rs->search({}, {
    columns => {
      'artist'                                  => 'me.artist',
      'title'                                   => 'me.title',
      'year'                                    => 'me.year',
      'single_track.cd.artist.artistid'         => 'artist.artistid',
      'single_track.cd.artist.cds.cdid'         => 'cds.cdid',
      'single_track.cd.artist.cds.tracks.title' => 'tracks.title',
    },
    join => { single_track => { cd => { artist => { cds => 'tracks' } } } },
    order_by => [qw/me.cdid artist.artistid cds.cdid tracks.trackid/],
  })->all ],
  [
    {
      artist => 1, title => "Magnetic Fields", year => 1981, single_track => undef,
    },
    {
      artist => 1, title => "Oxygene", year => 1976, single_track => undef,
    },
    {
      artist => 1, title => "Equinoxe", year => 1978, single_track => {
        cd => {
          artist => {
            artistid => 1, cds => {
              cdid => 1, tracks => {
                title => "m1"
              }
            }
          }
        }
      },
    },
    {
      artist => 1, title => "Equinoxe", year => 1978, single_track => {
        cd => {
          artist => {
            artistid => 1, cds => {
              cdid => 1, tracks => {
                title => "m2"
              }
            }
          }
        }
      },
    },
    {
      artist => 1, title => "Equinoxe", year => 1978, single_track => {
        cd => {
          artist => {
            artistid => 1, cds => {
              cdid => 1, tracks => {
                title => "m3"
              }
            }
          }
        }
      },
    },
    {
      artist => 1, title => "Equinoxe", year => 1978, single_track => {
        cd => {
          artist => {
            artistid => 1, cds => {
              cdid => 1, tracks => {
                title => "m4"
              }
            }
          }
        }
      },
    },
    {
      artist => 1, title => "Equinoxe", year => 1978, single_track => {
        cd => {
          artist => {
            artistid => 1, cds => {
              cdid => 2, tracks => {
                title => "o2"
              }
            }
          }
        }
      },
    },
    {
      artist => 1, title => "Equinoxe", year => 1978, single_track => {
        cd => {
          artist => {
            artistid => 1, cds => {
              cdid => 2, tracks => {
                title => "o1"
              }
            }
          }
        }
      },
    },
    {
      artist => 1, title => "Equinoxe", year => 1978, single_track => {
        cd => {
          artist => {
            artistid => 1, cds => {
              cdid => 3, tracks => {
                title => "e1"
              }
            }
          }
        }
      },
    },
    {
      artist => 1, title => "Equinoxe", year => 1978, single_track => {
        cd => {
          artist => {
            artistid => 1, cds => {
              cdid => 3, tracks => {
                title => "e2"
              }
            }
          }
        }
      },
    },
    {
      artist => 1, title => "Equinoxe", year => 1978, single_track => {
        cd => {
          artist => {
            artistid => 1, cds => {
              cdid => 3, tracks => {
                title => "e3"
              }
            }
          }
        }
      },
    },
    {
      artist => 1, title => "Equinoxe", year => 1978, single_track => {
        cd => {
          artist => {
            artistid => 1, cds => {
              cdid => 4, tracks => undef
            }
          }
        }
      },
    },
    {
      artist => 1, title => "Equinoxe", year => 1978, single_track => {
        cd => {
          artist => {
            artistid => 1, cds => {
              cdid => 5, tracks => undef
            }
          }
        }
      },
    },
    {
      artist => 1, title => "fuzzy_1", year => 1977, single_track => undef,
    },
    {
      artist => 1, title => "fuzzy_2", year => 1977, single_track => undef,
    }
  ],
  'non-collapsing 1:1:1:M:M chain ' . $rs->result_class,
;

cmp_deeply
  [ $rs->search({}, {
    columns => {
      'artist'                                  => 'me.artist',
      'title'                                   => 'me.title',
      'year'                                    => 'me.year',
      'single_track.cd.artist.artistid'         => 'artist.artistid',
      'single_track.cd.artist.cds.cdid'         => 'cds.cdid',
      'single_track.cd.artist.cds.tracks.title' => 'tracks.title',
    },
    join => { single_track => { cd => { artist => { cds => 'tracks' } } } },
    order_by => [qw/me.cdid artist.artistid cds.cdid tracks.trackid/],
    collapse => 1,
  })->all ],
  [
    {
      artist => 1, title => "Magnetic Fields", year => 1981, single_track => undef,
    },
    {
      artist => 1, title => "Oxygene", year => 1976, single_track => undef,
    },
    {
      artist => 1, title => "Equinoxe", year => 1978, single_track => {
        cd => {
          artist => {
            artistid => 1, cds => [
              {
                cdid => 1, tracks => [
                  { title => "m1" },
                  { title => "m2" },
                  { title => "m3" },
                  { title => "m4" },
                ]
              },
              {
                cdid => 2, tracks => [
                  { title => "o2" },
                  { title => "o1" },
                ]
              },
              {
                cdid => 3, tracks => [
                  { title => "e1" },
                  { title => "e2" },
                  { title => "e3" },
                ]
              },
              {
                cdid => 4, tracks => [],
              },
              {
                cdid => 5, tracks => [],
              }
            ]
          }
        }
      },
    },
    {
      artist => 1, title => "fuzzy_1", year => 1977, single_track => undef,
    },
    {
      artist => 1, title => "fuzzy_2", year => 1977, single_track => undef,
    }
  ],
  'collapsing 1:1:1:M:M chain ' . $rs->result_class,
;

}

done_testing;
