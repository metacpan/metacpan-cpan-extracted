#!/usr/bin/perl
use v5.40;

use Test::More;
use Test::Mojo;
use Daje::Generate::Test::TestData;
use Daje::Generate::Tools::Datasections;
use Daje::Generate::Sql::Table;

use Mojo::Loader qw {data_section};
use Mojo::JSON qw {from_json};

sub create_table {

    my $result = 0;
    my $json = from_json qq{
        [
          {
            "version":[
              {
                "number": "1",
                "tables": [
                  {
                     "table": {
                      "name": "users",
                      "fields": {
                        "userid": "varchar",
                        "username": "varchar",
                        "password": "varchar",
                        "phone": "varchar",
                        "active": "bigint",
                        "support": "bigint",
                        "is_admin": "bigint"
                      },
                      "index": [
                        {"type": "unique", "fields": "userid"}
                      ]
                    }
                  },
                  {
                    "table": {
                    "name": "company_type",
                      "fields": {
                        "company_type": "varchar"
                      }
                    },
                    "index": {
                      "type": "unique",
                      "fields": "company_type"
                    },
                    "sql" : [
                      {
                        "fields":"company_type",
                        "values": "'Office Coffee'",
                        "type": "insert"
                      },
                      {
                        "fields":"company_type",
                        "values":"'Recycling'",
                        "type": "insert"
                      }
                    ]
                  },
                  {
                    "table": {
                      "name": "companies",
                      "fields": {
                        "name": "varchar",
                        "regno": "varchar",
                        "homepage": "varchar",
                        "phone": "varchar",
                        "vatno": "varchar",
                        "company_type_fkey": "bigint"
                      }
                    }
                  },
                  {
                    "table": {
                      "name": "companies_users",
                      "fields": {
                        "companies_fkey": "bigint",
                        "users_fkey": "bigint"
                      }
                    }
                  }
                ]
              }
            ]
          }
        ]
    };

    my $template = Daje::Generate::Tools::Datasections->new(
        data_sections => "table,foreign_key,index" ,
        source        => 'Generate::Templates::Sql'
    );
    $template->load_data_sections();

    my $table = Daje::Generate::Sql::Table->new(
        json     => $json,
        template => $template,
    );

    $table->generate_table();
    my $sql = $table->sql();

    if(index($sql,"users") > -1) {
        $result = 1;
    }


    my $test = 1;
}

ok(create_table() == 1);
done_testing();
1;

__DATA__

