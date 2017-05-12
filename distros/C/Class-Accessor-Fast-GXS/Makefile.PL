use inc::Module::Install;

all_from        'lib/Class/Accessor/Fast/GXS.pm';

no_index        directory => 'example';

WriteAll;
