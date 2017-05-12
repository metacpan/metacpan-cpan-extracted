use strict;
use warnings;
use utf8;
use Test::More;

package Hoge;
use DBIx::Schema::DSL;

create_table user => columns {
    integer 'id',   primary_key => 1, auto_increment => 1;
    integer 'member_id', unique;
    column  'gender', 'tinyint', null => 1;
    integer 'age', limit => 1, unsigned => 0, null;
    varchar 'name', null => 0;
    varchar 'description', null => 1;
    text    'profile';
    timestamp 'timestamp', on_update => 'CURRENT_TIMESTAMP', default => \'CURRENT_TIMESTAMP';
};

create_table book => columns {
    integer 'id',   pk, auto_increment;
    varchar 'name', null => 0;
    integer 'author_id';
    decimal 'price', size => [4,2];
    enum    'classification', [qw/novel science/];

    belongs_to 'author', on_delete => 'cascade';
};

create_table author => columns {
    pk      'id';
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

package main;

{
    no warnings 'once';
    isa_ok $Hoge::CONTEXT, 'DBIx::Schema::DSL::Context';
}
my $c = Hoge->context;
is $c->db, 'MySQL';

isa_ok $c->translator, 'SQL::Translator';
isa_ok $c->schema,     'SQL::Translator::Schema';

ok $c->no_fk_translate;
ok my $ddl = $c->translate;
note $ddl;

like $ddl, qr/ON DELETE cascade/msi;
like $ddl, qr/on update CURRENT_TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP/msi;
like $ddl, qr/`classification` ENUM\('novel', 'science'\) NULL/msi;

ok $c->no_fk_translate ne $c->translate;

done_testing;
