use Test::More;
use Config::Yak;
use Try::Tiny;

my $cfg;

# make sure coercing works ...
try {
    $cfg = Config::Yak::->new('locations' => 't/conf/test001.conf',);
} catch {
    diag $_;
};
isa_ok($cfg,'Config::Yak');

# ... but loading array refs still works as well ...
$cfg = undef;
try {
    $cfg = Config::Yak::->new('locations' => [qw(t/conf/test001.conf t/conf/test002.conf)]);
} catch {
    diag $_;
};
isa_ok($cfg,'Config::Yak');

done_testing();