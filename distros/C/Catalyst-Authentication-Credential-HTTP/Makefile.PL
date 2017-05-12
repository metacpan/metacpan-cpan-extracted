use inc::Module::Install 0.87;
use Module::Install::AuthorRequires;
use Module::Install::AuthorTests;

name 'Catalyst-Authentication-Credential-HTTP';
all_from 'lib/Catalyst/Authentication/Credential/HTTP.pm';

requires 'Catalyst::Runtime';
requires 'Catalyst::Plugin::Authentication' => '0.10005';
requires 'Data::UUID' => '0.11';
requires 'String::Escape';
requires 'URI::Escape';
requires 'Class::Accessor::Fast';

test_requires 'Test::Exception';
test_requires 'Test::MockObject';
test_requires 'Test::More' => '0.88';

author_requires 'Test::WWW::Mechanize::Catalyst' => '0.51';
author_requires 'Test::Pod' => '1.14';
author_requires 'Test::Spelling' => '0.11';
author_requires 'Test::Pod::Coverage' => '1.04';

resources repository => 'git://git.shadowcat.co.uk/catagits/Catalyst/Catalyst-Authentication-Credential-HTTP';

author_tests 't/author';

auto_install;

WriteAll;

