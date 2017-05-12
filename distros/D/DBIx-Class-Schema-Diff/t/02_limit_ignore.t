# -*- perl -*-

use strict;
use warnings;
use FindBin '$Bin';
use lib "$Bin/lib";

use Test::More;
use Test::Exception;

use DBIx::Class::Schema::Diff;
use TestSchema::Sakila;
use TestSchema::Sakila3;

my @connect = ('dbi:SQLite::memory:', '', '');
my $s1  = TestSchema::Sakila->connect(@connect);
my $s3  = TestSchema::Sakila3->connect(@connect);

sub NewD { DBIx::Class::Schema::Diff->new(@_) } 

# Note: the commented out 'ignore' and 'limit' params below were
# options in an earlier version of the API that got scraped for the
# more flexible 'filter' feature. These tests were originally written
# for the limit/ignore API and later converted to equivelent code
# using filters. The original options have been left (commented out)
# for reference...

is_deeply(
  NewD( 
    old_schema => $s1, new_schema => $s3, 
    #ignore => [qw(columns relationships constraints)] 
  )->filter_out(qw(columns relationships constraints))->diff,
  {
    Address => {
      _event => "changed",
      isa => [
        "+Test::DummyClass"
      ],
      table_name => "sakila.address"
    },
    City => {
      _event => "changed",
      table_name => "city1"
    },
    FooBar => {
      _event => "added"
    },
    SaleByStore => {
      _event => "deleted"
    }
  },
  "Saw expected changes with 'ignore'"
);

is_deeply(
  NewD( 
    old_schema => $s1, new_schema => $s3, 
    #limit => [qw(table_name isa)] 
  )->filter(qw(table_name isa))->diff,
  {
    Address => {
      _event => "changed",
      isa => [
        "+Test::DummyClass"
      ],
      table_name => "sakila.address"
    },
    City => {
      _event => "changed",
      table_name => "city1"
    },
  },
  "Saw expected changes with 'limit'"
);


is_deeply(
  NewD( 
    old_schema => $s1, new_schema => $s3, 
    #limit => [qw(table_name isa)],
    #limit_sources => [qw(Address City)]
  )->filter(qw(table_name isa))->filter(qw(Address City))->diff,
  {
    Address => {
      _event => "changed",
      isa => [
        "+Test::DummyClass"
      ],
      table_name => "sakila.address"
    },
    City => {
      _event => "changed",
      table_name => "city1"
    }
  },
  "Saw expected changes with 'limit' and 'limit_sources'"
);

is_deeply(
  NewD( 
    old_schema => $s1, new_schema => $s3, 
    #ignore => [qw(columns relationships constraints)],
    #ignore_sources => [qw(FooBar SaleByStore)]
  )->filter_out(qw(columns relationships constraints FooBar SaleByStore))->diff,
  {
    Address => {
      _event => "changed",
      isa => [
        "+Test::DummyClass"
      ],
      table_name => "sakila.address"
    },
    City => {
      _event => "changed",
      table_name => "city1"
    }
  },
  "Saw expected changes with 'ignore' and 'ignore_sources'"
);

my $cust_limit = {
  Address => {
    _event => "changed",
    isa => [
      "+Test::DummyClass"
    ]
  },
  City => {
    _event => "changed",
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
    }
  }
};

is_deeply(
  NewD(
    old_schema => $s1, new_schema => $s3, 
    #limit => [qw(Film.columns City.table_name isa)],
    #limit_sources => [qw(Film Address City)]
  )->filter(qw(Film:columns City:table_name isa))->filter(qw(Film Address City))->diff,
  $cust_limit,
  "Saw expected changes with source-specific 'limit' (list style)"
);

is_deeply(
  NewD(
    old_schema => $s1, new_schema => $s3, 
    #limit => { Film => ['columns'], City => ['table_name'], '' => ['isa'] },
    #limit_sources => [qw(Film Address City)]
  )
  ->filter({ Film => {'columns'=>1}, City => {'table_name'=>1}, '*' => {'isa'=>1}})
  ->filter(qw(Film Address City))
  ->diff,
  $cust_limit,
  "Saw expected changes with source-specific 'limit' (hash style)"
);


my $cust_limit2 = {
  Address => {
    _event => "changed",
    isa => [
      "+Test::DummyClass"
    ]
  },
  City => {
    _event => "changed",
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
};


is_deeply(
  NewD(
    old_schema => $s1, new_schema => $s3, 
    #limit => [qw(Film.columns City.table_name isa)],
    #limit_sources => [qw(Film Address City)],
    #ignore_columns => [qw(rating)],
  )
  ->filter(qw(Film:columns City:table_name isa))
  ->filter(qw(Film Address City))
  ->filter_out('columns/rating')
  ->diff,
  $cust_limit2,
  "Saw expected changes with source-specific 'limit' + ignore_columns"
);


is_deeply(
  NewD(
    old_schema => $s1, new_schema => $s3, 
    #limit_columns => [qw(Film.rating Film.id)],
    #limit => [qw(columns isa)]
  )
  ->filter(qw(columns isa))
  ->filter(qw(Film:rating Film:id isa))
  ->diff,
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
        }
      }
    },
  },
  "Saw expected changes with type-specific ignores implied by limits"
);

done_testing;


# -- for debugging:
#
#use Data::Dumper::Concise;
#print STDERR "\n\n" . Dumper(
#  NewD( old_schema => $s1, new_schema => $s3 )->diff
#) . "\n\n";
