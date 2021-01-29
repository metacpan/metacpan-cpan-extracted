use Test::More;

use Crayon;
parse_test(
	q|
		body #class:hover, body .other:hover {
			background: #000; /* inline comment */
			color: #fff; /* another comment */
		}
	|,
	{
		body => {
			'#class' => {
				'&hover' => {
					background => '#000',
					color => '#fff',
				}
			},
			'.other' => {
				'&hover' => {
					background => '#000',
					color => '#fff',
				}
			}
		}
	},
	q|body #class:hover,
body .other:hover {
	background: #000;
	color: #fff;
}
|,
);

parse_test(
	q|
		body .class, body .other {
			&hover {
				background: #000; /* inline comment */
				color: #fff; /* another comment */
			}
		}
	|,
	{
		body => {
			'.class' => {
				'&hover' => {
					background => '#000',
					color => '#fff',
				}
			},
			'.other' => {
				'&hover' => {
					background => '#000',
					color => '#fff',
				}
			}
		}
	},
	q|body .class:hover,
body .other:hover {
	background: #000;
	color: #fff;
}
|,
);


sub parse_test {
	my ($css, $expected, $expected_css) = @_;
	my $h = Crayon->new(pretty => 1);
	my ($struct, $remaining) = $h->parse($css);
	is_deeply($struct, $expected);
	my $compile = $h->compile($struct);
	is($compile, $expected_css);
}

done_testing;

