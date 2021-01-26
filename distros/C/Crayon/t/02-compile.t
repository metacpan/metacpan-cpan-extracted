use Test::More;

use Crayon;

compile_test(
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
	},
	q|body .class, body .other {
	background: black;
	color: white;
}
|,
);


compile_test(
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
	},
	q|body .class {
	background: black;
	color: white;
}
body .other {
	background: white;
	color: blue;
}
|,
);

compile_test(
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
	},
	q|@media only screen and (max-width: 600px) {
	body .class {
		background: black;
		color: white;
		font-size: 10px;
	}
	body .class .other {
		background: white;
		color: blue;
	}
}
|,
);

sub compile_test {
	my ($css, $expected) = @_;
	my $h = Crayon->new( pretty => 1 );
	my ($struct, $remaining) = $h->compile($css);
	is($struct, $expected);
}

done_testing;

