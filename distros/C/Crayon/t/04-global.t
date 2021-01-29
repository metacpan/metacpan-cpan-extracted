use Test::More;

use Crayon;

parse_test(
	q|
	dd	$black: #000;
		$white: #fff;
		%colours: (
			background: $black;
			color: $white;
		);
		body .thing #other .class, body .other {
			$black: #0f0;
			%colours;
		}
	|,
	{
		'VARIABLES' => {
			'white' => '#fff',
			'colours' => {
				'background' => '$black',
				'color' => '$white'
			      },
			'black' => '#000'
		},
		body => {
			'.thing' => {
				'#other' => {
					'.class' => {
						'%colours' => 1,
						'VARIABLES' => {
							'black' => '#0f0'
						}
					}
				},
			},
			'.other' => {
				'%colours' => 1,
				'VARIABLES' => {
                            		'black' => '#0f0'
				}
			}
		}
	},
	q|body .other,
body .thing #other .class {
	background: #0f0;
	color: #fff;
}
|,
);

parse_test(
	q|
		$black: #000;
		$white: #fff;
		%colours: (
			black: $black;
			white: $white;
		);
		body .class, body .other {
			$black: #0f0;
			background: $colours{black};
			color: $colours{white};
		}
	|,
	{
		'VARIABLES' => {
			'white' => '#fff',
			'colours' => {
				'black' => '$black',
				'white' => '$white'
			      },
			'black' => '#000'
		},
		body => {
			'.class' => {
				background => '$colours{black}',
				color => '$colours{white}',
				'VARIABLES' => {
                            		'black' => '#0f0'
				}
			},
			'.other' => {
				background => '$colours{black}',
				color => '$colours{white}',
				'VARIABLES' => {
                            		'black' => '#0f0'
				}
			}
		}
	},
	q|body .class,
body .other {
	background: #0f0;
	color: #fff;
}
|,
);

parse_test(
	q|
		$black: #000;
		$white: #fff;
		%colours: (
			black: $black;
			white: $white;
		);
		body .class, body .other {
			%colours: (
				black: #0f0;
			);
			background: $colours{black};
			color: $colours{white};
		}
	|,
	{
		'VARIABLES' => {
			'white' => '#fff',
			'colours' => {
				'black' => '$black',
				'white' => '$white'
			      },
			'black' => '#000'
		},
		body => {
			'.class' => {
				background => '$colours{black}',
				color => '$colours{white}',
				'VARIABLES' => {
					colours => {
                            			'black' => '#0f0'
					}
				}
			},
			'.other' => {
				background => '$colours{black}',
				color => '$colours{white}',
				'VARIABLES' => {
                            		colours => {
						'black' => '#0f0'
					}
				}
			}
		}
	},
	q|body .class,
body .other {
	background: #0f0;
	color: #fff;
}
|,
);


parse_test(
	q|
		$black: #000;
		$white: #fff;
		%colours: (
			black: $black;
			white: $white;
		);
		body {
			$black: #0f0;
			.class, .other {
				background: $colours{black};
				color: $colours{white};
			}
		}
	|,
	{
		'VARIABLES' => {
			'white' => '#fff',
			'colours' => {
				'black' => '$black',
				'white' => '$white'
			      },
			'black' => '#000'
		},
		body => {
			'VARIABLES' => {
                        	'black' => '#0f0'
			},
			'.class' => {
				background => '$colours{black}',
				color => '$colours{white}',
			
			},
			'.other' => {
				background => '$colours{black}',
				color => '$colours{white}',
			}
		}
	},
	q|body .class,
body .other {
	background: #0f0;
	color: #fff;
}
|,
);

parse_test(
	q|
		$black: #000;
		$white: #fff;
		%colours: (
			black: $black;
			white: $white;
		);
		body {
			.class, .other {
				background: $colours{black};
				color: $colours{white};
			}
			$black: #0f0;
		}
	|,
	{
		'VARIABLES' => {
			'white' => '#fff',
			'colours' => {
				'black' => '$black',
				'white' => '$white'
			      },
			'black' => '#000'
		},
		body => {
			'VARIABLES' => {
                        	'black' => '#0f0'
			},
			'.class' => {
				background => '$colours{black}',
				color => '$colours{white}',
			
			},
			'.other' => {
				background => '$colours{black}',
				color => '$colours{white}',
			}
		}
	},
	q|body .class,
body .other {
	background: #0f0;
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

