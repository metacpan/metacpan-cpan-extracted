
use Test::More tests => 5;
BEGIN { use_ok('Config::ApacheFormat'); }

my $config = Config::ApacheFormat->new();
isa_ok($config, 'Config::ApacheFormat');

eval {
    $config->read("t/error.conf");
};
like($@, qr/^Error.*?error.conf.*?line 3/);

eval {
    $config->read("t/error_block.conf");
};
like($@, qr/^Error.*?error_block.conf.*?line 6/);

eval {
    $config->read("t/error_includer.conf");
};
like($@, qr/^Error.*?error_include.conf.*?line 4/);

