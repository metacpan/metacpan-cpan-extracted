use inc::Module::Install;
name 'CPAN-Source';

perl_version '5.10';
all_from 'lib/CPAN/Source.pm';

readme_from_pod      'lib/CPAN/Source.pm';
readme_markdown_from 'lib/CPAN/Source.pm';

requires 'Try::Tiny';
requires 'Mouse';
requires 'DateTime';
requires($_ => 0) for qw(URI Any::Moose Compress::Zlib LWP::UserAgent XML::Simple Cache::File DateTime::Format::HTTP YAML CPAN::DistnameInfo YAML::XS JSON::XS);

tests 't/*.t';
# author_tests 'xt';
# test_requires 'Test::More';
auto_include;
auto_set_repository;
WriteAll;
