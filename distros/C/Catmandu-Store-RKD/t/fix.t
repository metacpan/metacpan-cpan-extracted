use strict;
use warnings;
use Test::More;

use Catmandu::Fix;

my $pkg;

BEGIN {
    $pkg = 'Catmandu::Fix::rkd_name';
    use_ok $pkg;
}

my $record = {
    'author' => {
            'name' => 'Hans Memling'
        }
};

my $fixer = Catmandu::Fix->new(fixes => ['rkd_name(author.name)']);

my $record2 = $fixer->fix($record);

my $expected = {
    'author' => {
        'name' => [
            {
                "artist_link" => "https://rkd.nl/opensearch-eac-cpf?q=kunstenaarsnummer:55174",
                "guid" => "https://rkd.nl/explore/artists/55174",
                "title" => "Memling, Hans",
                "description" => "schilder, tekenaar"
            }
        ]
    }
};

is_deeply $record2, $expected;
    

done_testing 2;