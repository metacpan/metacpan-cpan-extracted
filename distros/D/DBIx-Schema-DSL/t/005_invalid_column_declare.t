use strict;
use warnings;
use utf8;
use Test::More;

eval {
    package Fuga;
    use DBIx::Schema::DSL;

    create_table player => columns {
        integer 'id',   primary_key => 1, auto_increment => 1;
        integer 'member_id', unique, #oops
        varchar 'name';

        add_unique_index member_id_uniq => [qw/member/];
    };
    1;
};
like $@, qr/non void context/ and diag $@;


eval {
    package Piyo;
    use DBIx::Schema::DSL;

    create_table player => columns {
        integer 'id',   primary_key => 1, auto_increment => 1;
        integer 'member_id', unique, 1;

        add_unique_index member_id_uniq => [qw/member/];
    };
    1;
};
like $@, qr/^odd number elements/ and diag $@;

done_testing;
