use strict;
use Test::More tests => 4022;

BEGIN {
	use_ok('Compress::unLZMA')
};

sub slurp {
	my ($filename) = @_;

	my $tmp;
	open(F, "<$filename");
	binmode F;
	{ local $/; $tmp = <F>; }
	close(F);

	return $tmp;
}

foreach my $file (qw(t/README t/test.png t/empty)) {
	my $origin = slurp($file);
	my $data = Compress::unLZMA::uncompressfile("$file.lzma");
	is($@, '', 'no error uncompressing file');
	is($data, $origin, 'uncompressed data from file matches original');

	my $tmp = slurp("$file.lzma");
	$data = Compress::unLZMA::uncompress($tmp);
	is($@, '', 'no error uncompressing buffer');
	is($data, $origin, 'uncompressed data from buffer matches original');

	is(Compress::unLZMA::uncompress(slurp("$file.lzma")), $origin);
	is($@, '');

#	ok(!Compress::unLZMA::uncompressfile($file));
#	like($@, qr/too long file/i);
}

ok(!Compress::unLZMA::uncompress(''));

ok(!Compress::unLZMA::uncompressfile("t/nofile.lzma"));
like($@, qr/input file error/i);

my $tmp = slurp("t/README.lzma");
for (my $i = 0; $i < 1000*1; $i++) {
	my $data = Compress::unLZMA::uncompressfile("t/README.lzma");
	is($@, '');
	if ($@) { last; }
	ok($data);

	my $data1 = Compress::unLZMA::uncompress($tmp);
	is($@, '');
	if ($@) { last; }
	ok($data1);
}
