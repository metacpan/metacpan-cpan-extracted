use strict;
use warnings;
use Test::More;
use DBIx::ObjectMapper::Engine::DBI;
use DBIx::ObjectMapper::Query;

my ($dsn, $user, $pass) = @ENV{map { "MAPPER_TEST_PG_${_}" } qw/DSN USER PASS/};

plan skip_all => 'Set $ENV{MAPPER_TEST_PG_DSN}, _USER and _PASS to run this test' unless ($dsn && $user);

my $engine = DBIx::ObjectMapper::Engine::DBI->new({
    dsn => $dsn,
    username => $user,
    password => $pass,
    on_connect_do => [
        q{CREATE TEMP TABLE artist (id serial primary key, name text)},
    ],
});

my $query = DBIx::ObjectMapper::Query->new($engine);

{
    my @name = qw(a b c d e f g);
    ok my $r = $query->insert->into('artist')->values(
        [qw(name)],
        map{ [$_] } @name
    )->execute();

    my $it = $query->select->column('name')->from('artist')->order_by('id')
        ->execute();
    my @a = @$it;
    for my $i ( 0 .. $#a ) {
        is $name[$i], $a[$i]->[0];
    }
};

{
    $query->delete->table('artist')->execute;
    my @name = qw(h i j k l m n);
    ok $query->insert->into('artist')->values(
        map { { name => $_ } } @name
    )->execute();

    my $it = $query->select->column('name')->from('artist')->order_by('id')
        ->execute();
    my @a = @$it;
    for my $i ( 0 .. $#a ) {
        is $name[$i], $a[$i]->[0];
    }

};

done_testing;
