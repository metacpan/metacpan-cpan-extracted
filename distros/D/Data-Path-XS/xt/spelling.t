use strict;
use warnings;
use Test::More;

eval { require Test::Spelling; 1 }
    or plan skip_all => 'Test::Spelling required';

# Whitelist proper nouns, project-specific terms, and Perl jargon that
# the system dictionary doesn't know.
Test::Spelling::add_stopwords(<DATA>);
Test::Spelling::all_pod_files_spelling_ok();

__DATA__
autovivification
autovivifies
autovivify
arrayref
arrayrefs
backend
binary-safe
buf
cpants
deref
HELEM
hashref
hashrefs
ithreads
JSON
klen
lookups
lvalue
metacpan
overhead
PV
RFC
RV
runloop
runtime
SV
SvUTF8
unescaping
unimport
UTF
XPath
XS
XSParseKeyword
XSUB
XSUBs
async
arrayrefs
endian
Errno
Encode
fooi
hashlike
hv
iget
intern
keyword
keywords
lvalue
namespace
op
ops
pathset
pathget
pathexists
pathdelete
pathc
patha
preallocated
README
recompiles
ref
refcount
refs
rfc
slash-separated
substr
threadsafe
typedef
unbless
vividsnow
zero-overhead
