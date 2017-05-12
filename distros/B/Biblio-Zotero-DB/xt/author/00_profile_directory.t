use Test::Most tests => 7;
use strict;
use Path::Class;
use File::HomeDir;

BEGIN { use_ok 'Biblio::Zotero::DB' }

use constant PROFILE_NAME => '1234.biblio-zotero-db-test';
use constant PROFILE_DIRECTORY => File::HomeDir->my_home.'/.zotero/zotero/'.PROFILE_NAME.'/zotero';

die "author test is only setup for Linux systems" if $^O ne 'linux';

dir(PROFILE_DIRECTORY)->mkpath(1); # create test directory

die "could not create directory: @{[PROFILE_DIRECTORY]}" unless -d PROFILE_DIRECTORY;

test_find_profile_directories();
test_attr_profile_name();
test_attr_profile_directory();
test_attr_storage_directory();
test_attr_db_file();
test_attr_schema();

END { # clean up at the end
	dir(PROFILE_DIRECTORY)->parent->rmtree(1);
}


sub test_find_profile_directories {
	my $db = Biblio::Zotero::DB->new;

	use DDP; p $db->find_profile_directories;
	ok( @{$db->find_profile_directories} >= 1, 'has a profile directory');
}

sub test_attr_profile_name {
	my $db = Biblio::Zotero::DB->new;
	$db->profile_name( PROFILE_NAME );
	is( $db->profile_directory, PROFILE_DIRECTORY,
		'profile_name trigger');
}

sub test_attr_profile_directory {
	my $db = Biblio::Zotero::DB->new;
	$db->profile_directory(PROFILE_DIRECTORY);
	is( $db->profile_name, PROFILE_NAME, 'profile_name builder');

}

sub test_attr_storage_directory {
	my $db = Biblio::Zotero::DB->new;
	$db->profile_name( PROFILE_NAME );
	is( $db->storage_directory, dir(PROFILE_DIRECTORY, 'storage'),
		'storage directory');
}

sub test_attr_db_file {
	my $db = Biblio::Zotero::DB->new;
	$db->profile_name( PROFILE_NAME );
	is( $db->db_file, dir(PROFILE_DIRECTORY)->file('zotero.sqlite'),
		'storage directory');
}

sub test_attr_schema {
	my $db = Biblio::Zotero::DB->new;
	$db->profile_name( PROFILE_NAME );
	isa_ok( $db->schema, 'Biblio::Zotero::DB::Schema' );
}

done_testing;
