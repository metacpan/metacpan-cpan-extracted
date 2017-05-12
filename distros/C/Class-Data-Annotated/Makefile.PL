use inc::Module::Install;

name    'Class-Data-Annotated';

perl_version    '5.006';

all_from        'lib/Class/Data/Annotated.pm';

requires        'Data::Annotated' => '0.01';

build_requires  'Test::More' => '0.7';
build_requires  'Test::Exception' => '0.25';

auto_install;
WriteAll;
