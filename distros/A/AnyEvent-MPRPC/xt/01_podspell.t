use Test::More;
eval q{ use Test::Spelling };
plan skip_all => "Test::Spelling is not installed." if $@;
add_stopwords(map { split /[\s\:\-]/ } <DATA>);
$ENV{LANG} = 'C';
all_pod_files_spelling_ok('lib');
__DATA__
Tokuhiro Matsuno
tokuhirom  slkjfd gmail.com
AnyEvent::MPRPC
params
msgid
Coro
Hostname
MessagePack
RPC
Str
blockingly
callback
condvar
condvars
occured
unix
Daisuke
KAYAC
Murase
coroutine
TCP

