use strict;
use warnings;
use utf8;
use Test::More;

package Hoge;
use DBIx::Schema::DSL;

database 'MySQL';
create_database 'test';

add_table_options
    mysql_charset => 'utf8mb4';

default_unsigned;

create_table user => columns {
    integer 'id',   primary_key, auto_increment;
    integer 'member_id', unique;
    column  'gender', 'tinyint', null => 1;
    integer 'age', limit => 1, unsigned => 0, null;
    varchar 'name', null => 0;
    varchar 'description', null => 1;
    text    'profile';
};

create_table book => columns {
    integer 'id',   primary_key, auto_increment;
    varchar 'name', null => 0;
    integer 'author_id';
    decimal 'price', size => [4,2];

    belongs_to 'author';
};

create_table author => columns {
    primary_key 'id';
    varchar 'name';
    decimal 'height', precision => 4, scale => 1;

    has_many 'book';
};

create_table user_purchase => columns {
    integer  'id', auto_increment;
    integer  'user_id';
    datetime 'purchased_at';

    set_primary_key qw/id purchased_at/;
    add_index user_id_idx => [qw/user_id/];
};

package Fuga;
use DBIx::Schema::DSL;

create_table player => columns {
    integer 'id',   primary_key => 1, auto_increment => 1;
    integer 'member_id', unique;
    column  'gender', 'tinyint', null => 1;
    integer 'age', limit => 1, unsigned => 0, null;
    varchar 'name', null => 0;
    varchar 'description', null => 1;
};

package main;

my $output = Hoge->output;
ok $output and note $output;
ok(Hoge->no_fk_output);
ok(Hoge->translate_to('POD')) or diag(Hoge->translator->error);

like(Fuga->output, qr/player/ms);
unlike(Fuga->output, qr/user_purchase/ms);

done_testing;
