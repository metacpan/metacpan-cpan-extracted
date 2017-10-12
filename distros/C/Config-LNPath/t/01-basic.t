use Test::More;

use Config::LNPath;

use Cwd qw/abs_path/;

my $file = abs_path('t/conf.yml');
my $conf = Config::LNPath->new({ config => $file });

is($conf->find('/change/simple'), 'structure');
is($conf->find('/change/test'), 'data');
is($conf->find('/another/simpler'), 'test');
is($conf->section_find('change', 'test'), 'data');

my $file2 = abs_path('t/conf2.yml');
my $conf2 = Config::LNPath->new({ config => [$file, $file2] });

is($conf2->find('/change/simple'), 'structure');
is($conf2->find('/change/test'), 'changed');
is($conf2->find('/another/simpler'), 'test');
is($conf2->section_find('change', 'test'), 'changed');

done_testing();
