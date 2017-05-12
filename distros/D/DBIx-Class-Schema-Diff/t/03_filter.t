# -*- perl -*-

use strict;
use warnings;
use FindBin '$Bin';
use lib "$Bin/lib";

use Test::More;
use Test::Exception;

use DBIx::Class::Schema::Diff;

ok(
  my $Diff =  DBIx::Class::Schema::Diff->new(
    old_schema => 'TestSchema::Sakila',
    new_schema => 'TestSchema::Sakila3'
  ),
  "Initialize new DBIx::Class::Schema::Diff object"
);


is_deeply(
  $Diff->filter()->diff,
  $Diff->diff,
  'Empty filter matches diff'
);
is_deeply(
  $Diff->filter_out()->diff,
  $Diff->diff,
  'Empty filter_out matches diff'
);
is_deeply(
  $Diff->filter->filter->filter_out->filter->filter_out->diff,
  $Diff->diff,
  'Chained empty filters matches diff'
);


my $added_sources_expected_diff = { FooBar => { _event => "added" } };
is_deeply(
  $Diff->filter({ source_events => 'added' })->diff,
  $added_sources_expected_diff,
  'filter "added" source_events'
);
is_deeply(
  $Diff->filter_out({ source_events => [qw(deleted changed)] })->diff,
  $added_sources_expected_diff,
  'filter_out "deleted" and "changed" source_events'
);
is_deeply(
  $Diff->filter_out({ source_events => 'deleted' })
       ->filter_out({ source_events => { changed => 1 } })
       ->diff,
  $added_sources_expected_diff,
  'filter_out "deleted" and "changed" source_events via chaining'
);

my $only_Address_expected_diff = {
  Address => {
    _event => "changed",
    isa => [
      "+Test::DummyClass"
    ],
    relationships => {
      customers2 => {
        _event => "added"
      },
      staffs => {
        _event => "changed",
        diff => {
          attrs => {
            cascade_delete => 1
          }
        }
      }
    },
    table_name => "sakila.address"
  }
};

is_deeply(
  $Diff->filter('Address')->diff,
  $only_Address_expected_diff,
  'filter all but Address (1)'
);
is_deeply(
  $Diff->filter('Address:')->diff,
  $only_Address_expected_diff,
  'filter all but Address (2)'
);
is_deeply(
  $Diff->filter({ Address => 1 })->diff,
  $only_Address_expected_diff,
  'filter all but Address (3)'
);


my $only_isa_expected_diff = {
  Address => {
    _event => "changed",
    isa => [
      "+Test::DummyClass"
    ]
  }
};
is_deeply(
  $Diff->filter('Address:isa')->diff,
  $only_isa_expected_diff,
  'filter all but Address:isa (1)'
);
is_deeply(
  $Diff->filter({ Address => { isa => 1 } })->diff,
  $only_isa_expected_diff,
  'filter all but Address:isa (2)'
);
is_deeply(
  $Diff->filter('*:isa')->diff,
  $only_isa_expected_diff,
  'filter all but *:isa (3)'
);
is_deeply(
  $Diff->filter('isa')->diff,
  $only_isa_expected_diff,
  'filter all but isa (4)'
);


is_deeply(
  $Diff->filter(qw(Film City Address:relationships))->diff,
  {
    Address => {
      _event => "changed",
      relationships => {
        customers2 => {
          _event => "added"
        },
        staffs => {
          _event => "changed",
          diff => {
            attrs => {
              cascade_delete => 1
            }
          }
        }
      }
    },
    City => {
      _event => "changed",
      constraints => {
        primary => {
          _event => "deleted"
        }
      },
      table_name => "city1"
    },
    Film => {
      _event => "changed",
      columns => {
        film_id => {
          _event => "changed",
          diff => {
            is_auto_increment => 0
          }
        },
        id => {
          _event => "added"
        },
        rating => {
          _event => "changed",
          diff => {
            extra => {
              list => [
                "G",
                "PG",
                "PG-13",
                "R",
                "NC-17",
                "TV-MA"
              ]
            }
          }
        },
        rental_rate => {
          _event => "changed",
          diff => {
            size => [
              6,
              2
            ]
          }
        }
      },
      constraints => {
        primary => {
          _event => "changed",
          diff => {
            columns => [
              "id"
            ]
          }
        }
      }
    }
  },
  "Filter to anything in City or Film, but only relationships in Address"
);

