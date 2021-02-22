use 5.012;
use strict;
use warnings;

# Artificial stupidity is easier to develop than artificial intelligence. 

package Acme::ConspiracyTheory::Random;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.014';

use Exporter::Shiny qw( theory bad_punctuation );
use List::Util 1.54 ();

sub _RANDOM_ {
	my $code = List::Util::sample( 1, @_ );
	ref($code) eq 'CODE' ? goto($code) : $code;
}

sub _MERGE_ {
	my ( $redstring, %new ) = @_;
	%$redstring = ( %$redstring, %new );
}

sub _UCFIRST_ ($) { # Some sentences start with a non-word character like a quote mark
	( my $str = shift )
		=~ s/ (\w) / uc($1) /xe;
	$str;
}

sub celebrity {
	my $redstring = shift // {};
	my $celeb = _RANDOM_(
		{ female => 0, name => 'Bill Gates' },
		{ female => 0, name => 'Jeff Bezos' },
		{ female => 1, name => 'Hillary Clinton' },
		{ female => 0, name => 'Donald Trump' },
		{ female => 0, name => 'Barack Obama' },
		{ female => 0, name => 'Bernie Sanders' },
		{ female => 0, name => 'Joe Biden' },
		{ female => 0, name => 'Bill Clinton' },
		{ female => 1, name => 'Queen Elizabeth II' },
		{ female => 0, name => 'Johnny Depp' },
		{ female => 0, name => 'Q' },
		{ female => 1, name => 'Madonna' },
		{ female => 0, name => 'Sir Paul McCartney' },
		{ female => 1, name => 'Lady Gaga' },
		{ female => 1, name => 'Margaret Thatcher' },
		{ female => 0, name => 'George Soros' },
		{ female => 1, name => 'Beyonce' },
		{ female => 1, name => 'Whitney Houston' },
		{ female => 0, name => 'Joe Rogan' },
	);
	_MERGE_( $redstring, celebrity => $celeb );
	return $celeb->{name};
}

sub shady_group {
	my $redstring = shift // {};
	
	my $xx;
	PICK: {
		$xx = _RANDOM_(
			{ plural => 1, name => 'the Knights Templar', shortname => 'the Templars' },
			{ plural => 1, name => 'the Illuminati' },
			{ plural => 1, name => 'the Freemasons', shortname => 'the Masons' },
			{ plural => 0, name => 'the Ordo Templi Orientis' },
			{ plural => 1, name => 'the Cabalists' },
			{ plural => 1, name => 'the Followers of the Temple Of The Vampire', shortname => 'the Vampires' },
			{ plural => 0, splural => 1, name => 'the Secret Order of the Knights of the Round Table', shortname => 'the Knights' },
			{ plural => 1, name => 'the Cardinals of the Catholic Church', shortname => 'the Cardinals' },
			{ plural => 0, name => 'the Church of Satan', shortname => 'the Church' },
			{ plural => 1, name => 'the Gnostics' },
			{ plural => 1, name => 'the Elders of Zion', shortname => 'the Elders' },
			{ plural => 1, name => 'the Jesuits' },
			{ plural => 0, name => 'the Babylonian Brotherhood', shortname => 'the Brotherhood' },
			{ plural => 0, name => 'the Hermetic Order of the Golden Dawn', shortname => 'the Order' },
			{ plural => 0, name => 'Opus Dei' },
			{ plural => 0, name => 'the Priory of Sion', shortname => 'the Priory' },
			{ plural => 0, name => 'GameStop' },
			{ plural => 0, splural => 1, name => 'the British Royal Family', shortname => 'the Royals' },
			{ plural => 0, name => 'NASA' },
			{ plural => 1, name => 'the Zionists' },
			{ plural => 0, name => 'the Trump administration' },
			{ plural => 0, name => 'the Biden administration' },
			{ plural => 0, splural => 1, name => 'the Republican party', shortname => 'the Republicans' },
			{ plural => 0, splural => 1, name => 'the Democrat party', shortname => 'the Democrats' },
			{ plural => 0, name => 'the New World Order' },
			{ plural => 1, name => 'the Communists' },
			{ plural => 0, name => 'the Shadow Government' },
			{ plural => 0, name => 'the global financial elite' },
			{ plural => 0, name => 'the global scientific elite' },
			{ plural => 0, name => 'Big Pharma' },
			{ plural => 0, name => 'Big Tobacco' },
			{ plural => 1, splural => 1, name => 'the lizard people', shortname => 'the lizardmen' },
			{ plural => 1, name => 'the grey aliens', shortname => 'the aliens' },
			{ plural => 1, name => 'the big Hollywood studios', shortname => 'Hollywood' },
			{ plural => 0, name => 'the music industry' },
			{ plural => 1, name => 'shape-shifting aliens', shortname => 'the shape-shifters' },
			{ plural => 1, name => 'Satanists' },
			{ plural => 1, name => 'pagans' },
			{ plural => 1, name => 'atheists' },
			{ plural => 1, name => 'people who like pineapple on pizza', shortname => 'the pineapple-lovers' },
			{ plural => 0, name => 'the deep state' },
			{ plural => 1, name => 'the descendents of Jesus', shortname => 'the descendents' },
			{ plural => 1, name => 'Qanon' },
			{ plural => 0, name => 'Microsoft' },
			{ plural => 0, name => 'Twitter' },
			{ plural => 0, name => 'Facebook' },
			{ plural => 0, name => 'Google' },
			{ plural => 0, name => 'Monsanto' },
			{ plural => 0, name => 'the Wall Street establishment', shortname => 'Wall Street' },
			{ plural => 1, name => 'people at 10 Downing Street', shortname => "Downing Street" },
			{ plural => 0, name => 'Goldman Sachs' },
			{ plural => 0, name => 'Skull and Bones (Order 322)', shortname => 'the Order' },
			{ plural => 0, name => 'the London Stock Exchange', shortname => 'LSE' },
			{ plural => 0, name => 'the New York Stock Exchange', shortname => 'NYSE' },
			{ plural => 1, name => 'feminists' },
			{ plural => 1, name => 'Socialists' },
			sub {
				my $planet = _RANDOM_(
					['Nibiru', 'the Nibiruans'],
					['Venus', 'the Venutians'],
					['Mars', 'the Martians'],
					['Pluto', 'the Plutonians'],
					['Andromeda', 'the Andromedans'],
					['the moon', 'the moonlings'],
					['the Counter-Earth', 'the anti-Earthlings'],
				);
				{ plural => 1, name => "aliens from ".$planet->[0], shortname => $planet->[1] };
			},
		);
		
		no warnings;
		redo PICK
			if ( $redstring->{protagonists} and $redstring->{protagonists}{name} eq $xx->{name} )
			|| ( $redstring->{antagonists}  and $redstring->{antagonists}{name}  eq $xx->{name} );
	};
	
	_MERGE_( $redstring, shady_group => $xx );
	my $name = $xx->{name};
	if ($name =~ /ists$/ && $name !~ /^the/) {
		$name = "the $name";
	}
	return $name;
}

sub real_animal {
	my $redstring = shift // {};
	
	my $animal = _RANDOM_(
		'cat',
		'dog',
		'horse',
		'penguin',
		'platypus',
		'toucan',
		'whale',
		'zebra',
		'frog',
		'fish',
	);
	
	_MERGE_( $redstring, real_animal => $animal );
	return $animal;
}

sub fake_animal {
	my $redstring = shift // {};
	
	my $animal = _RANDOM_(
		'unicorn',
		'bigfoot',
		'mermaid',
		'werewolf',
		'dragon',
		'wyvern',
		'yeti',
		'Loch Ness monster',
	);
	
	_MERGE_( $redstring, fake_animal => $animal );
	return $animal;
}

sub objects {
	my $redstring = shift // {};
	
	my $objects = _RANDOM_(
		'cars',
		'TVs',
		'smartphones',
		'microwave ovens',
		'trees',
		'clothes',
	);
	
	_MERGE_( $redstring, objects => $objects );
	return $objects;
}

sub invention {
	my $redstring = shift // {};
	
	my $invention = _RANDOM_(
		['the internet', 0],
		['cryptocurrencies', 1],
		['smartphones', 1],
		['bitcoin', 0],
	);
	
	_MERGE_( $redstring, invention => $invention->[0],
		 invention_plural => $invention->[1], );
	return $invention->[0];
}

