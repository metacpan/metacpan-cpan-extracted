use 5.010;
use lib 't/lib';
use Bot::Training;
use Test::More tests => 5;
use File::Slurp 'slurp';

my $bt = Bot::Training->new;

is_deeply([ grep /Test$/, $bt->plugins ], [ 'Bot::Training::Test' ], "The test plugin is loaded");

for ('test', grep /Test$/, $bt->plugins) {
    my $test = $bt->file('test');
    ok($test, "Got test plugin, it's a " . ref($test));
    my @test = split /\n/, slurp($test->file);
    is_deeply(\@test, [ 'I am a', 'little test', 'training file' ], "Got the test.trn file");
}