is_deeply(
  $Diff->filter(qw(table_name))->diff,
  {
    Address => {
      _event => "changed",
      table_name => "sakila.address"
    },
    City => {
      _event => "changed",
      table_name => "city1"
    }
  },
  "Filter to only changes in table_name"
);

is_deeply(
  $Diff->filter('constraints')->filter_out('rental_date')->diff,
  {
    City => {
      _event => "changed",
      constraints => {
        primary => {
          _event => "deleted"
        }
      }
    },
    Film => {
      _event => "changed",
      constraints => {
        primary => {
          _event => "changed",
          diff => {
            columns => [
              "id"
            ]
          }
        }
      }
    },
    Rental => {
      _event => "changed",
      constraints => {
        rental_date1 => {
          _event => "added"
        }
      }
    },
    Store => {
      _event => "changed",
      constraints => {
        idx_unique_store_manager => {
          _event => "added"
        }
      }
    }
  },
  "Filter to only contraints, then filter_out 'rental_date'"
);

is_deeply(
  $Diff->filter(qw(constraints relationships))
   ->filter_out(qw(staffs rental_date1 customer))
   ->filter_out({ events => 'deleted' })
   ->diff,
  {
    Address => {
      _event => "changed",
      relationships => {
        customers2 => {
          _event => "added"
        }
      }
    },
    Film => {
      _event => "changed",
      constraints => {
        primary => {
          _event => "changed",
          diff => {
            columns => [
              "id"
            ]
          }
        }
      }
    },
    Store => {
      _event => "changed",
      constraints => {
        idx_unique_store_manager => {
          _event => "added"
        }
      }
    }
  },
  "Complex chained filter/filter_out combo (1)"
);

is_deeply(
  $Diff->filter(qw(constraints relationships FooBar))
   ->filter_out(qw(staffs rental_date1 customer))
   ->filter_out({ events => 'deleted' })
   ->filter_out('Film')
   ->diff,
   {
    Address => {
      _event => "changed",
      relationships => {
        customers2 => {
          _event => "added"
        }
      }
    },
    FooBar => {
      _event => "added"
    },
    Store => {
      _event => "changed",
      constraints => {
        idx_unique_store_manager => {
          _event => "added"
        }
      }
    }
  },
  "Complex chained filter/filter_out combo (2)"
);

is_deeply(
  $Diff->filter('last_update')->diff,
  {
    FilmCategory => {
      _event => "changed",
      columns => {
        last_update => {
          _event => "changed",
          diff => {
            is_nullable => 1
          }
        }
      }
    }
  },
  "Filter the dynamic keyword 'last_update'"
);

is_deeply(
  $Diff->filter('FilmCategory:columns/last_update')->diff,
  {
    FilmCategory => {
      _event => "changed",
      columns => {
        last_update => {
          _event => "changed",
          diff => {
            is_nullable => 1
          }
        }
      }
    }
  },
  "Filter to specific 'last_update' (column of FilmCategory)"
);

is_deeply(
  $Diff->filter('columns/last_update')->diff,
  {
    FilmCategory => {
      _event => "changed",
      columns => {
        last_update => {
          _event => "changed",
          diff => {
            is_nullable => 1
          }
        }
      }
    }
  },
  "Filter to any column named 'last_update'"
);


is_deeply(
  $Diff->filter('rental_rate')->diff,
  {
    Film => {
      _event => "changed",
      columns => {
        rental_rate => {
          _event => "changed",
          diff => {
            size => [
              6,
              2
            ]
          }
        }
      }
    }
  },
  "Filter to any keyword/identifier 'rental_rate'"
);

