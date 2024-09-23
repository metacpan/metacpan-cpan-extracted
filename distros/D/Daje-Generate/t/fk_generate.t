#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

use Daje::Generate::Tools::Datasections;
use Daje::Generate::Sql::Table::ForeignKey;
use Mojo::JSON qw{from_json};
use Daje::Generate::Templates::Sql;

sub test_generate_foregin_key {
    my $result = 0;
    my $json = from_json(qq{
        {
            "fields": {
            "companies_fkey": "bigint",
            "users_fkey": "bigint"
            }
        }
    });
    my $template = Daje::Generate::Tools::Datasections->new(
        data_sections => "table,foreign_key,index" ,
        source        => 'Generate::Templates::Sql'
    );
    $template->load_data_sections();

    my $foreign_key = Daje::Generate::Sql::Table::ForeignKey->new(
        json      => $json,
        template  => $template,
        tablename => 'companies_users',
    );
    $foreign_key->create_foreign_keys();

    if ($foreign_key->created() == 1) {
        my $templates = $foreign_key->templates();
        if(exists($templates->{template_fkey}) and exists($templates->{template_ind})) {
            $result = 1;
        }
    }
    return $result;
}

ok(test_generate_foregin_key == 1);
done_testing();

