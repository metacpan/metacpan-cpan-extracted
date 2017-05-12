package Coy;

BEGIN
{
require Exporter;
@ISA = ('Exporter');
@EXPORT = qw(transcend enlighten);
$VERSION = '0.06';

my $USER_CONFIG_FILE = "$ENV{HOME}/.coyrc";

use Carp ();

sub transcend { &Carp::croak }

sub enlighten { &Carp::carp }

# THE REAL WORK STARTS HERE

use Lingua::EN::Inflect qw(PL_N PL_V NO inflect NUM A PART_PRES NUMWORDS);
use Lingua::EN::Hyphenate;

sub random
{
	for (1..100)
	{
		my $choice = $_[int rand @_];
		my $selection = (ref($choice) eq 'CODE') 
				  ? $choice->()
				  : $choice;
		return $selection if defined $selection;
	}
	die "couldn't randomize: " . join(", ", @_) . "at " . (caller)[2];
}

sub syl_count
{
	my $count = 0;
	my $word;
	foreach $word (split / /, $_[0])
	{
		$word =~ /^\d+$/ and $word = NUMWORDS($word);
		my @syllables = syllables($word);
		$count += @syllables;
	}
	return $count;
}

# Personages

@Coy::personage = ( "The Jade Emperor", "Master Po", "Mumon", 
		  "The Seventh Sage", "the Master", "Alan Watts",
		  "Tor Kin Tun", "Tom See", "Or Wunt",
		  "Homer Simpson", "Lao Tse", "The Buddha",
		  "Gautama", "Swordmaster Mushashi", "Con Wei",
		  "Joshu", "Bankei", "Ryokan", "Ryonen", "Eshun",
		);


# EXCLAMATIONS

my @exclamation = ( 'Oh!', 'See!', ' Look!' );


# LOCATIONS

my @aquatic    = qw( pond  river  pool  dam  stream  lake );

sub Aquatic::atRandom
	{ random 
		"in the " . random(@aquatic),
		"in " . A(random @aquatic)
		;
	}

sub Exoaquatic::atRandom
	{ random 
		"out of the " . random(@aquatic),
		"from " . A(random @aquatic)
		;
	}

sub Suraquatic::atRandom
	{ random 
		"on the " . random(@aquatic),
		"on " . A(random @aquatic)
		;
	}

sub Aerial::atRandom
	{ random
		"over the " . random(@aquatic),
		"above the " . random(@aquatic),
		"over " . random(@Coy::place),
		"above " . random(@Coy::place),
		"near " . random(@Coy::place)
	}

sub Arborial::atRandom
	{ random 
		"in " . A(random @Coy::tree),
		"in the branches of " . A(random @Coy::tree),
		"in " . A(random @Coy::tree, @Coy::fruit_tree) . " tree",
		"in the branches of " . A(random @Coy::tree, @Coy::fruit_tree) . " tree";
	}

sub Terrestrial::atRandom
	{ random
		"under " . A(random @Coy::tree) . random(" tree", ""),
		"near " . random(@Coy::place),
		"beside " . A(random @aquatic);
	}


# DIRECTIONS

my @horizontalNS = qw( north south );
my @horizontalEW = qw( east west );
my @vertical    = qw( up upwards down downwards );
my @general_dir = qw( away );
my @to_dir_prep    = ( "towards" );
my @from_dir_prep    = ( "away from", );

sub Horizontal::atRandom
	{ my $compass = random
		@horizontalNS,
		@horizontalEW,
		random(@horizontalNS).'-'.random(@horizontalEW)
		;
	  return random
	  	($compass x 8,
		@general_dir),
		random(@to_dir_prep)." the ".$compass,
		random(@to_dir_prep, @from_dir_prep)." ".random(@Coy::place);
	}

sub Any::atRandom
	{ my $compass = random
		@horizontalNS,
		@horizontalEW,
		random(@horizontalNS).'-'.random(@horizontalEW)
		;
	  return random
	  	$compass,
		@general_dir,
		random(@to_dir_prep)." the ".$compass,
		random(@to_dir_prep, @from_dir_prep)." ".random(@Coy::place);
		@vertical;
	}

# DATABASE

$Coy::agent = {};
$Coy::agent_categories = {};
@Coy::nouns = ();
$Coy::associations = "";
my $nonassoc = 0;

sub tree
{
	push @Coy::tree, @_;
	1;
}

sub fruit_tree
{
	push @Coy::fruit_tree, @_;
	1;
}

sub place
{
	push @Coy::place, @_;
	1;
}

sub personage
{
	push @Coy::personage, @_;
	1;
}

sub noun
{
	my $hashref = shift;
	Carp::croak "Usage: noun <hash reference>" unless ref($hashref) eq 'HASH';
	$Coy::agent = { %$Coy::agent, %$hashref };
	# print STDERR "Added ", scalar keys %$hashref, " to agent\n";
	1;
}

sub categories
{
	my $hashref = shift;
	Carp::croak "Usage: categories <hash reference>" unless ref($hashref) eq 'HASH';
	$Coy::agent_categories = { %$Coy::agent_categories, %$hashref };
	# print STDERR "Added ", scalar keys %$hashref, " to agent_categories\n";
	1;
}

sub syllable_counter
{
	my $sub = shift;
	$sub = \&$sub unless ref $sub;
	no strict;
	undef &syllables;
	local $SIG{__WARN__} = sub {};
	*syllables = $sub;
}

my @count_prob = ((0)x1,(1)x90,(2)x40,(3..5)x2,(6..12)x1);

sub get_Noun_Verb
{
	my ($count, $sound, $noun_only) = @_;
	my ($noun, $verb, $min, $max);
	my $tries = 0;
	$nonassoc = 0;
	while (++$tries) 
	{
		$noun  = random @Coy::nouns;
		return $noun if $noun_only;
		my @verbs = keys %{$Coy::agent->{$noun}{act}};
		# print STDERR "noun = $noun\n";
		# print STDERR "verbs = @verbs\n";
		push @verbs, @{$Coy::agent->{$noun}{sound}}
			if $sound && $Coy::agent->{$noun}{sound};
		$verb = random @verbs;
		# print STDERR "[trying $noun/$verb for $count";
		# print STDERR " (non-assoc)" if $nonassoc;
		# print STDERR "]\n";
		if ($tries>20) { $nonassoc = 1 }
		if ($Coy::associations && !$nonassoc)
		{
			my $assoc =
				$Coy::agent->{$noun}{act}{$verb}{associations}||"";
			# print "$noun/$verb: [$assoc]->[$Coy::associations]\n";
			next unless $assoc && ($assoc =~ /$Coy::associations/i);
			# print "[$assoc]\n";
		}
		if ($tries>50)
		{
			$_[0] = $Coy::agent->{$noun}{act}{$verb}{minimum}
				|| $Coy::agent->{$noun}{minimum};
			last;
		}
		$min = $Coy::agent->{$noun}{act}{$verb}{minimum};
		$min = $Coy::agent->{$noun}{minimum}
			if !defined ($min) || defined($Coy::agent->{$noun}{minimum})
			&& $min < $Coy::agent->{$noun}{minimum};
		$max = $Coy::agent->{$noun}{act}{$verb}{maximum};
		$max = $Coy::agent->{$noun}{maximum}
			if !defined ($max) || defined($Coy::agent->{$noun}{maximum})
			&& $max > $Coy::agent->{$noun}{maximum};
		# print STDERR "trying $noun/$verb [$min<=$count<=$max]\n";
		last unless (defined($min) && $count < $min ||
			     defined($max) && $count > $max);
	}

	# print STDERR "[accepted $noun/$verb]\n";
	return ($noun, $verb, PART_PRES($verb),
		$Coy::agent->{$noun}{act}{$verb}{non_adjectival});
}

sub Noun
{
	my $count = random @count_prob;
	my ($noun,@verb)  = get_Noun_Verb($count,'SOUND','NOUN_ONLY');
	return $noun if $Coy::agent->{$noun}{personage};;
	return inflect "NO($noun,$count)";
}

sub Noun_Verb
{
	my $count = random @count_prob;
	my ($noun,@verb)  = get_Noun_Verb($count,'SOUND');
	my $verb = random @verb[0..1];
	return inflect "$noun PL_V($verb,$count)" if $Coy::agent->{$noun}{personage};
	return inflect "NO($noun,$count) PL_V($verb,$count)";
}

sub Participle_Noun
{
	my $count = random @count_prob;
	my ($noun,$verb,$participle,$non_adjectival)  =
		get_Noun_Verb($count,'SOUND');
	return if $non_adjectival or $Coy::agent->{$noun}{personage};
	return inflect "NO($participle $noun,$count)";
}

sub Noun_Location
{
	my $count = random @count_prob;
	my ($noun,@verb)  = get_Noun_Verb($count,'NOUN_ONLY');
	my $verb = random @verb[0..1];
	return undef unless $Coy::agent->{$noun}{act}{$verb[0]}{location};
	my $location = $Coy::agent->{$noun}{act}{$verb[0]}{location}->atRandom();
	return inflect "$noun $location" if $Coy::agent->{$noun}{personage};
	return inflect "NO($noun,$count) $location";
}

sub Noun_Verb_Location
{
	my $count = random @count_prob;
	my ($noun,@verb)  = get_Noun_Verb($count);
	my $verb = random @verb[0..1];
	return undef unless $Coy::agent->{$noun}{act}{$verb[0]}{location};
	my $location = $Coy::agent->{$noun}{act}{$verb[0]}{location}->atRandom();
	return inflect "$noun PL_V($verb,$count) $location"
		if $Coy::agent->{$noun}{personage};
	return inflect "NO($noun,$count) PL_V($verb,$count) $location";
}

sub Noun_Verb_Direction
{
	my $count = random @count_prob;
	my ($noun,@verb)  = get_Noun_Verb($count);
	my $verb = random @verb[0..1];
	return undef unless $Coy::agent->{$noun}{act}{$verb[0]}{direction};
	my $direction = $Coy::agent->{$noun}{act}{$verb[0]}{direction}->atRandom();
	return inflect "$noun PL_V($verb,$count) $direction"
		if $Coy::agent->{$noun}{personage};
	return inflect "NO($noun,$count) PL_V($verb,$count) $direction";
}

sub expand_synonyms
{
	foreach my $noun ( @Coy::nouns )
	{
		my %act = %{$Coy::agent->{$noun}{act}};
		foreach my $verb ( keys %act )
		{
			if (exists $act{$verb}{synonyms})
			{
				foreach my $syn ( @{$act{$verb}{synonyms}} )
				{
					$Coy::agent->{$noun}{act}{$syn}
						= $act{$verb};
				}
			}
		}
	}
}

sub expand_categories
{
	foreach my $noun ( @Coy::nouns )
	{
		my $categories = $Coy::agent->{$noun}{category} or next;
		my %generic_acts = ();
		foreach my $category ( @$categories )
		{
			next unless $Coy::agent_categories->{$category};
			%generic_acts =
				( %{$Coy::agent_categories->{$category}{act}||{}},
				  %generic_acts );
		}
		# print STDERR "expanding $noun with", keys(%generic_acts), "\n";
		%{$Coy::agent->{$noun}{act}} =
			( %generic_acts, %{$Coy::agent->{$noun}{act}||{}} );
	}
	foreach my $noun ( @Coy::personage )
	{
		push @Coy::nouns, $noun;
		$Coy::agent->{$noun}{category} = [ "Human" ];
		$Coy::agent->{$noun}{maximum} = 1;
		$Coy::agent->{$noun}{minimum} = 1;
		$Coy::agent->{$noun}{personage} = 1;
		$Coy::agent->{$noun}{act} =  $Coy::agent_categories->{Human}{act}||{};
	}
}

sub Generate
{
	local $_ =  random 
		(
			(sub { Noun }) x 1,
			(sub { Noun_Location }) x 6,
			(sub { Noun_Verb }) x 3,
			(sub { Noun_Verb_Direction }) x 13,
			(sub { Noun_Verb_Location }) x 13,
			(sub { Participle_Noun }) x 5,
		);
		;

	s/^1(?= )/a/;
	s/^2(?= )/random "a pair of", "two"/e;
	s/^(\d+)(?= )/NUMWORDS($1)/e;
	$Coy::associations = "" unless $nonassoc;
	return ucfirst $_;
}

sub Generate_Sized
{
	my ($size) = @_;
	my $fulltext = "";
	my $fullcount = 0;
	while ($fullcount != $size)
	{
		my $text = Generate;
		my $count = $fullcount + syl_count($text);
		if ($count < $size-1 || $count == $size)
		{
			$fulltext .= ($fulltext?". ":"").$text;
			$fullcount = $count;
		}
	}
	return $fulltext;
}

use Text::Wrap;

sub with_haiku
{
	my $message = join("",@_);
	my $file = "Mysterious Compiler";
	my $line = "???";
	if ($message =~ s/(.*)at\s(\S+)\sline\s(\d+.*?)\s*\Z/$1/s)
	{
		$file = $2||$file;
		$line = $3||$line;
	}
	elsif ($message =~ s/(.*)File\s'([^']+)';\s+Line\s+(\d+.*)/$1/s)
	{
		$file = $2||$file;
		$line = $3||$line;
		chomp $line;
		$file =~ s/^.*://;
	}

	associate($message);

	my @words = ();
	foreach my $word (split /\s+/, Generate_Sized(17))
	{
		push @words, [$word, syl_count($word)];
	}

	my $haiku = "";
	my $count = 0;
	while ($count<5)
	{
		my $word = shift @words;
		$haiku .= "$word->[0] ";
		$count+=$word->[1];
	}
	$haiku .= "\n\t";
	while ($count<12)
	{
		my $word = shift @words;
		$haiku .= "$word->[0] ";
		$count+=$word->[1];
	}
	$haiku .= "\n\t";
	$haiku .= join(" ",map {$_->[0]} @words) . ".";


	$message = wrap("\t\t","\t\t",$message);
	$message =~ s/\t\t//;

	my @book = ('Analects of %s',
		    'Sayings of %s',
		    'The Wisdom of %s',
		    '"%s Speaks"',
		    '"The Way of %s"',
		   );

	my $book = sprintf(random(@book),$file);

	$where = wrap("\t\t\t","\t\t\t ","($book: line $line)");
	$where =~ s/\t\t\t//;


	my $personage = ucfirst random @Coy::personage;

	return <<MU;

	-----
	$haiku
	-----

		${personage}'s commentary...
	
		$message

			$where
MU
}

