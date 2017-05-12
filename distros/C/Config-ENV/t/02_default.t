package MyConfig;
use strict;

use Config::ENV 'FOO_ENV', default => 'development';


use Test::More;
use Test::Name::FromLine;

undef $ENV{FOO_ENV};

is __PACKAGE__->env, 'development';

$ENV{FOO_ENV} = 'production';;

is __PACKAGE__->env, 'production';

done_testing;
