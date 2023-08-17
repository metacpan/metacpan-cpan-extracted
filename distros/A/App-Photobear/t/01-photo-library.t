use v5.12;
use warnings;
use Test::More;
use FindBin qw($RealBin);
use_ok('App::Photobear');
my $api_check = 'a18c2f3d-1b2c-4d3e-8f4a-5b6c7d8e9f0a';

my $config = App::Photobear::loadconfig("$RealBin/photobear.ini");

ok($config->{"api_key"}, "API key is set");
ok($config->{"api_key"} eq "$api_check", "API key is correct: $api_check");

my $got = App::Photobear::url_exists("https://www.github.com/telatin.png");
ok(defined $got, "Answer received: $got [ignoring failure]");

my $badgot = App::Photobear::url_exists("https://www.telatin.com/sadly-not-existing.png");
ok($badgot == 0, "Answer received: $badgot (expecting failure)");
done_testing();