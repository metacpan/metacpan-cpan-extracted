#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

use Daje::Generate::Sql::Table::Index;
use Daje::Generate::Tools::Datasections ;
use Daje::Generate::Templates::Sql;

use Mojo::JSON qw {from_json};

sub test_generate_index {
    my $test = qq{CREATE unique INDEX idx_users_userid
    ON users USING btree
        (userid);


};
    my $result = 0;
    my $json = from_json(qq{{"index": [
                {"type": "unique", "fields": "userid"}
              ]}}
    );

    my $template = Daje::Generate::Tools::Datasections->new(
        data_sections => "table,foreign_key,index" ,
        source        => 'Generate::Templates::Sql'
    );
    $template->load_data_sections();

    my $index = Daje::Generate::Sql::Table::Index->new(
        json      => $json,
        template  => $template,
        tablename => 'users',
    );

    $index->create_index();

    my $sql = $index->sql;
    if($sql eq $test) {
        $result = 1;
    }
    return $result;
}

ok(test_generate_index() == 1);
done_testing();

