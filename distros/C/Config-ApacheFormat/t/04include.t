
use Test::More qw(no_plan);
BEGIN { use_ok 'Config::ApacheFormat'; }

my $config = Config::ApacheFormat->new();
$config->read("t/includer.conf");

is($config->get('foo'), 1);
is($config->get('bar'), 2);

is($config->get('first'), 'unset');
is($config->get('last'), 'second');

# make sure root_directive works
my $config2 = Config::ApacheFormat->new();
$config->root_directive('RootDir');
eval { $config->read("t/includer_with_root.conf"); };
like($@, qr!Unable to open include file '/this/path/should/not/exist/included.conf'!);

# make sure include_directives works
my $crazy = Config::ApacheFormat->new(include_directives => [ 'zany_inc',
                                                              'crazy_inc' ]);
$crazy->read('t/crazy_includer.conf');
is($crazy->get('foo'), 1);
is($crazy->get('bar'), 2);

is($crazy->get('first'), 'unset');
is($crazy->get('last'), 'second');
