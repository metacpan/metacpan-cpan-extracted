use inc::Module::Install;

# Define metadata
name            'Data-Faker-JapaneseFemaleName';
all_from        'lib/Data/Faker/JapaneseFemaleName.pm';

# Specific dependencies
requires        'Data::Faker'  => '0.07';
requires        'Pod::Parser'  => '1.35';

build_requires  'Test::More'   => 0;

auto_include;
auto_install;
WriteAll;
