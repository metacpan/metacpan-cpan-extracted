
use Test::More tests => 9;
BEGIN { use_ok('Config::ApacheFormat'); }

my $config = Config::ApacheFormat->new(valid_directives => [ 'foo' ]);
isa_ok($config, 'Config::ApacheFormat');

eval { $config->read("t/basic.conf") };
like($@, qr/not a valid directive/);


$config = Config::ApacheFormat->new(valid_directives => 
                                    [ qw(foo BiFf bopbop bool) ]);

$config->read("t/basic.conf");
is($config->get('foo'), "bar");
is(($config->get('biff'))[0], "baz");
is(($config->get('biff'))[1], "bop");

$config = Config::ApacheFormat->new(valid_blocks => 
                                    [ qw(plain) ]);

eval { $config->read("t/block.conf"); };
like($@, qr/not a valid block/);

$config = Config::ApacheFormat->new(valid_blocks => 
                                    [ qw(plain param multi) ]);
$config->read("t/block.conf");
my $block = $config->block('plain');
isa_ok($block, ref($config));
is($block->get("foo"), "bar");


