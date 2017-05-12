use inc::Module::Install;
name('Data-Page-FlickrLike');
all_from('lib/Data/Page/FlickrLike.pm');

requires('Data::Page');
requires('Exporter::Lite');

build_requires('Test::More');
build_requires('YAML');
githubmeta();
auto_include_deps();
author_tests('xt');
WriteAll();
