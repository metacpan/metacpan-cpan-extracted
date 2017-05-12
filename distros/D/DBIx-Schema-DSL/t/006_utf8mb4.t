use strict;
use warnings;
use utf8;
use Test::More;

package Hoge;
use DBIx::Schema::DSL;

create_table user => columns {
    varchar 'name';
};


package Fuga;
use DBIx::Schema::DSL;

add_table_options
    mysql_charset => 'utf8mb4';

create_table user => columns {
    varchar 'name';
};

package main;

subtest utf8 => sub {
    my $c = Hoge->context;
    my $sql = $c->translate;
    like   $sql, qr/255/;
    unlike $sql, qr/191/;
};

subtest utf8mb4 => sub {
    my $c = Fuga->context;
    my $sql = $c->translate;
    like   $sql, qr/191/;
    like   $sql, qr/utf8mb4/;
    unlike $sql, qr/255/;
};

done_testing;
