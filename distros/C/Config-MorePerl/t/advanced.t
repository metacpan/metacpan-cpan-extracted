use 5.012;
use warnings;
use Test::More;
use Test::Deep;
use Config::MorePerl;
use FindBin qw($Bin);

my $initial_cfg = {
    a => 1,
    b => [1,2,3],
    hash => {key1 => 1, b => 2},
    hello=> 'world',
    num2 => 500000000,
};

my $cfg = Config::MorePerl->process($Bin.'/configs/advanced.conf',$initial_cfg);
my $v7={
   'key1' => 'value1',
   'key3' => 100500,
   'key2' => 'value2',
   b      => 2,
};
my $v8=[444, 777, 999, $v7, 1000, 2000, 3000, 5000, 100000, $v7, 1];
my $h2={
    'key5' => 1400,
    'key4' => 'value4',
    'key6' => 6000,
    'key7' => $v7,
    'key9' => 'popa',
    'key8' => $v8,
    'key3' => 'value3'
};

my $my_cfg = {
    'hash2' => $h2,
    'str' => 'jopa',
    'array2' => [$v7, $h2, $h2, $v8, 'jopa'],
    'str7' => $v7,
    'str9' => undef,
    'str6' => 'value1',
    'str4' => 'value4',
    'num1' => 545,
    'hash3' => $h2,
    'str5' => 1400,
    'str8' => $v8,
    'hash' => $v7,
    'array' => $v8,
    'hello' => 'world',
    'a' => 1,
    'b' => [1,2,3],
    'str3' => 'value3',
    'num2' => 6000
};

is (ref($cfg),'HASH');
cmp_deeply($cfg,$my_cfg,"got the right horrible data structure");

done_testing();
