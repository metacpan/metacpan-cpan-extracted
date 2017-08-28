# -*- perl -*-

use strict;
use warnings;
use FindBin '$Bin';
use lib "$Bin/lib";

use DBIx::Class::Core ();
my @Core_ISA = @{ mro::get_linear_isa('DBIx::Class::Core') };

use Test::More;
use Test::Exception;

use aliased 'DBIx::Class::Schema::Diff';
use aliased 'DBIx::Class::Schema::Diff::SchemaData';

ok(
  my $SD1 =  SchemaData->new( schema => 'TestSchema::Sakila' ),
  "Initialize stand-alone SchemaData object using class name"
);

my $sig = 'schemsum-99a438a6df22065';
is(
  $SD1->fingerprint => $sig,
  "Saw expected SchemaData fingerprint ($sig)"
);

ok(
  my $SD2 =  $SD1->prune('private_col_attrs'),
  "Initialize new SchemaData object via ->prune('private_col_attrs')"
);

is_deeply( 
  $SD2->data => &_data_pruned_private_col_attrs,
  "Saw expected pruned Sakila schema data (1)"
);

$sig = 'schemsum-644d1615709c7d8';
is(
  $SD2->fingerprint => $sig,
  "Saw expected pruned SchemaData fingerprint ($sig)"
);

ok(
  my $SD3 =  $SD2->prune('isa','constraints'),
  "Initialize new SchemaData object via ->prune('isa','constraints')"
);


is_deeply( 
  $SD3->data => &_data_pruned_private_col_attrs_isa_constraints,
  "Saw expected pruned Sakila schema data (2)"
);

$sig = 'schemsum-30ba1112b1b42f5';
is(
  $SD3->fingerprint => $sig,
  "Saw expected pruned (2) SchemaData fingerprint ($sig)"
);


done_testing;


