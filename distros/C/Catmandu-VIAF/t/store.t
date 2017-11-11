use strict;
use warnings;
use Test::More;

use Catmandu::Fix;

my $pkg;

# replace with the actual test
ok 1;

done_testing;

# BEGIN {
#     $pkg = 'Catmandu::Store::VIAF';
#     use_ok $pkg;
# }

# SKIP : {
#     skip "Need network set \$ENV{RELEASE_TESTING}",1 unless $ENV{RELEASE_TESTING};

#     my $record = {
#         'authorName' => '102333412'
#     };

#     my $fixer = Catmandu::Fix->new(fixes => ['lookup_in_store(authorName, VIAF)']);

#     $fixer->fix($record);

#     my $expected = {
#         'authorName' => {
#             'dcterms:identifier' => '102333412',
#             'guid' => 'http://viaf.org/viaf/102333412',
#             'schema:birthDate' => '1775-12-16',
#             'schema:deathDate' => '1817-07-18',
#             'schema:description' => 'English novelist',
#             'skos:prefLabel' => 'Jane Austen'
#         }
#     };

#     is_deeply $record, $expected;
# }

# done_testing 2;
