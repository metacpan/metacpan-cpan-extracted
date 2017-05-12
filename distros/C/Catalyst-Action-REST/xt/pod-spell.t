use strict;
use warnings;

use Test::More;

eval "use Test::Spelling";
plan skip_all => "Test::Spelling required for testing POD coverage"
    if $@;

my @stopwords;
for (<DATA>) {
    chomp;
    push @stopwords, $_
        unless /\A (?: \# | \s* \z)/msx;    # skip comments, whitespace
}

add_stopwords(@stopwords);
set_spell_cmd('aspell list -l en');

# This prevents a weird segfault from the aspell command - see
# https://bugs.launchpad.net/ubuntu/+source/aspell/+bug/71322
local $ENV{LC_ALL} = 'C';
all_pod_files_spelling_ok();

__DATA__
Reis
ActionRole
de
Gerv
Newell
Wiki
json
APIs
ActionClass
Daisuke
Daisuke
Deserialize
Deserializer
Deserializing
Doran
Goulah
JSON
Laco
Maki
Maki
Marchex
Multipart
Pearcey
Rolsky
RESTful
RESTful
SERIALIZERS
TT
Wikipedia
XHR
XMLHttpRequest
YAML
conf
deserialization
deserialize
deserialized
deserializing
fREW
html
http
javascript
jrockway
mst
multipart
namespace
plugins
request's
serializer
thusly
wildcard
subclasses
Axel
URI
