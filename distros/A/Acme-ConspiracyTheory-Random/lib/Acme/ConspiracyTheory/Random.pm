use 5.012;
use strict;
use warnings;

package Acme::ConspiracyTheory::Random;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.007';

use Exporter::Shiny qw( theory );
use List::Util 1.54 ();

sub _RANDOM_ {
	my $code = List::Util::sample( 1, @_ );
	ref($code) eq 'CODE' ? goto($code) : $code;
}

sub _MERGE_ {
	my ( $orig_meta, %new ) = @_;
	%$orig_meta = ( %$orig_meta, %new );
}

sub _UCFIRST_ ($) {
	( my $str = shift )
		=~ s/ (\w) / uc($1) /xe;
	$str;
}

sub celebrity {
	my $orig_meta = shift // {};
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
	);
	_MERGE_( $orig_meta, celebrity => $celeb );
	return $celeb->{name};
}

sub shady_group {
	my $orig_meta = shift // {};
	
	my $xx;
	PICK: {
		$xx = _RANDOM_(
			{ plural => 1, name => 'the Knights Templar', shortname => 'the Templars' },
			{ plural => 1, name => 'the Illuminati' },
			{ plural => 1, name => 'the Freemasons', shortname => 'the Masons' },
			{ plural => 0, name => 'the Ordo Templi Orientis' },
			{ plural => 1, name => 'the Cabalists' },
			{ plural => 1, name => 'the Followers of the Temple Of The Vampire', shortname => 'the Vampires' },
			{ plural => 0, name => 'the Secret Order of the Knights of the Round Table', shortname => 'the Knights' },
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
			{ plural => 0, name => 'the British Royal Family', shortname => 'the Royals' },
			{ plural => 0, name => 'NASA' },
			{ plural => 1, name => 'the Zionists' },
			{ plural => 0, name => 'the Trump administration' },
			{ plural => 0, name => 'the Biden administration' },
			{ plural => 0, name => 'the Republican party', shortname => 'the Republicans' },
			{ plural => 0, name => 'the Democrat party', shortname => 'the Democrats' },
			{ plural => 0, name => 'the New World Order' },
			{ plural => 1, name => 'the Communists' },
			{ plural => 0, name => 'the Shadow Government' },
			{ plural => 0, name => 'the global financial elite' },
			{ plural => 0, name => 'the global scientific elite' },
			{ plural => 0, name => 'Big Pharma' },
			{ plural => 0, name => 'Big Tobacco' },
			{ plural => 1, name => 'the lizard people', shortname => 'the lizardmen' },
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
					['the moon', 'the moonlings'],
					['the Counter-Earth', 'the anti-Earthlings'],
				);
				{ plural => 1, name => "aliens from ".$planet->[0], shortname => $planet->[1] };
			},
		);
		
		no warnings;
		redo PICK
			if ( $orig_meta->{protagonists} and $orig_meta->{protagonists}{name} eq $xx->{name} )
			|| ( $orig_meta->{antagonists}  and $orig_meta->{antagonists}{name}  eq $xx->{name} );
	};
	
	_MERGE_( $orig_meta, shady_group => $xx );
	return $xx->{name};
}

sub real_animal {
	my $orig_meta = shift // {};
	
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
	
	_MERGE_( $orig_meta, real_animal => $animal );
	return $animal;
}

sub fake_animal {
	my $orig_meta = shift // {};
	
	my $animal = _RANDOM_(
		'unicorn',
		'bigfoot',
		'mermaid',
		'werewolf',
		'dragon',
		'wyvern',
		'yeti',
	);
	
	_MERGE_( $orig_meta, fake_animal => $animal );
	return $animal;
}

sub objects {
	my $orig_meta = shift // {};
	
	my $objects = _RANDOM_(
		'cars',
		'TVs',
		'smartphones',
		'microwave ovens',
		'trees',
		'clothes',
	);
	
	_MERGE_( $orig_meta, objects => $objects );
	return $objects;
}

sub shady_project {
	my $orig_meta = shift // {};
	
	my $x = _RANDOM_(
		'Project Blue Beam',
		'The Plan',
		'the Global Warming Hoax',
		'the New Chronology',
		'the Great Replacement',
		'the LGBT Agenda',
		'the Kalergi Plan',
		'Eurabia',
	);
	
	_MERGE_( $orig_meta, shady_project => $x );
	return $x;
}

sub authority {
	my $orig_meta = shift // {};
	
	my $x = _RANDOM_(
		'the Supreme Court',
		'the United Nations',
		'the FBI',
		'the CIA',
		'NATO',
	);
	
	_MERGE_( $orig_meta, authority => $x );
	return $x;
}

sub dark_lord {
	my $orig_meta = shift // {};
	
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
	
	_MERGE_( $orig_meta, dark_lord => $x );
	return $x;
}

sub disease {
	my $orig_meta = shift // {};
	
	my $disease = _RANDOM_(
		'cancer',
		'COVID-19',
		'HIV',
		'the common cold',
		'diabetes',
		'obesity',
	);
	
	_MERGE_( $orig_meta, disease => $disease );
	return $disease;
}

sub chemicals {
	my $orig_meta = shift // {};
	
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
	);
	
	_MERGE_( $orig_meta, chemicals => $chemicals );
	return $chemicals;
}

sub food {
	my $orig_meta = shift // {};
	
	my $food = _RANDOM_(
		'apples',
		'Big Macs',
		'KFC family buckets',
		'most wines',
		'Kraft instant mac and cheese boxes',
		'bananas',
	);
	
	_MERGE_( $orig_meta, food => $food );
	return $food;
}

sub attribute {
	my $orig_meta = shift // {};
	
	my $attr = _RANDOM_(
		'gay',
		'insane',
		'infertile',
		'immobile',
		'horny',
		'female',
		'fat',
		'flourescent',
	);
	
	_MERGE_( $orig_meta, attribute => $attr );
	return $attr;
}

