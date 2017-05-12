use inc::Module::Install;

name 'Catalyst-Plugin-Cache';
all_from 'lib/Catalyst/Plugin/Cache.pm';
requires        'Catalyst'        => '5.8';
requires 'Storable'        => 0;
requires        'Task::Weaken'    => 0;
test_requires        'Test::Deep'      => 0;
test_requires        'Test::Exception' => 0;
test_requires        'Test::More'      => '0.88';
requires        'MRO::Compat'     => 0;

resources repository  => 'git://git.shadowcat.co.uk/catagits/Catalyst-Plugin-Cache.git';
WriteAll;

