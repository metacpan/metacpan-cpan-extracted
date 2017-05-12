use inc::Module::Install;

name     'DBIx-Class-Indexer-WebService-Dezi';
all_from 'lib/DBIx/Class/Indexer/WebService/Dezi.pm';
author   q{Logan Bell <loganbell@gmail.com>};
license  'perl';

build_requires 'Test::More';
requires 'Moose'                    => 0;
requires 'DBIx::Class::Indexed'     => 0;
requires 'Dezi::Client'             => 0;
requires 'JSON'                     => 0;
requires 'XML::Simple'              => 0;
requires 'File::Slurp'              => 0;
requires 'MIME::Base64'             => 0;
requires 'Media::Type::Simple'      => 0;

test_requires 'Test::Exception';
test_requires 'Test::More';
test_requires 'Test::MockModule';
test_requires 'DBIx::Class::TimeStamp';

auto_install;

WriteAll;