sub artifact {
	my $orig_meta = shift // {};
	
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
		"the seal of Soloman",
	);
	
	_MERGE_( $orig_meta, artifact => $artifact );
	return $artifact;
}

sub bad_place {
	my $orig_meta = shift // {};
	
	my $bad_place = _RANDOM_(
		'a secret Antarctic base',
		'Area 51',
		'Langley, Virginia',
		'Guantanamo Bay Detention Camp',
		'Windsor Castle',
		'The Pentagon',
		'Denver International Airport',
		'the basement of the Vatican',
		sub { myth_place( $orig_meta ) },
		sub {
			my $p = random_place( $orig_meta );
			"a series of tunnels underneath $p";
		},
		sub {
			my $p = random_place( $orig_meta );
			"a secret base in $p";
		},
	);
	
	_MERGE_( $orig_meta, bad_place => $bad_place );
	return $bad_place;
}

sub random_place {
	my $orig_meta = shift // {};
	
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
	
	_MERGE_( $orig_meta, random_place => $random_place );
	return $random_place;
}

sub myth_place {
	my $orig_meta = shift // {};
	
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
	);
	
	_MERGE_( $orig_meta, myth_place => $place );
	return $place;
}

sub cryptids {
	my $orig_meta = shift // {};
	
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
	
	_MERGE_( $orig_meta, cryptids => $cryptids );
	return $cryptids;
}

sub fiction {
	my $orig_meta = shift // {};
	
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
	
	_MERGE_( $orig_meta, fiction => $fiction );
	return $fiction->{title};
}

sub precious_resource {
	my $orig_meta = shift // {};
	
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
	
	_MERGE_( $orig_meta, precious_resource => $resource );
	return $resource;
}

sub precious_resource_with_quantity {
	my $orig_meta = shift // {};
	my $resource = precious_resource( $orig_meta );
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
	my $orig_meta = shift // {};
	
	my $mc = _RANDOM_(
		'chemtrails',
		'mind control drugs in the water',
		'5G',
		'WiFi',
		'microchips implanted at birth',
		'vaccines',
		'childhood indoctrination',
		'neurolinguistic programming',
		'video games',
		'mass media',
		'space lasers',
		'hypnotism',
	);
	
	_MERGE_( $orig_meta, mind_control_device => $mc );
	return $mc;
}

sub future_time {
	my $orig_meta = shift // {};
	
	my $time = _RANDOM_(
		'in 2030',
		'by the end of the century',
		'in 2666',
		'when Queen Elizabeth II dies',
		'when the ice caps melt',
		'next Christmas',
	);
	
	_MERGE_( $orig_meta, future_time => $time );
	return $time;
}

