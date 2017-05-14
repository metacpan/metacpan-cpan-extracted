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

{
    my $loc = Data::Localize->new;
    $loc->add_localizer(
        class         => 'Gettext',
        path          => 't/001-basic/*.po',
        storage_class => 'MongoDB',
        storage_args  => {
            database => $conn->get_database('data_localize_test')
        }
    );

    $loc->set_languages('ja');

    {
        my $out = $loc->localize('Hello, stranger!', '牧大輔');
        is($out, '牧大輔さん、こんにちは!', q{translation for "Hello, stranger!" from MongoDB for ja});
    }

    $loc->set_languages('en');

    {
        my $out = $loc->localize('Hello, stranger!', 'Stevan');
        is($out, 'Hello, Stevan!', q{translation for "Hello, stranger!" from MongoDB for en});
    }
}

$conn->get_database('data_localize_test')->drop;

done_testing;
