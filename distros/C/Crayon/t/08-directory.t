use Test::More;

use Crayon;
compile_test(
	't/compile',
	q|body{background:red;color:black;margin:10px;padding:1em;}|,
);

sub compile_test {
	my ($css, $expected) = @_;
	my $h = Crayon->new();
	$h->parse_directory($css);
	my ($crayon, $remaining) = $h->compile();
	is($crayon, $expected);
}

done_testing;

