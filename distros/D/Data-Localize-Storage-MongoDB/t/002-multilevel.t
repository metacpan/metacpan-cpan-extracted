#!perl

use strict;
use warnings;
use utf8;

use Test::More;
use MongoDB;
use Data::Localize;

my $HOST = $ENV{MONGOD} || "localhost";

my $conn = eval { MongoDB::Connection->new( host => $HOST ) };
plan skip_all => $@ if $@;

use_ok "Data::Localize::Storage::MongoDB";

my $loc = Data::Localize->new;
$loc->add_localizer(
    class         => "MultiLevel",
    paths         => [ 't/002-multilevel/*.yml' ],
    storage_class => 'MongoDB',
    storage_args  => {
        database => $conn->get_database('data_localize_test')
    }
);

{
    $loc->set_languages('en');
    is( $loc->localize( 'hello_world' ), 'Hello, World!', "hello_world (en)" );
    is( $loc->localize( 'greetings.hello', { name => 'John Doe' } ), 'Hello, John Doe', "greetings.hello (en)" );
    is( $loc->localize( 'greetings.morning', { name => 'John Doe' } ), 'Good morning, John Doe', "greetings.morning (en)" );
    is( $loc->localize( 'greetings.afternoon', { name => 'John Doe' } ), 'Good afternoon, John Doe', "greetings.afternoon (en)" );
    is( $loc->localize( 'greetings.evening', { name => 'John Doe' } ), 'Good evening, John Doe', "greetings.evening (en)" );
    is( $loc->localize( 'nonexistent.hello_world' ), 'nonexistent.hello_world' );
}

{
    $loc->set_languages('ja', 'en');
    is( $loc->localize( 'hello_world' ), 'こんにちは、世界！', "hello_world (ja)" );
    is( $loc->localize( 'greetings.hello', { name => 'John Doe' } ), 'こんにちは、 John Doe', "greetings.hello (ja)" );
    is( $loc->localize( 'greetings.morning', { name => 'John Doe' } ), 'おはよう、 John Doe', "greetings.morning (ja)" );
    is( $loc->localize( 'greetings.afternoon', { name => 'John Doe' } ), 'こんにちは、 John Doe', "greetings.afternoon (ja)" );
    is( $loc->localize( 'greetings.evening', { name => 'John Doe' } ), 'こんばんは、 John Doe', "greetings.evening (ja)" );
    is( $loc->localize( 'nonexistent.hello_world' ), 'nonexistent.hello_world' );
}

$conn->get_database('data_localize_test')->get_collection('en')->update(
    { _id => 'greetings' },
    { '$set' => { 'msg.hello' => 'WTF {{name}}' } }
);

{
    $loc->set_languages('en');
    is( $loc->localize( 'greetings.hello', { name => 'John Doe' } ), 'WTF John Doe', "greetings.hello (en) (manipulated in the DB)" );
}

done_testing();