sub shady_project {
	my $redstring = shift // {};
	
	my $x = _RANDOM_(
		'Project Blue Beam',
		'The Plan',
		'the Global Warming Hoax',
		'the New Chronology',
		'the Great Replacement',
		'the Great Reset',
		'the LGBT Agenda',
		'the Kalergi Plan',
		'Eurabia',
		'the moon-landing hoax',
	);
	
	_MERGE_( $redstring, shady_project => $x );
	return $x;
}

sub authority {
	my $redstring = shift // {};
	
	my $x = _RANDOM_(
		'the Supreme Court',
		'the United Nations',
		'the FBI',
		'the CIA',
		'NATO',
	);
	
	_MERGE_( $redstring, authority => $x );
	return $x;
}

sub dark_lord {
	my $redstring = shift // {};
	
	my $x = _RANDOM_(
		'the dark lord',
		'Beelzebub',
		'Lord Vader',
		'Lord Satan',
		'Thanos',
		'the devil',
		'the evil one',
		'the almighty',
	);
	
	_MERGE_( $redstring, dark_lord => $x );
	return $x;
}

sub disease {
	my $redstring = shift // {};
	
	my $disease = _RANDOM_(
		'cancer',
		'COVID-19',
		'HIV',
		'the common cold',
		'diabetes',
		'obesity',
		'autism',
		'Ebola',
	);
	
	_MERGE_( $redstring, disease => $disease );
	return $disease;
}

sub disease_cause {
	my $redstring = shift // {};
	
	my $cause = _RANDOM_(
		sub {
			my $food = food( $redstring );
			( $food =~ /wine/ ) ? "drinking $food" : "eating $food";
		},
		sub {
			chemicals( $redstring );
		},
		'non-vegan food',
		'vegan food',
		'socialism',
		'electromagnetic radiation (WiFi!)',
		'radon gas',
	);
	
	_MERGE_( $redstring, disease_cause => $cause );
	return $cause;
}

sub chemicals {
	my $redstring = shift // {};
	
	my $chemicals = _RANDOM_(
		'oestrogen',
		'testosterone',
		'acid',
		'birth-control',
		'fertilizer',
		'Diet Coke',
		'heavy hydrogen',
		'5G',
		'antimatter',
		'dark matter',
		'fluoride',
	);
	
	_MERGE_( $redstring, chemicals => $chemicals );
	return $chemicals;
}

sub food {
	my $redstring = shift // {};
	
	my $food = _RANDOM_(
		'apples',
		'Big Macs',
		'KFC family buckets',
		'most wines',
		'Kraft instant mac and cheese boxes',
		'bananas',
	);
	
	_MERGE_( $redstring, food => $food );
	return $food;
}

sub attribute {
	my $redstring = shift // {};
	
	my $attr = _RANDOM_(
		'gay',
		'insane',
		'infertile',
		'immobile',
		'horny',
		'female',
		'fat',
		'fluorescent',
	);
	
	_MERGE_( $redstring, attribute => $attr );
	return $attr;
}

sub artifact {
	my $redstring = shift // {};
	
	my $artifact = _RANDOM_(
		'the holy grail',
		'the golden fleece',
		'Excalibur',
		'the ark of the covenant',
		"Jesus's foreskin",
		'the Holy Prepuce',
		'the Book of the Dead',
		'the Necronomicon',
		"the Philosopher's Stone",
		"a fragment of the true cross",
		"the seal of Solomon",
	);
	
	_MERGE_( $redstring, artifact => $artifact );
	return $artifact;
}

sub bad_place {
	my $redstring = shift // {};
	
	my $bad_place = _RANDOM_(
		'a secret Antarctic base',
		'Area 51',
		'Langley, Virginia',
		'Guantanamo Bay Detention Camp',
		'Windsor Castle',
		'The Pentagon',
		'Denver International Airport',
		'the basement of the Vatican',
		sub { myth_place( $redstring ) },
		sub {
			my $p = random_place( $redstring );
			"a series of tunnels underneath $p";
		},
		sub {
			my $p = random_place( $redstring );
			"a secret base in $p";
		},
		'a facility inside the hollow Earth', 
	);
	
	_MERGE_( $redstring, bad_place => $bad_place );
	return $bad_place;
}

sub random_place {
	my $redstring = shift // {};
	
	my $random_place = _RANDOM_(
		'the USA',
		'the UK',
		'France',
		'Italy',
		'Germany',
		'Spain',
		'Egypt',
		'Israel',
		'Lebanon',
		'Syria',
		'Japan',
		'China',
		'Brazil',
		'Argentina',
		'Chile',
		'Tunisia',
		'Antarctica',
		'Norway',
		'Australia',
		'New Zealand',
	);
	
	_MERGE_( $redstring, random_place => $random_place );
	return $random_place;
}

sub myth_place {
	my $redstring = shift // {};
	
	my $place = _RANDOM_(
		'the Garden of Eden',
		'the lost city of Atlantis',
		'the final resting place of Noah\'s Ark',
		'the umbilicus mundi',
		'Camelot',
		"Lucifer's crypt",
		"Jesus's grave",
		"Jesus's true birthplace",
		'the entrance to the hollow Earth',
		'the REAL Stonehenge',
	);
	
	_MERGE_( $redstring, myth_place => $place );
	return $place;
}

sub cryptids {
	my $redstring = shift // {};
	
	my $cryptids = _RANDOM_(
		'vampires',
		'ghosts',
		'werewolves',
		'demons',
		'angels',
		'skinwalkers',
		'elves',
		'goblins',
		'mermaids',
	);
	
	_MERGE_( $redstring, cryptids => $cryptids );
	return $cryptids;
}

sub fiction {
	my $redstring = shift // {};
	
	my $fiction = _RANDOM_(
		{ title => 'Harry Potter', author => 'J K Rowling' },
		{ title => 'Tintin', author => 'Herge' },
		{ title => 'Star Wars', author => 'George Lucas' },
		{ title => 'Avengers: Age of Ultron', author => 'Kevin Feige' },
		{ title => 'The Book of Mormon', author => 'Joseph Smith' },
		{ title => 'Lord of the Rings', author => 'J R R Tolkien' },
		{ title => 'The Chronicles of Narnia', author => 'C S Lewis' },
		{ title => 'Game of Thrones', author => 'George R R Martin' },
		{ title => 'Spider-Man', author => 'Stan Lee' },
	);
	
	_MERGE_( $redstring, fiction => $fiction );
	return $fiction->{title};
}

sub precious_resource {
	my $redstring = shift // {};
	
	my $resource = _RANDOM_(
		'pineapple',
		'oil',
		'coal',
		'uranium',
		'holy water',
		'diamond',
		'blood',
		'gold',
		'silver',
		'neutron star material',
		'Belle Delphine bath water',
		'crystals',
	);
	
	_MERGE_( $redstring, precious_resource => $resource );
	return $resource;
}

sub precious_resource_with_quantity {
	my $redstring = shift // {};
	my $resource = precious_resource( $redstring );
	my $quantity = _RANDOM_(
		'a warehouse full',
		'a lot',
		'unknown quantities',
		'vast amounts',
		'unimaginable quantities',
		'unspeakable quantities',
		'5.3 metric pounds',
		'6.9 Imperial litres',
		'666 tonnes',
	);
	"$quantity of $resource";
}

sub mind_control_device {
	my $redstring = shift // {};

	my @mc = (
		['chemtrails', 1],
		['mind control drugs in the water', 1],
		['5G', 0],
		['WiFi', 0],
		['microchips implanted at birth', 1],
		['vaccines', 1],
		['childhood indoctrination', 0],
		['neurolinguistic programming', 0],
		['video games', 1],
		['mass media', 1],
		['space lasers', 1],
		['hypnotism', 0],
	);
	
	my $mc = _RANDOM_(@mc);
	
	_MERGE_( $redstring, mind_control_device => $mc->[0] );
	_MERGE_( $redstring, mind_control_device_plural => $mc->[1] );
	return $mc->[0];
}

sub future_time {
	my $redstring = shift // {};
	
	my $time = _RANDOM_(
		'in 2030',
		'by the end of the century',
		'in 2666',
		'when Queen Elizabeth II dies',
		'when the ice caps melt',
		'next Christmas',
	);
	
	_MERGE_( $redstring, future_time => $time );
	return $time;
}

sub splural {
	my $a = shift;
	if (defined $a->{splural}) {
		return $a->{splural};
	}
	return $a->{plural};
}