sub associate
{
	%Coy::associations = ();
	my ($message) = @_;
	$message =~ s/[^A-Za-z]+/ /g;
	my @words = split /\s+/, $message;
	$Coy::associations = join "|", grep {$_} @words;
	# $Coy::associations = qr/$Coy::associations/;
}

# LOAD STANDARD DATA

syllable_counter "Lingua::EN::Hyphenate::syllables";

noun
{
	duck =>
	{
		category => [ Bird ],
		act =>
		{
			swims =>
			{
				location => Suraquatic,
				direction => Horizontal,
			},
		},
		sound => [ "quacks", ]
	},
	swallow =>
	{
		category => [ Bird ],
		act => { swoops => { location => Aerial, } },
	},
	raven	   => { category => [ Bird ] },
	thrush	   => { category => [ Bird ], sound => [ "sings" ]},
	songbird   => { category => [ Bird ], sound => [ "sings" ]},
	lark       => { category => [ Bird ], sound => [ "sings" ]},
	gannet	   => { category => [ Bird ] },
	dove	   => { category => [ Bird ], sound => [ "coos" ] },
	kingfisher => { category => [ Bird ] },
	woodpecker => { category => [ Bird ] },

	'carp'	   => { category => [ Fish ] },
	goldfish   => { category => [ Fish ] },
	salmon     => { category => [ Fish, Leaper ] },
	pike       => { category => [ Fish, Leaper ] },
	trout      => { category => [ Fish, Leaper ] },

	fox =>
	{
		category => [ Animal, Hunter ],
		sound    => [ "barks" ],
		act =>
		{
			trots => { location => Terrestrial },
		},
	},
	bear =>
	{
		category => [ Animal ],
		sound    => [ "howls" ],
		act      =>
		{
			fishes => { location => Aquatic },
		},
	},
	wolf =>
	{
		category => [ Animal, Hunter ],
		sound    => [ "howls" ],
	},
	cat =>
	{
		category => [ Animal, Hunter ],
		sound    => [ "purrs", "yowls" ],
		act =>
		{
			washes   => { location => Terrestrial },
			sits     => { location => Terrestrial },
		},
	},
	rabbit =>
	{
		category => [ Animal ],
		act =>
		{
			sniffs   => { location => Terrestrial },
			grazes   => { location => Terrestrial },
		},
	},

	"young girl" =>
	{
		category => [ Human ],
		act =>
		{
			skips =>
			{
				location => Terrestrial,
				non_adjectival => 1,
			}
		},
	},
	"old man" =>
	{
		category => [ Human ],
		act =>
		{
			swims =>
			{
				location => Aquatic,
				non_adjectival => 1,
			}
		},
	},
	lover =>
	{
		category => [ Human ],
		minimum  => 2,
		maximum  => 2,
		act =>
		{
			kisses => { location => Terrestrial, },
			cuddles => { location => Terrestrial, },
			touch => { location => Terrestrial, },
			whisper => { location => Terrestrial, },
			dance => { location => Terrestrial, },
		},
	},
};

