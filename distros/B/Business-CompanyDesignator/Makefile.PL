use inc::Module::Install;

name          'Business-CompanyDesignator';
all_from      'lib/Business/CompanyDesignator.pm';
license       'perl';
perl_version  '5.010001';
homepage      'https://github.com/gavincarr/Business-CompanyDesignator';
repository    'https://github.com/gavincarr/Business-CompanyDesignator';

requires      'File::ShareDir';
requires      'FindBin';
requires      'List::MoreUtils';
requires      'Mouse';
requires      'MouseX::NativeTraits';
requires      'namespace::autoclean';
requires      'Regexp::Assemble';
requires      'Unicode::Normalize';
requires      'YAML' => 0.71;

test_requires 'Data::Dump';
test_requires 'File::HomeDir';
test_requires 'Test::More' => 0.88;
test_requires 'Test::Files';
test_requires 'Test::Exception';

auto_install;

install_share;

WriteAll;

