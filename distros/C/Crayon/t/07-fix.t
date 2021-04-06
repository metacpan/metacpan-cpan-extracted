use Test::More;

use Crayon;

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
				.other {
					background: black;
					.other {
						background: white;
						color: blue;
					}
					font-size: 10px;				

					color: white;
				}
			}
			.over {
				.class {
					background: black;
					.other {
						background: white;
						color: blue;
					}
					font-size: 10px;				

					color: white;
				}
				.other {
					background: black;
					.other {
						background: white;
						color: blue;
					}
					font-size: 10px;				

					color: white;
				}
			}
			.nested {
				.class {
					background: black;
					.other {
						background: white;
						color: blue;
					}
					font-size: 10px;				

					color: white;
				}
				.other {
					background: black;
					.other {
						background: white;
						color: blue;
					}
					font-size: 10px;				

					color: white;
				}
			}
			.nester {
				.class {
					background: black;
					.other {
						background: white;
						color: blue;
					}
					font-size: 10px;				

					color: white;
				}
				.other {
					background: black;
					.other {
						background: white;
						color: blue;
					}
					font-size: 10px;				

					color: white;
				}
			}
			.nestes {
				.class {
					background: black;
					.other {
						background: white;
						color: blue;
					}
					font-size: 10px;				

					color: white;
				}
				.other {
					background: black;
					.other {
						background: white;
						color: blue;
					}
					font-size: 10px;				

					color: white;
				}
			}
			.nest {
				.class {
					background: black;
					.other {
						background: white;
						color: blue;
					}
					font-size: 10px;				

					color: white;
				}
				.other {
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
			'.nester' => {
				'.other' => {
					'color' => 'white',
					'font-size' => '10px',
					'background' => 'black',
					'.other' => {
						'color' => 'blue',
						'background' => 'white'
					}
				},
				'.class' => {
					'color' => 'white',
					'font-size' => '10px',
					'.other' => {
						'color' => 'blue',
						'background' => 'white'
					},
					'background' => 'black'
				}
			},
		   	'body' => {
				'.other' => {
					'color' => 'white',
					'font-size' => '10px',
					'background' => 'black',
					'.other' => {
						'color' => 'blue',
						'background' => 'white'
					}
				},
				'.class' => {
					'color' => 'white',
					'font-size' => '10px',
					'.other' => {
						'color' => 'blue',
						'background' => 'white'
					},
					'background' => 'black'
				}
			},
			'.over' => {
				'.other' => {
					'color' => 'white',
					'font-size' => '10px',
					'background' => 'black',
					'.other' => {
						'color' => 'blue',
						'background' => 'white'
					}
				},
				'.class' => {
					'color' => 'white',
					'font-size' => '10px',
					'.other' => {
						'color' => 'blue',
						'background' => 'white'
					},
					'background' => 'black'
				}
			},
		   	'.nestes' => {
				'.other' => {
					'color' => 'white',
					'font-size' => '10px',
					'background' => 'black',
					'.other' => {
						'color' => 'blue',
						'background' => 'white'
					}
				},
				'.class' => {
					'color' => 'white',
					'font-size' => '10px',
					'.other' => {
						'color' => 'blue',
						'background' => 'white'
					},
					'background' => 'black'
				}
			},
		   	'.nest' => {
				'.other' => {
					'color' => 'white',
					'font-size' => '10px',
					'background' => 'black',
					'.other' => {
						'color' => 'blue',
						'background' => 'white'
					}
				},
				'.class' => {
					'color' => 'white',
					'font-size' => '10px',
					'.other' => {
						'color' => 'blue',
						'background' => 'white'
					},
					'background' => 'black'
				}
			},
		   	'.nested' => {
				'.other' => {
					'color' => 'white',
					'font-size' => '10px',
					'background' => 'black',
					'.other' => {
						'color' => 'blue',
						'background' => 'white'
					}
				},
				'.class' => {
					'color' => 'white',
					'font-size' => '10px',
					'.other' => {
						'color' => 'blue',
						'background' => 'white'
					},
					'background' => 'black'
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