categories
{
	Human =>
	{
		act =>
		{
			dies =>
			{
				associations => "die depart exit",
				location => Terrestrial,
			},
			quarrels =>
			{
				associations => "argument",
				location => Terrestrial,
				minimum => 2,
				synonyms => [qw(bickers argues banters fights)],
			},
			contends =>
			{
				associations => "argument",
				location => Terrestrial,
				minimum => 2,
				synonyms => [qw(debates)],
				non_adjectival => 1,
			},
			sits =>
			{
				associations => "rest static stop",
				location => Terrestrial,
				non_adjectival => 1,
			},
			meets =>
			{
				associations => "join together",
				location => Terrestrial,
				minimum => 2,
				non_adjectival => 1,
				synonyms => [qw(encounters)],
			},
			laughs =>
			{
				associations => "happy",
				location => Terrestrial,
				non_adjectival => 1,
			},
			parts =>
			{
				associations => "leave left miss",
				location => Terrestrial,
				minimum => 2,
			},
			departs =>
			{
				associations => "leave left miss",
				location => Terrestrial,
			},
			weeps =>
			{
				associations => "NEG",
				location => Terrestrial,
			},
			sighs =>
			{
				associations => "NEG",
				location => Terrestrial,
			},
			embraces =>
			{
				associations => "join together with",
				location => Terrestrial,
				minimum => 2,
				maximum => 2,
			},
		},
	},
	Animal =>
	{
		act =>
		{
			sits =>
			{
				associations => "static",
				location => Terrestrial,
			},
			walks =>
			{
				associations => "gone",
				location => Terrestrial,
				non_adjectival => 1,
			},
			watches =>
			{
				associations => "see",
				location => Terrestrial,
				non_adjectival => 1,
			},
			waits =>
			{
				associations => "wait",
				location => Terrestrial,
				non_adjectival => 1,
			},
			eats =>
			{
				associations => 'eat consume use',
				location => Terrestrial,
				non_adjectival => 1,
			}
		},
	},

	Hunter =>
	{
		act =>
		{
			crouches => { location => Terrestrial },
			prowls   => { location => Terrestrial },
			stalks   => { location => Terrestrial },
			leaps    => { location => Terrestrial },
		},
	},
	Fish =>
	{
		act =>
		{
			darts =>
			{
				location => Aquatic,
			},
			swims =>
			{
				location => Aquatic,
				non_adjectival => 1,
			},
		},
	},
	Leaper =>
	{
		act => { leaps => { location => Exoaquatic } },
	},
	Bird =>
	{
		act =>
		{
			flies =>
			{
				location => Aerial,
				direction => Any,
			},
			nests =>
			{
				location => Arborial,
			},
		},
	},
};

