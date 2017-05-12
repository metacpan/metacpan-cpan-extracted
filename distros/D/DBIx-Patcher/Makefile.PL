use inc::Module::Install 1.00;


name 'DBIx-Patcher';
all_from 'lib/DBIx/Patcher.pm';

requires (
    'DateTime' => '0.66',
    'DBIx::Class' => '0.08124',
    'Carp' => '1.11',
    'Data::Dump' => '1.19',
    'Digest::MD5' => '2.39',
    'FindBin::libs' => '1.5100',
    'Getopt::Long' => '2.38',
    'IO::File' => '1.14',
    'Path::Class' => '0.21',
);

test_requires (
    'Test::More' => '0.96',
);

install_script 'bin/patcher';
WriteMakefile();

license 'perl';

WriteAll;
