use inc::Module::Install;

all_from('lib/DBIx/Poggy.pm');
readme_from_pod('lib/DBIx/Poggy.pm');

requires
    'DBI' => 0,
    'DBD::Pg' => 0,
    'AnyEvent' => 0,
    'Guard' => 0,
    'Promises' => 0,
    'Scalar::Util' => 0,
    'Devel::GlobalDestruction' => 0,
;

WriteAll();