tree qw( oak elm willow maple she-oak );

fruit_tree qw( cherry apple lemon );

place ( "Mount Fuji", "a temple",  "the Emperor's palace",
        "a dojo", "the Shaolin temple", "a farmer's cottage",
        "the village", "the town square", "the harbor",
        "Bill Clinton's office", "a monastry", "the market-place",
      );


# LOAD USER-DEFINED DATA

if (-f $USER_CONFIG_FILE)
{
	no strict;
	do $USER_CONFIG_FILE;
}

@Coy::nouns = keys %$Coy::agent;

expand_categories;
expand_synonyms;

# print STDERR "Nouns: ", scalar @Coy::nouns, "\n";

}

# AND FINALLY, INSTALL IT ALL...

my $nested = -1;

$SIG{__WARN__} = sub
{
	local $SIG{__WARN__};
	$nested++;
	warn with_haiku(@_) unless $nested;
	warn @_ if $nested;
	$nested--;
};

$SIG{__DIE__}  = sub
{
	local $SIG{__DIE__};
	$nested++;
	die with_haiku(@_) unless $nested;
	die @_ if $nested;
	$nested--;
};

1;


__END__

=head1 NAME

Coy - Like Carp only prettier

=head1 SYNOPSIS

    # In your application:
    # ====================

	    use Coy;

	    warn "There seems to be a problem";

	    die "Looks like it might be fatal";


    # You can add vocab in the $HOME/.coyrc file:
    # ===========================================
	    
	    noun {
			wookie =>
			{
				category => [ Sentient ],
				sound    => [ "roars", "grunts", "bellows" ],
				act      =>
				{
					sits   => { location => Arborial },

					fights => { minimum => 2,
						    association => "argument",
						  },
				},
			},

	         };

	    category {
			Sentient =>
			{
				act =>
				{
					quarrels =>
					{
						associations => "argument",
						location => Terrestrial,
						minimum => 2,
						synonyms => [qw(bickers argues)],
					},
					laughs =>
					{
						associations => "happy",
						location => Terrestrial,
						non_adjectival => 1,
					},
				},
			}
		     };

	    personage "R2D2";
	    personage "Darth Vader";

	    place "Mos Eisley";
	    place "the Death Star"; 

	    tree "Alderaan mangrove";
	    fruit_tree "Wookie-oak";


    # You can also select a different syllable counter via .coyrc
    # ===========================================================
	    
	    use Lingua::EN::Syllables::syllable;
	    syllable_counter  "Lingua::EN::Syllables::syllable";

    # or

	    use Lingua::EN::Syllables::syllable;
	    syllable_counter  \&Lingua::EN::Syllables::syllable;

    # or

	    syllable_counter  sub { return 1 };  # FAST BUT INACCURATE



