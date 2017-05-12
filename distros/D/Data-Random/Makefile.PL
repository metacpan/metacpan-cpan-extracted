use inc::Module::Install;


# Define metadata
name            'Data-Random';
all_from        'lib/Data/Random.pm';


# Specific dependencies
requires        'Carp'              =>  0;
requires        'Time::Piece'       =>  '1.16';

recommends      'GD'                =>  0;

test_requires   'Test::More'        => '0.88';
test_requires   'File::Temp'        => 0;

configure_requires 'YAML::Tiny'		=> 0;

githubmeta;
jsonmeta;
realclean_files 'META.json';


WriteAll;