sub a_long_time {
	my $orig_meta = shift // {};
	
	my @extras = ();
	for my $actor ( qw/ protagonists antagonists / ) {
		push @extras, sub {
			my $have = $orig_meta->{$actor}{plural} ? 'have' : 'has';
			"for as long as " . ($orig_meta->{$actor}{shortname}//$orig_meta->{$actor}{name}) . " $have existed";
		} if $orig_meta->{$actor}{name};
	}
	
	my $time = _RANDOM_(
		'since 1492',
		'since 1666',
		'since 1066',
		'since the time of Christ',
		'since time immemorial',
		'since the dawn of time',
		'for hundreds of years',
		'for millenia',
		@extras,
	);
	
	_MERGE_( $orig_meta, a_long_time => $time );
	return $time;
}

sub misinformation {
	my $orig_meta = shift // {};
	
	my $info = _RANDOM_(
		'the Earth is round',
		'the Earth goes around the sun',
		'humans are animals',
		'birds are dinosaurs',
		sub {
			$orig_meta->{topic} = { name => 'the moon', plural => 0 };
			'men have walked on the moon';
		},
		sub {
			$orig_meta->{topic} = { name => 'electricity', plural => 0 };
			'electricity exists';
		},
		sub {
			$orig_meta->{topic} = { name => 'magnetism', plural => 0 };
			'magnetism is real';
		},
		sub {
			$orig_meta->{topic} = { name => 'gravity', plural => 0 };
			'gravity is real';
		},
		sub {
			$orig_meta->{topic} = { name => 'outer space', plural => 0 };
			'space is real';
		},
		sub {
			$orig_meta->{topic} = { name => 'viruses', plural => 1 };
			'viruses are real';
		},
		sub {
			$orig_meta->{topic} = { name => 'vaccines', plural => 1 };
			'vaccines are safe';
		},
		sub {
			my $animal = real_animal( $orig_meta );
			"the $animal is real";
		},
		sub {
			my $place = random_place( $orig_meta );
			"$place is real";
		},
		sub {
			$orig_meta->{topic} = { name => 'carbon dating', plural => 0 };
			'the Earth is 4.5 billion years old';
		},
		sub {
			$orig_meta->{topic} = { name => 'radiocarbon dating', plural => 0 };
			'the universe is 14 billion years old';
		},
		sub {
			$orig_meta->{topic} = { name => 'pigeons', plural => 1 };
			'dinosaurs are real';
		},
		sub {
			$orig_meta->{topic} = { name => 'surveillance drones', plural => 1 };
			'birds are real';
		},
	);
	
	_MERGE_( $orig_meta, misinformation => $info );
	return $info;
}

sub victim {
	my $orig_meta = shift // {};
	
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
	
	_MERGE_( $orig_meta, victim => $victim );
	return $victim;
}

sub physicist {  # and chemists
	my $orig_meta = shift // {};
	
	my $x = _RANDOM_(
		'Nikola Tesla',
		'Benjamin Franklin',
		'Albert Einstein',
		'Isaac Newton',
		'Stephen Hawking',
		'Henry Cavendish',
	);
	
	_MERGE_( $orig_meta, physicist => $x );
	return $x;
}

sub biologist {  # and medics
	my $orig_meta = shift // {};
	
	my $x = _RANDOM_(
		'Charles Darwin',
		'Edward Jenner',
		'Robert Koch',
		'Edward Jenner',
		'Carl Linneaus',
		'Alexander Fleming',
	);
	
	_MERGE_( $orig_meta, biologist => $x );
	return $x;
}

sub clone {
	my $orig_meta = shift // {};

	my $x = _RANDOM_(
		'an alien',
		'an avatar',
		'a CGI replica',
		'a clone',
		'a cyborg',
		'a hologram',
		'a look-alike',
		'a robot',
	);

	_MERGE_( $orig_meta, clone => $x );
	return $x;
}


sub evidence {
	my $orig_meta = shift // {};
	
	my @x = (
		"there's a video about it on YouTube",
		"there was something about it on Facebook",
		"the voices told me",
		"I had a dream",
		'Pinterest is censoring me',
		'Reddit was down this morning',
	);

	if ( my $m = $orig_meta->{misinformation} ) {
		push @x, (
			"they indoctrinate people about '$m' at schools and if it were the truth they wouldn't need to",
			"'$m' gets pushed down our throats by mass media",
		);
	}
	
	if ( my $auth = $orig_meta->{authority} ) {
		push @x, (
			"$auth are the obvious people to go to",
			"$auth are the only ones with the power to stop them",
			"$auth are able to save us",
		);
	}

	if ( my $p = $orig_meta->{myth_place} ) {
		push @x, (
			"there are clues about $p in the Bible",
			"$p is on some old maps",
			"$p is on Google Maps",
		);
	}

	if ( my $art = $orig_meta->{artifact} ) {
		push @x, (
			"$art isn't in any museum",
			"$art must be somewhere",
			"$art is out there",
			"$art can be found with GPS",
		);
	}

	if ( my $proj = $orig_meta->{shady_project} ) {
		push @x, (
			"everybody knows $proj is happening soon",
			"$proj is well-funded",
			"$proj is an open secret",
			"there is so much evidence for $proj",
		);
	}
	
	if ( my $dl = $orig_meta->{dark_lord} ) {
		push @x, (
			"$dl is known to be growing in power",
			"$dl has never seemed more powerful",
			"$dl needs to be getting power from somewhere",
			"$dl told me",
			"I have seen signs from $dl",
		);
	}
	
	if ( my $v = $orig_meta->{victim} // $orig_meta->{physicist} // $orig_meta->{biologist} ) {
		push @x, (
			"$v died too young",
			"$v sent a letter containing the truth before dying",
			sub {
				my $clone = clone( $orig_meta );
				"when they did an autopsy on $v it turned out it was $clone",
			},
			"they never did an autopsy on $v",
			"$v wrote a will",
			sub {
				my $g = shady_group( $orig_meta );
				"$v was secretly one of $g";
			},
			sub {
				my $animal = real_animal( $orig_meta );
				"when they did an autopsy on $v it turned out they were secretly a $animal in a human suit";
			},
		);
	}

	if ( my $v = $orig_meta->{physicist} // $orig_meta->{biologist} ) {
		push @x, (
			"$v isn't mentioned in Aristotle's writing",
			"$v hasn't given a lecture in months",
			"$v isn't taken seriously by TRUE SCIENTISTS",
		);
	}

	if ( my $c = $orig_meta->{celebrity} ) {
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

	if ( my $f = $orig_meta->{fiction} ) {
		
		push @x, (
			$f->{title} . " has secret messages encoded in it with numerology",
			$f->{title} . " is satanic",
			sub {
				my $g = shady_group( $orig_meta );
				$f->{author} . " has ties to $g";
			},
			sub {
				my $b = bad_place( $orig_meta );
				$f->{author} . " got taken to $b for questioning";
			},
		);
		
		if ( my $p = $orig_meta->{random_place} ) {
			push @x, (
				$f->{author} . " had a secret home in $p",
				$f->{author} . " was secretly born in $p",
			);
		}
	}
	
	if ( my $animal = $orig_meta->{real_animal} // $orig_meta->{fake_animal} ) {
		push @x, (
			"the $animal wasn't mentioned in the Bible",
			"the $animal was mentioned in the Satanic Verses",
			"the $animal looks kind of weird",
			"nobody has ever seen a $animal in real life",
			"the $animal obviously isn't native to this planet",
			sub {	"${ \ shady_group($orig_meta) } sacrifice $animal${\'s'} to ${ \ dark_lord($orig_meta) }" },
			"the $animal looks bigger in real life",
			"the $animal makes a funny noise",
			"Alex Jones did a podcast about the $animal",
		);
	}
	
	if ( my $mc = $orig_meta->{mind_control_device} ) {
		my $time = a_long_time();
		push @x, (
			"everybody knows $mc is real",
			sub { "$mc has been researched by ${ \ shady_group($orig_meta) } $time" },
			sub { "$mc was used to conceal ${ \ shady_group($orig_meta) } $time" },
			sub { "$mc was used to infiltrate ${ \ shady_group($orig_meta) }" },
		);
	}

	if ( my $ft = $orig_meta->{future_time} ) {
		push @x, (
			"some of the few people still alive $ft time-travelled back to tell us",
			"the people still alive $ft sent us hidden messages in ${ \ fiction() }",
			"it will all become clear $ft",
		);
	}

	if ( my $d = $orig_meta->{disease} ) {
		push @x, (
			"patients with $d keep disappearing from hospitals",
			"patients with $d are being silenced by the government",
			"doctors working on $d are being killed",
			"$d probably isn't even a real disease",
			"nobody has ever died of $d",
		);
	}

	if ( my $f = $orig_meta->{food} ) {
		push @x, (
			"$f don't taste like they used to",
			"$f smell funny",
			"$f make me feel sick",
			"I don't like $f",
		);
	}

	if ( my $chem = $orig_meta->{chemicals} ) {
		push @x, (
			"$chem isn't on the periodic table",
			"$chem isn't real",
			"$chem isn't natural",
			"you'd have to be stupid to think $chem is real",
		);
	}

	if ( my $r = $orig_meta->{precious_resource} ) {
		my ( $bad, $are );
		$orig_meta->{shady_group}{name} or shady_group( $orig_meta );
		foreach ( qw/ antagonist protagonist shady_group / ) {
			if ( $orig_meta->{$_}{name} ) {
				$bad = $orig_meta->{$_}{name};
				$are = $orig_meta->{$_}{plural} ? 'are' : 'is';
			}
		}
		push @x, (
			"the Wikipedia entry for $r keeps getting edited by $bad",
			"$bad keeps buying $r secretly on the stock market",
			"the global supply of $r is at an all time low",
			"have you ever seen $r for real with your own eyes",
			"$r is so damn expensive",
			"$r is really rare",
			"Alex Jones says $bad $are linked to $r",
		);
	}

	if ( my $topic = $orig_meta->{topic} ) {
		my $topicname = $topic->{name};
		my $have      = $topic->{plural} ? 'have' : 'has';
		push @x, (
			"there's hidden clues in the Wikipedia page about $topicname",
			"THEY let it slip during an edit war in a Wikipedia page about $topicname",
			"Bible numerology has clues about $topicname",
			"$topicname $have always been suspicious",
			"$topicname $have connections to THEM",
			"nobody really understands $topicname",
			"all my posts about $topicname keep getting taken down by Tumblr",
		);
	}

	if ( my $p = $orig_meta->{random_place} // $orig_meta->{bad_place} ) {
		my $bad = $orig_meta->{antagonist}{name}
			// $orig_meta->{protagonist}{name}
			// $orig_meta->{shady_group}{name}
			// shady_group( $orig_meta );
		push @x, (
			"the Wikipedia entry for $p keeps getting edited by $bad",
			"$bad has ties to $p",
			"$p probably isn't a real place anyway",
		);
	}

	for my $actor ( qw/ protagonists antagonists / ) {
		next unless $orig_meta->{$actor}{name};
		
		my $name   = $orig_meta->{$actor}{shortname} // $orig_meta->{$actor}{name};
		my $have   = $orig_meta->{$actor}{plural} ? 'have' : 'has';
		my $are    = $orig_meta->{$actor}{plural} ? 'are'  : 'is';
		my $s      = $orig_meta->{$actor}{plural} ? ''     : 's';
		
		( my $fbname = $name ) =~ s/^the //i;
		$fbname = _UCFIRST_ $fbname;
		
		push @x, (
			"$name $have included it in their manifesto",
			"$name $have been strangely quiet about it",
			"$name $are always untrustworthy",
			"$name $are controlling everything",
			"if you Google for $name there's loads of info",
			"the '$fbname Truth' Facebook page says so",
			"the '$fbname Exposed' website says so",
			"$name even admit$s it",
			"$name deny$s it but that is obvious lies",
		);
		
		if ( my $animal = $orig_meta->{real_animal} // $orig_meta->{fake_animal} ) {
			push @x, "$name $have a picture of the $animal on their Wikipedia entry";
		}
		
		if ( my $place  = $orig_meta->{random_place} ) {
			push @x, "$name $have a secret base in $place";
		}
		
		if ( my $topic = $orig_meta->{topic} ) {
			my $topicname = $topic->{name};
			push @x, (
				"$name ${( $orig_meta->{$actor}{plural} ? \'keep' : \'keeps' )} editing the Wikipedia page about $topicname",
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
			"You can tell this is the truth because $e1 and $e2.",
			"I know because $e1 and $e2.",
			"You just need to connect the dots. " . _UCFIRST_( "$e1 and $e2." ),
			"I used to be asleep like you, but then I saw the clues. " . _UCFIRST_( "$e1 and $e2. WAKE UP!" ),
			"THEY HIDE THE TRUTH IN PLAIN SIGHT. " . _UCFIRST_( "$e1 and $e2." ),
			"You won't believe how deep the rabbit hole goes. " . _UCFIRST_( "$e1 and $e2." ),
			_UCFIRST_( "$e1 and $e2. It's obvious if you connect the dots." ),
			_UCFIRST_( "$e1 and $e2. They leave clues to mock us." ),
			_UCFIRST_( "$e1 and $e2. Isn't it obvious?" ),
			_UCFIRST_( "$e1 and $e2. Wake up, sheeple!" ),
			sub {
				my $e3 = uc _RANDOM_(@x);
				_UCFIRST_( "$e1 and $e2. Isn't it obvious? $e3!" );
			},
			sub {
				my $e3 = uc _RANDOM_(@x);
				_UCFIRST_( "$e1 and $e2. They leave clues to mock us! $e3! MOCK! MOCK!" );
			},
			sub {
				my $t = {};
				theory($t);
				_UCFIRST_( "$e1 and $e2. Isn't it obvious? Also: " . $t->{base_theory} );
			},
		);
	}
	elsif ( @evidences == 1 ) {
		my ( $e1 ) = @evidences;
		return _RANDOM_(
			"You can tell the truth because $e1.",
			_UCFIRST_("$e1 and that reveals the truth."),
			"The truth is obvious if you're not a sheep - $e1.",
		);
	}
	
	return _RANDOM_(
		'The truth is plain to see.',
		"You're blind if you can't see the truth.",
		"The truth is obvious if you're not a sheep.",
	);
}

sub hidden_truth {
	my $orig_meta = shift // {};
	
	my $truth = _RANDOM_(
		sub { # wrap classics in a sub so they don't come up too often
			_RANDOM_(
				sub {
					$orig_meta->{topic} = { name => 'geology', plural => 0 };
					'the Earth is flat';
				},
				sub {
					$orig_meta->{topic} = { name => 'Inner Space (1987)', plural => 0 };
					'space is fake';
				},
				sub {
					$orig_meta->{topic} = { name => 'theology', plural => 0 };
					'God is real';
				},
				sub {
					$orig_meta->{topic} = { name => 'Buddhism', plural => 0 };
					'reincarnation is true';
				},
				sub {
					$orig_meta->{topic} = { name => 'germs', plural => 1 };
					"germs aren't real";
				},
				sub {
					$orig_meta->{topic} = { name => 'viruses', plural => 1 };
					"viruses aren't real";
				},
				sub {
					$orig_meta->{topic} = { name => 'MKUltra', plural => 1 };
					"MKUltra is still happening";
				},
				sub {
					$orig_meta->{topic} = { name => 'Jeffrey Epstein', plural => 1 };
					"Epstein didn't kill himself";
				},
				sub {
					$orig_meta->{topic} = { name => 'Stonehenge', plural => 0 };
					$orig_meta->{random_place} //= 'Somerset';
					"the aliens built Stonehenge";
				},
				sub {
					$orig_meta->{topic} = { name => 'the Sphinx', plural => 0 };
					$orig_meta->{random_place} //= 'Egypt';
					"the aliens built the Pyramids";
				},
				sub {
					$orig_meta->{topic} = { name => 'Loch Ness', plural => 0 };
					$orig_meta->{random_place} //= 'Scotland';
					"the Loch Ness monster is real";
				},
				sub {
					$orig_meta->{topic} = { name => 'grain farming', plural => 0 };
					$orig_meta->{random_place} //= 'Alabama';
					"crop circles are caused by aliens";
				},
				sub {
					$orig_meta->{topic} = { name => 'kidnapping', plural => 0 };
					$orig_meta->{random_place} //= 'Alabama';
					"aliens abduct people for probing";
				},
				sub {
					$orig_meta->{topic} = { name => 'steal beams', plural => 1 };
					$orig_meta->{random_place} //= 'New York';
					"9/11 was an inside job";
				},
				sub {
					$orig_meta->{topic} = { name => 'glaciers', plural => 1 };
					$orig_meta->{random_place} //= 'Greenland';
					"global warming is a hoax";
				},
				sub {
					$orig_meta->{topic} = { name => 'gas chambers', plural => 1 };
					$orig_meta->{random_place} //= 'Germany';
					"the holocaust never happened";
				},
				sub {
					$orig_meta->{topic} = { name => 'fascism', plural => 0 };
					$orig_meta->{random_place} //= 'Australia';
					"Antifa International have been starting wildfires";
				},
				sub {
					$orig_meta->{topic} = { name => 'phantom time', plural => 0 };
					"the years between 614 and 911 never happened";
				},
				sub {
					$orig_meta->{topic} = { name => 'Nazis', plural => 1 };
					"there is a Nazi base on the moon";
				},
				sub {
					$orig_meta->{topic} = { name => 'Nazis', plural => 1 };
					"there is a Nazi base in Antarctica";
				},
			);
		},
		sub {
			$orig_meta->{topic} = { name => 'the Mandela effect', plural => 0 };
			_RANDOM_(
				'Looney Tunes used to be Looney Toons',
				'the Berenstain Bears used to be spelled Berenstein',
				'Curious George used to have a tail',
				'Febreze used to have another E in it',
				'Froot Loops used to be Fruit Loops',
				'the Monopoly man is supposed to have a monacle',
				'Kitkat used to have a hyphen',
				'the Mona Lisa used to smile more',
				'C-3PO never used to have a silver leg',
				'Darth Vader said Luke I Am Your Father',
				'We Are the Champions used to say "of the world" at the end',
				'the USA used to have 52 states',
			);
		},
		sub {
			$orig_meta->{topic} = { name => 'the crusades', plural => 1 };
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
			my $cryptids = cryptids( $orig_meta );
			"$cryptids are real";
		},
		sub {
			my $cryptids = cryptids( $orig_meta );
			my $group    = shady_group( $orig_meta );
			"$group are $cryptids";
		},
		sub {
			my $objects = objects( $orig_meta );
			"$objects are sentient";
		},
		sub {
			my $celebrity = celebrity( $orig_meta );
			my $long_time = a_long_time( $orig_meta );
			"$celebrity has been drinking the blood of infants $long_time to stay looking young";
		},
		sub {
			my $celebrity = celebrity( $orig_meta );
			$orig_meta->{topic} = { name => 'cross-dressing', plural => 0 };
			"$celebrity is transsexual";
		},
		sub {
			my $celebrity = celebrity( $orig_meta );
			my $consequence = _RANDOM_(
				sub {
					$orig_meta->{topic} = { name => 'robotics', plural => 0 };
					'replaced by a robot';
				},
				sub {
					$orig_meta->{topic} = { name => 'impersonation', plural => 0 };
					'replaced by a look-alike';
				},
				sub {
					$orig_meta->{topic} = { name => 'blackmail', plural => 0 };
					'blackmailed into silence';
				},
			);
			"$celebrity has been $consequence";
		},
		sub {
			my $objects = objects( $orig_meta );
			my $group   = shady_group( $orig_meta );
			"$objects were invented by $group";
		},
		sub {
			my $resource = precious_resource( $orig_meta );
			"$resource is a source of free energy";
		},
		sub {
			my $mythplace  = myth_place( $orig_meta );
			my $place      = random_place( $orig_meta );
			"$mythplace is in $place";
		},
		sub {
			my $victim     = victim( $orig_meta );
			my $mythplace  = myth_place( $orig_meta );
			"$victim discovered $mythplace and was killed to keep it a secret";
		},
		sub {
			my $resource = precious_resource( $orig_meta );
			my $disease  = disease( $orig_meta );
			"$resource can cure $disease";
		},
		sub {
			my $animal = real_animal( $orig_meta );
			my $group  = shady_group( $orig_meta );
			"the $animal is a fake animal, engineered by $group";
		},
		sub {
			my $chemicals = chemicals( $orig_meta );
			my $animal    = real_animal( $orig_meta );
			my $attribute = attribute( $orig_meta );
			"the $chemicals in the water is turning the $animal" . "s $attribute";
		},
		sub {
			my $chemicals = chemicals( $orig_meta );
			my $food      = food( $orig_meta );
			"$food are full of $chemicals";
		},
		sub {
			my $animal = real_animal( $orig_meta );
			"the $animal originally comes from another planet";
		},
		sub {
			my $animal = real_animal( $orig_meta );
			my $group  = shady_group( $orig_meta );
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
			my $animal = fake_animal( $orig_meta );
			"the $animal is a real animal";
		},
		sub {
			my $time = future_time( $orig_meta );
			"the world will end $time";
		},
		sub {
			my $time = future_time( $orig_meta );
			$orig_meta->{topic} = { name => 'comets', plural => 1 };
			"the comet will hit us $time";
		},
		sub {
			my $place = random_place( $orig_meta );
			$orig_meta->{topic} = { name => 'flooding', plural => 1 };
			"$place was destroyed by floods";
		},
		sub {
			my $place = random_place( $orig_meta );
			my $group = $orig_meta->{shady_group}{name} // shady_group( $orig_meta );
			$orig_meta->{topic} = { name => 'coup d\'etats', plural => 1 };
			"$place is ruled by $group";
		},
		sub {
			my $time = future_time( $orig_meta );
			$orig_meta->{topic} = { name => 'zombies', plural => 1 };
			"the zombie apocalypse will start $time";
		},
		sub {
			my $time = future_time( $orig_meta );
			$orig_meta->{topic} = { name => 'Jesus', plural => 0 };
			"Jesus will return $time";
		},
		sub {
			my $mc    = mind_control_device( $orig_meta );
			my $group = $orig_meta->{shady_group}{name} // shady_group( $orig_meta );
			"THEY ($group) are using $mc";
		},
		sub {
			my $victim = victim( $orig_meta );
			my $place  = bad_place( $orig_meta );
			"$victim is alive and kept at $place";
		},
		sub {
			my $artifact = artifact( $orig_meta );
			my $p = random_place( $orig_meta );
			"$artifact is in $p";
		},
		sub {
			my $victim = victim( $orig_meta );
			$orig_meta->{topic} = { name => 'the antichrist', plural => 0 };
			"$victim was the antichrist";
		},
		sub {
			my $victim = victim( $orig_meta );
			"$victim was a time-traveller";
		},
		sub {
			my $victim = victim( $orig_meta );
			"$victim was an inter-dimensional being";
		},
		sub {
			my $chem = chemicals( $orig_meta );
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
			my $fiction = fiction( $orig_meta );
			"$fiction is historically accurate";
		},
		sub {
			my $fiction = fiction( $orig_meta );
			my $victim = $orig_meta->{victim} // victim( $orig_meta );
			"$fiction was really written by $victim";
		},
		sub {
			my $p = random_place( $orig_meta );
			my $extinct = _RANDOM_(
				'dinosaur',
				'mammoth',
				'sabre-tooth tiger',
				'Tasmanian tiger',
				'pterodactyl',
			);
			$orig_meta->{real_animal} //= $extinct;
			"the $extinct is not extinct and there is a colony in $p";
		},
	);
	
	_MERGE_( $orig_meta, hidden_truth => $truth );
	return $truth;
}

sub theory {
	my $orig_meta = shift // {};
	
	my $theory = _RANDOM_(
		sub {
			my $group = shady_group( $orig_meta );
			$orig_meta->{protagonists} = $orig_meta->{shady_group};
			my $is = $orig_meta->{protagonists}->{plural} ? 'are' : 'is';
			
			my $misinfo = misinformation( $orig_meta );
			
			my $truth = hidden_truth( $orig_meta );
			
			my $exclaim = _RANDOM_(
				'',
				'',
				" But the truth shall not be buried!",
				" Don't let yourself be deceived!",
				" Take the red pill!",
				" Believing $misinfo is taking the blue pill!",
				" Take the red pill - $truth!",
				" Believing $misinfo is for blue pill sheeple!",
				" Open your mind!",
			);
			
			_UCFIRST_ "$group $is spreading the lie that $misinfo to distract the public from the truth that $truth.$exclaim";
		},
		sub {
			my $protagonists = shady_group( $orig_meta );
			$orig_meta->{protagonists} = $orig_meta->{shady_group};
			
			my $antagonists = shady_group( $orig_meta );
			$orig_meta->{antagonists} = $orig_meta->{shady_group};
			
			my $time = a_long_time( $orig_meta );
			
			my $war_reason = _RANDOM_(
				'Nobody knows why',
				'The reasons for this have been long forgotten',
				sub {
					my $consequence = _RANDOM_(
						'disappears',
						'is assassinated',
						sub {
							my $badplace = bad_place( $orig_meta );
							"is taken away to $badplace";
						},
						sub {
							my $badplace = bad_place( $orig_meta );
							"has their mind wiped at $badplace";
						},
						'is given a blue pill',
					);
					"Everybody who finds out why $consequence";
				},
				sub {
					my $truth = hidden_truth();
					my $pro   = $orig_meta->{protagonists}{shortname} // $protagonists;
					my $ant   = $orig_meta->{antagonists}{shortname} // $antagonists;
					_UCFIRST_ "$pro want to expose the truth that $truth and $ant will do whatever they can to stop them";
				},
			);
			
			_UCFIRST_ "$protagonists and $antagonists have been in a secret war with each other $time. $war_reason."
		},
		sub {
			my $group = shady_group( $orig_meta );
			$orig_meta->{protagonists} = $orig_meta->{shady_group};
			
			my $victim = victim( $orig_meta );
			
			my $truth = hidden_truth( $orig_meta );
			
			my $explanation = _UCFIRST_ _RANDOM_(
				sub {
					my $group2 = shady_group( $orig_meta );
					$orig_meta->{antagonists} = $orig_meta->{shady_group};
					
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
			my $truth = hidden_truth( $orig_meta );
			
			my $sheeple = _RANDOM_(
				'people are sheeple',
				'they refuse to see the truth',
				'the mass media refuse to report it',
				sub {
					my $group = shady_group( $orig_meta );
					$orig_meta->{protagonists} = $orig_meta->{shady_group};
					my $is = $orig_meta->{protagonists}->{plural} ? 'are' : 'is';
					my $mc = mind_control_device( $orig_meta );
					"$group $is controlling people's minds with $mc";
				},
				sub {
					my $group = shady_group( $orig_meta );
					$orig_meta->{protagonists} = $orig_meta->{shady_group};
					my $have = $orig_meta->{protagonists}->{plural} ? 'have' : 'has';
					my $long_time = a_long_time( $orig_meta );
					"$group $have been hiding it $long_time";
				},
				sub {
					my $group = shady_group( $orig_meta );
					$orig_meta->{protagonists} = $orig_meta->{shady_group};
					my $is = $orig_meta->{protagonists}->{plural} ? 'are' : 'is';
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
			my $fiction = fiction( $orig_meta );
			my $truth = hidden_truth( $orig_meta );
			
			_UCFIRST_ _RANDOM_(
				"$fiction has a hidden message that $truth.",
				"$fiction is just an allegory which shows that $truth.",
				sub {
					my $group = shady_group( $orig_meta );
					$orig_meta->{protagonists} //= $orig_meta->{shady_group};
					"$fiction was analysed with a computer by $group and it revealed $truth.",
				},
			);
		},
		sub {
			my $group = shady_group( $orig_meta );
			$orig_meta->{protagonists} = $orig_meta->{shady_group};
			my $are = $orig_meta->{protagonists}->{plural} ? 'are' : 'is';
			
			my $place    = random_place( $orig_meta );
			my $darklord = dark_lord( $orig_meta );
			
			my $getting_kids = _RANDOM_(
				'abducting orphan children',
				'buying child slaves',
				'cloning babies',
				'growing babies in test tubes',
				'breeding babies',
				'buying kids from poor families',
				'stealing babies',
				sub {
					$orig_meta->{topic} //= { name => 'adoption', plural => 0 };
					'adopting babies';
				},
				sub {
					$orig_meta->{topic} //= { name => 'adoption', plural => 0 };
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
			my $group = shady_group( $orig_meta );
			$orig_meta->{protagonists} = $orig_meta->{shady_group};
			my $have = $orig_meta->{protagonists}->{plural} ? 'have' : 'has';
			my $are  = $orig_meta->{protagonists}->{plural} ? 'are'  : 'is';
			
			my $resource = precious_resource_with_quantity( $orig_meta );
			
			_UCFIRST_ _RANDOM_(
				"$group $have $resource.",
				"$group $are trying to obtain $resource.",
				"$group $are in possession of $resource.",
				"$group $have taken a delivery of $resource.",
			);
		},
		sub {
			my $group = shady_group( $orig_meta );
			$orig_meta->{protagonists} = $orig_meta->{shady_group};
			my $are  = $orig_meta->{protagonists}->{plural} ? 'are'  : 'is';
			
			my $project = shady_project( $orig_meta );
			
			_UCFIRST_ _RANDOM_(
				"$group $are running $project.",
				"$group $are in charge of $project.",
				"$group $are working against $project.",
				sub {
					my $auth = authority( $orig_meta );
					"$group $are investigating $project. They will soon have enough evidence to go to $auth.",
				},
			);
		},
		sub {
			my $group = shady_group( $orig_meta );
			$orig_meta->{protagonists} = $orig_meta->{shady_group};
			
			my $physicist = physicist( $orig_meta );
			
			my $fact = _RANDOM_(
				sub {
					$orig_meta->{topic} = { name => 'bathroom scales', plural => 1 };
					'electrons have more mass than protons';
				},
				sub {
					$orig_meta->{topic} = { name => 'weighing scales', plural => 1 };
					"protons don't have mass";
				},
				sub {
					my $things = _RANDOM_( 'electrons', 'protons' );
					$orig_meta->{topic} = { name => $things, plural => 1 };
					"$things are not real particles, they are just the terminal lines of a dieletric pulse";
				},
				sub {
					$orig_meta->{topic} = { name => 'water', plural => 0 };
					'water is its own element';
				},
				sub {
					$orig_meta->{topic} = { name => 'geocentrism', plural => 0 };
					'the sun goes round the Earth';
				},
				sub {
					$orig_meta->{topic} = { name => 'the moon', plural => 0 };
					'the moon is a hologram';
				},
				sub {
					$orig_meta->{topic} = { name => 'camembert', plural => 0 };
					'the moon is made of cheese';
				},
				sub {
					$orig_meta->{topic} = { name => 'the man in the moon', plural => 0 };
					'the man in the moon is a real man';
				},
				sub {
					my $chem = chemicals( $orig_meta );
					$orig_meta->{topic} = { name => 'the periodic table', plural => 0 };
					"element 119 is $chem";
				},
				sub {
					$orig_meta->{topic} = { name => 'air', plural => 0 };
					"air isn't real";
				},
				sub {
					$orig_meta->{topic} = { name => 'vacuum cleaners', plural => 0 };
					"space isn't a vacuum because then it would suck all the air";
				},
				sub {
					$orig_meta->{topic} = { name => 'the firmament', plural => 0 };
					"there is a dome over the flat Earth";
				},
				sub {
					$orig_meta->{topic} = { name => 'Satan', plural => 0 };
					'the axis of evil in the cosmic microwave background was put there by Satan';
				},
				sub {
					$orig_meta->{topic} = { name => 'the zodiac', plural => 0 };
					'astrology has been scientifically verified';
				},
				sub {
					$orig_meta->{topic} = { name => 'the year of the dragon', plural => 0 };
					'the Chinese zodiac can predict the future';
				},
			);
			
			my $solution = _UCFIRST_ _RANDOM_(
				"They paid $group to kill him.",
				"$group helped cover up the truth.",
				"$group threatened to kill him to keep him quiet.",
				"He was a member of $group so they knew he would keep quiet.",
			);
			
			my $destruction = _RANDOM_(
				"all of modern physics",
				'our understanding of the universe',
				"the Big Bang 'theory'",
			);
			
			_UCFIRST_ "$physicist discovered that $fact but the scientific establishment is suppressing it because it would destroy $destruction. $solution";
		},
		sub {
			my $group = shady_group( $orig_meta );
			$orig_meta->{protagonists} = $orig_meta->{shady_group};
			
			my $biologist = biologist( $orig_meta );
			
			my $fact = _RANDOM_(
				sub {
					$orig_meta->{topic} = { name => 'pandas', plural => 1 };
					'pandas are really just fat racoons';
				},
				sub {
					$orig_meta->{topic} = { name => 'spaghetti', plural => 1 };
					"spaghetti is a type of worm";
				},
				sub {
					$orig_meta->{celebrity} //= { name => 'Louis Armstrong', female => 0 };
					$orig_meta->{topic} = { name => 'snakes', plural => 1 };
					"snakes like jazz music";
				},
				sub {
					$orig_meta->{real_place} //= 'Antarctica';
					$orig_meta->{topic} = { name => 'penguins', plural => 1 };
					"penguins can fly but they get nervous when people are watching";
				},
				sub {
					$orig_meta->{topic} = { name => 'DNA', plural => 0 };
					"the 10 commandments are encoded in human DNA";
				},
				sub {
					$orig_meta->{topic} = { name => 'essential oils', plural => 1 };
					"essential oils cure all diseases";
				},
				sub {
					$orig_meta->{topic} = { name => 'vaccines', plural => 1 };
					"essential oils cure autism";
				},
				sub {
					$orig_meta->{topic} = { name => 'anger managemment', plural => 0 };
					"wasps are just angry bees";
				},
				sub {
					$orig_meta->{topic} = { name => 'oncology', plural => 0 };
					"windmills cause cancer";
				},
				sub {
					my $animal = real_animal( $orig_meta );
					$orig_meta->{topic} = { name => 'space flight', plural => 0 };
					"$animal DNA comes from space";
				},
			);
			
			my $solution = _UCFIRST_ _RANDOM_(
				"They paid $group to kill him.",
				"$group helped cover up the truth.",
				"$group threatened to kill him to keep him quiet.",
				"He was a member of $group so they knew he would keep quiet.",
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
			my $group = shady_group( $orig_meta );
			$orig_meta->{protagonists} = $orig_meta->{shady_group};
			my $have = $orig_meta->{protagonists}->{plural} ? 'have' : 'has';
			
			my $place = random_place( $orig_meta );
			
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
			my $place  = random_place( $orig_meta );
			my $truth1 = hidden_truth( $orig_meta );
			
			_UCFIRST_ _RANDOM_(
				"It is common knowledge in $place that $truth1.",
				"They teach $truth1 at schools in $place.",
				"Everybody in $place knows that $truth1.",
				"People in $place found out that $truth1.",
			);
		},
		sub {
			my $celeb  = celebrity( $orig_meta );
			my $pronoun = $orig_meta->{celebrity}{female} ? 'she' : 'he';
			my $truth1 = hidden_truth( $orig_meta );
			my $group = shady_group( $orig_meta );
			$orig_meta->{protagonists} = $orig_meta->{shady_group};
			my $are = $orig_meta->{protagonists}->{plural} ? 'are' : 'is';
			
			my $silence = _RANDOM_(
				"$pronoun will probably have to be eliminated",
				"$pronoun is going to be killed if $pronoun isn't dead already",
				"$pronoun is being paid to stay quiet",
				sub {
					my $clone = clone( $orig_meta );
					"$pronoun has been replaced by $clone";
				},
				sub {
					my $place = bad_place( $orig_meta );
					"$pronoun has been imprisoned in $place";
				},
			);
			
			_UCFIRST_ "$celeb found out that $truth1 and $silence. " . _UCFIRST_ "$group $are protecting this secret.";
		},
		sub {
			my $celeb  = celebrity( $orig_meta );
			my $pronoun = $orig_meta->{celebrity}{female} ? 'she' : 'he';
			my $group = shady_group( $orig_meta );
			$orig_meta->{protagonists} = $orig_meta->{shady_group};
			
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

	if ( $orig_meta->{protagonists} and not $orig_meta->{antagonists} and _RANDOM_(0..1) ) {
		my $group1 = $orig_meta->{protagonists}{shortname} // $orig_meta->{protagonists}{name};
		my $group2 = shady_group( $orig_meta );
		$orig_meta->{antagonists} = $orig_meta->{shady_group};
		my $know = $orig_meta->{antagonists}->{plural} ? 'know' : 'knows';
		$theory .= " " . _UCFIRST_ _RANDOM_(
			sub {
				my $bribe = precious_resource_with_quantity( $orig_meta );
				"$group2 $know the truth but $group1 have paid them off with $bribe.";
			},
			"$group2 $know the truth but $group1 have threatened them to keep them silent.",
			"$group2 were helping them until $group1 betrayed them.",
			"$group2 were helping them for a while.",
			"$group2 were originally opposed to this but they're now in on it.",
			"$group2 are trying to get evidence to prove it.",
		);
	}

	_MERGE_( $orig_meta, base_theory => $theory );
	
	my $evidence = evidence( $orig_meta );
	
	$theory .= " $evidence" if $evidence;

	_MERGE_( $orig_meta, theory => $theory );

	return $theory;
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Acme::ConspiracyTheory::Random - random theories

=head1 SYNOPSIS

  use feature 'say';
  use Acme::ConspiracyTheory::Random 'theory';
  
  say theory();

=head1 DESCRIPTION

This module exports one function, C<< theory() >> which returns a string.

=head1 BUGS

Please report any bugs to
L<https://github.com/tobyink/p5-acme-conspiracytheory-random/issues>.

=head1 SEE ALSO

REDACTED

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2021 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

