use strict;
use warnings;
use Test::More;

# generated by Dist::Zilla::Plugin::Test::PodSpelling 2.007005
use Test::Spelling 0.12;
use Pod::Wordlist;


add_stopwords(<DATA>);
all_pod_files_spelling_ok( qw( bin lib ) );
__DATA__
AES128
AES256
Cipher
Crypt
DES3
Devlin
Graham
KeyGenerator
OpenToken
Serializer
Shawn
Socialtext
TerMarsch
Token
cpan
lib
null
shawn
