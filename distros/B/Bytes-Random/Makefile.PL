use 5.006000;
use inc::Module::Install;
name           'Bytes-Random';
all_from       'lib/Bytes/Random.pm';
perl_version   '5.006000';
test_requires  'Statistics::Basic' => 0;
WriteAll;
