use Test::More;
use blib;
use Data::Dumper;
use_ok 'Alien::Capstone';
my $capstone = new_ok('Alien::Capstone');
note $capstone->cflags;
note $capstone->libs;
note Alien::Capstone::ConfigData->config('finished_installing');
is(&Alien::Capstone::is_installed(), 1, 'Capstone is installed');

done_testing();

__END__
