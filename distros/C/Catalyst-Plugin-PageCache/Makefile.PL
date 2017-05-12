use inc::Module::Install 0.87;

name 'Catalyst-Plugin-PageCache';
all_from 'lib/Catalyst/Plugin/PageCache.pm';

requires 'Catalyst::Runtime' => '0';
requires 'MRO::Compat' => '0.10';
requires 'Digest::SHA1' => '0';

test_requires 'Test::More' => 0;
test_requires 'Catalyst::Plugin::Cache' => '0.10';
test_requires 'Cache::FileCache' => 0;
test_requires 'Cache::Cache' => '1.04'; # for Cache::FileCache (which has no version)
test_requires 'File::Path' => '2.07';

auto_install;
resources repository => 'http://dev.catalyst.perl.org/repos/Catalyst/trunk/Catalyst-Plugin-PageCache/';

WriteAll;
