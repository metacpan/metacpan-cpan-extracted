use inc::Module::Install;

name     'CouchDB-View';
all_from 'lib/CouchDB/View.pm';
author   'Hans Dieter Pearcey <hdp@cpan.org>';

build_requires 'Test::More';
build_requires 'Test::Deep';

requires 'JSON::XS';
requires 'Data::Dump::Streamer';
requires 'PadWalker';
requires 'URI::Escape';

install_script <script/*>;

auto_manifest;
extra_tests;

WriteAll;
