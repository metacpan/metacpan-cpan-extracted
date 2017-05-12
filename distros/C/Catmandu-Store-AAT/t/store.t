use strict;
use warnings;
use Test::More;

use Catmandu::Fix;

my $pkg;

BEGIN {
    $pkg = 'Catmandu::Store::AAT';
    use_ok $pkg;
}

my $record = {
    'objectName' => '300033618'
};

my $record_lang = {
    'objectName' => '300033618'
};

my $fixer = Catmandu::Fix->new(fixes => ['lookup_in_store(objectName, AAT)']);
my $fixer_lang = Catmandu::Fix->new(fixes => ['lookup_in_store(objectName, AAT, lang:en)']);

$fixer->fix($record);
$fixer_lang->fix($record_lang);

my $expected = {
    'objectName' => {
        'id' => '300033618',
        'prefLabel' => 'schilderingen',
        'uri' => 'http://vocab.getty.edu/aat/300033618'
    }
};

my $expected_lang = {
    'objectName' => {
        'id' => '300033618',
        'prefLabel' => 'paintings (visual works)',
        'uri' => 'http://vocab.getty.edu/aat/300033618'
    }
};

is_deeply $record, $expected;
is_deeply $record_lang, $expected_lang;

done_testing 3;