#!perl

use Test::More tests => 1;

eval "use Config::PFiles::Path 'bad_method'";

ok ( $@ && $@ =~ /in this context/, "bad import context" );
