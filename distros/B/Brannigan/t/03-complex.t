#!perl -T

use strict;
use warnings;
use Test::More tests => 4;
use Brannigan;

my $b = Brannigan->new(
	{
		name => 'complex_scheme',
		ignore_missing => 1,
		params => {
			name => {
				hash => 1,
				keys => {
					'/^(first|last)_name$/' => {
						required => 1,
					},
					middle_name => {
						required => 0,
					},
				},
			},
			'/^(birth|death)_date$/' => {
				hash => 1,
				required => 1,
				keys => {
					_all => {
						required => 1,
						integer => 1,
					},
					day => {
						value_between => [1, 31],
					},
					mon => {
						value_between => [1, 12],
					},
					year => {
						value_between => [1900, 2100],
					},
				},
				parse => sub {
					my ($date, $type) = @_;

					# $type has either 'birth' or 'date',
					# $date has the hash-ref that was provided
					$date->{day} = '0'.$date->{day} if $date->{day} < 0;
					$date->{mon} = '0'.$date->{mon} if $date->{mon} < 0;
					return { "${type}_date" => join('-', $date->{year}, $date->{mon}, $date->{day}) };
				},
			},
			death_date => {
				required => 0,
			},
			id_num => {
				integer => 1,
				exact_length => 9,
				validate => sub {
					my $value = shift;

					return $value =~ m/^0/ ? 1 : undef;
				},
				default => sub {
					# generate a random 9-digit number that begins with zero
					my @digits = (0);
					foreach (2 .. 9) {
						push(@digits, int(rand(10)));
					}
					#return join('', @digits);
					
					# commented out so we can actually write a test for this
					return '012345678';
				},
			},
			phones => {
				hash => 1,
				keys => {
					_all => {
						validate => sub {
							my $value = shift;

							return $value =~ m/^\d{2,3}-\d{7}$/ ? 1 : undef;
						},
					},
					'/^(home|mobile|fax)$/' => {
						parse => sub {
							my ($value, $type) = @_;

							return { $type => $value };
						},
					},
				},
			},
			education => {
				required => 1,
				array => 1,
				length_between => [1, 3],
				values => {
					hash => 1,
					keys => {
						'/^(start_year|end_year)$/' => {
							required => 1,
							value_between => [1900, 2100],
						},
						school => {
							required => 1,
							min_length => 4,
						},
						type => {
							required => 1,
							one_of => ['Elementary', 'High School', 'College/University'],
							parse => sub {
								my $value = shift;

								# returns the first character of the value in lowercase
								my @chars = split(//, $value);
								return { type => lc shift @chars };
							},
						},
					},
				},
			},
			employment => {
				required => 1,
				array => 1,
				length_between => [1, 5],
				values => {
					hash => 1,
					keys => {
						'/^(start|end)_year$/' => {
							required => 1,
							value_between => [1900, 2100],
						},
						employer => {
							required => 1,
							max_length => 20,
						},
						responsibilities => {
							array => 1,
							required => 1,
							values => {
								forbid_words => ['chief', 'super'],
							},
						},
					},
				},
			},
			other_info => {
				hash => 1,
				keys => {
					bio => {
						hash => 1,
						keys => {
							'/^(en|he|fr)$/' => {
								length_between => [100, 300],
								no_lorem => 1,
							},
							fr => {
								required => 1,
							},
						},
					},
				},
			},
			'/^picture_(\d+)$/' => {
				max_length => 5,
				validate => sub {
					my ($value, $num) = @_;

					return $value =~ m!^http://! && $value =~ m!\.(png|jpg)$! ? 1 : undef;
				},
			},
			picture_1 => {
				default => 'http://www.example.com/images/default.png',
			},
		},
		groups => {
			generate_url => {
				params => [qw/id_num name/],
				parse => sub {
					my ($id_num, $name) = @_;

					return { url => "http://www.example.com/?id=${id_num}&$name->{last_name}" };
				},
			},
			pictures => {
				regex => '/^picture_(\d+)$/',
				parse => sub {
					return { pictures => \@_ };
				},
			},
		},
	},
	{
		name => 'complex_inherit',
		inherits_from => 'complex_scheme',
		params => {
			education => {
				values => {
					keys => {
						honors => {
							array => 1,
							max_length => 5,
							values => {
								length_between => [5, 15],
							},
						},
					},
				},
			},
			picture_1 => {
				required => 1,
			},
			other_info => {
				keys => {
					social => {
						array => 1,
						values => {
							hash => 1,
							keys => {
								website => {
									required => 1,
								},
								user_id => {
									required => 1,
								},
							},
						},
					},
				},
			},
		},
	}, {
		name => 'complex_inherit_2',
		inherits_from => 'complex_inherit',
		params => {
			some_other_thing => {
				validate => sub {
					my $value = shift;

					return $value =~ m/I'm a little teapot/ ? 1 : undef;
				},
				parse => sub {
					my $value = shift;

					$value =~ s/I'm a little teapot/I like to wear women's clothing/;

					return { some_other_thing => $value };
				},
			},
		},
		groups => {
			dates => {
				params => [qw/birth_date death_date/],
				parse => sub {
					my ($b, $d) = @_;

					return { dates => 'This guy was born '.$b->{year}.'-'.$b->{mon}.'-'.$b->{day}.', unfortunately, he died '.$d->{year}.'-'.$d->{mon}.'-'.$d->{day} };
				},
			},
		},
	},
	{
		name => 'complex_inherit_3',
		inherits_from => ['complex_inherit', 'complex_inherit_2'],
		params => {
			employment => {
				required => 0,
			},
		},
	}
);

ok($b, 'Got a proper Brannigan object');

# let's create custom validation methods
$b->custom_validation('no_lorem', sub {
	my $value = shift;

	return $value =~ m/lorem ipsum/ ? 0 : 1;
});

$b->custom_validation('forbid_words', sub {
	my $value = shift;

	foreach (@_) {
		return 0 if $value =~ m/$_/;
	}

	return 1;
});

my %params = (
	name => {
		first_name => 'Some',
		last_name => 'One',
	},
	birth_date => {
		day => 32,
		mon => -5,
		year => 1984,
	},
	death_date => {
		day => 12,
		mon => 12,
		year => 2112,
	},
	phones => {
		home => '123-1234567',
		mobile => 'what?',
	},
	education => [
		{ school => 'First Elementary School of Somewhere', start_year => 1990, end_year => 1996, type => 'Elementary' },
		{ school => 'Sch', start_year => 1996, end_year => 3000, type => 'Fake' },
	],
	other_info => {
		bio => { en => "Born, lives, will die.", he => "Nolad, Chai, Yamut." },
	},
	picture_1 => '',
	picture_2 => 'http://www.example.com/images/mypic.jpg',
	picture_3 => 'http://www.example.com/images/mypic.png',
	picture_4 => 'http://www.example.com/images/mypic.gif',
);

my $output = $b->process('complex_scheme', \%params);

is_deeply($output, {
		'education' => [
			{
				'start_year' => 1990,
				'type' => 'e',
				'school' => 'First Elementary School of Somewhere',
				'end_year' => 1996
			},
			{
				'start_year' => 1996,
				'type' => 'f',
				'school' => 'Sch',
				'end_year' => 3000
			}
		],
		'death_date' => {
			'mon' => 12,
			'day' => 12,
			'year' => 2112
		},
		'name' => {
			'last_name' => 'One',
			'first_name' => 'Some'
		},
		'id_num' => '012345678',
		'picture_2' => 'http://www.example.com/images/mypic.jpg',
		'phones' => {
			'mobile' => 'what?',
			'home' => '123-1234567'
		},
		'birth_date' => {
			'mon' => -5,
			'day' => 32,
			'year' => 1984
		},
		'other_info' => {
			'bio' => {
				'en' => 'Born, lives, will die.',
				'he' => 'Nolad, Chai, Yamut.'
			}
		},
		'_rejects' => {
			'education' => {
				'1' => {
					'type' => [
						'one_of(Elementary, High School, College/University)'
					],
					'school' => [
						'min_length(4)'
					],
					'end_year' => [
						'value_between(1900, 2100)'
					]
				}
			},
			'death_date' => {
				'year' => [
					'value_between(1900, 2100)'
				]
			},
			'picture_2' => [
				'max_length(5)'
			],
			'birth_date' => {
				'mon' => [
					'integer(1)',
					'value_between(1, 12)'
				],
				'day' => [
					'value_between(1, 31)'
				]
			},
			'phones' => {
				'mobile' => [
					'validate'
				]
			},
			'employment' => [
				'required(1)'
			],
			'other_info' => {
				'bio' => {
					'en' => [
						'length_between(100, 300)'
					],
					'fr' => [
						'required(1)'
					],
					'he' => [
						'length_between(100, 300)'
					]
				}
			},
			'picture_3' => [
				'max_length(5)'
			],
			'picture_4' => [
				'max_length(5)',
				'validate'
			]
		},
		'picture_3' => 'http://www.example.com/images/mypic.png',
		'picture_4' => 'http://www.example.com/images/mypic.gif',
		'url' => 'http://www.example.com/?id=012345678&One',
		'pictures' => [
			'http://www.example.com/images/default.png',
			'http://www.example.com/images/mypic.jpg',
			'http://www.example.com/images/mypic.png',
			'http://www.example.com/images/mypic.gif'
		],
		'picture_1' => 'http://www.example.com/images/default.png'
	}, 'complex scheme with no inheritance');

my %params2 = %params;
$params2{education}->[0]->{honors} = ['Valedictorian', "Teacher's Pet", "The Dean's Suckup"];
$params2{education}->[1]->{honors} = 'Woooooeeeee!';
$params2{other_info}->{bio}->{fr} = "I have lorem ipsum, that's not good.";
$params2{other_info}->{social} = [{ website => 'facebook', user_id => 123412341234 }, { website => 'noogie.com', user_id => 'snoogens' }];

my $output2 = $b->process('complex_inherit', \%params2);

is_deeply($output2, {
		'education' => [
			{
				'start_year' => 1990,
				'honors' => [
					'Valedictorian',
					'Teacher\'s Pet',
					'The Dean\'s Suckup'
				],
				'type' => 'e',
				'school' => 'First Elementary School of Somewhere',
				'end_year' => 1996
			},
			{
				'start_year' => 1996,
				'honors' => 'Woooooeeeee!',
				'type' => 'f',
				'school' => 'Sch',
				'end_year' => 3000
			}
		],
		'name' => {
			'last_name' => 'One',
			'first_name' => 'Some'
		},
		'death_date' => {
			'mon' => 12,
			'day' => 12,
			'year' => 2112
		},
		'id_num' => '012345678',
		'picture_2' => 'http://www.example.com/images/mypic.jpg',
		'birth_date' => {
			'mon' => -5,
			'day' => 32,
			'year' => 1984
		},
		'phones' => {
			'mobile' => 'what?',
			'home' => '123-1234567'
		},
		'other_info' => {
			'social' => [
				{
					'website' => 'facebook',
					'user_id' => '123412341234'
				},
				{
					'website' => 'noogie.com',
					'user_id' => 'snoogens'
				}
			],
			'bio' => {
				'en' => 'Born, lives, will die.',
				'he' => 'Nolad, Chai, Yamut.',
				'fr' => "I have lorem ipsum, that's not good.",
			}
		},
		'_rejects' => {
			'education' => {
				'1' => {
					'honors' => {
						'_self' => [
							'array(1)'
						]
					},
					'type' => [
						'one_of(Elementary, High School, College/University)'
					],
					'school' => [
						'min_length(4)'
					],
					'end_year' => [
						'value_between(1900, 2100)'
					]
				},
				'0' => {
					'honors' => {
						'2' => [
							'length_between(5, 15)'
						]
					}
				}
			},
			'death_date' => {
				'year' => [
					'value_between(1900, 2100)'
				]
			},
			'picture_2' => [
				'max_length(5)'
			],
			'phones' => {
				'mobile' => [
					'validate'
				]
			},
			'birth_date' => {
				'mon' => [
					'integer(1)',
					'value_between(1, 12)'
				],
				'day' => [
					'value_between(1, 31)'
				]
			},
			'employment' => [
				'required(1)'
			],
			'other_info' => {
				'bio' => {
					'en' => [
						'length_between(100, 300)'
					],
					'fr' => [
						'length_between(100, 300)',
						'no_lorem(1)'
					],
					'he' => [
						'length_between(100, 300)'
					]
				}
			},
			'picture_3' => [
				'max_length(5)'
			],
			'picture_4' => [
				'max_length(5)',
				'validate'
			],
			'picture_1' => [
				'required(1)'
			]
		},
		'picture_3' => 'http://www.example.com/images/mypic.png',
		'picture_4' => 'http://www.example.com/images/mypic.gif',
		'url' => 'http://www.example.com/?id=012345678&One',
		'pictures' => [
			'http://www.example.com/images/default.png',
			'http://www.example.com/images/mypic.jpg',
			'http://www.example.com/images/mypic.png',
			'http://www.example.com/images/mypic.gif'
		],
		'picture_1' => 'http://www.example.com/images/default.png'
	}, 'complex scheme with simple inheritance');

my %params3 = %params;
$params3{some_other_thing} = "I'd like to tell the whole world that I'm a little teapot.";
$params3{employment} = [{ start_year => 1995, end_year => 2000, employer => 'Distortion Inc.', responsibilities => ['Big chief, a real super-star'] }];

my $output3 = $b->process('complex_inherit_2', \%params3);

is_deeply($output3, {
		'education' => [
			{
				'start_year' => 1990,
				'honors' => [
					'Valedictorian',
					'Teacher\'s Pet',
					'The Dean\'s Suckup'
				],
				'type' => 'e',
				'school' => 'First Elementary School of Somewhere',
				'end_year' => 1996
			},
			{
				'start_year' => 1996,
				'honors' => 'Woooooeeeee!',
				'type' => 'f',
				'school' => 'Sch',
				'end_year' => 3000
			}
		],
		'dates' => 'This guy was born 1984--5-32, unfortunately, he died 2112-12-12',
		'name' => {
			'last_name' => 'One',
			'first_name' => 'Some'
		},
		'death_date' => {
			'mon' => 12,
			'day' => 12,
			'year' => 2112
		},
		'id_num' => '012345678',
		'picture_2' => 'http://www.example.com/images/mypic.jpg',
		'birth_date' => {
			'mon' => -5,
			'day' => 32,
			'year' => 1984
		},
		'phones' => {
			'mobile' => 'what?',
			'home' => '123-1234567'
		},
		'other_info' => {
			'social' => [
				{
					'website' => 'facebook',
					'user_id' => '123412341234'
				},
				{
					'website' => 'noogie.com',
					'user_id' => 'snoogens'
				}
			],
			'bio' => {
				'en' => 'Born, lives, will die.',
				'he' => 'Nolad, Chai, Yamut.',
				'fr' => "I have lorem ipsum, that's not good."
			}
		},
		'_rejects' => {
			'education' => {
				'1' => {
					'honors' => {
						'_self' => [
							'array(1)'
						]
					},
					'type' => [
						'one_of(Elementary, High School, College/University)'
					],
					'school' => [
						'min_length(4)'
					],
					'end_year' => [
						'value_between(1900, 2100)'
					]
				},
				'0' => {
					'honors' => {
						'2' => [
							'length_between(5, 15)'
						]
					}
				}
			},
			'death_date' => {
				'year' => [
					'value_between(1900, 2100)'
				]
			},
			'picture_2' => [
				'max_length(5)'
			],
			'phones' => {
				'mobile' => [
					'validate'
				]
			},
			'birth_date' => {
				'mon' => [
					'integer(1)',
					'value_between(1, 12)'
				],
				'day' => [
					'value_between(1, 31)'
				]
			},
			'employment' => {
				'0' => {
					'responsibilities' => {
						'0' => [
							'forbid_words(chief, super)'
						]
					}
				}
			},
			'other_info' => {
				'bio' => {
					'en' => [
						'length_between(100, 300)'
					],
					'fr' => [
						'length_between(100, 300)',
						'no_lorem(1)'
					],
					'he' => [
						'length_between(100, 300)'
					]
				}
			},
			'picture_3' => [
				'max_length(5)'
			],
			'picture_4' => [
				'max_length(5)',
				'validate'
			],
			'picture_1' => [
				'required(1)'
			]
		},
		'employment' => [{ start_year => 1995, end_year => 2000, employer => 'Distortion Inc.', responsibilities => ['Big chief, a real super-star'] }],
		'picture_3' => 'http://www.example.com/images/mypic.png',
		'picture_4' => 'http://www.example.com/images/mypic.gif',
		'url' => 'http://www.example.com/?id=012345678&One',
		'some_other_thing' => 'I\'d like to tell the whole world that I like to wear women\'s clothing.',
		'pictures' => [
			'http://www.example.com/images/default.png',
			'http://www.example.com/images/mypic.jpg',
			'http://www.example.com/images/mypic.png',
			'http://www.example.com/images/mypic.gif',
		],
		'picture_1' => 'http://www.example.com/images/default.png'
	}, 'complex scheme with multiple inheritance');

done_testing();
