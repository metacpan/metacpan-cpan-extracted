package MyConfig;
use strict;
use Test::More;
use Test::Name::FromLine;

use Config::ENV 'FOO_ENV';

$ENV{FOO_ENV} = 'development';

common +{
	name => 'foobar',
};

is __PACKAGE__->param('name'), 'foobar';

config development => +{
	name => 'override',
};

is __PACKAGE__->param('name'), 'override';

done_testing;
