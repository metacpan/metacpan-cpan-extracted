package TestData;
use Exporter 'import';
@EXPORT    = qw(get_test_db_path get_db);   # afunc is a function

use strict;
use warnings;
use Path::Class;

sub get_test_db_path {
	return file(__FILE__)->dir
		->parent
		->subdir('test-data', 'abcdef.module-test-stub' , 'zotero')
		->file('zotero.sqlite')
		->absolute;
}

sub get_db {
	require Biblio::Zotero::DB;
	return Biblio::Zotero::DB->new( profile_directory =>
		file(__FILE__)->dir
			->parent
			->subdir('test-data', 'abcdef.module-test-stub' , 'zotero')
	);
}

1;
