use Test::More tests => 26;

# -----------------------------------------------

sub check
{
	my($data, $page, $offset, $result)	= @_;
	my(@bounds)							= $page -> offset($offset) -> bounds();

	is(join(' ', @$data[$bounds[0] .. $bounds[1] ]), $result, "Offset: $offset. Result: $result");

}	# End of check.

# -----------------------------------------------

BEGIN{ use_ok('Data::Page::Viewport'); }

my(@data) = (qw/zero one two three four five six
seven eight nine ten eleven twelve thirteen fourteen/);
my($page) = Data::Page::Viewport -> new
(
	data_size => $#data,
	old_style => 1,
	page_size => 4
);

isa_ok($page, 'Data::Page::Viewport');
check(\@data, $page, - 2, 'zero one two three');
check(\@data, $page, 1, 'one two three four');
check(\@data, $page, 4, 'five six seven eight');
check(\@data, $page, 4, 'nine ten eleven twelve');
check(\@data, $page, 1, 'ten eleven twelve thirteen');
check(\@data, $page, 3, 'eleven twelve thirteen fourteen');
check(\@data, $page, 2, 'eleven twelve thirteen fourteen');
check(\@data, $page, - 2, 'nine ten eleven twelve');
check(\@data, $page, 1, 'ten eleven twelve thirteen');
check(\@data, $page, 2, 'eleven twelve thirteen fourteen');
check(\@data, $page, 1, 'eleven twelve thirteen fourteen');
check(\@data, $page, - 4, 'seven eight nine ten');
check(\@data, $page, - 4, 'three four five six');
check(\@data, $page, - 1, 'two three four five');
check(\@data, $page, 1, 'three four five six');
check(\@data, $page, 2, 'five six seven eight');
check(\@data, $page, - 1, 'four five six seven');
check(\@data, $page, - 2, 'two three four five');
check(\@data, $page, - 2, 'zero one two three');
check(\@data, $page, - 1, 'zero one two three');
check(\@data, $page, - 4, 'zero one two three');
check(\@data, $page, 4, 'four five six seven');
check(\@data, $page, 4, 'eight nine ten eleven');
check(\@data, $page, 4, 'eleven twelve thirteen fourteen');
