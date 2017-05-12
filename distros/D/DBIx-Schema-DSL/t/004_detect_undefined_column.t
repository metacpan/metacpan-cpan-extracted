use strict;
use warnings;
use utf8;
use Test::More;

eval {
    package Fuga;
    use DBIx::Schema::DSL;

    create_table player => columns {
        integer 'id',   primary_key => 1, auto_increment => 1;
        integer 'member_id', unique;

        add_unique_index member_id_uniq => [qw/member/];
    };
    1;
};
like $@, qr/^Index error: Key column \[member\]/;

eval {
    package Piyo;
    use DBIx::Schema::DSL;

    create_table player => columns {
        integer 'member_id', unique;

        set_primary_key qw/id member_id/;
    };
    1;
};
like $@, qr/^Primary key error: Key column \[id\]/;

done_testing;
