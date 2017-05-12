use strict;
use warnings;
use Test::More;

use DBIx::ObjectMapper::Metadata;
use DBIx::ObjectMapper::Engine::DBI;

my $engine = DBIx::ObjectMapper::Engine::DBI->new({
    dsn => 'DBI:SQLite:',
    username => '',
    password => '',
    on_connect_do => [
        q{CREATE TABLE artist( id integer primary key, name text, name2 text )},
    ],
});

my $meta = DBIx::ObjectMapper::Metadata->new( engine => $engine );

my $call = 0;
my $def_name2 = sub {
    my ( $context, $dbh ) = @_;
    ok $context;
    is ref($context), 'HASH';
    ok $dbh;
    ok $context->{name};
    $call++;
    my $num = $dbh->selectrow_array("SELECT 1 + $call");
    return $context->{name} . '-' . $num;
};

my $person = $meta->table(
    'artist' => 'autoload',
    {
        default   => { name2 => $def_name2 },
        on_update => { name2 => $def_name2 },
    },
);

ok $person->insert( name => 'name1' )->execute;
ok $person->insert( name => 'name2' )->execute;
ok $person->insert( name => 'name3' )->execute;

is $call, 3;

is $person->find(1)->{name2}, 'name1-2';
is $person->find(2)->{name2}, 'name2-3';
is $person->find(3)->{name2}, 'name3-4';

$person->update->set( name => 'name1m' )->where( $person->c('id') == 1 )->execute;
is $call, 4;
is $person->find(1)->{name2}, 'name1m-5';

done_testing;
