use inc::Module::Install;

name        'Class-Spiffy';
all_from    'lib/Class/Spiffy.pm';

requires    perl => '5.6.1';
requires    Scalar::Util => '0';

WriteAll;
