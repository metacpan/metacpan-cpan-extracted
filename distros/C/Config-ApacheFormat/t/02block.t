
use Test::More tests => 17;

BEGIN { use_ok 'Config::ApacheFormat'; }

my $config = Config::ApacheFormat->new();
$config->read("t/block.conf");

#use Data::Dumper;
#print STDERR Dumper($config->_dir());

is($config->get('global'), 1);

my $block = $config->block('plain');
isa_ok($block, ref($config));
is($block->get("foo"), "bar");
is(($block->get("baz"))[0], "Bif");
is(($block->get("baz"))[1], "Bap");

$block = $config->block(Param => 'foo');
is($block->get("fooz"), "Bat");

$block = $config->block(Param => 'bar');
is($block->get("fooz"), "Batty");

is($block->get("global"), 1, "inheritence works");

my @blocks = $config->get("Param");
is(@blocks, 2);
is($blocks[0][0], "param");
is($blocks[0][1], "foo");
is($blocks[1][0], "param");
is($blocks[1][1], "bar");

foreach my $b (@blocks) {
    my $block = $config->block(@$b);
    isa_ok($block, ref($config));
}

$block = $config->block(qw(Multi a b c));
is($block->get("foo"), "bar");
