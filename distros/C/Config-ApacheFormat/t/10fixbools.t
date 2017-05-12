
use Test::More tests => 7;
BEGIN { use_ok 'Config::ApacheFormat'; }

my $config = Config::ApacheFormat->new(fix_booleans => 1);
$config->read("t/fixbools.conf");

is($config->get('usecanonicalname'), 1);
is($config->get('haveprettyflowers'), 1);
is($config->get('likesalads'), 1);

is($config->get('actlikeanimals'), 0);
is($config->get('killfluffy'), 0);
is($config->get('dislikesalads'), 0);

