use inc::Module::Install;

name            'Compile-Generators';
all_from        'lib/Compile/Generators.pm';

requires        'Module::Compile' => '0.17';

clean_files     't/*.tc';

WriteAll;