sub a_long_time {
	my $redstring = shift // {};
	
	my @extras = ();
	for my $actor ( qw/ protagonists antagonists / ) {
		push @extras, sub {
			my $have = splural( $redstring->{$actor} ) ? 'have' : 'has';
			"for as long as " . ($redstring->{$actor}{shortname}//$redstring->{$actor}{name}) . " $have existed";
		} if $redstring->{$actor}{name};
	}
	
	my $time = _RANDOM_(
		'since 1492',
		'since 1666',
		'since 1066',
		'since the time of Christ',
		'since time immemorial',
		'since the dawn of time',
		'for hundreds of years',
		'for millennia',
		@extras,
	);
	
	_MERGE_( $redstring, a_long_time => $time );
	return $time;
}

sub misinformation {
	my $redstring = shift // {};
	
	my $info = _RANDOM_(
		'the Earth is round',
		'the Earth goes around the sun',
		'humans are animals',
		'birds are dinosaurs',
		sub {
			$redstring->{topic} = { name => 'the moon', plural => 0 };
			'men have walked on the moon';
		},
		sub {
			$redstring->{topic} = { name => 'electricity', plural => 0 };
			'electricity exists';
		},
		sub {
			$redstring->{topic} = { name => 'magnetism', plural => 0 };
			'magnetism is real';
		},
		sub {
			$redstring->{topic} = { name => 'gravity', plural => 0 };
			'gravity is real';
		},
		sub {
			$redstring->{topic} = { name => 'outer space', plural => 0 };
			'space is real';
		},
		sub {
			$redstring->{topic} = { name => 'viruses', plural => 1 };
			'viruses are real';
		},
		sub {
			$redstring->{topic} = { name => 'vaccines', plural => 1 };
			'vaccines are safe';
		},
		sub {
			my $animal = real_animal( $redstring );
			"the $animal is real";
		},
		sub {
			my $place = random_place( $redstring );
			"$place is real";
		},
		sub {
			$redstring->{topic} = { name => 'carbon dating', plural => 0 };
			'the Earth is 4.5 billion years old';
		},
		sub {
			$redstring->{topic} = { name => 'radiocarbon dating', plural => 0 };
			'the universe is 14 billion years old';
		},
		sub {
			$redstring->{topic} = { name => 'pigeons', plural => 1 };
			'dinosaurs are real';
		},
		sub {
			$redstring->{topic} = { name => 'surveillance drones', plural => 1 };
			'birds are real';
		},
	);
	
	_MERGE_( $redstring, misinformation => $info );
	return $info;
}

sub victim {
	my $redstring = shift // {};
	
	my $victim = _RANDOM_(
		'Elvis Presley',
		'JFK',
		'Hitler',
		'Robin Williams',
		'Martin Luther King Jr',
		'Abraham Lincoln',
		'King Charles I',
		'Marilyn Monroe',
		'Tupac Shakur',
		'Princess Di',
		'Jeff Buckley',
		'Andy Kaufman',
		'Jim Morrison',
		'Brandon Lee',
		'Lee Harvey Oswald',
		'Archduke Franz Ferdinand',
		'the original Avril Lavigne',
		'Malcolm X',
		'John Lennon',
		'Michael Jackson',
	);
	
	_MERGE_( $redstring, victim => $victim );
	return $victim;
}

sub physicist {  # and chemists
	my $redstring = shift // {};
	
	my $x = _RANDOM_(
		'Nikola Tesla',
		'Benjamin Franklin',
		'Albert Einstein',
		'Isaac Newton',
		'Stephen Hawking',
		'Henry Cavendish',
	);
	
	_MERGE_( $redstring, physicist => $x );
	return $x;
}

sub biologist {  # and medics
	my $redstring = shift // {};
	
	my $x = _RANDOM_(
		'Charles Darwin',
		'Edward Jenner',
		'Robert Koch',
		'Carl Linneaus',
		'Alexander Fleming',
	);
	
	_MERGE_( $redstring, biologist => $x );
	return $x;
}

sub website {
	my $redstring = shift // {};

	my $x = _RANDOM_(
		'Tumblr',
		'Pinterest',
		'Youtube',
		'Facebook',
		'Wikipedia',
		'Twitter',
		'Instagram',
		'Geocities',
		'Parler',
	);

	_MERGE_( $redstring, website => $x );
	return $x;
}

sub fatuous {
	my $redstring = shift // {};

	my $x = _RANDOM_(
		"We all know what's going on here.",
		"It's plain and simple common sense.",
		'Most people are in denial.',
		"Isn't it obvious?",
		"Wake up, sheeple!",
		"It's obvious if you connect the dots.",
		"They leave clues to mock us.",
		"It's not funny!",
		"There are too many coincidences to ignore.",
	);

	_MERGE_( $redstring, clone => $x );
	return $x;
}

sub clone {
	my $redstring = shift // {};

	my $x = _RANDOM_(
		'an alien',
		'an avatar',
		'a CGI replica',
		'a clone',
		'a cyborg',
		'a hologram',
		'a look-alike',
		'a robot',
		'a shapeshifter',
	);

	_MERGE_( $redstring, clone => $x );
	return $x;
}

sub lies {
	my $redstring = shift // {};

	my $x = _RANDOM_(
		'obvious lies',
		'a big coverup',
		'a fairy tale',
		'disinformation',
	);
	
	_MERGE_( $redstring, lies => $x );
	return $x;
}

sub evidence {
	my $redstring = shift // {};
	
	my @x = (
		"there's a video about it on YouTube",
		sub { 'there was something about it on ' . website() },
		"the voices told me",
		"I had a dream",
		sub { website() . ' is censoring me' },
		sub { website() . ' was down this morning' },
	);

	if ( my $c = $redstring->{disease_cause} ) {
		push @x, (
			"$c is addictive",
		);
	}
	
	if ( my $m = $redstring->{misinformation} ) {
		push @x, (
			"they indoctrinate people about '$m' at schools and if it were the truth they wouldn't need to",
			"'$m' gets pushed down our throats by mass media",
			"'$m' is a false-flag operation",
		);
	}
	
	if ( my $auth = $redstring->{authority} ) {
		push @x, (
			"$auth are the obvious people to go to",
			"$auth are the only ones with the power to stop them",
			"$auth are able to save us",
		);
	}

	if ( my $p = $redstring->{myth_place} ) {
		push @x, (
			"there are clues about $p in the Bible",
			"there are clues about $p in the Voynich manuscript",
			"$p is on some old maps",
			"$p is on Google Maps",
		);
	}

	if ( my $art = $redstring->{artifact} ) {
		push @x, (
			"$art isn't in any museum",
			"$art must be somewhere",
			"$art is out there",
			"$art can be found with GPS",
		);
	}

	if ( my $proj = $redstring->{shady_project} ) {
		push @x, (
			"everybody knows $proj is happening soon",
			"$proj is well-funded",
			"$proj is an open secret",
			"there is so much evidence for $proj",
		);
	}
	
	if ( my $dl = $redstring->{dark_lord} ) {
		push @x, (
			"$dl is known to be growing in power",
			"$dl has never seemed more powerful",
			"$dl needs to be getting power from somewhere",
			"$dl told me",
			"I have seen signs from $dl",
		);
	}
	
	if ( my $v = $redstring->{victim} // $redstring->{physicist} // $redstring->{biologist} ) {
		push @x, (
			"$v died too young",
			"$v sent a letter containing the truth before dying",
			sub {
				my $clone = clone( $redstring );
				"when they did an autopsy on $v it turned out it was $clone",
			},
			"they never did an autopsy on $v",
			"$v wrote a will",
			sub {
				my $g = shady_group( $redstring );
				"$v was secretly one of $g";
			},
			sub {
				my $animal = real_animal( $redstring );
				"when they did an autopsy on $v it turned out they were secretly a $animal in a human suit";
			},
		);
	}

	if ( my $v = $redstring->{physicist} // $redstring->{biologist} ) {
		push @x, (
			"$v isn't mentioned in Aristotle's writing",
			"$v hasn't given a lecture in months",
			"$v isn't taken seriously by TRUE SCIENTISTS",
		);
	}

	if ( my $c = $redstring->{celebrity} ) {
		if ( $c->{female} ) {
			push @x, (
				"you can't trust women",
				"she said so on her Twitter",
			);
		}
		else {
			push @x, (
				"you can't trust men",
				"he said so on his Twitter",
			);
		}
	}

	if ( my $f = $redstring->{fiction} ) {
		
		push @x, (
			$f->{title} . " has secret messages encoded in it with numerology",
			$f->{title} . " is satanic",
			sub {
				my $g = shady_group( $redstring );
				my $has = splural( $redstring->{shady_group} ) ? 'have' : 'has';
				$f->{author} . " $has ties to $g";
			},
			sub {
				my $b = bad_place( $redstring );
				$f->{author} . " got taken to $b for questioning";
			},
		);
		
		if ( my $p = $redstring->{random_place} ) {
			push @x, (
				$f->{author} . " had a secret home in $p",
				$f->{author} . " was secretly born in $p",
			);
		}
	}
	
	if ( my $animal = $redstring->{real_animal} // $redstring->{fake_animal} ) {
		push @x, (
			"the $animal wasn't mentioned in the Bible",
			"the $animal was mentioned in the Satanic Verses",
			"the $animal looks kind of weird",
			"nobody has ever seen a $animal in real life",
			"the $animal obviously isn't native to this planet",
			sub { "${ \ shady_group($redstring) } sacrifice $animal${\'s'} to ${ \ dark_lord($redstring) }" },
			"the $animal looks bigger in real life",
			"the $animal makes a funny noise",
			"Alex Jones did a podcast about the $animal",
		);
	}
	
	if ( my $mc = $redstring->{mind_control_device} ) {
		my $time = a_long_time();
		my $mcp = $redstring->{mind_control_device_plural};
		my $is = 'is';
		my $has = 'has';
		my $was = 'was';
		if ($mcp) {
			$is = 'are';
			$has = 'have';
			$was = 'were';
		}
		push @x, (
			"everybody knows $mc $is real",
			sub { "$mc $has been researched by ${ \ shady_group($redstring) } $time" },
			sub { "$mc $was used to conceal ${ \ shady_group($redstring) } $time" },
			sub { "$mc $was used to infiltrate ${ \ shady_group($redstring) }" },
		);
	}

	if ( my $ft = $redstring->{future_time} ) {
		push @x, (
			"some of the few people still alive $ft time-travelled back to tell us",
			"the people still alive $ft sent us hidden messages in ${ \ fiction() }",
			"it will all become clear $ft",
		);
	}

	if ( my $d = $redstring->{disease} ) {
		push @x, (
			"patients with $d keep disappearing from hospitals",
			"patients with $d are being silenced by the government",
			"doctors working on $d are being killed",
			"$d probably isn't even a real disease",
			"nobody has ever died of $d",
		);
	}

	if ( my $f = $redstring->{food} ) {
		push @x, (
			"$f don't taste like they used to",
			"$f smell funny",
			"$f make me feel sick",
			"I don't like $f",
		);
	}

	if ( my $chem = $redstring->{chemicals} ) {
		push @x, (
			"$chem isn't on the periodic table",
			"$chem isn't real",
			"$chem isn't natural",
			"you'd have to be stupid to think $chem is real",
		);
	}

	if ( my $r = $redstring->{precious_resource} ) {
		my ( $bad, $are, $r_are );
		$redstring->{shady_group}{name} or shady_group( $redstring );
		foreach ( qw/ antagonist protagonist shady_group / ) {
			if ( $redstring->{$_}{name} ) {
				$bad = $redstring->{$_}{name};
				$are = $redstring->{$_}{plural} ? 'are' : 'is';
				$r_are = ($r =~ /s$/) ? 'are' : 'is';
			}
		}
		push @x, (
			"the Wikipedia entry for $r keeps getting edited by $bad",
			"$bad keeps buying $r secretly on the stock market",
			"the global supply of $r is at an all time low",
			"have you ever seen $r for real with your own eyes",
			"$r $r_are so damn expensive",
			"$r $r_are really rare",
			"Alex Jones says $bad $are linked to $r",
		);
	}

	if ( my $topic = $redstring->{topic} ) {
		my $topicname = $topic->{name};
		my $have      = $topic->{plural} ? 'have' : 'has';
		push @x, (
			"there's hidden clues in the Wikipedia page about $topicname",
			"THEY let it slip during an edit war in a Wikipedia page about $topicname",
			"Bible numerology has clues about $topicname",
			"the Voynich manuscript has clues about $topicname",
			"$topicname $have always been suspicious",
			"$topicname $have connections to THEM",
			"nobody really understands $topicname",
			"all my posts about $topicname keep getting taken down by Tumblr",
		);
	}

	if ( my $p = $redstring->{random_place} // $redstring->{bad_place} ) {
		my $bad = $redstring->{antagonist}{name}
			// $redstring->{protagonist}{name}
			// $redstring->{shady_group}{name}
			// shady_group( $redstring );
		push @x, (
			"the Wikipedia entry for $p keeps getting edited by $bad",
			# This has singular/plural problems - how to solve?
			"$bad has ties to $p",
			"$p probably isn't a real place anyway",
		);
	}

	for my $actor ( qw/ protagonists antagonists / ) {
		next unless $redstring->{$actor}{name};
		
		my $name   = $redstring->{$actor}{shortname} // $redstring->{$actor}{name};
		my $have   = splural( $redstring->{$actor} ) ? 'have' : 'has';
		my $are    = splural( $redstring->{$actor} ) ? 'are'  : 'is';
		my $s      = splural( $redstring->{$actor} ) ? ''     : 's';
		my $ies    = splural( $redstring->{$actor} ) ? 'y'    : 'ies';
		
		( my $fbname = $name ) =~ s/^the //i;
		$fbname = _UCFIRST_ $fbname;

		my $lies = lies();
		
		push @x, (
			"$name $have included it in their manifesto",
			"$name $have been strangely quiet about it",
			"$name $are always untrustworthy",
			"$name $are controlling everything",
			"if you Google for $name there's loads of info",
			"the '$fbname Truth' Facebook page says so",
			"the '$fbname Exposed' website says so",
			"$name even admit$s it",
			"$name den$ies it but that is $lies",
		);
		
		if ( my $animal = $redstring->{real_animal} // $redstring->{fake_animal} ) {
			push @x, "$name $have a picture of the $animal on their Wikipedia entry";
		}
		
		if ( my $place  = $redstring->{random_place} ) {
			push @x, "$name $have a secret base in $place";
		}
		
		if ( my $topic = $redstring->{topic} ) {
			my $topicname = $topic->{name};
			push @x, (
				"$name ${( $redstring->{$actor}{plural} ? \'keep' : \'keeps' )} editing the Wikipedia page about $topicname",
				"$name $are known to have ties to $topicname",
				"'$name' is almost an anagram of '$topicname'",
				"'$name' is the Hebrew word for '$topicname'",
				"'$name' is an anagram of '$topicname' (if you spell it wrong)",
			);
		}
	}

	my @evidences = List::Util::uniq( map { _RANDOM_(@x) } 1..2 );
	
	if ( @evidences == 2 ) {
		my ( $e1, $e2 ) = @evidences;
		return _RANDOM_(
			"You can tell this is the truth because $e1, and $e2.",
			( ( "I know because $e1, and $e2." ) x 6 ),
			"You just need to connect the dots. " . _UCFIRST_( "$e1 and $e2." ),
			"I used to be asleep like you, but then I saw the clues. " . _UCFIRST_( "$e1, and $e2. WAKE UP!" ),
			"THEY HIDE THE TRUTH IN PLAIN SIGHT. " . _UCFIRST_( "$e1, and $e2." ),
			"You won't believe how deep the rabbit hole goes. " . _UCFIRST_( "$e1, and $e2." ),
			sub { _UCFIRST_("$e1, and $e2. " . fatuous()) },
			sub {
				my $e3 = uc _RANDOM_(@x);
				my $fatuous = fatuous();
				_UCFIRST_( "$e1, and $e2. $fatuous $e3!" );
			},
			sub {
				my $e3 = uc _RANDOM_(@x);
				_UCFIRST_( "$e1, and $e2. They leave clues to mock us! $e3! MOCK! MOCK!" );
			},
			sub {
				my $t = {};
				theory($t);
				_UCFIRST_( "$e1, and $e2. Isn't it obvious? Also: " . $t->{base_theory} );
			},
		);
	}
	elsif ( @evidences == 1 ) {
		my ( $e1 ) = @evidences;
		return _RANDOM_(
			"You can tell the truth because $e1.",
			_UCFIRST_("$e1 and that reveals the truth."),
			"The truth is obvious if you're not a sheep, $e1.",
		);
	}
	
	return _RANDOM_(
		'The truth is plain to see.',
		"You're blind if you can't see the truth.",
		"The truth is obvious if you're not a sheep.",
	);
}

sub hidden_truth {
	my $redstring = shift // {};
	
	my $truth = _RANDOM_(
		sub { # wrap classics in a sub so they don't come up too often
			_RANDOM_(
				sub {
					$redstring->{topic} = { name => 'geology', plural => 0 };
					'the Earth is flat';
				},
				sub {
					$redstring->{topic} = { name => 'Inner Space (1987)', plural => 0 };
					'space is fake';
				},
				sub {
					$redstring->{topic} = { name => 'theology', plural => 0 };
					'God is real';
				},
				sub {
					$redstring->{topic} = { name => 'Buddhism', plural => 0 };
					'reincarnation is true';
				},
				sub {
					$redstring->{topic} = { name => 'germs', plural => 1 };
					"germs aren't real";
				},
				sub {
					$redstring->{topic} = { name => 'viruses', plural => 1 };
					"viruses aren't real";
				},
				sub {
					$redstring->{topic} = { name => 'MKUltra', plural => 0 };
					"MKUltra is still happening";
				},
				sub {
					shady_group( $redstring );
					$redstring->{antagonist} //= $redstring->{shady_group};
					$redstring->{topic} = { name => 'avalanches', plural => 1 };
					$redstring->{antagonist}{name} . " was responsible for the Dyatlov Pass incident";
				},
				sub {
					$redstring->{topic} = { name => 'Jeffrey Epstein', plural => 0 };
					"Epstein didn't kill himself";
				},
				sub {
					$redstring->{topic} = { name => "Sgt Pepper's Lonely Hearts Club Band", plural => 0 };
					"Paul McCartney died in a car crash in 1966";
				},
				sub {
					$redstring->{topic} = { name => 'Stonehenge', plural => 0 };
					$redstring->{random_place} //= 'Somerset';
					"the aliens built Stonehenge";
				},
				sub {
					$redstring->{topic} = { name => 'the Sphinx', plural => 0 };
					$redstring->{random_place} //= 'Egypt';
					"the aliens built the Pyramids";
				},
				sub {
					$redstring->{topic} = { name => 'Loch Ness', plural => 0 };
					$redstring->{random_place} //= 'Scotland';
					"the Loch Ness monster is real";
				},
				sub {
					$redstring->{topic} = { name => 'grain farming', plural => 0 };
					$redstring->{random_place} //= 'Alabama';
					"crop circles are caused by aliens";
				},
				sub {
					$redstring->{topic} = { name => 'kidnapping', plural => 0 };
					$redstring->{random_place} //= 'Alabama';
					"aliens abduct people for probing";
				},
				sub {
					$redstring->{topic} = { name => 'CERN', plural => 0 };
					$redstring->{random_place} //= 'Switzerland';
					"the large hadron collider will destroy the planet";
				},
				sub {
					$redstring->{topic} = { name => 'steal beams', plural => 1 };
					$redstring->{random_place} //= 'New York';
					"9/11 was an inside job";
				},
				sub {
					my $badevent = _RANDOM_(
						'Columbine',
						'Sandy Hook',
						'the Boston Marathon Bombing',
						'Malaysia Airlines Flight 370',
						'the JFK assassination',
						'Project Monarch',
						'the 1993 WTC bombing',
						'the 2017 hurricane season (Project Geostorm)',
						'Deepwater Horizon',
					);
					$redstring->{topic} = { name => 'false flag operations', plural => 1 };
					"$badevent was orchestrated by the US government";
				},
				sub {
					$redstring->{topic} = { name => 'glaciers', plural => 1 };
					$redstring->{random_place} //= 'Greenland';
					"global warming is a hoax";
				},
				sub {
					$redstring->{topic} = { name => 'geology', plural => 0 };
					'the US government knows exactly when Yellowstone will erupt';
				},
				sub {
					$redstring->{topic} = { name => 'cloud seeding', plural => 0 };
					"the government controls the weather";
				},
				sub {
					$redstring->{topic} = { name => 'Snapple', plural => 0 };
					"Snapple is owned by the KKK";
				},
				sub {
					my $disease = disease( $redstring );
					$redstring->{topic} = { name => 'biological warfare', plural => 0 };
					"$disease was developed as a bioweapon";
				},
				sub {
					$redstring->{topic} = { name => 'gas chambers', plural => 1 };
					$redstring->{random_place} //= 'Germany';
					"the holocaust never happened";
				},
				sub {
					$redstring->{topic} = { name => 'fascism', plural => 0 };
					$redstring->{random_place} //= 'Australia';
					"Antifa International have been starting wildfires";
				},
				sub {
					$redstring->{topic} = { name => 'phantom time', plural => 0 };
					"the years between 614 and 911 never happened";
				},
				sub {
					$redstring->{topic} = { name => 'Nazis', plural => 1 };
					"there is a Nazi base on the moon";
				},
				sub {
					$redstring->{topic} = { name => 'Nazis', plural => 1 };
					"there is a Nazi base in Antarctica";
				},
				sub {
					$redstring->{topic} = { name => 'wrestling', plural => 0 };
					"all professional sports are scripted";
				},
				sub {
					my $website = website( $redstring );
					my $spies   = _RANDOM_(
						'spies',
						'the CIA',
						'GCHQ',
						'the NSA',
						'the Kremlin',
						'Ipsos MORI',
						sub {
							my $g = shady_group( $redstring );
							$redstring->{shady_group}{plural} ? $g : "spies from $g";
						}
					);
					$redstring->{topic} = { name => 'biscuits', plural => 1 };
					"$spies are using cookies to see everything you look at on $website";
				},
			);
		},
		sub {
			$redstring->{topic} = { name => 'the Mandela effect', plural => 0 };
			_RANDOM_(
				'Looney Tunes used to be Looney Toons',
				'the Berenstain Bears used to be spelled Berenstein',
				'Curious George used to have a tail',
				'Febreze used to have another E in it',
				'Froot Loops used to be Fruit Loops',
				'the Monopoly man is supposed to have a monocle',
				'Kitkat used to have a hyphen',
				'the Mona Lisa used to smile more',
				'C-3PO never used to have a silver leg',
				'Darth Vader said Luke I Am Your Father',
				'We Are the Champions used to say "of the world" at the end',
				'the USA used to have 52 states',
			);
		},
		sub {
			$redstring->{topic} = { name => 'the crusades', plural => 1 };
			my $subst = _RANDOM_(
				'TikTok',
				'Twitter',
				'the world wars',
				'intergalactic warfare',
				'the white genocide',
				'colonization',
				'robot wars',
			);
			"the crusades never stopped, they were just replaced with $subst";
		},
		sub {
			my $cryptids = cryptids( $redstring );
			"$cryptids are real";
		},
		sub {
			my $cause   = disease_cause( $redstring );
			my $disease = disease( $redstring );
			$redstring->{topic} = { name => 'western medicine', plural => 0 };
			"$cause causes $disease";
		},
		sub {
			my $cryptids = cryptids( $redstring );
			my $group    = shady_group( $redstring );
			"$group are $cryptids";
		},
		sub {
			my $objects = objects( $redstring );
			"$objects are sentient";
		},
		sub {
			my $celebrity = celebrity( $redstring );
			my $long_time = a_long_time( $redstring );
			"$celebrity has been drinking the blood of infants $long_time to stay looking young";
		},
		sub {
			my $celebrity = celebrity( $redstring );
			$redstring->{topic} = { name => 'cross-dressing', plural => 0 };
			$redstring->{celebrity}{female} = ! $redstring->{celebrity}{female};
			"$celebrity is transsexual";
		},
		sub {
			my $celebrity = celebrity( $redstring );
			my $consequence = _RANDOM_(
				sub {
					$redstring->{topic} = { name => 'robotics', plural => 0 };
					'replaced by a robot';
				},
				sub {
					$redstring->{topic} = { name => 'impersonation', plural => 0 };
					'replaced by a look-alike';
				},
				sub {
					$redstring->{topic} = { name => 'blackmail', plural => 0 };
					'blackmailed into silence';
				},
			);
			"$celebrity has been $consequence";
		},
		sub {
			my $objects = objects( $redstring );
			my $group   = shady_group( $redstring );
			"$objects were invented by $group";
		},
		sub {
			my $resource = precious_resource( $redstring );
			"$resource is a source of free energy";
		},
		sub {
			my $mythplace  = myth_place( $redstring );
			my $place      = random_place( $redstring );
			"$mythplace is in $place";
		},
		sub {
			my $victim     = victim( $redstring );
			my $mythplace  = myth_place( $redstring );
			"$victim discovered $mythplace and was killed to keep it a secret";
		},
		sub {
			my $resource = precious_resource( $redstring );
			my $disease  = disease( $redstring );
			"$resource can cure $disease";
		},
		sub {
			my $animal = real_animal( $redstring );
			my $group  = shady_group( $redstring );
			"the $animal is a fake animal, engineered by $group";
		},
		sub {
			my $chemicals = chemicals( $redstring );
			my $animal    = real_animal( $redstring );
			my $s         = ($animal ne 'fish') ? 's' : '';
			my $attribute = attribute( $redstring );
			"the $chemicals in the water is turning the $animal$s $attribute";
		},
		sub {
			my $chemicals = chemicals( $redstring );
			my $food      = food( $redstring );
			"$food are full of $chemicals";
		},
		sub {
			my $animal = real_animal( $redstring );
			"the $animal originally comes from another planet";
		},
		sub {
			my $animal = real_animal( $redstring );
			my $group  = shady_group( $redstring );
			my $stupid = _RANDOM_(
				'people in costumes',
				'animatronics',
				'CGI',
				'highly coordinated swarms of bees',
				'holograms',
				'a mirage',
			);
			"the $animal is a fake animal and is just $stupid";
		},
		sub {
			my $animal = fake_animal( $redstring );
			"the $animal is a real animal";
		},
		sub {
			my $time = future_time( $redstring );
			"the world will end $time";
		},
		sub {
			my $time = future_time( $redstring );
			$redstring->{topic} = { name => 'comets', plural => 1 };
			"the comet will hit us $time";
		},
		sub {
			my $place = random_place( $redstring );
			$redstring->{topic} = { name => 'flooding', plural => 1 };
			"$place was destroyed by floods";
		},
		sub {
			my $place = random_place( $redstring );
			my $group = $redstring->{shady_group}{name} // shady_group( $redstring );
			$redstring->{topic} = { name => 'coup d\'etats', plural => 1 };
			"$place is ruled by $group";
		},
		sub {
			my $time = future_time( $redstring );
			$redstring->{topic} = { name => 'zombies', plural => 1 };
			"the zombie apocalypse will start $time";
		},
		sub {
			my $time = future_time( $redstring );
			$redstring->{topic} = { name => 'Jesus', plural => 0 };
			"Jesus will return $time";
		},
		sub {
			my $mc    = mind_control_device( $redstring );
			my $group = $redstring->{shady_group}{name} // shady_group( $redstring );
			"THEY ($group) are using $mc";
		},
		sub {
			my $victim = victim( $redstring );
			my $place  = bad_place( $redstring );
			"$victim is alive and kept at $place";
		},
		sub {
			my $artifact = artifact( $redstring );
			my $p = random_place( $redstring );
			"$artifact is in $p";
		},
		sub {
			my $victim = victim( $redstring );
			$redstring->{topic} = { name => 'the antichrist', plural => 0 };
			"$victim was the antichrist";
		},
		sub {
			my $victim = victim( $redstring );
			"$victim was a time-traveller";
		},
		sub {
			my $victim = victim( $redstring );
			"$victim was an inter-dimensional being";
		},
		sub {
			my $chem = chemicals( $redstring );
			my $stupid = _RANDOM_(
				'water mixed with food-colouring',
				'water that they put in the microwave',
				'water that came from a goat\'s insides',
				'water that they used magic on',
				'made of fairy dust',
				'melted potato starch',
			);
			"$chem is really just $stupid";
		},
		sub {
			my $fiction = fiction( $redstring );
			"$fiction is historically accurate";
		},
		sub {
			my $fiction = fiction( $redstring );
			my $victim = $redstring->{victim} // victim( $redstring );
			"$fiction was really written by $victim";
		},
		sub {
			my $p = random_place( $redstring );
			my $extinct = _RANDOM_(
				'dinosaur',
				'mammoth',
				'sabre-tooth tiger',
				'Tasmanian tiger',
				'pterodactyl',
			);
			$redstring->{real_animal} //= $extinct;
			"the $extinct is not extinct and there is a colony in $p";
		},
		sub {
			my $group   = shady_group( $redstring );
			my $invention = invention( $redstring );
			my $are = $redstring->{shady_group}{plural} ? 'are' : 'is';
			my $was = $redstring->{invention_plural} ? 'were' : 'was';
			my $invented = _RANDOM_(
				'invented',
				'cooked up',
				'fabricated',
			);
			_RANDOM_(
				"$group $are behind $invention",
				"$group $invented $invention",
				"$invention $was $invented by $group",
			);
		},
	);
	
	_MERGE_( $redstring, hidden_truth => $truth );
	return $truth;
}

sub theory {
	my $redstring = shift // {};
	
	my $theory = _RANDOM_(
		sub {
			my $group = shady_group( $redstring );
			$redstring->{protagonists} = $redstring->{shady_group};
			my $is = $redstring->{protagonists}->{plural} ? 'are' : 'is';
			
			my $misinfo = misinformation( $redstring );
			
			my $truth = hidden_truth( $redstring );
			
			my $exclaim = _RANDOM_(
				'', '', '', '', '', '',
				" But the truth shall not be buried!",
				" Don't let yourself be deceived!",
				" Take the red pill!",
				" Believing $misinfo is taking the blue pill!",
				" Take the red pill - $truth!",
				" Believing $misinfo is for blue-pilled sheeple!",
				" Open your mind!",
			);
			
			_UCFIRST_ "$group $is spreading the lie that $misinfo to distract the public from the truth that $truth.$exclaim";
		},
		sub {
			my $protagonists = shady_group( $redstring );
			$redstring->{protagonists} = $redstring->{shady_group};
			
			my $antagonists = shady_group( $redstring );
			$redstring->{antagonists} = $redstring->{shady_group};
			
			my $time = a_long_time( $redstring );
			
			my $war_reason = _RANDOM_(
				'Nobody knows why',
				'The reasons for this have been long forgotten',
				sub {
					my $consequence = _RANDOM_(
						'disappears',
						'is assassinated',
						sub {
							my $badplace = bad_place( $redstring );
							"is taken away to $badplace";
						},
						sub {
							my $badplace = bad_place( $redstring );
							"has their mind wiped at $badplace";
						},
						'is given a blue pill',
					);
					"Everybody who finds out why $consequence";
				},
				sub {
					my $truth = hidden_truth();
					my $pro   = $redstring->{protagonists}{shortname} // $protagonists;
					my $ant   = $redstring->{antagonists}{shortname} // $antagonists;
					my $want = splural( $redstring->{protagonists} ) ? 'want' : 'wants';
					_UCFIRST_ "$pro $want to expose the truth that $truth and $ant will do whatever they can to stop them";
				},
			);
			
			_UCFIRST_ "$protagonists and $antagonists have been in a secret war with each other $time. $war_reason."
		},
		sub {
			my $group = shady_group( $redstring );
			$redstring->{protagonists} = $redstring->{shady_group};
			
			my $victim = victim( $redstring );
			
			my $truth = hidden_truth( $redstring );
			
			my $explanation = _UCFIRST_ _RANDOM_(
				sub {
					my $group2 = shady_group( $redstring );
					$redstring->{antagonists} = $redstring->{shady_group};
					
					"$victim learnt the truth from $group2";
				},
				"Nobody knows how $victim found out",
				"$victim found out because they were the source of all knowledge",
				"$victim found out using time travel",
				"$victim found out using mind reading",
				"$victim took the red pill",
			);
			
			_UCFIRST_ "$group killed $victim to hide the truth that $truth. $explanation.";
		},
		sub {
			my $truth = hidden_truth( $redstring );
			
			my $sheeple = _RANDOM_(
				'people are sheeple',
				'they refuse to see the truth',
				'the mass media refuse to report it',
				sub {
					my $group = shady_group( $redstring );
					$redstring->{protagonists} = $redstring->{shady_group};
					my $is = $redstring->{protagonists}->{plural} ? 'are' : 'is';
					my $mc = mind_control_device( $redstring );
					"$group $is controlling people's minds with $mc";
				},
				sub {
					my $group = shady_group( $redstring );
					$redstring->{protagonists} = $redstring->{shady_group};
					my $have = $redstring->{protagonists}->{plural} ? 'have' : 'has';
					my $long_time = a_long_time( $redstring );
					"$group $have been hiding it $long_time";
				},
				sub {
					my $group = shady_group( $redstring );
					$redstring->{protagonists} = $redstring->{shady_group};
					my $is = $redstring->{protagonists}->{plural} ? 'are' : 'is';
					my $medium = _RANDOM_(
						'the Internet',
						'Twitter',
						'Facebook',
						'Instagram',
						'the mass media',
						'the TV news',
						'Tiktok',
						'both Tiktok and Instagram',
					);
					"$group $is censoring $medium";
				},
			);
			
			_UCFIRST_ _RANDOM_(
				"$truth but nobody knows because $sheeple.",
				"$truth but nobody believes me because $sheeple.",
				"$truth but everybody ignores it because $sheeple.",
				"$truth but people are blind because $sheeple.",
			);
		},
		sub {
			my $fiction = fiction( $redstring );
			my $truth = hidden_truth( $redstring );
			
			_UCFIRST_ _RANDOM_(
				"$fiction has a hidden message that $truth.",
				"$fiction is just an allegory which shows that $truth.",
				sub {
					my $group = shady_group( $redstring );
					$redstring->{protagonists} //= $redstring->{shady_group};
					"$fiction was analysed with a computer by $group and it revealed $truth.",
				},
			);
		},
		sub {
			my $group = shady_group( $redstring );
			$redstring->{protagonists} = $redstring->{shady_group};
			my $are = $redstring->{protagonists}->{plural} ? 'are' : 'is';
			
			my $place    = random_place( $redstring );
			my $darklord = dark_lord( $redstring );
			
			my $getting_kids = _RANDOM_(
				'abducting orphan children',
				'buying child slaves',
				'cloning babies',
				'growing babies in test tubes',
				'breeding babies',
				'buying kids from poor families',
				'stealing babies',
				sub {
					$redstring->{topic} //= { name => 'adoption', plural => 0 };
					'adopting babies';
				},
				sub {
					$redstring->{topic} //= { name => 'adoption', plural => 0 };
					'adopting kids';
				},
			);
			
			my $sacrifice = _RANDOM_(
				'sacrifice them',
				'ritually sacrifice them',
				'offer them',
				'offer them as a blood sacrifice',
				'offer them as brides',
				'offer them as sex slaves',
				'feed them',
				'sell them',
				'mass sacrifice them',
			);
			
			_UCFIRST_ "$group $are $getting_kids in $place to $sacrifice to $darklord.";
		},
		sub {
			my $group = shady_group( $redstring );
			$redstring->{protagonists} = $redstring->{shady_group};
			my $have = $redstring->{protagonists}->{plural} ? 'have' : 'has';
			my $are  = $redstring->{protagonists}->{plural} ? 'are'  : 'is';
			
			my $resource = precious_resource_with_quantity( $redstring );
			
			_UCFIRST_ _RANDOM_(
				"$group $have $resource.",
				"$group $are trying to obtain $resource.",
				"$group $are in possession of $resource.",
				"$group $have taken a delivery of $resource.",
			);
		},
		sub {
			my $group = shady_group( $redstring );
			$redstring->{protagonists} = $redstring->{shady_group};
			my $are  = $redstring->{protagonists}->{plural} ? 'are'  : 'is';
			
			my $project = shady_project( $redstring );
			
			_UCFIRST_ _RANDOM_(
				"$group $are running $project.",
				"$group $are in charge of $project.",
				"$group $are working against $project.",
				sub {
					my $auth = authority( $redstring );
					"$group $are investigating $project. They will soon have enough evidence to go to $auth.",
				},
			);
		},
		sub {
			my $group = shady_group( $redstring );
			$redstring->{protagonists} = $redstring->{shady_group};
			
			my $physicist = physicist( $redstring );
			
			my $fact = _RANDOM_(
				sub {
					$redstring->{topic} = { name => 'bathroom scales', plural => 1 };
					'electrons have more mass than protons';
				},
				sub {
					$redstring->{topic} = { name => 'weighing scales', plural => 1 };
					"protons don't have mass";
				},
				sub {
					my $things = _RANDOM_( 'electrons', 'protons' );
					$redstring->{topic} = { name => $things, plural => 1 };
					"$things are not real particles, they are just the terminal lines of a dielectric pulse";
				},
				sub {
					$redstring->{topic} = { name => 'water', plural => 0 };
					'water is its own element';
				},
				sub {
					$redstring->{topic} = { name => 'geocentrism', plural => 0 };
					'the sun goes round the Earth';
				},
				sub {
					$redstring->{topic} = { name => 'the moon', plural => 0 };
					'the moon is a hologram';
				},
				sub {
					$redstring->{topic} = { name => 'camembert', plural => 0 };
					'the moon is made of cheese';
				},
				sub {
					$redstring->{topic} = { name => 'the man in the moon', plural => 0 };
					'the man in the moon is a real man';
				},
				sub {
					my $chem = chemicals( $redstring );
					$redstring->{topic} = { name => 'the periodic table', plural => 0 };
					"element 119 is $chem";
				},
				sub {
					$redstring->{topic} = { name => 'air', plural => 0 };
					"air isn't real";
				},
				sub {
					$redstring->{topic} = { name => 'vacuum cleaners', plural => 0 };
					"space isn't a vacuum because then it would suck all the air";
				},
				sub {
					$redstring->{topic} = { name => 'the firmament', plural => 0 };
					"there is a dome over the flat Earth";
				},
				sub {
					$redstring->{topic} = { name => 'Satan', plural => 0 };
					'the axis of evil in the cosmic microwave background was put there by Satan';
				},
				sub {
					$redstring->{topic} = { name => 'the zodiac', plural => 0 };
					'astrology has been scientifically verified';
				},
				sub {
					$redstring->{topic} = { name => 'the year of the dragon', plural => 0 };
					'the Chinese zodiac can predict the future';
				},
			);
			
			my $solution = _UCFIRST_ _RANDOM_(
				"They paid $group to kill him.",
				"$group helped cover up the truth.",
				"$group threatened to kill him to keep him quiet.",
				"He was a member of $group so they knew he would keep quiet.",
				"$group arranged a convenient \"accident\".",
			);
			
			my $destruction = _RANDOM_(
				"all of modern physics",
				'our understanding of the universe',
				"the Big Bang 'theory'",
				"Einstein's theory of relativity",
			);
			
			_UCFIRST_ "$physicist discovered that $fact but the scientific establishment is suppressing it because it would destroy $destruction. $solution";
		},
		sub {
			my $group = shady_group( $redstring );
			$redstring->{protagonists} = $redstring->{shady_group};
			
			my $biologist = biologist( $redstring );
			
			my $fact = _RANDOM_(
				sub {
					$redstring->{topic} = { name => 'pandas', plural => 1 };
					'pandas are really just fat raccoons';
				},
				sub {
					$redstring->{topic} = { name => 'spaghetti', plural => 1 };
					"spaghetti is a type of worm";
				},
				sub {
					$redstring->{celebrity} //= { name => 'Louis Armstrong', female => 0 };
					$redstring->{topic} = { name => 'snakes', plural => 1 };
					"snakes like jazz music";
				},
				sub {
					$redstring->{real_place} //= 'Antarctica';
					$redstring->{topic} = { name => 'penguins', plural => 1 };
					"penguins can fly but they get nervous when people are watching";
				},
				sub {
					$redstring->{topic} = { name => 'DNA', plural => 0 };
					"the 10 commandments are encoded in human DNA";
				},
				sub {
					$redstring->{topic} = { name => 'essential oils', plural => 1 };
					"essential oils cure all diseases";
				},
				sub {
					$redstring->{topic} = { name => 'vaccines', plural => 1 };
					"essential oils cure autism";
				},
				sub {
					$redstring->{topic} = { name => 'anger management', plural => 0 };
					"wasps are just angry bees";
				},
				sub {
					$redstring->{topic} = { name => 'oncology', plural => 0 };
					"windmills cause cancer";
				},
				sub {
					my $chem = chemicals( $redstring );
					$redstring->{topic} = { name => 'honey', plural => 0 };
					"$chem is killing all the bees";
				},
				sub {
					my $animal = real_animal( $redstring );
					$redstring->{topic} = { name => 'space flight', plural => 0 };
					"$animal DNA comes from space";
				},
			);
			
			my $solution = _UCFIRST_ _RANDOM_(
				"They paid $group to kill him.",
				"$group helped cover up the truth.",
				"$group threatened to kill him to keep him quiet.",
				"He was a member of $group so they knew he would keep quiet.",
				"$group arranged a convenient \"accident\".",
			);
			
			my $destruction = _RANDOM_(
				"the 'theory' of evolution",
				'modern medicine',
				"the germ theory of disease",
				"our understanding of DNA",
				'creation science',
			);
			
			_UCFIRST_ "$biologist discovered that $fact but the scientific establishment is suppressing it because it would destroy $destruction. $solution";
		},
		sub {
			my $group = shady_group( $redstring );
			$redstring->{protagonists} = $redstring->{shady_group};
			my $have = $redstring->{protagonists}->{plural} ? 'have' : 'has';
			
			my $place = random_place( $redstring );
			
			my $how = _RANDOM_(
				"by diverting flights to $place to a Hollywood studio",
				'using mirrors',
				'by paying the UN',
				'by talking with funny accents',
				'by hacking satellites',
			);
			
			_UCFIRST_ "$place is just a hologram created by $group who $have been hiding it for years $how.";
		},
		sub {
			my $place  = random_place( $redstring );
			my $truth1 = hidden_truth( $redstring );
			
			_UCFIRST_ _RANDOM_(
				"It is common knowledge in $place that $truth1.",
				"They teach $truth1 at schools in $place.",
				"Everybody in $place knows that $truth1.",
				"People in $place found out that $truth1.",
			);
		},
		sub {
			my $celeb  = celebrity( $redstring );
			my $pronoun = $redstring->{celebrity}{female} ? 'she' : 'he';
			my $truth1 = hidden_truth( $redstring );
			my $group = shady_group( $redstring );
			$redstring->{protagonists} = $redstring->{shady_group};
			my $are = $redstring->{protagonists}->{plural} ? 'are' : 'is';
			
			my $silence = _RANDOM_(
				"$pronoun will probably have to be eliminated",
				"$pronoun is going to be killed if $pronoun isn't dead already",
				"$pronoun is being paid to stay quiet",
				"$pronoun will meet a convenient \"accident\"",
				sub {
					my $clone = clone( $redstring );
					"$pronoun has been replaced by $clone";
				},
				sub {
					my $place = bad_place( $redstring );
					"$pronoun has been imprisoned in $place";
				},
			);
			
			_UCFIRST_ "$celeb found out that $truth1 and $silence. " . _UCFIRST_ "$group $are protecting this secret.";
		},
		sub {
			my $celeb  = celebrity( $redstring );
			my $pronoun = $redstring->{celebrity}{female} ? 'she' : 'he';
			my $group = shady_group( $redstring );
			$redstring->{protagonists} = $redstring->{shady_group};
			
			_UCFIRST_ _RANDOM_(
				"$celeb is a member of $group.",
				"$celeb is a former member of $group.",
				"$celeb was thrown out of $group.",
				"$celeb infiltrated $group.",
				"$celeb is the leader of $group.",
				"$celeb is secretly worshipped by $group.",
			);
		},
	);

	if ( $redstring->{protagonists} and not $redstring->{antagonists} and _RANDOM_(0..1) ) {
		my $group1 = $redstring->{protagonists}{shortname} // $redstring->{protagonists}{name};
		my $group2 = shady_group( $redstring );
		$redstring->{antagonists} = $redstring->{shady_group};
		my $know = splural ($redstring->{antagonists}) ? 'know' : 'knows';
		$theory .= " " . _UCFIRST_ _RANDOM_(
			sub {
				my $bribe = precious_resource_with_quantity( $redstring );
				"$group2 $know the truth but $group1 have paid them off with $bribe.";
			},
			"$group2 $know the truth but $group1 have threatened them to keep them silent.",
			"$group2 were helping them until $group1 betrayed them.",
			"$group2 were helping them for a while.",
			"$group2 were originally opposed to this but they're now in on it.",
			"$group2 are trying to get evidence to prove it.",
		);
	}

	_MERGE_( $redstring, base_theory => $theory );
	
	my $evidence = evidence( $redstring );
	$theory .= " $evidence" if $evidence;

	my $numerology = numerology( $redstring );
	$theory .= " $numerology" if $numerology;

	_MERGE_( $redstring, theory => $theory );

	return $theory;
}

my %special_numbers = (
	19   => [ qr/COVID/,             '19 is the coronavirus number' ],
	24   => [ qr/TINTIN/,            'There are 24 Tintin comics' ],
	33   => [ qr/MASON/,             '33 is associated with the masons' ],
	35   => [ qr/ELVIS/,             'Elvis was born in 1935' ],
	44   => [ qr/OBAMA/,             'Barack Obama was the 44th President of the USA' ],
	45   => [ qr/TRUMP|QANON|USA/,   'Donald Trump was the 45th President of the USA',
	          qr/UNITEDNATIONS/,     'The United Nations was founded in 1945' ],
	46   => [ qr/BIDEN/,             'Joe Biden was the 46th President of the USA' ],
	47   => [ qr/THECIA/,            'The CIA was founded in 1947',
	          qr/SILVER/,            'Silver has atomic number 47' ],
	49   => [ qr/NATO/,              'NATO was founded in 1949' ],
	51   => [ qr/KFC/,               'Area 51 is the fifty-first area' ],
	52   => [ qr/KFC/,               'KFC was founded in 1952' ],
	55   => [ qr/BIGMAC|MCDONALDS/,  'McDonalds was founded in 1955' ],
	63   => [ qr/JFK|OSWALD/,        'JFK was shot in 1963' ],
	79   => [ qr/GOLD/,              'Gold has the atomic number 79' ],
	81   => [ qr/HIV/,               'AIDS was discovered in 1981' ],
	82   => [ qr/COKE/,              'Diet Coke first came out in 1982' ],
	86   => [ qr/RADON/,             'The atomic number for radon is 86' ],
	92   => [ qr/URANIUM/,           'The atomic number for uranium is 92' ],
	322  => [ qr/SKULL/,             'Skull and Bones is Order 322' ],
	666  => [ qr/DEVIL|DEMON|SATAN/, '666 is the number of the beast' ],
);

sub numerology {
	my $redstring = shift // {};
	
	my @strings = List::Util::uniq(
		grep { length }
		map { my $letters = uc( $_ ); $letters =~ s/[^A-Z0-9]//g; $letters }
		map {
			/^(the )(.+)$/i ? $2 : $_
		}
		map {
			ref( $_ ) ? grep( defined, $_->{name}, $_->{shortname}, $_->{title}, $_->{author} ) : $_
		}
		values( %$redstring )
	);
	
	my %calcs;
	foreach my $string ( @strings ) {
		next if length($string) >= 20;
		my @letters = split //, $string;
		my @numbers = map /[A-Z]/ ? ( ord($_) - 0x40 ) : $_, @letters;
		my $sum     = List::Util::sum( @numbers );
		
		push @{ $calcs{$sum} ||= [] }, sprintf(
			'%s = %s = %s',
			join( '+', @letters ),
			join( '+', @numbers ),
			$sum,
		);
	}
	
	foreach my $key ( %special_numbers ) {
		if ( $calcs{$key} ) {
			my @copy = @{ $special_numbers{$key} };
			while ( @copy ) {
				my ( $test, $statement ) = splice( @copy, 0 , 2 );
				next unless "@strings" =~ $test;
				push @{ $calcs{$key} }, "And guess what? " . $statement;
			}
		}
	}
	
	my @wow = map { @$_ > 1 ? @$_ : () } values %calcs;
	
	if ( @wow ) {
		return sprintf(
			"%s %s",
			_RANDOM_(
				'The numbers never lie.',
				'Trust the numbers.',
				'You can see the truth in the numbers.',
			),
			join(
				'',
				map( "$_. ", @wow ),
			)
		);
	}
	
	return '';
}

sub bad_punctuation {
	my ( $string, $cancel ) = @_;
	unless ( $cancel ) {
		$string =~ s/ ([A-Za-z]) ([,!?]) / $1 . _RANDOM_(    $2, " $2", " $2", " $2$2") /exg;
		$string =~ s/ ([A-Za-z]) ([.])   / $1 . _RANDOM_($2, $2, " $2", " ", " $2$2$2") /exg;
		$string =~ s/\!/_RANDOM_('!', '!', '!!',  "!!!!")/ex;
	}
	return $string;
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Acme::ConspiracyTheory::Random - random theories

=head1 SYNOPSIS

  use feature 'say';
  use Acme::ConspiracyTheory::Random -all;
  
  say bad_punctuation( theory() );

=head1 DESCRIPTION

This module exports a function, C<< theory() >> which returns a string.

=for html <p><img src="https://raw.githubusercontent.com/tobyink/p5-acme-conspiracytheory-random/master/assets/pepe-silvia.jpeg" alt=""></p>

There is also a function C<< bad_punctuation >> which, given a string, might
make the punctuation worse.

=head1 BUGS

Please report any bugs to
L<https://github.com/tobyink/p5-acme-conspiracytheory-random/issues>.

=head1 SEE ALSO

REDACTED

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 CONTRIBUTORS

Alex Jones discovered that there are secretly other people who have contributed
to this module but Toby Inkster is working with Microsoft and the Illuminati to
cover it up. I tried to blog about it but all my posts keep getting taken down
from Tumblr. There are hidden clues on L<GitHub|https://github.com/tobyink/p5-acme-conspiracytheory-random/graphs/contributors>.
You don't want to know how deep this rabbit hole goes!

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2021 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

