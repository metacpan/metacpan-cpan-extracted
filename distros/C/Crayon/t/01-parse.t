use Test::More;

use Crayon;

parse_test(
	q|
		body .class, body .other {
			background: black;
			color: white;
		}
	|,
	{
		body => {
			'.class' => {
				background => 'black',
				color => 'white'
			},
			'.other' => {
				background => 'black',
				color => 'white'
			}
		}
	}
);

parse_test(
	q|
		body .class {
			background: black;
			color: white;
		}
		body .other {
			background: white;
			color: blue;
		}
	|,
	{
		body => {
			'.class' => {
				background => 'black',
				color => 'white'
			},
			'.other' => {
				background => 'white',
				color => 'blue'
			}
		}
	}
);

parse_test(
	q|
		body {
			.class {
				background: black;
				color: white;
			}
			.other {
				background: white;
				color: blue;
			}
		}
	|,
	{
		body => {
			'.class' => {
				background => 'black',
				color => 'white'
			},
			'.other' => {
				background => 'white',
				color => 'blue'
			}
		}
	}
);

parse_test(
	q|
		body {
			.class {
				background: black;
				color: white;
				.other {
					background: white;
					color: blue;
				}
			}
		}
	|,
	{
		body => {
			'.class' => {
				background => 'black',
				color => 'white',
				'.other' => {
					background => 'white',
					color => 'blue'
				}
			}
		}
	}
);

parse_test(
	q|
		body {
			.class {
				background: black;
				.other {
					background: white;
					color: blue;
				}
				font-size: 10px;				

				color: white;
			}
		}
	|,
	{
		body => {
			'.class' => {
				background => 'black',
				color => 'white',
				'font-size' => '10px',
				'.other' => {
					background => 'white',
					color => 'blue'
				}
			}
		}
	}
);

parse_test(
	q|
		@media only screen and (max-width: 600px) {
			body {
				.class {
					background: black;
					.other {
						background: white;
						color: blue;
					}
					font-size: 10px;				

					color: white;
				}
			}
		}
	|,
	{
		'@media only screen and (max-width: 600px)' => {
			body => {
				'.class' => {
					background => 'black',
					color => 'white',
					'font-size' => '10px',
					'.other' => {
						background => 'white',
						color => 'blue'
					}
				}
			}
		}
	}
);

sub parse_test {
	my ($css, $expected) = @_;
	my $h = Crayon->new;
	my ($struct, $remaining) = $h->parse($css);
	is_deeply($struct, $expected);
}

done_testing;

