use inc::Module::Install;
name 'Data-Petitcom';
all_from 'lib/Data/Petitcom.pm';

perl_version '5.010001';

requires(
    'App::Rad'          => 1.04,
    'Compress::Zlib'    => 2.048,
    'GD'                => 2.46,
    'GD::Barcode'       => 1.15,
    'GD::Tiler'         => 0.11,
    'Path::Class'       => 0.26,
    'Term::ANSIColor'   => 3.01,
    'Unicode::Japanese' => 0.49,
    'YAML'              => 0.84,
);

install_script 'bin/petc';

test_requires(
    'Test::More'      => 0.98,
    'Test::Exception' => 0.31,
);
tests 't/*.t t/*/*.t';

auto_set_repository;
auto_include;

WriteAll;
