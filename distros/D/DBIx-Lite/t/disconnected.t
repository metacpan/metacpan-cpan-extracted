#!/usr/bin/perl -w

 use strict;
 use warnings;

 use Test::More tests => 7;
 use DBIx::Lite;

 my $dbix = DBIx::Lite->new(driver_name => 'Pg');

{
    my ($sql) = eval { $dbix->table('authors')->select('id')->select_sql };
    ok !$@, 'no exception thrown';
    if ($@) {
        diag $@;
    }
    is $sql, 'SELECT me.id FROM authors AS me', 'simple select';
}

{
    my ($sql) = $dbix->table('authors')->select_sql;
    is $sql, 'SELECT me.* FROM authors AS me', 'basic';
}

{
    my ($sql) = $dbix->table('authors')->select('id')->distinct->select_sql;
    is $sql, 'SELECT DISTINCT me.id FROM authors AS me', 'distinct';
}

{
    my ($sql) = $dbix->table('authors')->select('id')->distinct('name')->select_sql;
    is $sql, 'SELECT DISTINCT ON (name) me.id FROM authors AS me', 'distinct on';
}

{
    my ($sql) = $dbix->table('authors')->select('id')->distinct(\'lower(name)')->select_sql;
    is $sql, 'SELECT DISTINCT ON (lower(name)) me.id FROM authors AS me', 'distinct on with expression';
}

{
    my ($sql) = $dbix->table('authors')->table_alias('target')->select('id')->select_sql;
    is $sql, 'SELECT target.id FROM authors AS target', 'custom table alias';
}

 __END__