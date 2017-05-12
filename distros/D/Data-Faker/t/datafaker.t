use Test::More;

sub check_this {
	my $arg = shift;
	my $result = shift;

	ok(my $res = `$^X -Ilib ./datafaker $arg`, "Run for $arg");
	like($res,$result,"Results for $arg");
}

check_this('--help', qr/Usage/);
check_this('--help', qr/--help/);
check_this('--datatypes',qr/data/);

done_testing();
