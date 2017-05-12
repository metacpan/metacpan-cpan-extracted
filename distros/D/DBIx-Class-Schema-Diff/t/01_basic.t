# -*- perl -*-

use strict;
use warnings;
use FindBin '$Bin';
use lib "$Bin/lib";

use Test::More;
use Test::Exception;

use_ok('DBIx::Class::Schema::Diff');
use_ok('TestSchema::Sakila');
use_ok('TestSchema::Sakila2');
use_ok('TestSchema::Sakila3');

sub NewD { DBIx::Class::Schema::Diff->new(@_) } 

ok(
  NewD(
    old_schema => 'TestSchema::Sakila',
    new_schema => 'TestSchema::Sakila2'
  ),
  'Instantiate DBIx::Class::Schema::Diff object using class names'
);

is(
  NewD(
    old_schema => 'TestSchema::Sakila',
    new_schema => 'TestSchema::Sakila'
  )->diff,
  undef,
  "Diffing the same schema class shows no changes"
);

is(
  NewD(
    old_schema => 'TestSchema::Sakila',
    new_schema => 'TestSchema::Sakila2'
  )->diff,
  undef,
  "Diffing identical schema classes shows no changes"
);

my @connect = ('dbi:SQLite::memory:', '', '');
my $s1  = TestSchema::Sakila->connect(@connect);
my $s1b = TestSchema::Sakila->connect(@connect);
my $s3  = TestSchema::Sakila3->connect(@connect);

ok(
  NewD( old_schema => $s1, new_schema => $s1b ),
  'Instantiate DBIx::Class::Schema::Diff object using objects'
);

is(
  NewD( old_schema => $s1, new_schema => $s1b )->diff,
  undef,
  "Diffing identical schema objects shows no changes"
);

is(
  NewD( old_schema => $s1, new_schema => 'TestSchema::Sakila2' )->diff,
  undef,
  "Diffing identical schema object with class name shows no changes"
);


$s1b->source('Country')->add_columns( foo => {
  data_type => "varchar", is_nullable => 0, size => 50 
});

is_deeply(
  NewD( old_schema => $s1, new_schema => $s1b )->diff,
  {
    Country => {
      _event => "changed",
      columns => {
        foo => {
          _event => "added"
        }
      }
    }
  },
  "Saw on-the-fly added column 'foo'"
);


# add to existing columns to change their attrs:
$s1b->source('Customer')->add_columns( 
  "first_name",
  { data_type => "varchar", is_nullable => 1, size => 45 },
  "last_name",
  { data_type => "varchar", is_nullable => 0, size => 60 }
);

is_deeply(
  NewD( old_schema => $s1, new_schema => $s1b )->diff,
  {
    Country => {
      _event => "changed",
      columns => {
        foo => {
          _event => "added"
        }
      }
    },
    Customer => {
      _event => "changed",
      columns => {
        first_name => {
          _event => "changed",
          diff => {
            is_nullable => 1
          }
        },
        last_name => {
          _event => "changed",
          diff => {
            size => 60
          }
        }
      }
    }
  },
  "Saw on-the-fly changes to 'first_name' and 'last_name' columns"
);



is_deeply(
  NewD( old_schema => $s1, new_schema => $s3 )->diff,
  {
    Address => {
      _event => "changed",
      isa => [
        "+Test::DummyClass",
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
    },
    City => {
      _event => "changed",
      table_name => "city1",
      constraints => {
        primary => {
          _event => "deleted"
        }
      }
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
    Rental => {
      _event => "changed",
      relationships => {
        customer => {
          _event => "deleted"
        }
      },
      constraints => {
        rental_date => {
          _event => "deleted"
        },
        rental_date1 => {
          _event => "added"
        }
      }
    },
    SaleByStore => {
      _event => "deleted"
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
  "Saw expected changes between Sakila and Sakila3"
);

is_deeply(
  NewD( old_schema => $s3, new_schema => $s1 )->diff,
  {
    Address => {
      _event => "changed",
      isa => [
        "-Test::DummyClass"
      ],
      relationships => {
        customers2 => {
          _event => "deleted"
        },
        staffs => {
          _event => "changed",
          diff => {
            attrs => {
              cascade_delete => 0
            }
          }
        }
      },
      table_name => "address"
    },
    City => {
      _event => "changed",
      table_name => "city",
      constraints => {
        primary => {
          _event => "added"
        }
      }
    },
    Film => {
      _event => "changed",
      columns => {
        film_id => {
          _event => "changed",
          diff => {
            is_auto_increment => 1
          }
        },
        id => {
          _event => "deleted"
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
                "NC-17"
              ]
            }
          }
        },
        rental_rate => {
          _event => "changed",
          diff => {
            size => [
              4,
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
              "film_id"
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
            is_nullable => 0
          }
        }
      }
    },
    FooBar => {
      _event => "deleted"
    },
    Rental => {
      _event => "changed",
      relationships => {
        customer => {
          _event => "added"
        }
      },
      constraints => {
        rental_date => {
          _event => "added"
        },
        rental_date1 => {
          _event => "deleted"
        }
      }
    },
    SaleByStore => {
      _event => "added"
    },
    Store => {
      _event => "changed",
      constraints => {
        idx_unique_store_manager => {
          _event => "deleted"
        }
      }
    }
  },
  "Saw expected changes between Sakila3 and Sakila"
);


done_testing;


# -- for debugging:
#
#use Data::Dumper::Concise;
#print STDERR "\n\n" . Dumper(
#  NewD( old_schema => $s1, new_schema => $s3 )->diff
#) . "\n\n";
