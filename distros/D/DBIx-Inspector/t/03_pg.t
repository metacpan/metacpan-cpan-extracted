use strict;
use warnings;
use Test::More;
use Test::Requires 'Test::postgresql', 'DBD::Pg';
use DBIx::Inspector;

push @Test::postgresql::SEARCH_PATHS, '/Library/PostgreSQL/9.0/';

my $pgsql = Test::postgresql->new()
    or plan skip_all => $Test::postgresql::errstr;

subtest 'basic' => sub {
    my $dbh = DBI->connect($pgsql->dsn, undef, undef, {Warn => 0, RaiseError => 1}) or die;
    $dbh->do(q{
        create table post (
            post_id int8 not null primary key,
            user_id int8,
            body varchar(255)
        );
    });
    $dbh->do(q{
        create table usr (
            user_id int8 not null primary key,
            name varchar(255)
        );
    });
    $dbh->do(q{
        create table nopk (
            nopk_id serial not null,
            name varchar(255)
        );
    });
    my $inspector = DBIx::Inspector->new(dbh => $dbh);
    my @tables = $inspector->tables;
    is(join(",", sort map { $_->name } @tables), 'nopk,post,usr');
    my ($post) = grep { $_->name eq 'post' } @tables;
    isa_ok $post, 'DBIx::Inspector::Table';
    ok $post;
    is $post->schema, 'public';
    is $post->type, 'TABLE';
    is(join(',', sort map { $_->name } $post->columns), 'body,post_id,user_id');
    is(join(',', sort map { $_->name } $post->primary_key), 'post_id');
    my ($nopk) = grep { $_->name eq 'nopk' } @tables;
    isa_ok $nopk->primary_key, 'DBIx::Inspector::Iterator::Null';
};

subtest 'foreign key' => sub {
    my $dbh = DBI->connect($pgsql->dsn(), '', '', {RaiseError => 1, Warn => 0}) or die;
    $dbh->do(q{
        CREATE TABLE other (id INT NOT NULL, PRIMARY KEY (id));
    });
    $dbh->do(q{
        CREATE TABLE parent(id INT NOT NULL, PRIMARY KEY (id));
    });
    $dbh->do(q{
        CREATE TABLE child(id INT, parent_id INT,
            FOREIGN KEY (parent_id) REFERENCES parent(id)
            ON DELETE SET NULL
        );
    }) or die;
    my $inspector = DBIx::Inspector->new(dbh => $dbh);
    my $parent = $inspector->table('parent');
    {
        my $iter = $inspector->table('parent')->pk_foreign_keys();
        my $fk = $iter->next;
        is $fk->pkcolumn_name, 'id';
        is $fk->pktable_name, 'parent';
        is $fk->fktable_name, 'child', 'fktable_name';
        is $fk->fkcolumn_name, 'parent_id';
        is $iter->next, undef;
    }
    {
        my $iter = $inspector->table('child')->pk_foreign_keys();
        is $iter->next(), undef;
        my @fks = $inspector->table('child')->pk_foreign_keys();
        is scalar @fks, 0;
    }
    {
        my $iter = $inspector->table('parent')->fk_foreign_keys();
        is $iter->next(), undef;
        my @fks = $inspector->table('parent')->fk_foreign_keys();
        is scalar @fks, 0;
    }
    {
        my $iter = $inspector->table('other')->pk_foreign_keys();
        is $iter->next(), undef;
        my @fks = $inspector->table('other')->pk_foreign_keys();
        is scalar @fks, 0;
    }
    {
        my $iter = $inspector->table('other')->fk_foreign_keys();
        is $iter->next(), undef;
        my @fks = $inspector->table('other')->fk_foreign_keys();
        is scalar @fks, 0;
    }
    {
        my $iter = $inspector->table('child')->fk_foreign_keys();
        my $fk = $iter->next;
        is $fk->pkcolumn_name, 'id';
        is $fk->pktable_name, 'parent';
        is $fk->fktable_name, 'child';
        is $fk->fkcolumn_name, 'parent_id';
        is $iter->next, undef;
    }
};


subtest 'system reserved word' => sub {
    my $dbh = DBI->connect($pgsql->dsn, undef, undef, {Warn => 0, RaiseError => 1}) or die;
    $dbh->do(q{
        create table "user" (
            "user" serial primary key,
            name varchar(255)
        );
    });
    my $inspector = DBIx::Inspector->new(dbh => $dbh);
    my @tables = $inspector->tables;
    ok( grep { $_->name eq 'user' } @tables );
    my ($user) =  $inspector->table('user');
    ok $user;
    is $user->schema, 'public';
    is $user->type, 'TABLE';
    is(join(',', sort map { $_->name } $user->columns), 'name,user');
    is(join(',', sort map { $_->name } $user->primary_key), 'user');
};




done_testing;

