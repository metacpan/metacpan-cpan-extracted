use strict;
use warnings;
use Test::More;

use Catmandu::Fix;

my $pkg;

BEGIN {
    $pkg = 'Catmandu::Fix::viaf_search';
    use_ok $pkg;
}

my $record = {
    'authorName' => 'Jane Austen'
};

my $fixer = Catmandu::Fix->new(fixes => ['viaf_search(authorName)']);

$fixer->fix($record);

isa_ok($record->{'authorName'}, 'ARRAY');

done_testing 2;
