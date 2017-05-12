use Test::More;
eval q{ use Test::Spelling };
plan skip_all => "Test::Spelling is not installed." if $@;
add_stopwords(<DATA>);
set_spell_cmd("aspell -l en list");
all_pod_files_spelling_ok('lib');
__DATA__
VCS
tuple
tuples
tarantool
github
repo
NUM
async
cb
errstr
lua
JSON
STR
UTF
coro
errorstr
destructor
ok
cfg
utf
happenned
ator
autoloads
iter
itemlist
LLClient
Destructor
Tuple
API
BIGMONEY
TODO
deserialized
iproto
multi
unicode
msgpack
auth
