#!perl -w
# $Id: /local/CPAN/Catalyst-Model-NetBlogger/t/pod_spelling.t 1376 2005-11-19T03:45:12.647758Z claco  $
use strict;
use warnings;
use Test::More;

eval 'use Test::Spelling 0.11';
plan skip_all => 'Test::Spelling 0.11 not installed' if $@;
plan skip_all => 'set TEST_SPELLING to enable this test' unless $ENV{TEST_SPELLING};

set_spell_cmd('aspell list');

add_stopwords(<DATA>);

all_pod_files_spelling_ok();

__DATA__
NetBlogger
blog
API
Blogger
XMLRPC
appkey
uri
url
username
blogger
blogid
blogs
