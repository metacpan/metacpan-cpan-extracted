use strict;
use warnings FATAL => 'all';
use Test::More;

eval "use JSON::Any";
plan skip_all => "JSON::Any couldn't be loaded" if $@;
plan tests => 4;

use_ok('App::EvalServer');
use_ok('App::EvalServer::Child');
use_ok('App::EvalServer::Language::Perl');
use_ok('App::EvalServer::Language::Deparse');