=head1 DESCRIPTION

	Error messages 
	strewn across my terminal. 
	A vein starts to throb. 

	Their reproof adds the 
	injury of insult to 
	the shame of failure. 

	When a program dies 
	what you need is a moment 
	of serenity. 

	The Coy.pm 
	module brings tranquillity 
	to your debugging. 

	The module alters 
	the behaviour of C<die> and 
	C<warn> (and C<croak> and C<carp>). 

	It also provides 
	C<transcend> and C<enlighten> -- two 
	Zen alternatives. 

	Like Carp.pm, 
	Coy reports errors from the 
	caller's point-of-view. 

	But it prefaces 
	the bad news of failure with 
	a soothing haiku. 

	The haiku are not 
	"canned", but are generated 
	freshly every time. 

	Once the haiku is 
	complete, it's prepended to 
	the error message. 

	Execution of 
	the original call to
	C<die> or C<warn> resumes. 

	Haiku and error
	message strew across my screen. 
	A smile starts to form. 


=head1 EXTENDING THE VOCABULARY

	Any code placed in
	"$ENV{HOME}/.coyrc"
	runs at compile-time.

	You can use that file
	to extend Coy.pm's
	vocabulary.

	The "SYNOPSIS" at
	the start of this POD shows how
	you might set it up.

	(Eventually
	 this section will detail the
	 full mechanism.)
	

