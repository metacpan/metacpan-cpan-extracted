use Test::More;
use blib;
use Data::Dumper;
use_ok 'Alien::UnicornEngine';
my $unicorn = new_ok('Alien::UnicornEngine');
note $unicorn->cflags;
note $unicorn->libs;
note Alien::UnicornEngine::ConfigData->config('finished_installing');
my $insttype = Alien::UnicornEngine::ConfigData->config('install_type');
note "Install type: $insttype";
if ($insttype eq 'system') {
    is(Alien::UnicornEngine::ConfigData->config('finished_installing'), 0, 'Using system install of unicorn.');
} else {
    is(Alien::UnicornEngine::ConfigData->config('finished_installing'), 1, 'Installation complete of custom build of unicorn');
}

done_testing();

__END__