# This is in a sub at the end just to prevent scrolling since its so long:
sub _data_pruned_private_col_attrs { my $h = {
  schema_class => "TestSchema::Sakila",
  sources => {
    Actor => {
      columns => {
        actor_id => {
          data_type => "smallint",
          extra => {
            unsigned => 1
          },
          is_auto_increment => 1,
          is_nullable => 0
        },
        first_name => {
          data_type => "varchar",
          is_nullable => 0,
          size => 45
        },
        last_name => {
          data_type => "varchar",
          is_nullable => 0,
          size => 45
        },
        last_update => {
          data_type => "timestamp",
          datetime_undef_if_invalid => 1,
          default_value => "\\\"current_timestamp\"",
          is_nullable => 0
        }
      },
      constraints => {
        primary => {
          columns => [
            "actor_id"
          ]
        }
      },
      isa => [
        "{schema_class}::Result::Actor",
        "DBIx::Class::InflateColumn::DateTime",
        @Core_ISA,
      ],
      relationships => {
        film_actors => {
          attrs => {
            accessor => "multi",
            cascade_copy => 0,
            cascade_delete => 0,
            is_depends_on => 0,
            join_type => "LEFT"
          },
          class => "{schema_class}::Result::FilmActor",
          cond => {
            "foreign.actor_id" => "self.actor_id"
          },
          source => "{schema_class}::Result::FilmActor"
        }
      },
      table_name => "actor"
    },
    ActorInfo => {
      columns => {
        actor_id => {
          data_type => "smallint",
          default_value => 0,
          extra => {
            unsigned => 1
          },
          is_nullable => 0
        },
        film_info => {
          data_type => "varchar",
          is_nullable => 1,
          size => 341
        },
        first_name => {
          data_type => "varchar",
          is_nullable => 0,
          size => 45
        },
        last_name => {
          data_type => "varchar",
          is_nullable => 0,
          size => 45
        }
      },
      constraints => {},
      isa => [
        "{schema_class}::Result::ActorInfo",
        "DBIx::Class::InflateColumn::DateTime",
        @Core_ISA,
      ],
      relationships => {},
      table_name => "actor_info"
    },
    Address => {
      columns => {
        address => {
          data_type => "varchar",
          is_nullable => 0,
          size => 50
        },
        address2 => {
          data_type => "varchar",
          is_nullable => 1,
          size => 50
        },
        address_id => {
          data_type => "smallint",
          extra => {
            unsigned => 1
          },
          is_auto_increment => 1,
          is_nullable => 0
        },
        city_id => {
          data_type => "smallint",
          extra => {
            unsigned => 1
          },
          is_foreign_key => 1,
          is_nullable => 0
        },
        district => {
          data_type => "varchar",
          is_nullable => 0,
          size => 20
        },
        last_update => {
          data_type => "timestamp",
          datetime_undef_if_invalid => 1,
          default_value => "\\\"current_timestamp\"",
          is_nullable => 0
        },
        phone => {
          data_type => "varchar",
          is_nullable => 0,
          size => 20
        },
        postal_code => {
          data_type => "varchar",
          is_nullable => 1,
          size => 10
        }
      },
      constraints => {
        primary => {
          columns => [
            "address_id"
          ]
        }
      },
      isa => [
        "{schema_class}::Result::Address",
        "DBIx::Class::InflateColumn::DateTime",
        @Core_ISA,
      ],
      relationships => {
        city => {
          attrs => {
            accessor => "single",
            fk_columns => {
              city_id => 1
            },
            is_deferrable => 1,
            is_depends_on => 1,
            is_foreign_key_constraint => 1,
            on_delete => "CASCADE",
            on_update => "CASCADE",
            undef_on_null_fk => 1
          },
          class => "{schema_class}::Result::City",
          cond => {
            "foreign.city_id" => "self.city_id"
          },
          source => "{schema_class}::Result::City"
        },
        customers => {
          attrs => {
            accessor => "multi",
            cascade_copy => 0,
            cascade_delete => 0,
            is_depends_on => 0,
            join_type => "LEFT"
          },
          class => "{schema_class}::Result::Customer",
          cond => {
            "foreign.address_id" => "self.address_id"
          },
          source => "{schema_class}::Result::Customer"
        },
        staffs => {
          attrs => {
            accessor => "multi",
            cascade_copy => 0,
            cascade_delete => 0,
            is_depends_on => 0,
            join_type => "LEFT"
          },
          class => "{schema_class}::Result::Staff",
          cond => {
            "foreign.address_id" => "self.address_id"
          },
          source => "{schema_class}::Result::Staff"
        },
        stores => {
          attrs => {
            accessor => "multi",
            cascade_copy => 0,
            cascade_delete => 0,
            is_depends_on => 0,
            join_type => "LEFT"
          },
          class => "{schema_class}::Result::Store",
          cond => {
            "foreign.address_id" => "self.address_id"
          },
          source => "{schema_class}::Result::Store"
        }
      },
      table_name => "address"
    },
    Category => {
      columns => {
        category_id => {
          data_type => "tinyint",
          extra => {
            unsigned => 1
          },
          is_auto_increment => 1,
          is_nullable => 0
        },
        last_update => {
          data_type => "timestamp",
          datetime_undef_if_invalid => 1,
          default_value => "\\\"current_timestamp\"",
          is_nullable => 0
        },
        name => {
          data_type => "varchar",
          is_nullable => 0,
          size => 25
        }
      },
      constraints => {
        primary => {
          columns => [
            "category_id"
          ]
        }
      },
      isa => [
        "{schema_class}::Result::Category",
        "DBIx::Class::InflateColumn::DateTime",
        @Core_ISA,
      ],
      relationships => {
        film_categories => {
          attrs => {
            accessor => "multi",
            cascade_copy => 0,
            cascade_delete => 0,
            is_depends_on => 0,
            join_type => "LEFT"
          },
          class => "{schema_class}::Result::FilmCategory",
          cond => {
            "foreign.category_id" => "self.category_id"
          },
          source => "{schema_class}::Result::FilmCategory"
        }
      },
      table_name => "category"
    },
    City => {
      columns => {
        city => {
          data_type => "varchar",
          is_nullable => 0,
          size => 50
        },
        city_id => {
          data_type => "smallint",
          extra => {
            unsigned => 1
          },
          is_auto_increment => 1,
          is_nullable => 0
        },
        country_id => {
          data_type => "smallint",
          extra => {
            unsigned => 1
          },
          is_foreign_key => 1,
          is_nullable => 0
        },
        last_update => {
          data_type => "timestamp",
          datetime_undef_if_invalid => 1,
          default_value => "\\\"current_timestamp\"",
          is_nullable => 0
        }
      },
      constraints => {
        primary => {
          columns => [
            "city_id"
          ]
        }
      },
      isa => [
        "{schema_class}::Result::City",
        "DBIx::Class::InflateColumn::DateTime",
        @Core_ISA,
      ],
      relationships => {
        addresses => {
          attrs => {
            accessor => "multi",
            cascade_copy => 0,
            cascade_delete => 0,
            is_depends_on => 0,
            join_type => "LEFT"
          },
          class => "{schema_class}::Result::Address",
          cond => {
            "foreign.city_id" => "self.city_id"
          },
          source => "{schema_class}::Result::Address"
        },
        country => {
          attrs => {
            accessor => "single",
            fk_columns => {
              country_id => 1
            },
            is_deferrable => 1,
            is_depends_on => 1,
            is_foreign_key_constraint => 1,
            on_delete => "CASCADE",
            on_update => "CASCADE",
            undef_on_null_fk => 1
          },
          class => "{schema_class}::Result::Country",
          cond => {
            "foreign.country_id" => "self.country_id"
          },
          source => "{schema_class}::Result::Country"
        }
      },
      table_name => "city"
    },
    Country => {
      columns => {
        country => {
          data_type => "varchar",
          is_nullable => 0,
          size => 50
        },
        country_id => {
          data_type => "smallint",
          extra => {
            unsigned => 1
          },
          is_auto_increment => 1,
          is_nullable => 0
        },
        last_update => {
          data_type => "timestamp",
          datetime_undef_if_invalid => 1,
          default_value => "\\\"current_timestamp\"",
          is_nullable => 0
        }
      },
      constraints => {
        primary => {
          columns => [
            "country_id"
          ]
        }
      },
      isa => [
        "{schema_class}::Result::Country",
        "DBIx::Class::InflateColumn::DateTime",
        @Core_ISA,
      ],
      relationships => {
        cities => {
          attrs => {
            accessor => "multi",
            cascade_copy => 0,
            cascade_delete => 0,
            is_depends_on => 0,
            join_type => "LEFT"
          },
          class => "{schema_class}::Result::City",
          cond => {
            "foreign.country_id" => "self.country_id"
          },
          source => "{schema_class}::Result::City"
        }
      },
      table_name => "country"
    },
    Customer => {
      columns => {
        active => {
          data_type => "tinyint",
          default_value => 1,
          is_nullable => 0
        },
        address_id => {
          data_type => "smallint",
          extra => {
            unsigned => 1
          },
          is_foreign_key => 1,
          is_nullable => 0
        },
        create_date => {
          data_type => "datetime",
          datetime_undef_if_invalid => 1,
          is_nullable => 0
        },
        customer_id => {
          data_type => "smallint",
          extra => {
            unsigned => 1
          },
          is_auto_increment => 1,
          is_nullable => 0
        },
        email => {
          data_type => "varchar",
          is_nullable => 1,
          size => 50
        },
        first_name => {
          data_type => "varchar",
          is_nullable => 0,
          size => 45
        },
        last_name => {
          data_type => "varchar",
          is_nullable => 0,
          size => 45
        },
        last_update => {
          data_type => "timestamp",
          datetime_undef_if_invalid => 1,
          default_value => "\\\"current_timestamp\"",
          is_nullable => 0
        },
        store_id => {
          data_type => "tinyint",
          extra => {
            unsigned => 1
          },
          is_foreign_key => 1,
          is_nullable => 0
        }
      },
      constraints => {
        primary => {
          columns => [
            "customer_id"
          ]
        }
      },
      isa => [
        "{schema_class}::Result::Customer",
        "DBIx::Class::InflateColumn::DateTime",
        @Core_ISA,
      ],
      relationships => {
        address => {
          attrs => {
            accessor => "single",
            fk_columns => {
              address_id => 1
            },
            is_deferrable => 1,
            is_depends_on => 1,
            is_foreign_key_constraint => 1,
            on_delete => "CASCADE",
            on_update => "CASCADE",
            undef_on_null_fk => 1
          },
          class => "{schema_class}::Result::Address",
          cond => {
            "foreign.address_id" => "self.address_id"
          },
          source => "{schema_class}::Result::Address"
        },
        payments => {
          attrs => {
            accessor => "multi",
            cascade_copy => 0,
            cascade_delete => 0,
            is_depends_on => 0,
            join_type => "LEFT"
          },
          class => "{schema_class}::Result::Payment",
          cond => {
            "foreign.customer_id" => "self.customer_id"
          },
          source => "{schema_class}::Result::Payment"
        },
        rentals => {
          attrs => {
            accessor => "multi",
            cascade_copy => 0,
            cascade_delete => 0,
            is_depends_on => 0,
            join_type => "LEFT"
          },
          class => "{schema_class}::Result::Rental",
          cond => {
            "foreign.customer_id" => "self.customer_id"
          },
          source => "{schema_class}::Result::Rental"
        },
        store => {
          attrs => {
            accessor => "single",
            fk_columns => {
              store_id => 1
            },
            is_deferrable => 1,
            is_depends_on => 1,
            is_foreign_key_constraint => 1,
            on_delete => "CASCADE",
            on_update => "CASCADE",
            undef_on_null_fk => 1
          },
          class => "{schema_class}::Result::Store",
          cond => {
            "foreign.store_id" => "self.store_id"
          },
          source => "{schema_class}::Result::Store"
        }
      },
      table_name => "customer"
    },
    CustomerList => {
      columns => {
        address => {
          data_type => "varchar",
          is_nullable => 0,
          size => 50
        },
        city => {
          data_type => "varchar",
          is_nullable => 0,
          size => 50
        },
        country => {
          data_type => "varchar",
          is_nullable => 0,
          size => 50
        },
        id => {
          data_type => "smallint",
          default_value => 0,
          extra => {
            unsigned => 1
          },
          is_nullable => 0
        },
        name => {
          data_type => "varchar",
          default_value => "",
          is_nullable => 0,
          size => 91
        },
        notes => {
          data_type => "varchar",
          default_value => "",
          is_nullable => 0,
          size => 6
        },
        phone => {
          data_type => "varchar",
          is_nullable => 0,
          size => 20
        },
        sid => {
          data_type => "tinyint",
          extra => {
            unsigned => 1
          },
          is_nullable => 0
        },
        "zip code" => {
          accessor => "zip_code",
          data_type => "varchar",
          is_nullable => 1,
          size => 10
        }
      },
      constraints => {},
      isa => [
        "{schema_class}::Result::CustomerList",
        "DBIx::Class::InflateColumn::DateTime",
        @Core_ISA,
      ],
      relationships => {},
      table_name => "customer_list"
    },
    Film => {
      columns => {
        description => {
          data_type => "text",
          is_nullable => 1
        },
        film_id => {
          data_type => "smallint",
          extra => {
            unsigned => 1
          },
          is_auto_increment => 1,
          is_nullable => 0
        },
        language_id => {
          data_type => "tinyint",
          extra => {
            unsigned => 1
          },
          is_foreign_key => 1,
          is_nullable => 0
        },
        last_update => {
          data_type => "timestamp",
          datetime_undef_if_invalid => 1,
          default_value => "\\\"current_timestamp\"",
          is_nullable => 0
        },
        length => {
          data_type => "smallint",
          extra => {
            unsigned => 1
          },
          is_nullable => 1
        },
        original_language_id => {
          data_type => "tinyint",
          extra => {
            unsigned => 1
          },
          is_foreign_key => 1,
          is_nullable => 1
        },
        rating => {
          data_type => "enum",
          default_value => "G",
          extra => {
            list => [
              "G",
              "PG",
              "PG-13",
              "R",
              "NC-17"
            ]
          },
          is_nullable => 1
        },
        release_year => {
          data_type => "year",
          is_nullable => 1
        },
        rental_duration => {
          data_type => "tinyint",
          default_value => 3,
          extra => {
            unsigned => 1
          },
          is_nullable => 0
        },
        rental_rate => {
          data_type => "decimal",
          default_value => "4.99",
          is_nullable => 0,
          size => [
            4,
            2
          ]
        },
        replacement_cost => {
          data_type => "decimal",
          default_value => "19.99",
          is_nullable => 0,
          size => [
            5,
            2
          ]
        },
        special_features => {
          data_type => "set",
          extra => {
            list => [
              "Trailers",
              "Commentaries",
              "Deleted Scenes",
              "Behind the Scenes"
            ]
          },
          is_nullable => 1
        },
        title => {
          data_type => "varchar",
          is_nullable => 0,
          size => 255
        }
      },
      constraints => {
        primary => {
          columns => [
            "film_id"
          ]
        }
      },
      isa => [
        "{schema_class}::Result::Film",
        "DBIx::Class::InflateColumn::DateTime",
        @Core_ISA,
      ],
      relationships => {
        film_actors => {
          attrs => {
            accessor => "multi",
            cascade_copy => 0,
            cascade_delete => 0,
            is_depends_on => 0,
            join_type => "LEFT"
          },
          class => "{schema_class}::Result::FilmActor",
          cond => {
            "foreign.film_id" => "self.film_id"
          },
          source => "{schema_class}::Result::FilmActor"
        },
        film_categories => {
          attrs => {
            accessor => "multi",
            cascade_copy => 0,
            cascade_delete => 0,
            is_depends_on => 0,
            join_type => "LEFT"
          },
          class => "{schema_class}::Result::FilmCategory",
          cond => {
            "foreign.film_id" => "self.film_id"
          },
          source => "{schema_class}::Result::FilmCategory"
        },
        inventories => {
          attrs => {
            accessor => "multi",
            cascade_copy => 0,
            cascade_delete => 0,
            is_depends_on => 0,
            join_type => "LEFT"
          },
          class => "{schema_class}::Result::Inventory",
          cond => {
            "foreign.film_id" => "self.film_id"
          },
          source => "{schema_class}::Result::Inventory"
        },
        language => {
          attrs => {
            accessor => "single",
            fk_columns => {
              language_id => 1
            },
            is_deferrable => 1,
            is_depends_on => 1,
            is_foreign_key_constraint => 1,
            on_delete => "CASCADE",
            on_update => "CASCADE",
            undef_on_null_fk => 1
          },
          class => "{schema_class}::Result::Language",
          cond => {
            "foreign.language_id" => "self.language_id"
          },
          source => "{schema_class}::Result::Language"
        },
        original_language => {
          attrs => {
            accessor => "single",
            fk_columns => {
              original_language_id => 1
            },
            is_deferrable => 1,
            is_depends_on => 1,
            is_foreign_key_constraint => 1,
            join_type => "LEFT",
            on_delete => "CASCADE",
            on_update => "CASCADE",
            undef_on_null_fk => 1
          },
          class => "{schema_class}::Result::Language",
          cond => {
            "foreign.language_id" => "self.original_language_id"
          },
          source => "{schema_class}::Result::Language"
        }
      },
      table_name => "film"
    },
    FilmActor => {
      columns => {
        actor_id => {
          data_type => "smallint",
          extra => {
            unsigned => 1
          },
          is_foreign_key => 1,
          is_nullable => 0
        },
        film_id => {
          data_type => "smallint",
          extra => {
            unsigned => 1
          },
          is_foreign_key => 1,
          is_nullable => 0
        },
        last_update => {
          data_type => "timestamp",
          datetime_undef_if_invalid => 1,
          default_value => "\\\"current_timestamp\"",
          is_nullable => 0
        }
      },
      constraints => {
        primary => {
          columns => [
            "actor_id",
            "film_id"
          ]
        }
      },
      isa => [
        "{schema_class}::Result::FilmActor",
        "DBIx::Class::InflateColumn::DateTime",
        @Core_ISA,
      ],
      relationships => {
        actor => {
          attrs => {
            accessor => "single",
            fk_columns => {
              actor_id => 1
            },
            is_deferrable => 1,
            is_depends_on => 1,
            is_foreign_key_constraint => 1,
            on_delete => "CASCADE",
            on_update => "CASCADE",
            undef_on_null_fk => 1
          },
          class => "{schema_class}::Result::Actor",
          cond => {
            "foreign.actor_id" => "self.actor_id"
          },
          source => "{schema_class}::Result::Actor"
        },
        film => {
          attrs => {
            accessor => "single",
            fk_columns => {
              film_id => 1
            },
            is_deferrable => 1,
            is_depends_on => 1,
            is_foreign_key_constraint => 1,
            on_delete => "CASCADE",
            on_update => "CASCADE",
            undef_on_null_fk => 1
          },
          class => "{schema_class}::Result::Film",
          cond => {
            "foreign.film_id" => "self.film_id"
          },
          source => "{schema_class}::Result::Film"
        }
      },
      table_name => "film_actor"
    },
    FilmCategory => {
      columns => {
        category_id => {
          data_type => "tinyint",
          extra => {
            unsigned => 1
          },
          is_foreign_key => 1,
          is_nullable => 0
        },
        film_id => {
          data_type => "smallint",
          extra => {
            unsigned => 1
          },
          is_foreign_key => 1,
          is_nullable => 0
        },
        last_update => {
          data_type => "timestamp",
          datetime_undef_if_invalid => 1,
          default_value => "\\\"current_timestamp\"",
          is_nullable => 0
        }
      },
      constraints => {
        primary => {
          columns => [
            "film_id",
            "category_id"
          ]
        }
      },
      isa => [
        "{schema_class}::Result::FilmCategory",
        "DBIx::Class::InflateColumn::DateTime",
        @Core_ISA,
      ],
      relationships => {
        category => {
          attrs => {
            accessor => "single",
            fk_columns => {
              category_id => 1
            },
            is_deferrable => 1,
            is_depends_on => 1,
            is_foreign_key_constraint => 1,
            on_delete => "CASCADE",
            on_update => "CASCADE",
            undef_on_null_fk => 1
          },
          class => "{schema_class}::Result::Category",
          cond => {
            "foreign.category_id" => "self.category_id"
          },
          source => "{schema_class}::Result::Category"
        },
        film => {
          attrs => {
            accessor => "single",
            fk_columns => {
              film_id => 1
            },
            is_deferrable => 1,
            is_depends_on => 1,
            is_foreign_key_constraint => 1,
            on_delete => "CASCADE",
            on_update => "CASCADE",
            undef_on_null_fk => 1
          },
          class => "{schema_class}::Result::Film",
          cond => {
            "foreign.film_id" => "self.film_id"
          },
          source => "{schema_class}::Result::Film"
        }
      },
      table_name => "film_category"
    },
    FilmList => {
      columns => {
        actors => {
          data_type => "varchar",
          is_nullable => 1,
          size => 341
        },
        category => {
          data_type => "varchar",
          is_nullable => 0,
          size => 25
        },
        description => {
          data_type => "text",
          is_nullable => 1
        },
        fid => {
          data_type => "smallint",
          default_value => 0,
          extra => {
            unsigned => 1
          },
          is_nullable => 1
        },
        length => {
          data_type => "smallint",
          extra => {
            unsigned => 1
          },
          is_nullable => 1
        },
        price => {
          data_type => "decimal",
          default_value => "4.99",
          is_nullable => 1,
          size => [
            4,
            2
          ]
        },
        rating => {
          data_type => "enum",
          default_value => "G",
          extra => {
            list => [
              "G",
              "PG",
              "PG-13",
              "R",
              "NC-17"
            ]
          },
          is_nullable => 1
        },
        title => {
          data_type => "varchar",
          is_nullable => 1,
          size => 255
        }
      },
      constraints => {},
      isa => [
        "{schema_class}::Result::FilmList",
        "DBIx::Class::InflateColumn::DateTime",
        @Core_ISA,
      ],
      relationships => {},
      table_name => "film_list"
    },
    FilmText => {
      columns => {
        description => {
          data_type => "text",
          is_nullable => 1
        },
        film_id => {
          data_type => "smallint",
          is_nullable => 0
        },
        title => {
          data_type => "varchar",
          is_nullable => 0,
          size => 255
        }
      },
      constraints => {
        primary => {
          columns => [
            "film_id"
          ]
        }
      },
      isa => [
        "{schema_class}::Result::FilmText",
        "DBIx::Class::InflateColumn::DateTime",
        @Core_ISA,
      ],
      relationships => {},
      table_name => "film_text"
    },
    Inventory => {
      columns => {
        film_id => {
          data_type => "smallint",
          extra => {
            unsigned => 1
          },
          is_foreign_key => 1,
          is_nullable => 0
        },
        inventory_id => {
          data_type => "mediumint",
          extra => {
            unsigned => 1
          },
          is_auto_increment => 1,
          is_nullable => 0
        },
        last_update => {
          data_type => "timestamp",
          datetime_undef_if_invalid => 1,
          default_value => "\\\"current_timestamp\"",
          is_nullable => 0
        },
        store_id => {
          data_type => "tinyint",
          extra => {
            unsigned => 1
          },
          is_foreign_key => 1,
          is_nullable => 0
        }
      },
      constraints => {
        primary => {
          columns => [
            "inventory_id"
          ]
        }
      },
      isa => [
        "{schema_class}::Result::Inventory",
        "DBIx::Class::InflateColumn::DateTime",
        @Core_ISA,
      ],
      relationships => {
        film => {
          attrs => {
            accessor => "single",
            fk_columns => {
              film_id => 1
            },
            is_deferrable => 1,
            is_depends_on => 1,
            is_foreign_key_constraint => 1,
            on_delete => "CASCADE",
            on_update => "CASCADE",
            undef_on_null_fk => 1
          },
          class => "{schema_class}::Result::Film",
          cond => {
            "foreign.film_id" => "self.film_id"
          },
          source => "{schema_class}::Result::Film"
        },
        rentals => {
          attrs => {
            accessor => "multi",
            cascade_copy => 0,
            cascade_delete => 0,
            is_depends_on => 0,
            join_type => "LEFT"
          },
          class => "{schema_class}::Result::Rental",
          cond => {
            "foreign.inventory_id" => "self.inventory_id"
          },
          source => "{schema_class}::Result::Rental"
        },
        store => {
          attrs => {
            accessor => "single",
            fk_columns => {
              store_id => 1
            },
            is_deferrable => 1,
            is_depends_on => 1,
            is_foreign_key_constraint => 1,
            on_delete => "CASCADE",
            on_update => "CASCADE",
            undef_on_null_fk => 1
          },
          class => "{schema_class}::Result::Store",
          cond => {
            "foreign.store_id" => "self.store_id"
          },
          source => "{schema_class}::Result::Store"
        }
      },
      table_name => "inventory"
    },
    Language => {
      columns => {
        language_id => {
          data_type => "tinyint",
          extra => {
            unsigned => 1
          },
          is_auto_increment => 1,
          is_nullable => 0
        },
        last_update => {
          data_type => "timestamp",
          datetime_undef_if_invalid => 1,
          default_value => "\\\"current_timestamp\"",
          is_nullable => 0
        },
        name => {
          data_type => "char",
          is_nullable => 0,
          size => 20
        }
      },
      constraints => {
        primary => {
          columns => [
            "language_id"
          ]
        }
      },
      isa => [
        "{schema_class}::Result::Language",
        "DBIx::Class::InflateColumn::DateTime",
        @Core_ISA,
      ],
      relationships => {
        film_languages => {
          attrs => {
            accessor => "multi",
            cascade_copy => 0,
            cascade_delete => 0,
            is_depends_on => 0,
            join_type => "LEFT"
          },
          class => "{schema_class}::Result::Film",
          cond => {
            "foreign.language_id" => "self.language_id"
          },
          source => "{schema_class}::Result::Film"
        },
        film_original_languages => {
          attrs => {
            accessor => "multi",
            cascade_copy => 0,
            cascade_delete => 0,
            is_depends_on => 0,
            join_type => "LEFT"
          },
          class => "{schema_class}::Result::Film",
          cond => {
            "foreign.original_language_id" => "self.language_id"
          },
          source => "{schema_class}::Result::Film"
        }
      },
      table_name => "language"
    },
    NicerButSlowerFilmList => {
      columns => {
        actors => {
          data_type => "varchar",
          is_nullable => 1,
          size => 341
        },
        category => {
          data_type => "varchar",
          is_nullable => 0,
          size => 25
        },
        description => {
          data_type => "text",
          is_nullable => 1
        },
        fid => {
          data_type => "smallint",
          default_value => 0,
          extra => {
            unsigned => 1
          },
          is_nullable => 1
        },
        length => {
          data_type => "smallint",
          extra => {
            unsigned => 1
          },
          is_nullable => 1
        },
        price => {
          data_type => "decimal",
          default_value => "4.99",
          is_nullable => 1,
          size => [
            4,
            2
          ]
        },
        rating => {
          data_type => "enum",
          default_value => "G",
          extra => {
            list => [
              "G",
              "PG",
              "PG-13",
              "R",
              "NC-17"
            ]
          },
          is_nullable => 1
        },
        title => {
          data_type => "varchar",
          is_nullable => 1,
          size => 255
        }
      },
      constraints => {},
      isa => [
        "{schema_class}::Result::NicerButSlowerFilmList",
        "DBIx::Class::InflateColumn::DateTime",
        @Core_ISA,
      ],
      relationships => {},
      table_name => "nicer_but_slower_film_list"
    },
    Payment => {
      columns => {
        amount => {
          data_type => "decimal",
          is_nullable => 0,
          size => [
            5,
            2
          ]
        },
        customer_id => {
          data_type => "smallint",
          extra => {
            unsigned => 1
          },
          is_foreign_key => 1,
          is_nullable => 0
        },
        last_update => {
          data_type => "timestamp",
          datetime_undef_if_invalid => 1,
          default_value => "\\\"current_timestamp\"",
          is_nullable => 0
        },
        payment_date => {
          data_type => "datetime",
          datetime_undef_if_invalid => 1,
          is_nullable => 0
        },
        payment_id => {
          data_type => "smallint",
          extra => {
            unsigned => 1
          },
          is_auto_increment => 1,
          is_nullable => 0
        },
        rental_id => {
          data_type => "integer",
          is_foreign_key => 1,
          is_nullable => 1
        },
        staff_id => {
          data_type => "tinyint",
          extra => {
            unsigned => 1
          },
          is_foreign_key => 1,
          is_nullable => 0
        }
      },
      constraints => {
        primary => {
          columns => [
            "payment_id"
          ]
        }
      },
      isa => [
        "{schema_class}::Result::Payment",
        "DBIx::Class::InflateColumn::DateTime",
        @Core_ISA,
      ],
      relationships => {
        customer => {
          attrs => {
            accessor => "single",
            fk_columns => {
              customer_id => 1
            },
            is_deferrable => 1,
            is_depends_on => 1,
            is_foreign_key_constraint => 1,
            on_delete => "CASCADE",
            on_update => "CASCADE",
            undef_on_null_fk => 1
          },
          class => "{schema_class}::Result::Customer",
          cond => {
            "foreign.customer_id" => "self.customer_id"
          },
          source => "{schema_class}::Result::Customer"
        },
        rental => {
          attrs => {
            accessor => "single",
            fk_columns => {
              rental_id => 1
            },
            is_deferrable => 1,
            is_depends_on => 1,
            is_foreign_key_constraint => 1,
            join_type => "LEFT",
            on_delete => "CASCADE",
            on_update => "CASCADE",
            undef_on_null_fk => 1
          },
          class => "{schema_class}::Result::Rental",
          cond => {
            "foreign.rental_id" => "self.rental_id"
          },
          source => "{schema_class}::Result::Rental"
        },
        staff => {
          attrs => {
            accessor => "single",
            fk_columns => {
              staff_id => 1
            },
            is_deferrable => 1,
            is_depends_on => 1,
            is_foreign_key_constraint => 1,
            on_delete => "CASCADE",
            on_update => "CASCADE",
            undef_on_null_fk => 1
          },
          class => "{schema_class}::Result::Staff",
          cond => {
            "foreign.staff_id" => "self.staff_id"
          },
          source => "{schema_class}::Result::Staff"
        }
      },
      table_name => "payment"
    },
    Rental => {
      columns => {
        customer_id => {
          data_type => "smallint",
          extra => {
            unsigned => 1
          },
          is_foreign_key => 1,
          is_nullable => 0
        },
        inventory_id => {
          data_type => "mediumint",
          extra => {
            unsigned => 1
          },
          is_foreign_key => 1,
          is_nullable => 0
        },
        last_update => {
          data_type => "timestamp",
          datetime_undef_if_invalid => 1,
          default_value => "\\\"current_timestamp\"",
          is_nullable => 0
        },
        rental_date => {
          data_type => "datetime",
          datetime_undef_if_invalid => 1,
          is_nullable => 0
        },
        rental_id => {
          data_type => "integer",
          is_auto_increment => 1,
          is_nullable => 0
        },
        return_date => {
          data_type => "datetime",
          datetime_undef_if_invalid => 1,
          is_nullable => 1
        },
        staff_id => {
          data_type => "tinyint",
          extra => {
            unsigned => 1
          },
          is_foreign_key => 1,
          is_nullable => 0
        }
      },
      constraints => {
        primary => {
          columns => [
            "rental_id"
          ]
        },
        rental_date => {
          columns => [
            "rental_date",
            "inventory_id",
            "customer_id"
          ]
        }
      },
      isa => [
        "{schema_class}::Result::Rental",
        "DBIx::Class::InflateColumn::DateTime",
        @Core_ISA,
      ],
      relationships => {
        customer => {
          attrs => {
            accessor => "single",
            fk_columns => {
              customer_id => 1
            },
            is_deferrable => 1,
            is_depends_on => 1,
            is_foreign_key_constraint => 1,
            on_delete => "CASCADE",
            on_update => "CASCADE",
            undef_on_null_fk => 1
          },
          class => "{schema_class}::Result::Customer",
          cond => {
            "foreign.customer_id" => "self.customer_id"
          },
          source => "{schema_class}::Result::Customer"
        },
        inventory => {
          attrs => {
            accessor => "single",
            fk_columns => {
              inventory_id => 1
            },
            is_deferrable => 1,
            is_depends_on => 1,
            is_foreign_key_constraint => 1,
            on_delete => "CASCADE",
            on_update => "CASCADE",
            undef_on_null_fk => 1
          },
          class => "{schema_class}::Result::Inventory",
          cond => {
            "foreign.inventory_id" => "self.inventory_id"
          },
          source => "{schema_class}::Result::Inventory"
        },
        payments => {
          attrs => {
            accessor => "multi",
            cascade_copy => 0,
            cascade_delete => 0,
            is_depends_on => 0,
            join_type => "LEFT"
          },
          class => "{schema_class}::Result::Payment",
          cond => {
            "foreign.rental_id" => "self.rental_id"
          },
          source => "{schema_class}::Result::Payment"
        },
        staff => {
          attrs => {
            accessor => "single",
            fk_columns => {
              staff_id => 1
            },
            is_deferrable => 1,
            is_depends_on => 1,
            is_foreign_key_constraint => 1,
            on_delete => "CASCADE",
            on_update => "CASCADE",
            undef_on_null_fk => 1
          },
          class => "{schema_class}::Result::Staff",
          cond => {
            "foreign.staff_id" => "self.staff_id"
          },
          source => "{schema_class}::Result::Staff"
        }
      },
      table_name => "rental"
    },
    SaleByFilmCategory => {
      columns => {
        category => {
          data_type => "varchar",
          is_nullable => 0,
          size => 25
        },
        total_sales => {
          data_type => "decimal",
          is_nullable => 1,
          size => [
            27,
            2
          ]
        }
      },
      constraints => {},
      isa => [
        "{schema_class}::Result::SaleByFilmCategory",
        "DBIx::Class::InflateColumn::DateTime",
        @Core_ISA,
      ],
      relationships => {},
      table_name => "sales_by_film_category"
    },
    SaleByStore => {
      columns => {
        manager => {
          data_type => "varchar",
          default_value => "",
          is_nullable => 0,
          size => 91
        },
        store => {
          data_type => "varchar",
          default_value => "",
          is_nullable => 0,
          size => 101
        },
        total_sales => {
          data_type => "decimal",
          is_nullable => 1,
          size => [
            27,
            2
          ]
        }
      },
      constraints => {},
      isa => [
        "{schema_class}::Result::SaleByStore",
        "DBIx::Class::InflateColumn::DateTime",
        @Core_ISA,
      ],
      relationships => {},
      table_name => "sales_by_store"
    },
    Staff => {
      columns => {
        active => {
          data_type => "tinyint",
          default_value => 1,
          is_nullable => 0
        },
        address_id => {
          data_type => "smallint",
          extra => {
            unsigned => 1
          },
          is_foreign_key => 1,
          is_nullable => 0
        },
        email => {
          data_type => "varchar",
          is_nullable => 1,
          size => 50
        },
        first_name => {
          data_type => "varchar",
          is_nullable => 0,
          size => 45
        },
        last_name => {
          data_type => "varchar",
          is_nullable => 0,
          size => 45
        },
        last_update => {
          data_type => "timestamp",
          datetime_undef_if_invalid => 1,
          default_value => "\\\"current_timestamp\"",
          is_nullable => 0
        },
        password => {
          data_type => "varchar",
          is_nullable => 1,
          size => 40
        },
        picture => {
          data_type => "blob",
          is_nullable => 1
        },
        staff_id => {
          data_type => "tinyint",
          extra => {
            unsigned => 1
          },
          is_auto_increment => 1,
          is_nullable => 0
        },
        store_id => {
          data_type => "tinyint",
          extra => {
            unsigned => 1
          },
          is_foreign_key => 1,
          is_nullable => 0
        },
        username => {
          data_type => "varchar",
          is_nullable => 0,
          size => 16
        }
      },
      constraints => {
        primary => {
          columns => [
            "staff_id"
          ]
        }
      },
      isa => [
        "{schema_class}::Result::Staff",
        "DBIx::Class::InflateColumn::DateTime",
        @Core_ISA,
      ],
      relationships => {
        address => {
          attrs => {
            accessor => "single",
            fk_columns => {
              address_id => 1
            },
            is_deferrable => 1,
            is_depends_on => 1,
            is_foreign_key_constraint => 1,
            on_delete => "CASCADE",
            on_update => "CASCADE",
            undef_on_null_fk => 1
          },
          class => "{schema_class}::Result::Address",
          cond => {
            "foreign.address_id" => "self.address_id"
          },
          source => "{schema_class}::Result::Address"
        },
        payments => {
          attrs => {
            accessor => "multi",
            cascade_copy => 0,
            cascade_delete => 0,
            is_depends_on => 0,
            join_type => "LEFT"
          },
          class => "{schema_class}::Result::Payment",
          cond => {
            "foreign.staff_id" => "self.staff_id"
          },
          source => "{schema_class}::Result::Payment"
        },
        rentals => {
          attrs => {
            accessor => "multi",
            cascade_copy => 0,
            cascade_delete => 0,
            is_depends_on => 0,
            join_type => "LEFT"
          },
          class => "{schema_class}::Result::Rental",
          cond => {
            "foreign.staff_id" => "self.staff_id"
          },
          source => "{schema_class}::Result::Rental"
        },
        store => {
          attrs => {
            accessor => "single",
            cascade_copy => 0,
            cascade_delete => 0,
            cascade_update => 1,
            is_depends_on => 0,
            join_type => "LEFT"
          },
          class => "{schema_class}::Result::Store",
          cond => {
            "foreign.manager_staff_id" => "self.staff_id"
          },
          source => "{schema_class}::Result::Store"
        }
      },
      table_name => "staff"
    },
    StaffList => {
      columns => {
        address => {
          data_type => "varchar",
          is_nullable => 0,
          size => 50
        },
        city => {
          data_type => "varchar",
          is_nullable => 0,
          size => 50
        },
        country => {
          data_type => "varchar",
          is_nullable => 0,
          size => 50
        },
        id => {
          data_type => "tinyint",
          default_value => 0,
          extra => {
            unsigned => 1
          },
          is_nullable => 0
        },
        name => {
          data_type => "varchar",
          default_value => "",
          is_nullable => 0,
          size => 91
        },
        phone => {
          data_type => "varchar",
          is_nullable => 0,
          size => 20
        },
        sid => {
          data_type => "tinyint",
          extra => {
            unsigned => 1
          },
          is_nullable => 0
        },
        "zip code" => {
          accessor => "zip_code",
          data_type => "varchar",
          is_nullable => 1,
          size => 10
        }
      },
      constraints => {},
      isa => [
        "{schema_class}::Result::StaffList",
        "DBIx::Class::InflateColumn::DateTime",
        @Core_ISA,
      ],
      relationships => {},
      table_name => "staff_list"
    },
    Store => {
      columns => {
        address_id => {
          data_type => "smallint",
          extra => {
            unsigned => 1
          },
          is_foreign_key => 1,
          is_nullable => 0
        },
        last_update => {
          data_type => "timestamp",
          datetime_undef_if_invalid => 1,
          default_value => "\\\"current_timestamp\"",
          is_nullable => 0
        },
        manager_staff_id => {
          data_type => "tinyint",
          extra => {
            unsigned => 1
          },
          is_foreign_key => 1,
          is_nullable => 0
        },
        store_id => {
          data_type => "tinyint",
          extra => {
            unsigned => 1
          },
          is_auto_increment => 1,
          is_nullable => 0
        }
      },
      constraints => {
        idx_unique_manager => {
          columns => [
            "manager_staff_id"
          ]
        },
        primary => {
          columns => [
            "store_id"
          ]
        }
      },
      isa => [
        "{schema_class}::Result::Store",
        "DBIx::Class::InflateColumn::DateTime",
        @Core_ISA,
      ],
      relationships => {
        address => {
          attrs => {
            accessor => "single",
            fk_columns => {
              address_id => 1
            },
            is_deferrable => 1,
            is_depends_on => 1,
            is_foreign_key_constraint => 1,
            on_delete => "CASCADE",
            on_update => "CASCADE",
            undef_on_null_fk => 1
          },
          class => "{schema_class}::Result::Address",
          cond => {
            "foreign.address_id" => "self.address_id"
          },
          source => "{schema_class}::Result::Address"
        },
        customers => {
          attrs => {
            accessor => "multi",
            cascade_copy => 0,
            cascade_delete => 0,
            is_depends_on => 0,
            join_type => "LEFT"
          },
          class => "{schema_class}::Result::Customer",
          cond => {
            "foreign.store_id" => "self.store_id"
          },
          source => "{schema_class}::Result::Customer"
        },
        inventories => {
          attrs => {
            accessor => "multi",
            cascade_copy => 0,
            cascade_delete => 0,
            is_depends_on => 0,
            join_type => "LEFT"
          },
          class => "{schema_class}::Result::Inventory",
          cond => {
            "foreign.store_id" => "self.store_id"
          },
          source => "{schema_class}::Result::Inventory"
        },
        manager_staff => {
          attrs => {
            accessor => "single",
            fk_columns => {
              manager_staff_id => 1
            },
            is_deferrable => 1,
            is_depends_on => 1,
            is_foreign_key_constraint => 1,
            on_delete => "CASCADE",
            on_update => "CASCADE",
            undef_on_null_fk => 1
          },
          class => "{schema_class}::Result::Staff",
          cond => {
            "foreign.staff_id" => "self.manager_staff_id"
          },
          source => "{schema_class}::Result::Staff"
        },
        staffs => {
          attrs => {
            accessor => "multi",
            cascade_copy => 0,
            cascade_delete => 0,
            is_depends_on => 0,
            join_type => "LEFT"
          },
          class => "{schema_class}::Result::Staff",
          cond => {
            "foreign.store_id" => "self.store_id"
          },
          source => "{schema_class}::Result::Staff"
        }
      },
      table_name => "store"
    }
  }
  };
  
  # Starting with the next release of DBIC (v0.082800) the new 'is_depends_on'
  # attr is present in relationships. For backward compatibility with earlier
  # versions, we need to go in and strip this attr out of the structure above
  #  (see:  https://github.com/dbsrgits/dbix-class/commit/d0cefd99a )
  if(DBIx::Class->VERSION <= 0.082700) {
    for my $rsrc (values %{$h->{sources}}) {
      my $rels = $rsrc->{relationships} or next;
      delete $rels->{$_}{attrs}{is_depends_on} for (keys %$rels); 
    }
  }

  return $h;
}



