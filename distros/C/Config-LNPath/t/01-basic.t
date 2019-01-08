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

eval { Config::LNPath->new() };
like($@, qr/^no config path passed to new at/, 'catch the error');

my $conf3 = Config::LNPath->new({ section => 'change', config => [$file, $file2], merge => { unique_hash => 1 }});
is($conf3->find('/simple'), 'structure');
is($conf3->find('/test'), 'data');

my $hmm = eval { $conf2->find('/simpler') };
like($@, qr/Could not find value from config using path/, 'Could not find path');
eval { $conf2->section_find('/another') };
like($@, qr/^Could not find value from config section/, 'Couls not find section');



done_testing();
