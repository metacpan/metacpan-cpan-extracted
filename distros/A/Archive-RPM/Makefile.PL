use inc::Module::Install;

githubmeta;

name     'Archive-RPM';
all_from 'lib/Archive/RPM.pm';
author   'Chris Weyl <cweyl@alumni.drew.edu>';
license  'lgpl';

readme_from 'lib/Archive/RPM.pm';
readme_markdown_from 'lib/Archive/RPM.pm';

requires 'Moose';
requires 'MooseX::AttributeHelpers';
requires 'MooseX::MarkAsMethods';
requires 'MooseX::Types::DateTime';
requires 'MooseX::Types::DateTimeX';
requires 'MooseX::Types::Path::Class';
requires 'MooseX::Traits';

requires 'DateTime';
requires 'English';
requires 'Path::Class';
requires 'RPM2' => '0.68';

requires_external_bin 'rpm2cpio';
requires_external_bin 'cpio';

test_requires 'Test::More';

extra_tests;
auto_provides;
auto_install;

WriteAll;

