use strict;
use warnings;
use Test::More;

use DBIx::ObjectMapper::Engine::DBI;
use DBIx::ObjectMapper::Metadata;

my $engine = DBIx::ObjectMapper::Engine::DBI->new({
    dsn => 'DBI:SQLite:',
    username => '',
    password => '',
    on_connect_do => [
        q{ CREATE TABLE test_default (id integer primary key, name text, is_foo integer default 0 not null)},
    ],
});

my $meta = DBIx::ObjectMapper::Metadata->new( engine => $engine );
my $test = $meta->t( 'test_default' => 'autoload' );
ok $test->insert( name => 'name', is_foo => undef )->execute;

my $data = $test->select->first;
is $data->{name}, 'name';
is $data->{is_foo}, 0;

done_testing;
