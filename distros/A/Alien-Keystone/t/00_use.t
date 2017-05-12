use Test::More;
use blib;
use_ok 'Alien::Keystone';

my $keystone = new_ok 'Alien::Keystone';
note $keystone->cflags;
note $keystone->libs;
note Alien::Keystone::ConfigData->config('finished_installing');
is(Alien::Keystone::ConfigData->config('finished_installing'), 1, 'Installing complete');

done_testing;

__END__
