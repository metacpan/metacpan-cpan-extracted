#!perl -T

use Test::More tests => 23;
use Bio::Trace::ABIF;

my $ab = Bio::Trace::ABIF->new();
ok(defined $ab);
ok($ab->isa('Bio::Trace::ABIF'));

SKIP: {
	skip('Cannot find test.ab1 test file', 13)
		unless (-e 'test.ab1');

	# The test file is a manually built file with only
	# three directory entries
	ok($ab->open_abif('test.ab1'), 'opening test file');
	ok($ab->is_abif_open());
	is($ab->num_dir_entries(), 4, 'number of dir entries');
	is($ab->data_offset(), 32, 'data offset');

	# Test reading a directory entry
	%DirEntry = $ab->get_directory('SPAC', 3, 'reading a directory');
	is($DirEntry{TAG_NAME}, 'SPAC', 'tag name');
	is($DirEntry{TAG_NUMBER}, 3, 'tag number');
	is($DirEntry{ELEMENT_TYPE}, 'float', 'element type');
	is($DirEntry{ELEMENT_SIZE}, 4, 'element size');
	is($DirEntry{NUM_ELEMENTS}, 1, 'number of elements');
	is($DirEntry{DATA_SIZE}, 4, 'data size');
	is($DirEntry{DATA_ITEM}, pack('H*', '41264433'), 'data item');
	
	# Test reading a directory entry with data size > 4
	my %DirEntry = $ab->get_directory('PBAS', 1, 'reading a directory with large data');
	is($DirEntry{TAG_NAME}, 'PBAS', 'tag name');
	is($DirEntry{TAG_NUMBER}, 1, 'tag number');
	is($DirEntry{ELEMENT_TYPE}, 'char', 'element type');
	is($DirEntry{ELEMENT_SIZE}, 1, 'element size');
	is($DirEntry{NUM_ELEMENTS}, 7, 'number of elements');
	is($DirEntry{DATA_SIZE}, 7, 'data size');
	is(unpack("A*", $DirEntry{DATA_ITEM}), 'TCGGAGC', 'data item');
	
	# Test unpacking floating numbers
	my ($v) = $ab->get_data_item('SPAC', 3, 'B32');
	$v = $ab->_ieee2decimal($v);
	ok( ($v >= 10.39 and $v <= 10.4), 'parsing float');

	# Test unpacking integers
	($v) = $ab->get_data_item('LANE', 1, 'n');
	is($v, 65535, 'integer');

	if ($ab->is_abif_open()) {
		$ab->close_abif();
	}
}

SKIP: {
	skip('Cannot find test_broken.ab1 test file', 1)
		unless (-e 'test_broken.ab1');
		
	ok(!$ab->open_abif('test_broken.ab1'), 'opening broken file fails gracefully')
}

exit;