# This is in a sub at the end just to prevent scrolling since its so long:
sub _data_pruned_private_col_attrs_isa_constraints { my $h = {
  schema_class => "TestSchema::Sakila",
  sources => {
    Actor => {
      columns => {
        actor_id => {
          data_type => "smallint",
          extra => {
            unsigned => 1
          },
          is_auto_increment => 1,
          is_nullable => 0
        },
        first_name => {
          data_type => "varchar",
          is_nullable => 0,
          size => 45
        },
        last_name => {
          data_type => "varchar",
          is_nullable => 0,
          size => 45
        },
        last_update => {
          data_type => "timestamp",
          datetime_undef_if_invalid => 1,
          default_value => "\\\"current_timestamp\"",
          is_nullable => 0
        }
      },
      relationships => {
        film_actors => {
          attrs => {
            accessor => "multi",
            cascade_copy => 0,
            cascade_delete => 0,
            is_depends_on => 0,
            join_type => "LEFT"
          },
          class => "{schema_class}::Result::FilmActor",
          cond => {
            "foreign.actor_id" => "self.actor_id"
          },
          source => "{schema_class}::Result::FilmActor"
        }
      },
      table_name => "actor"
    },
    ActorInfo => {
      columns => {
        actor_id => {
          data_type => "smallint",
          default_value => 0,
          extra => {
            unsigned => 1
          },
          is_nullable => 0
        },
        film_info => {
          data_type => "varchar",
          is_nullable => 1,
          size => 341
        },
        first_name => {
          data_type => "varchar",
          is_nullable => 0,
          size => 45
        },
        last_name => {
          data_type => "varchar",
          is_nullable => 0,
          size => 45
        }
      },
      relationships => {},
      table_name => "actor_info"
    },
    Address => {
      columns => {
        address => {
          data_type => "varchar",
          is_nullable => 0,
          size => 50
        },
        address2 => {
          data_type => "varchar",
          is_nullable => 1,
          size => 50
        },
        address_id => {
          data_type => "smallint",
          extra => {
            unsigned => 1
          },
          is_auto_increment => 1,
          is_nullable => 0
        },
        city_id => {
          data_type => "smallint",
          extra => {
            unsigned => 1
          },
          is_foreign_key => 1,
          is_nullable => 0
        },
        district => {
          data_type => "varchar",
          is_nullable => 0,
          size => 20
        },
        last_update => {
          data_type => "timestamp",
          datetime_undef_if_invalid => 1,
          default_value => "\\\"current_timestamp\"",
          is_nullable => 0
        },
        phone => {
          data_type => "varchar",
          is_nullable => 0,
          size => 20
        },
        postal_code => {
          data_type => "varchar",
          is_nullable => 1,
          size => 10
        }
      },
      relationships => {
        city => {
          attrs => {
            accessor => "single",
            fk_columns => {
              city_id => 1
            },
            is_deferrable => 1,
            is_depends_on => 1,
            is_foreign_key_constraint => 1,
            on_delete => "CASCADE",
            on_update => "CASCADE",
            undef_on_null_fk => 1
          },
          class => "{schema_class}::Result::City",
          cond => {
            "foreign.city_id" => "self.city_id"
          },
          source => "{schema_class}::Result::City"
        },
        customers => {
          attrs => {
            accessor => "multi",
            cascade_copy => 0,
            cascade_delete => 0,
            is_depends_on => 0,
            join_type => "LEFT"
          },
          class => "{schema_class}::Result::Customer",
          cond => {
            "foreign.address_id" => "self.address_id"
          },
          source => "{schema_class}::Result::Customer"
        },
        staffs => {
          attrs => {
            accessor => "multi",
            cascade_copy => 0,
            cascade_delete => 0,
            is_depends_on => 0,
            join_type => "LEFT"
          },
          class => "{schema_class}::Result::Staff",
          cond => {
            "foreign.address_id" => "self.address_id"
          },
          source => "{schema_class}::Result::Staff"
        },
        stores => {
          attrs => {
            accessor => "multi",
            cascade_copy => 0,
            cascade_delete => 0,
            is_depends_on => 0,
            join_type => "LEFT"
          },
          class => "{schema_class}::Result::Store",
          cond => {
            "foreign.address_id" => "self.address_id"
          },
          source => "{schema_class}::Result::Store"
        }
      },
      table_name => "address"
    },
    Category => {
      columns => {
        category_id => {
          data_type => "tinyint",
          extra => {
            unsigned => 1
          },
          is_auto_increment => 1,
          is_nullable => 0
        },
        last_update => {
          data_type => "timestamp",
          datetime_undef_if_invalid => 1,
          default_value => "\\\"current_timestamp\"",
          is_nullable => 0
        },
        name => {
          data_type => "varchar",
          is_nullable => 0,
          size => 25
        }
      },
      relationships => {
        film_categories => {
          attrs => {
            accessor => "multi",
            cascade_copy => 0,
            cascade_delete => 0,
            is_depends_on => 0,
            join_type => "LEFT"
          },
          class => "{schema_class}::Result::FilmCategory",
          cond => {
            "foreign.category_id" => "self.category_id"
          },
          source => "{schema_class}::Result::FilmCategory"
        }
      },
      table_name => "category"
    },
    City => {
      columns => {
        city => {
          data_type => "varchar",
          is_nullable => 0,
          size => 50
        },
        city_id => {
          data_type => "smallint",
          extra => {
            unsigned => 1
          },
          is_auto_increment => 1,
          is_nullable => 0
        },
        country_id => {
          data_type => "smallint",
          extra => {
            unsigned => 1
          },
          is_foreign_key => 1,
          is_nullable => 0
        },
        last_update => {
          data_type => "timestamp",
          datetime_undef_if_invalid => 1,
          default_value => "\\\"current_timestamp\"",
          is_nullable => 0
        }
      },
      relationships => {
        addresses => {
          attrs => {
            accessor => "multi",
            cascade_copy => 0,
            cascade_delete => 0,
            is_depends_on => 0,
            join_type => "LEFT"
          },
          class => "{schema_class}::Result::Address",
          cond => {
            "foreign.city_id" => "self.city_id"
          },
          source => "{schema_class}::Result::Address"
        },
        country => {
          attrs => {
            accessor => "single",
            fk_columns => {
              country_id => 1
            },
            is_deferrable => 1,
            is_depends_on => 1,
            is_foreign_key_constraint => 1,
            on_delete => "CASCADE",
            on_update => "CASCADE",
            undef_on_null_fk => 1
          },
          class => "{schema_class}::Result::Country",
          cond => {
            "foreign.country_id" => "self.country_id"
          },
          source => "{schema_class}::Result::Country"
        }
      },
      table_name => "city"
    },
    Country => {
      columns => {
        country => {
          data_type => "varchar",
          is_nullable => 0,
          size => 50
        },
        country_id => {
          data_type => "smallint",
          extra => {
            unsigned => 1
          },
          is_auto_increment => 1,
          is_nullable => 0
        },
        last_update => {
          data_type => "timestamp",
          datetime_undef_if_invalid => 1,
          default_value => "\\\"current_timestamp\"",
          is_nullable => 0
        }
      },
      relationships => {
        cities => {
          attrs => {
            accessor => "multi",
            cascade_copy => 0,
            cascade_delete => 0,
            is_depends_on => 0,
            join_type => "LEFT"
          },
          class => "{schema_class}::Result::City",
          cond => {
            "foreign.country_id" => "self.country_id"
          },
          source => "{schema_class}::Result::City"
        }
      },
      table_name => "country"
    },
    Customer => {
      columns => {
        active => {
          data_type => "tinyint",
          default_value => 1,
          is_nullable => 0
        },
        address_id => {
          data_type => "smallint",
          extra => {
            unsigned => 1
          },
          is_foreign_key => 1,
          is_nullable => 0
        },
        create_date => {
          data_type => "datetime",
          datetime_undef_if_invalid => 1,
          is_nullable => 0
        },
        customer_id => {
          data_type => "smallint",
          extra => {
            unsigned => 1
          },
          is_auto_increment => 1,
          is_nullable => 0
        },
        email => {
          data_type => "varchar",
          is_nullable => 1,
          size => 50
        },
        first_name => {
          data_type => "varchar",
          is_nullable => 0,
          size => 45
        },
        last_name => {
          data_type => "varchar",
          is_nullable => 0,
          size => 45
        },
        last_update => {
          data_type => "timestamp",
          datetime_undef_if_invalid => 1,
          default_value => "\\\"current_timestamp\"",
          is_nullable => 0
        },
        store_id => {
          data_type => "tinyint",
          extra => {
            unsigned => 1
          },
          is_foreign_key => 1,
          is_nullable => 0
        }
      },
      relationships => {
        address => {
          attrs => {
            accessor => "single",
            fk_columns => {
              address_id => 1
            },
            is_deferrable => 1,
            is_depends_on => 1,
            is_foreign_key_constraint => 1,
            on_delete => "CASCADE",
            on_update => "CASCADE",
            undef_on_null_fk => 1
          },
          class => "{schema_class}::Result::Address",
          cond => {
            "foreign.address_id" => "self.address_id"
          },
          source => "{schema_class}::Result::Address"
        },
        payments => {
          attrs => {
            accessor => "multi",
            cascade_copy => 0,
            cascade_delete => 0,
            is_depends_on => 0,
            join_type => "LEFT"
          },
          class => "{schema_class}::Result::Payment",
          cond => {
            "foreign.customer_id" => "self.customer_id"
          },
          source => "{schema_class}::Result::Payment"
        },
        rentals => {
          attrs => {
            accessor => "multi",
            cascade_copy => 0,
            cascade_delete => 0,
            is_depends_on => 0,
            join_type => "LEFT"
          },
          class => "{schema_class}::Result::Rental",
          cond => {
            "foreign.customer_id" => "self.customer_id"
          },
          source => "{schema_class}::Result::Rental"
        },
        store => {
          attrs => {
            accessor => "single",
            fk_columns => {
              store_id => 1
            },
            is_deferrable => 1,
            is_depends_on => 1,
            is_foreign_key_constraint => 1,
            on_delete => "CASCADE",
            on_update => "CASCADE",
            undef_on_null_fk => 1
          },
          class => "{schema_class}::Result::Store",
          cond => {
            "foreign.store_id" => "self.store_id"
          },
          source => "{schema_class}::Result::Store"
        }
      },
      table_name => "customer"
    },
    CustomerList => {
      columns => {
        address => {
          data_type => "varchar",
          is_nullable => 0,
          size => 50
        },
        city => {
          data_type => "varchar",
          is_nullable => 0,
          size => 50
        },
        country => {
          data_type => "varchar",
          is_nullable => 0,
          size => 50
        },
        id => {
          data_type => "smallint",
          default_value => 0,
          extra => {
            unsigned => 1
          },
          is_nullable => 0
        },
        name => {
          data_type => "varchar",
          default_value => "",
          is_nullable => 0,
          size => 91
        },
        notes => {
          data_type => "varchar",
          default_value => "",
          is_nullable => 0,
          size => 6
        },
        phone => {
          data_type => "varchar",
          is_nullable => 0,
          size => 20
        },
        sid => {
          data_type => "tinyint",
          extra => {
            unsigned => 1
          },
          is_nullable => 0
        },
        "zip code" => {
          accessor => "zip_code",
          data_type => "varchar",
          is_nullable => 1,
          size => 10
        }
      },
      relationships => {},
      table_name => "customer_list"
    },
    Film => {
      columns => {
        description => {
          data_type => "text",
          is_nullable => 1
        },
        film_id => {
          data_type => "smallint",
          extra => {
            unsigned => 1
          },
          is_auto_increment => 1,
          is_nullable => 0
        },
        language_id => {
          data_type => "tinyint",
          extra => {
            unsigned => 1
          },
          is_foreign_key => 1,
          is_nullable => 0
        },
        last_update => {
          data_type => "timestamp",
          datetime_undef_if_invalid => 1,
          default_value => "\\\"current_timestamp\"",
          is_nullable => 0
        },
        length => {
          data_type => "smallint",
          extra => {
            unsigned => 1
          },
          is_nullable => 1
        },
        original_language_id => {
          data_type => "tinyint",
          extra => {
            unsigned => 1
          },
          is_foreign_key => 1,
          is_nullable => 1
        },
        rating => {
          data_type => "enum",
          default_value => "G",
          extra => {
            list => [
              "G",
              "PG",
              "PG-13",
              "R",
              "NC-17"
            ]
          },
          is_nullable => 1
        },
        release_year => {
          data_type => "year",
          is_nullable => 1
        },
        rental_duration => {
          data_type => "tinyint",
          default_value => 3,
          extra => {
            unsigned => 1
          },
          is_nullable => 0
        },
        rental_rate => {
          data_type => "decimal",
          default_value => "4.99",
          is_nullable => 0,
          size => [
            4,
            2
          ]
        },
        replacement_cost => {
          data_type => "decimal",
          default_value => "19.99",
          is_nullable => 0,
          size => [
            5,
            2
          ]
        },
        special_features => {
          data_type => "set",
          extra => {
            list => [
              "Trailers",
              "Commentaries",
              "Deleted Scenes",
              "Behind the Scenes"
            ]
          },
          is_nullable => 1
        },
        title => {
          data_type => "varchar",
          is_nullable => 0,
          size => 255
        }
      },
      relationships => {
        film_actors => {
          attrs => {
            accessor => "multi",
            cascade_copy => 0,
            cascade_delete => 0,
            is_depends_on => 0,
            join_type => "LEFT"
          },
          class => "{schema_class}::Result::FilmActor",
          cond => {
            "foreign.film_id" => "self.film_id"
          },
          source => "{schema_class}::Result::FilmActor"
        },
        film_categories => {
          attrs => {
            accessor => "multi",
            cascade_copy => 0,
            cascade_delete => 0,
            is_depends_on => 0,
            join_type => "LEFT"
          },
          class => "{schema_class}::Result::FilmCategory",
          cond => {
            "foreign.film_id" => "self.film_id"
          },
          source => "{schema_class}::Result::FilmCategory"
        },
        inventories => {
          attrs => {
            accessor => "multi",
            cascade_copy => 0,
            cascade_delete => 0,
            is_depends_on => 0,
            join_type => "LEFT"
          },
          class => "{schema_class}::Result::Inventory",
          cond => {
            "foreign.film_id" => "self.film_id"
          },
          source => "{schema_class}::Result::Inventory"
        },
        language => {
          attrs => {
            accessor => "single",
            fk_columns => {
              language_id => 1
            },
            is_deferrable => 1,
            is_depends_on => 1,
            is_foreign_key_constraint => 1,
            on_delete => "CASCADE",
            on_update => "CASCADE",
            undef_on_null_fk => 1
          },
          class => "{schema_class}::Result::Language",
          cond => {
            "foreign.language_id" => "self.language_id"
          },
          source => "{schema_class}::Result::Language"
        },
        original_language => {
          attrs => {
            accessor => "single",
            fk_columns => {
              original_language_id => 1
            },
            is_deferrable => 1,
            is_depends_on => 1,
            is_foreign_key_constraint => 1,
            join_type => "LEFT",
            on_delete => "CASCADE",
            on_update => "CASCADE",
            undef_on_null_fk => 1
          },
          class => "{schema_class}::Result::Language",
          cond => {
            "foreign.language_id" => "self.original_language_id"
          },
          source => "{schema_class}::Result::Language"
        }
      },
      table_name => "film"
    },
    FilmActor => {
      columns => {
        actor_id => {
          data_type => "smallint",
          extra => {
            unsigned => 1
          },
          is_foreign_key => 1,
          is_nullable => 0
        },
        film_id => {
          data_type => "smallint",
          extra => {
            unsigned => 1
          },
          is_foreign_key => 1,
          is_nullable => 0
        },
        last_update => {
          data_type => "timestamp",
          datetime_undef_if_invalid => 1,
          default_value => "\\\"current_timestamp\"",
          is_nullable => 0
        }
      },
      relationships => {
        actor => {
          attrs => {
            accessor => "single",
            fk_columns => {
              actor_id => 1
            },
            is_deferrable => 1,
            is_depends_on => 1,
            is_foreign_key_constraint => 1,
            on_delete => "CASCADE",
            on_update => "CASCADE",
            undef_on_null_fk => 1
          },
          class => "{schema_class}::Result::Actor",
          cond => {
            "foreign.actor_id" => "self.actor_id"
          },
          source => "{schema_class}::Result::Actor"
        },
        film => {
          attrs => {
            accessor => "single",
            fk_columns => {
              film_id => 1
            },
            is_deferrable => 1,
            is_depends_on => 1,
            is_foreign_key_constraint => 1,
            on_delete => "CASCADE",
            on_update => "CASCADE",
            undef_on_null_fk => 1
          },
          class => "{schema_class}::Result::Film",
          cond => {
            "foreign.film_id" => "self.film_id"
          },
          source => "{schema_class}::Result::Film"
        }
      },
      table_name => "film_actor"
    },
    FilmCategory => {
      columns => {
        category_id => {
          data_type => "tinyint",
          extra => {
            unsigned => 1
          },
          is_foreign_key => 1,
          is_nullable => 0
        },
        film_id => {
          data_type => "smallint",
          extra => {
            unsigned => 1
          },
          is_foreign_key => 1,
          is_nullable => 0
        },
        last_update => {
          data_type => "timestamp",
          datetime_undef_if_invalid => 1,
          default_value => "\\\"current_timestamp\"",
          is_nullable => 0
        }
      },
      relationships => {
        category => {
          attrs => {
            accessor => "single",
            fk_columns => {
              category_id => 1
            },
            is_deferrable => 1,
            is_depends_on => 1,
            is_foreign_key_constraint => 1,
            on_delete => "CASCADE",
            on_update => "CASCADE",
            undef_on_null_fk => 1
          },
          class => "{schema_class}::Result::Category",
          cond => {
            "foreign.category_id" => "self.category_id"
          },
          source => "{schema_class}::Result::Category"
        },
        film => {
          attrs => {
            accessor => "single",
            fk_columns => {
              film_id => 1
            },
            is_deferrable => 1,
            is_depends_on => 1,
            is_foreign_key_constraint => 1,
            on_delete => "CASCADE",
            on_update => "CASCADE",
            undef_on_null_fk => 1
          },
          class => "{schema_class}::Result::Film",
          cond => {
            "foreign.film_id" => "self.film_id"
          },
          source => "{schema_class}::Result::Film"
        }
      },
      table_name => "film_category"
    },
    FilmList => {
      columns => {
        actors => {
          data_type => "varchar",
          is_nullable => 1,
          size => 341
        },
        category => {
          data_type => "varchar",
          is_nullable => 0,
          size => 25
        },
        description => {
          data_type => "text",
          is_nullable => 1
        },
        fid => {
          data_type => "smallint",
          default_value => 0,
          extra => {
            unsigned => 1
          },
          is_nullable => 1
        },
        length => {
          data_type => "smallint",
          extra => {
            unsigned => 1
          },
          is_nullable => 1
        },
        price => {
          data_type => "decimal",
          default_value => "4.99",
          is_nullable => 1,
          size => [
            4,
            2
          ]
        },
        rating => {
          data_type => "enum",
          default_value => "G",
          extra => {
            list => [
              "G",
              "PG",
              "PG-13",
              "R",
              "NC-17"
            ]
          },
          is_nullable => 1
        },
        title => {
          data_type => "varchar",
          is_nullable => 1,
          size => 255
        }
      },
      relationships => {},
      table_name => "film_list"
    },
    FilmText => {
      columns => {
        description => {
          data_type => "text",
          is_nullable => 1
        },
        film_id => {
          data_type => "smallint",
          is_nullable => 0
        },
        title => {
          data_type => "varchar",
          is_nullable => 0,
          size => 255
        }
      },
      relationships => {},
      table_name => "film_text"
    },
    Inventory => {
      columns => {
        film_id => {
          data_type => "smallint",
          extra => {
            unsigned => 1
          },
          is_foreign_key => 1,
          is_nullable => 0
        },
        inventory_id => {
          data_type => "mediumint",
          extra => {
            unsigned => 1
          },
          is_auto_increment => 1,
          is_nullable => 0
        },
        last_update => {
          data_type => "timestamp",
          datetime_undef_if_invalid => 1,
          default_value => "\\\"current_timestamp\"",
          is_nullable => 0
        },
        store_id => {
          data_type => "tinyint",
          extra => {
            unsigned => 1
          },
          is_foreign_key => 1,
          is_nullable => 0
        }
      },
      relationships => {
        film => {
          attrs => {
            accessor => "single",
            fk_columns => {
              film_id => 1
            },
            is_deferrable => 1,
            is_depends_on => 1,
            is_foreign_key_constraint => 1,
            on_delete => "CASCADE",
            on_update => "CASCADE",
            undef_on_null_fk => 1
          },
          class => "{schema_class}::Result::Film",
          cond => {
            "foreign.film_id" => "self.film_id"
          },
          source => "{schema_class}::Result::Film"
        },
        rentals => {
          attrs => {
            accessor => "multi",
            cascade_copy => 0,
            cascade_delete => 0,
            is_depends_on => 0,
            join_type => "LEFT"
          },
          class => "{schema_class}::Result::Rental",
          cond => {
            "foreign.inventory_id" => "self.inventory_id"
          },
          source => "{schema_class}::Result::Rental"
        },
        store => {
          attrs => {
            accessor => "single",
            fk_columns => {
              store_id => 1
            },
            is_deferrable => 1,
            is_depends_on => 1,
            is_foreign_key_constraint => 1,
            on_delete => "CASCADE",
            on_update => "CASCADE",
            undef_on_null_fk => 1
          },
          class => "{schema_class}::Result::Store",
          cond => {
            "foreign.store_id" => "self.store_id"
          },
          source => "{schema_class}::Result::Store"
        }
      },
      table_name => "inventory"
    },
    Language => {
      columns => {
        language_id => {
          data_type => "tinyint",
          extra => {
            unsigned => 1
          },
          is_auto_increment => 1,
          is_nullable => 0
        },
        last_update => {
          data_type => "timestamp",
          datetime_undef_if_invalid => 1,
          default_value => "\\\"current_timestamp\"",
          is_nullable => 0
        },
        name => {
          data_type => "char",
          is_nullable => 0,
          size => 20
        }
      },
      relationships => {
        film_languages => {
          attrs => {
            accessor => "multi",
            cascade_copy => 0,
            cascade_delete => 0,
            is_depends_on => 0,
            join_type => "LEFT"
          },
          class => "{schema_class}::Result::Film",
          cond => {
            "foreign.language_id" => "self.language_id"
          },
          source => "{schema_class}::Result::Film"
        },
        film_original_languages => {
          attrs => {
            accessor => "multi",
            cascade_copy => 0,
            cascade_delete => 0,
            is_depends_on => 0,
            join_type => "LEFT"
          },
          class => "{schema_class}::Result::Film",
          cond => {
            "foreign.original_language_id" => "self.language_id"
          },
          source => "{schema_class}::Result::Film"
        }
      },
      table_name => "language"
    },
    NicerButSlowerFilmList => {
      columns => {
        actors => {
          data_type => "varchar",
          is_nullable => 1,
          size => 341
        },
        category => {
          data_type => "varchar",
          is_nullable => 0,
          size => 25
        },
        description => {
          data_type => "text",
          is_nullable => 1
        },
        fid => {
          data_type => "smallint",
          default_value => 0,
          extra => {
            unsigned => 1
          },
          is_nullable => 1
        },
        length => {
          data_type => "smallint",
          extra => {
            unsigned => 1
          },
          is_nullable => 1
        },
        price => {
          data_type => "decimal",
          default_value => "4.99",
          is_nullable => 1,
          size => [
            4,
            2
          ]
        },
        rating => {
          data_type => "enum",
          default_value => "G",
          extra => {
            list => [
              "G",
              "PG",
              "PG-13",
              "R",
              "NC-17"
            ]
          },
          is_nullable => 1
        },
        title => {
          data_type => "varchar",
          is_nullable => 1,
          size => 255
        }
      },
      relationships => {},
      table_name => "nicer_but_slower_film_list"
    },
    Payment => {
      columns => {
        amount => {
          data_type => "decimal",
          is_nullable => 0,
          size => [
            5,
            2
          ]
        },
        customer_id => {
          data_type => "smallint",
          extra => {
            unsigned => 1
          },
          is_foreign_key => 1,
          is_nullable => 0
        },
        last_update => {
          data_type => "timestamp",
          datetime_undef_if_invalid => 1,
          default_value => "\\\"current_timestamp\"",
          is_nullable => 0
        },
        payment_date => {
          data_type => "datetime",
          datetime_undef_if_invalid => 1,
          is_nullable => 0
        },
        payment_id => {
          data_type => "smallint",
          extra => {
            unsigned => 1
          },
          is_auto_increment => 1,
          is_nullable => 0
        },
        rental_id => {
          data_type => "integer",
          is_foreign_key => 1,
          is_nullable => 1
        },
        staff_id => {
          data_type => "tinyint",
          extra => {
            unsigned => 1
          },
          is_foreign_key => 1,
          is_nullable => 0
        }
      },
      relationships => {
        customer => {
          attrs => {
            accessor => "single",
            fk_columns => {
              customer_id => 1
            },
            is_deferrable => 1,
            is_depends_on => 1,
            is_foreign_key_constraint => 1,
            on_delete => "CASCADE",
            on_update => "CASCADE",
            undef_on_null_fk => 1
          },
          class => "{schema_class}::Result::Customer",
          cond => {
            "foreign.customer_id" => "self.customer_id"
          },
          source => "{schema_class}::Result::Customer"
        },
        rental => {
          attrs => {
            accessor => "single",
            fk_columns => {
              rental_id => 1
            },
            is_deferrable => 1,
            is_depends_on => 1,
            is_foreign_key_constraint => 1,
            join_type => "LEFT",
            on_delete => "CASCADE",
            on_update => "CASCADE",
            undef_on_null_fk => 1
          },
          class => "{schema_class}::Result::Rental",
          cond => {
            "foreign.rental_id" => "self.rental_id"
          },
          source => "{schema_class}::Result::Rental"
        },
        staff => {
          attrs => {
            accessor => "single",
            fk_columns => {
              staff_id => 1
            },
            is_deferrable => 1,
            is_depends_on => 1,
            is_foreign_key_constraint => 1,
            on_delete => "CASCADE",
            on_update => "CASCADE",
            undef_on_null_fk => 1
          },
          class => "{schema_class}::Result::Staff",
          cond => {
            "foreign.staff_id" => "self.staff_id"
          },
          source => "{schema_class}::Result::Staff"
        }
      },
      table_name => "payment"
    },
    Rental => {
      columns => {
        customer_id => {
          data_type => "smallint",
          extra => {
            unsigned => 1
          },
          is_foreign_key => 1,
          is_nullable => 0
        },
        inventory_id => {
          data_type => "mediumint",
          extra => {
            unsigned => 1
          },
          is_foreign_key => 1,
          is_nullable => 0
        },
        last_update => {
          data_type => "timestamp",
          datetime_undef_if_invalid => 1,
          default_value => "\\\"current_timestamp\"",
          is_nullable => 0
        },
        rental_date => {
          data_type => "datetime",
          datetime_undef_if_invalid => 1,
          is_nullable => 0
        },
        rental_id => {
          data_type => "integer",
          is_auto_increment => 1,
          is_nullable => 0
        },
        return_date => {
          data_type => "datetime",
          datetime_undef_if_invalid => 1,
          is_nullable => 1
        },
        staff_id => {
          data_type => "tinyint",
          extra => {
            unsigned => 1
          },
          is_foreign_key => 1,
          is_nullable => 0
        }
      },
      relationships => {
        customer => {
          attrs => {
            accessor => "single",
            fk_columns => {
              customer_id => 1
            },
            is_deferrable => 1,
            is_depends_on => 1,
            is_foreign_key_constraint => 1,
            on_delete => "CASCADE",
            on_update => "CASCADE",
            undef_on_null_fk => 1
          },
          class => "{schema_class}::Result::Customer",
          cond => {
            "foreign.customer_id" => "self.customer_id"
          },
          source => "{schema_class}::Result::Customer"
        },
        inventory => {
          attrs => {
            accessor => "single",
            fk_columns => {
              inventory_id => 1
            },
            is_deferrable => 1,
            is_depends_on => 1,
            is_foreign_key_constraint => 1,
            on_delete => "CASCADE",
            on_update => "CASCADE",
            undef_on_null_fk => 1
          },
          class => "{schema_class}::Result::Inventory",
          cond => {
            "foreign.inventory_id" => "self.inventory_id"
          },
          source => "{schema_class}::Result::Inventory"
        },
        payments => {
          attrs => {
            accessor => "multi",
            cascade_copy => 0,
            cascade_delete => 0,
            is_depends_on => 0,
            join_type => "LEFT"
          },
          class => "{schema_class}::Result::Payment",
          cond => {
            "foreign.rental_id" => "self.rental_id"
          },
          source => "{schema_class}::Result::Payment"
        },
        staff => {
          attrs => {
            accessor => "single",
            fk_columns => {
              staff_id => 1
            },
            is_deferrable => 1,
            is_depends_on => 1,
            is_foreign_key_constraint => 1,
            on_delete => "CASCADE",
            on_update => "CASCADE",
            undef_on_null_fk => 1
          },
          class => "{schema_class}::Result::Staff",
          cond => {
            "foreign.staff_id" => "self.staff_id"
          },
          source => "{schema_class}::Result::Staff"
        }
      },
      table_name => "rental"
    },
    SaleByFilmCategory => {
      columns => {
        category => {
          data_type => "varchar",
          is_nullable => 0,
          size => 25
        },
        total_sales => {
          data_type => "decimal",
          is_nullable => 1,
          size => [
            27,
            2
          ]
        }
      },
      relationships => {},
      table_name => "sales_by_film_category"
    },
    SaleByStore => {
      columns => {
        manager => {
          data_type => "varchar",
          default_value => "",
          is_nullable => 0,
          size => 91
        },
        store => {
          data_type => "varchar",
          default_value => "",
          is_nullable => 0,
          size => 101
        },
        total_sales => {
          data_type => "decimal",
          is_nullable => 1,
          size => [
            27,
            2
          ]
        }
      },
      relationships => {},
      table_name => "sales_by_store"
    },
    Staff => {
      columns => {
        active => {
          data_type => "tinyint",
          default_value => 1,
          is_nullable => 0
        },
        address_id => {
          data_type => "smallint",
          extra => {
            unsigned => 1
          },
          is_foreign_key => 1,
          is_nullable => 0
        },
        email => {
          data_type => "varchar",
          is_nullable => 1,
          size => 50
        },
        first_name => {
          data_type => "varchar",
          is_nullable => 0,
          size => 45
        },
        last_name => {
          data_type => "varchar",
          is_nullable => 0,
          size => 45
        },
        last_update => {
          data_type => "timestamp",
          datetime_undef_if_invalid => 1,
          default_value => "\\\"current_timestamp\"",
          is_nullable => 0
        },
        password => {
          data_type => "varchar",
          is_nullable => 1,
          size => 40
        },
        picture => {
          data_type => "blob",
          is_nullable => 1
        },
        staff_id => {
          data_type => "tinyint",
          extra => {
            unsigned => 1
          },
          is_auto_increment => 1,
          is_nullable => 0
        },
        store_id => {
          data_type => "tinyint",
          extra => {
            unsigned => 1
          },
          is_foreign_key => 1,
          is_nullable => 0
        },
        username => {
          data_type => "varchar",
          is_nullable => 0,
          size => 16
        }
      },
      relationships => {
        address => {
          attrs => {
            accessor => "single",
            fk_columns => {
              address_id => 1
            },
            is_deferrable => 1,
            is_depends_on => 1,
            is_foreign_key_constraint => 1,
            on_delete => "CASCADE",
            on_update => "CASCADE",
            undef_on_null_fk => 1
          },
          class => "{schema_class}::Result::Address",
          cond => {
            "foreign.address_id" => "self.address_id"
          },
          source => "{schema_class}::Result::Address"
        },
        payments => {
          attrs => {
            accessor => "multi",
            cascade_copy => 0,
            cascade_delete => 0,
            is_depends_on => 0,
            join_type => "LEFT"
          },
          class => "{schema_class}::Result::Payment",
          cond => {
            "foreign.staff_id" => "self.staff_id"
          },
          source => "{schema_class}::Result::Payment"
        },
        rentals => {
          attrs => {
            accessor => "multi",
            cascade_copy => 0,
            cascade_delete => 0,
            is_depends_on => 0,
            join_type => "LEFT"
          },
          class => "{schema_class}::Result::Rental",
          cond => {
            "foreign.staff_id" => "self.staff_id"
          },
          source => "{schema_class}::Result::Rental"
        },
        store => {
          attrs => {
            accessor => "single",
            cascade_copy => 0,
            cascade_delete => 0,
            cascade_update => 1,
            is_depends_on => 0,
            join_type => "LEFT"
          },
          class => "{schema_class}::Result::Store",
          cond => {
            "foreign.manager_staff_id" => "self.staff_id"
          },
          source => "{schema_class}::Result::Store"
        }
      },
      table_name => "staff"
    },
    StaffList => {
      columns => {
        address => {
          data_type => "varchar",
          is_nullable => 0,
          size => 50
        },
        city => {
          data_type => "varchar",
          is_nullable => 0,
          size => 50
        },
        country => {
          data_type => "varchar",
          is_nullable => 0,
          size => 50
        },
        id => {
          data_type => "tinyint",
          default_value => 0,
          extra => {
            unsigned => 1
          },
          is_nullable => 0
        },
        name => {
          data_type => "varchar",
          default_value => "",
          is_nullable => 0,
          size => 91
        },
        phone => {
          data_type => "varchar",
          is_nullable => 0,
          size => 20
        },
        sid => {
          data_type => "tinyint",
          extra => {
            unsigned => 1
          },
          is_nullable => 0
        },
        "zip code" => {
          accessor => "zip_code",
          data_type => "varchar",
          is_nullable => 1,
          size => 10
        }
      },
      relationships => {},
      table_name => "staff_list"
    },
    Store => {
      columns => {
        address_id => {
          data_type => "smallint",
          extra => {
            unsigned => 1
          },
          is_foreign_key => 1,
          is_nullable => 0
        },
        last_update => {
          data_type => "timestamp",
          datetime_undef_if_invalid => 1,
          default_value => "\\\"current_timestamp\"",
          is_nullable => 0
        },
        manager_staff_id => {
          data_type => "tinyint",
          extra => {
            unsigned => 1
          },
          is_foreign_key => 1,
          is_nullable => 0
        },
        store_id => {
          data_type => "tinyint",
          extra => {
            unsigned => 1
          },
          is_auto_increment => 1,
          is_nullable => 0
        }
      },
      relationships => {
        address => {
          attrs => {
            accessor => "single",
            fk_columns => {
              address_id => 1
            },
            is_deferrable => 1,
            is_depends_on => 1,
            is_foreign_key_constraint => 1,
            on_delete => "CASCADE",
            on_update => "CASCADE",
            undef_on_null_fk => 1
          },
          class => "{schema_class}::Result::Address",
          cond => {
            "foreign.address_id" => "self.address_id"
          },
          source => "{schema_class}::Result::Address"
        },
        customers => {
          attrs => {
            accessor => "multi",
            cascade_copy => 0,
            cascade_delete => 0,
            is_depends_on => 0,
            join_type => "LEFT"
          },
          class => "{schema_class}::Result::Customer",
          cond => {
            "foreign.store_id" => "self.store_id"
          },
          source => "{schema_class}::Result::Customer"
        },
        inventories => {
          attrs => {
            accessor => "multi",
            cascade_copy => 0,
            cascade_delete => 0,
            is_depends_on => 0,
            join_type => "LEFT"
          },
          class => "{schema_class}::Result::Inventory",
          cond => {
            "foreign.store_id" => "self.store_id"
          },
          source => "{schema_class}::Result::Inventory"
        },
        manager_staff => {
          attrs => {
            accessor => "single",
            fk_columns => {
              manager_staff_id => 1
            },
            is_deferrable => 1,
            is_depends_on => 1,
            is_foreign_key_constraint => 1,
            on_delete => "CASCADE",
            on_update => "CASCADE",
            undef_on_null_fk => 1
          },
          class => "{schema_class}::Result::Staff",
          cond => {
            "foreign.staff_id" => "self.manager_staff_id"
          },
          source => "{schema_class}::Result::Staff"
        },
        staffs => {
          attrs => {
            accessor => "multi",
            cascade_copy => 0,
            cascade_delete => 0,
            is_depends_on => 0,
            join_type => "LEFT"
          },
          class => "{schema_class}::Result::Staff",
          cond => {
            "foreign.store_id" => "self.store_id"
          },
          source => "{schema_class}::Result::Staff"
        }
      },
      table_name => "store"
    }
  }
  };
  
  # Starting with the next release of DBIC (v0.082800) the new 'is_depends_on'
  # attr is present in relationships. For backward compatibility with earlier
  # versions, we need to go in and strip this attr out of the structure above
  #  (see:  https://github.com/dbsrgits/dbix-class/commit/d0cefd99a )
  if(DBIx::Class->VERSION <= 0.082700) {
    for my $rsrc (values %{$h->{sources}}) {
      my $rels = $rsrc->{relationships} or next;
      delete $rels->{$_}{attrs}{is_depends_on} for (keys %$rels); 
    }
  }

  return $h;
}





# -- for debugging:
#
#use Data::Dumper::Concise;
#sub Dumper { DumperObject->Deparse(0)->Values([ @_ ])->Dump }
#print STDERR "\n\n" . Dumper(
#  $SD1->data
#) . "\n\n";