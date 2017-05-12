use strict;
use warnings;
use inc::Module::Install 0.92;

name 'Cantella-Store-UUID';
license 'perl';
all_from 'lib/Cantella/Store/UUID.pm';

requires 'JSON';
requires 'Moose';
requires 'Class::MOP';
requires 'File::Copy';
requires 'Data::GUID';
requires 'Path::Class' => '0.18';
requires 'Sub::Exporter';
requires 'File::MimeInfo' => '0.15';
requires 'namespace::autoclean' => '0.09';
requires 'MooseX::Types::Path::Class' => '0.05';
requires 'MooseX::Types::Data::GUID' => '0.001000';

#tests
test_requires 'Dir::Self';
test_requires 'Test::More';
test_requires 'Test::Fatal';
test_requires 'Directory::Scratch';

resources(
  'license', => 'http://dev.perl.org/licenses/',
  'repository', => 'http://github.com/arcanez/Cantella-Store-UUID',
);

WriteAll;
