use inc::Module::Install;

name 'Data-Pipeline';
all_from 'lib/Data/Pipeline.pm';

requires 'Moose' => 2.06;

feature 'CSV Adapter' => (
    'Text::CSV' => 0,
    'IO::Handle' => 0,
    'IO::String' => 0,
    'IO::File' => 0
);

feature 'SPARQL Adapter' => (
    'RDF::Query' => 0,
    'RDF::Core' => 0
);

feature 'RSS Adapter' => (
    'XML::RAI' => 0
);

feature 'JSON Adapter' => (
    'JSON' => 0
);

feature 'FetchPage Adapter' => (
    'LWP' => 5,
);

build_requires 'Test::More';

tests('t/*.t');
author_tests('xt');

install_script glob('scripts/*');

WriteAll;
