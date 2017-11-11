use strict;
use warnings;
use Test::More;

use Catmandu::Fix;

# replace with the actual test
ok 1;

done_testing;

# my $pkg;

# BEGIN {
#     $pkg = 'Catmandu::Fix::viaf_match';
#     use_ok $pkg;
# }

# SKIP : {
#     skip "Need network set \$ENV{RELEASE_TESTING}",1 unless $ENV{RELEASE_TESTING};

#     my $record = {
#         'authorName' => 'Jane Austen'
#     };

#     my $fixer = Catmandu::Fix->new(fixes => ['viaf_match(authorName)']);

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