is_deeply(
  $Diff->filter(qw(constraints relationships FooBar last_update))
   ->filter_out(qw(staffs rental_date1 customer))
   ->filter_out({ events => 'deleted' })
   ->filter_out('Film')
   ->diff,
   {
    Address => {
      _event => "changed",
      relationships => {
        customers2 => {
          _event => "added"
        }
      }
    },
    FilmCategory => {
      _event => "changed",
      columns => {
        last_update => {
          _event => "changed",
          diff => {
            is_nullable => 1
          }
        }
      }
    },
    FooBar => {
      _event => "added"
    },
    Store => {
      _event => "changed",
      constraints => {
        idx_unique_store_manager => {
          _event => "added"
        }
      }
    }
  },
  "Complex chained filter/filter_out combo (3)"
);

is(
  $Diff->filter('something_which_will_not_be_found')->diff,
  undef,
  'Filtering on a invalid keyword results in an empty diff (undef)'
);

my $target_extra_list = {
  Film => {
    _event => "changed",
    columns => {
      rating => {
        _event => "changed",
        diff => {
          extra => {
            list => [
              "G",
              "PG",
              "PG-13",
              "R",
              "NC-17",
              "TV-MA"
            ]
          }
        }
      }
    }
  }
};

is_deeply(
  $Diff->filter('*.extra')->diff,
  $target_extra_list,
  "Filter to only column/relationship info with 'extra'"
);

is_deeply(
  $Diff->filter('*.extra.list')->diff,
  $target_extra_list,
  "Filter to only column/relationship info with 'extra.list'"
);

is_deeply(
  $Diff->filter('columns/*.extra.list')->diff,
  $target_extra_list,
  "Filter to only column info with 'extra.list'"
);

is_deeply(
  $Diff->filter('Film:*.extra')->diff,
  $target_extra_list,
  "Filter to only column/relationship info with 'extra' in 'Film'"
);

is_deeply(
  $Diff->filter('Film:columns/*.extra')->diff,
  $target_extra_list,
  "Filter to only column info with 'extra' in 'Film'"
);

is_deeply(
  $Diff->filter('Film:columns/rating.extra')->diff,
  $target_extra_list,
  "Filter to only 'rating' column info with 'extra' in 'Film'"
);

is_deeply(
  $Diff->filter('Film:columns/rating.extra.list')->diff,
  $target_extra_list,
  "Filter to only 'rating' column info with 'extra.list' in 'Film'"
);

is_deeply(
  $Diff->filter('columns/rating.extra.list')->diff,
  $target_extra_list,
  "Filter to only 'rating' column info with 'extra.list'"
);

is_deeply(
  $Diff->filter('rating.extra.list')->diff,
  $target_extra_list,
  "Filter to only 'rating' column/relationship info with 'extra.list'"
);


is_deeply(
  $Diff->filter(qw(isa *.is_nullable *.size))->diff,
  {
    Address => {
      _event => "changed",
      isa => [
        "+Test::DummyClass"
      ]
    },
    Film => {
      _event => "changed",
      columns => {
        rental_rate => {
          _event => "changed",
          diff => {
            size => [
              6,
              2
            ]
          }
        }
      }
    },
    FilmCategory => {
      _event => "changed",
      columns => {
        last_update => {
          _event => "changed",
          diff => {
            is_nullable => 1
          }
        }
      }
    }
  },
  "Filter to only info 'is_nullable' or 'size' + isa"
);

is_deeply(
  $Diff->filter(qw(table_name relationships/*.attrs.cascade_delete))->diff,
  {
    Address => {
      _event => "changed",
      relationships => {
        staffs => {
          _event => "changed",
          diff => {
            attrs => {
              cascade_delete => 1
            }
          }
        }
      },
      table_name => "sakila.address"
    },
    City => {
      _event => "changed",
      table_name => "city1"
    }
  },
  "Filter to only relationship cascade_delete attrs + table_name"
);

is_deeply(
  $Diff->filter('relationships')->filter_out('*.attrs')->diff,
  {
    Address => {
      _event => "changed",
      relationships => {
        customers2 => {
          _event => "added"
        }
      }
    },
    Rental => {
      _event => "changed",
      relationships => {
        customer => {
          _event => "deleted"
        }
      }
    }
  },
  "Filter to only relationships, excluding attrs"
);

done_testing;
