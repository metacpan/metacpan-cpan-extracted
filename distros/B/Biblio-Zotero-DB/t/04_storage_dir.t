use strict;
use warnings;
use Test::Most tests => 4;

use lib "t/lib";
use TestData;
use Path::Class;
use Path::Class::URI;


my $db = get_db();
my $schema = $db->schema;
my $storage_dir = $db->storage_directory;

is($schema->zotero_storage_directory, $storage_dir, 'Zotero storage attribute exists');

my $attachments;
ok( $attachments = $schema->resultset('ItemAttachment')->search(
	{
		sourceitemid => 4,
	}
), 'got attachments');

is( $attachments->count, 3,  'got 3 attachments');

my $itemid_to_uri = {
	3 => URI->new('http://hop.perl.plover.com/'), # link to URI, path: <undef>
	# TODO the regex below is a fix for Path::Class::URI. Remove later when new version is released.
	6 => URI->new_abs('UI2AB38F/HigherOrderPerl.pdf', $storage_dir->uri->as_string =~ s,[^/]$,$&/,r ), # in storage, path: <storage:HigherOrderPerl.pdf>
	11 => file('/tmp/HOP.tgz')->uri,  # link to file, path: </tmp/HOP.tgz>
};

subtest 'testing attachment to URI' => sub {
	for my $attach ($attachments->all) {
		my $itemid = $attach->itemid->itemid;
		my $uri = $attach->uri;
		isa_ok $uri, 'URI';
		is($uri, $itemid_to_uri->{$itemid}, "mapped item attachment to @{[$itemid_to_uri->{$itemid}]}" );
	}
};

done_testing;
