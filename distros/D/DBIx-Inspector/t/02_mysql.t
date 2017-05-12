use strict;
use warnings;
use Test::More;
use Test::Requires 'Test::mysqld', 'DBD::mysql';
use DBIx::Inspector;
plan skip_all => "skip tests unless \$ENV{TEST_MYSQL} is true" unless $ENV{TEST_MYSQL};

my $mysqld = Test::mysqld->new(
    my_cnf => {
        'skip-networking' => '',    # no TCP socket
    }
) or plan skip_all => $Test::mysqld::errstr;

subtest 'basic' => sub {
    my $dbh = DBI->connect($mysqld->dsn(dbname => 'test')) or die;
    $dbh->do(q{
        create table post (
            post_id int unsigned not null primary key,
            user_id int,
            body varchar(255)
        );
    });
    $dbh->do(q{
        create table user (
            user_id int unsigned not null,
            name varchar(255)
        );
    });
    my $inspector = DBIx::Inspector->new(dbh => $dbh);
    my @tables = $inspector->tables;
    is(join(",", sort map { $_->name } @tables), 'post,user');
    my ($post) = grep { $_->name eq 'post' } @tables;
    isa_ok $post, 'DBIx::Inspector::Table';
    ok $post;
    is(join(',', sort map { $_->name } $post->columns), 'body,post_id,user_id');
    is(join(',', sort map { $_->name } $post->primary_key), 'post_id');
    $dbh->do(qq{DROP TABLE $_}) for map { $_->name } @tables;
};

subtest 'foreign key' => sub {
    my $dbh = DBI->connect($mysqld->dsn(dbname => 'test'), '', '', {RaiseError => 1, 'mysql_multi_statements' => 1}) or die;
    $dbh->do(q{
        CREATE TABLE other (id INT NOT NULL, PRIMARY KEY (id)) TYPE=INNODB;
        CREATE TABLE parent(id INT NOT NULL, PRIMARY KEY (id)) TYPE=INNODB;
        CREATE TABLE child(id INT, parent_id INT, INDEX par_ind (parent_id),
            FOREIGN KEY (parent_id) REFERENCES parent(id)
            ON DELETE SET NULL
        ) TYPE=INNODB;
    }) or die;
    my $inspector = DBIx::Inspector->new(dbh => $dbh);
    my $parent = $inspector->table('parent');
    {
        my $iter = $inspector->table('parent')->pk_foreign_keys();
        my $fk = $iter->next;
        is $fk->pkcolumn_name, 'id';
        is $fk->pktable_name, 'parent';
        is $fk->fktable_name, 'child';
        is $fk->fkcolumn_name, 'parent_id';
        is $iter->next, undef;
    }
    {
        my $iter = $inspector->table('child')->pk_foreign_keys();
        is scalar($iter->all), 0;
    }
    {
        my $iter = $inspector->table('parent')->fk_foreign_keys();
        is scalar($iter->all), 0;
    }
    {
        my $iter = $inspector->table('other')->fk_foreign_keys();
        is scalar($iter->all), 0;
    }
    {
        my $iter = $inspector->table('other')->pk_foreign_keys();
        is scalar($iter->all), 0;
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

done_testing;