=head1 CHANGING THE SYLLABLE COUNTER

	If you don't like the
	syllable counter you can
	always replace it.

	Coy provides a sub
	called C<syllable_counter> for
	that very purpose.

	It is passed a sub
	reference. That sub is then used
	to count syllables.

	You can also pass
	the sub's I<name> (that is, pass a
	symbolic reference).

	The new counter sub
	should take a string and return
	its syllable count.

	C<syllable_counter>
	can be called from your code, or
	from .coyrc.


=head1 BUGS AND LIMITATIONS

	In its current form, 
	the module has four problems 
	and limitations:

	* Vocabulary: 
	  The list of nouns and verbs is 
	  too small at present.

	  This limits the range 
	  of topics that the haiku 
	  produced can cover. 

	  That in turn leads to 
	  tell-tale repetition (which 
	  fails the Turing test). 

	  Extending the range 
	  of words Coy.pm can 
	  use is no problem 
  
	  (though finding the time 
	  and the creativity 
	  required may be :-).

	  Users of Coy are
	  encouraged to add their own
	  vocabulary.

	  (See the "SYNOPSIS",
	   and also "EXTENDING THE
	   VOCABULARY").
	
	
	* Associations: 
	  The vocabulary has 
	  too few topic links.

	  Hence it's often not 
	  able to find relevant 
	  words for a message. 

	  This leads to haiku 
	  utterly unrelated 
	  to the error text. 
  
	  Again, there is no 
	  technical difficulty 
	  in adding more links: 
  
	  Defining enough 
	  associations isn't 
	  hard, just tedious.

	  User-specified
	  vocabularies can solve
	  this problem as well.
 	 
	
	* Limited grammar: 
	  The number of syntactic 
	  templates is too small.
  
	  This leads to haiku 
	  that are (structurally, at 
	  least) monotonous. 
  
	  Yet again, this needs 
	  no technical solution, 
	  just time and effort. 
  
	  Of course, such enhanced 
	  templates might require richer 
	  vocabulary. 
  
	  For example, verb 
	  predicates would need extra 
	  database structure: 
  
	  Each verb entry would 
	  have to be extended with 
	  links to object nouns.
 	 
	
	* Syllable counting: 
	  This is perhaps the major 
	  problem at present.
  
	  The algorithmic 
	  syllable counter is still 
	  being developed. 
    
	  It is currently 
	  around 96% 
	  accurate (per word). 
  
	  This means that correct 
	  syllable counts for haiku 
	  can't be guaranteed. 
  
	  Syllable counts for 
	  single words are correct to 
	  plus-or-minus 1. 
    
	  In a multi-word 
	  haiku these errors cancel 
	  out in most cases. 
  
	  Thus, the haiku tend 
	  to be correct within one 
	  or two syllables. 
  
	  As the syllable 
	  counter slowly improves, this 
	  problem will abate.

	  Alteratively,
	  you can choose to use your own
	  syllable counter.
  
	  (See above in the
	   section titled "CHANGING THE
	   SYLLABLE COUNTER".)


=head1 AUTHOR

	The Coy.pm
	module was developed by
	Damian Conway.

	And Michael G Schwern
	Carried it back from the dead
	And maintains it now.

=head1 BUGS

	Please report all bugs,
	suggestions as well as trouble
	to this URL:

L<http://rt.cpan.org/Public/Dist/Display.html?Name=Coy>

	The latest version
	Can be found for all to see
	Posted on github

L<http://github.com/schwern/coy/tree/master>


=head1 COPYRIGHT

        Copyright (c) 1998, 2009 Damian Conway. All Rights Reserved.
      This module is free software. It may be used, redistributed
      and/or modified under the terms of the Perl Artistic License
           (see http://www.perl.com/perl/misc/Artistic.html)



=cut
