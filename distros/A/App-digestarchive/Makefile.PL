use inc::Module::Install;
name 'App-digestarchive';
all_from 'lib/App/digestarchive.pm';

install_script "bin/digestarchive";

requires
	'Class::Accessor'         => '0.34',
	'Archive::Tar'            => '1.78',
	'Compress::Zlib'          => 0,
	'IO::Uncompress::Bunzip2' => 0,
	'Digest'                  => 0,
	'Digest::MD5'             => 0,
	'Digest::SHA1'            => 0,
;

tests 't/*.t';
author_tests 'xt';

test_requires 'Test::More';
auto_set_repository;
auto_include;
WriteAll;
