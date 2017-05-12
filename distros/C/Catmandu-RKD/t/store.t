use strict;
use warnings;
use Test::More;

use Catmandu::Fix;

my $pkg;

BEGIN {
    $pkg = 'Catmandu::Store::RKD';
    use_ok $pkg;
}

my $record = {
    'author' => {
            'id' => '38885'
        }
};

my $fixer = Catmandu::Fix->new(fixes => ['lookup_in_store(author.id, RKD)']);

my $record2 = $fixer->fix($record);

my $expected = {
    'author' => {
        'id' => [
            {
                "description" => "hofschilder, schilder, tekenaar",
                "guid" => "https://rkd.nl/explore/artists/38885",
                "title" => "Hoey, Jan de",
                "artist_link" => "https://rkd.nl/opensearch-eac-cpf?q=kunstenaarsnummer:38885"
            }
        ]
    }
};

is_deeply $record2, $expected;
    

done_testing 2;