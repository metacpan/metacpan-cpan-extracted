use Test::More;
eval q{ use Test::Spelling };
plan skip_all => "Test::Spelling is not installed." if $@;
add_stopwords(map { split /[\s\:\-]/ } <DATA>);
$ENV{LANG} = 'C';
all_pod_files_spelling_ok('lib');
__DATA__
punytan
punytan@gmail.com
AnyEvent::Twitter
OAuth
API
api
callback
JSON
json
HTTP
url
Hideki
Wiki
Yamamura
ramusara
params
timestamp
