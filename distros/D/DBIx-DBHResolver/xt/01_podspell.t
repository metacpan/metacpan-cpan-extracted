use Test::More;
eval q{ use Test::Spelling };
plan skip_all => "Test::Spelling is not installed." if $@;
add_stopwords(map { split /[\s\:\-]/ } <DATA>);
$ENV{LANG} = 'C';
all_pod_files_spelling_ok('lib');
__DATA__
Kosuke Arisawa
arisawa@gmail.com
DBIx::DBHResolver
Toru Yamaguchi
Pluggable
pluggable
resolver
sharding
YAML
yaml
DBI
ref
attrs
dsn
