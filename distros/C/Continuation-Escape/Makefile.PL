# Load the Module::Install bundled in ./inc/
use inc::Module::Install;

# Define metadata
name           'Continuation-Escape';
all_from       'lib/Continuation/Escape.pm';
githubmeta;

requires       'Scope::Upper' => '0.06';

build_requires 'Test::Exception' => '0.27';

WriteAll;

