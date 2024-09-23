#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

use Daje::Generate::Tools::Datasections ;
use Daje::Generate::Templates::Sql;
use Daje::Generate::Sql::Table::Fields;
use Mojo::JSON qw{from_json};

sub test_create_fields {
    my $result = 0;
    my $json = from_json( qq (
        {
            "fields": {
                "userid": "varchar",
                "username": "varchar",
                "password": "varchar",
                "phone": "varchar",
                "active": "bigint",
                "support": "bigint",
                "is_admin": "bigint"
            }
        }
    ));
    my $test_result = qq {is_admin bigint not null default 0};
    my $template = Daje::Generate::Tools::Datasections->new(
        data_sections => "table,foreign_key,index" ,
        source        => 'Generate::Templates::Sql'
    );
    $template->load_data_sections();

    my $fields = Generate::Sql::Table::Fields->new(
        json     => $json,
        template => $template,
    );

    $fields->create_fields();
    my $sql = $fields->sql;
    my $test = "";

    if (index($sql, $test_result) > -1) {
        $result = 1;
    }
    return $result;
}

sub test_get_defaults {
    my $result = 0;
    my $defaults = Daje::GenerateSQL::Sql::Table::Fields->new(
        json     => "json",
        template => "template",
    )->get_defaults('integer');

    if ($defaults eq " not null default 0 \n") {
        $result = 1;
    }

    return $result;
}

ok(test_get_defaults() == 1);
ok(test_create_fields() == 1);
done_testing();

