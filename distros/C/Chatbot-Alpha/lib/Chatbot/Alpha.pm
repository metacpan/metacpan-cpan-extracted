package Chatbot::Alpha;

our $VERSION = '2.05';

# For debugging...
use strict;
use warnings;
use Data::Dumper;

# Syntax checking
use Chatbot::Alpha::Syntax;

sub new {
	my $proto = shift;

	my $class = ref($proto) || $proto;

	my $self = {
		debug   => 0,
		version => $VERSION,
		default => "I'm afraid I don't know how to reply to that!",
		stream  => undef,
		syntax  => new Chatbot::Alpha::Syntax(
			syntax   => 'strict',
			denytype => 'allow_all',
		),
		verify  => 1,
		@_,
	};

	bless ($self,$class);

	return $self;
}

sub version {
	my $self = shift;

	return $self->{version};
}

sub debug {
	my ($self,$msg) = @_;

	# Only show if debug mode is on.
	if ($self->{debug} == 1) {
		print STDOUT "Alpha::Debug // $msg\n";
	}

	return 1;
}

sub loadFolder {
	my ($self,$dir) = (shift,shift);
	my $type = shift || undef;

	# Open the folder.
	opendir (DIR, $dir) or return 0;
	foreach my $file (sort(grep(!/^\./, readdir(DIR)))) {
		if (defined $type) {
			if ($file !~ /\.$type$/i) {
				next;
			}
		}

		my $load = $self->loadFile ("$dir/$file");
		return $load unless $load == 1;
	}
	closedir (DIR);

	return 1;
}

sub stream {
	my ($self,$code) = @_;

	# Must have Alpha code defined.
	if (!defined $code) {
		warn "Chatbot::Alpha::stream - no code included with call!\n";
		return 0;
	}

	# Stream the code.
	$self->{stream} = $code;
	$self->loadFile (undef,1);
}

sub loadFile {
	my ($self,$file,$stream) = @_;
	$stream = 0 unless defined $stream;
	$stream = 0 if defined $file;

	$file = '(Streamed)' unless defined $file;

	$self->debug ("loadFile called for file: $file");

	# Open the file.
	my @data = ();
	if ($stream != 1) {
		# Syntax check this.
		if ($self->{verify} == 1) {
			$self->{syntax}->check ($file);
		}

		open (FILE, "$file") or return 0;
		@data = <FILE>;
		close (FILE);
		chomp @data;
	}
	else {
		@data = split ("\n", $self->{stream});
	}

	# (Re)-define temporary variables.
	my $topic = 'random';
	my $inReply = 0;
	my $trigger = '';
	my $counter = 0;
	my $ccount = 0; # Conditions counter
	my $holder = 0;
	my $num = 0;

	# Go through the file.
	foreach my $line (@data) {
		$num++;
		$self->debug ("Line $num: $line");
		next if length $line == 0;
		next if $line =~ /^\//;
		$line =~ s/^\s+//g;
		$line =~ s/^\t+//g;
		$line =~ s/^\s//g;
		$line =~ s/^\t//g;

		# Get the command off.
		my ($command,$data) = split(//, $line, 2);

		# Go through commands...
		if ($command eq '>') {
			$self->debug ("> Command - Label Begin!");
			$data =~ s/^\s//g;
			my ($type,$text) = split(/\s+/, $data, 2);
			if ($type eq 'topic') {
				$self->debug ("Topic set to $data");
				$topic = $text;
			}
		}
		elsif ($command eq '<') {
			$self->debug ("< Command - Label Ender!");
			$data =~ s/^\s//g;
			if ($data eq 'topic' || $data eq '/topic') {
				$self->debug ("Topic reset");
				$topic = 'random';
			}
		}
		elsif ($command eq '+') {
			$self->debug ("+ Command - Reply Trigger!");
			if ($inReply == 1) {
				# Reset the topics?
				if ($topic =~ /^_that_/i) {
					$topic = 'random';
				}

				# New reply.
				$inReply = 0;
				$trigger = '';
				$counter = 0;
				$holder = 0;
			}

			# Reply trigger.
			$inReply = 1;

			$data =~ s/^\s//g;
			$data =~ s/([^A-Za-z0-9 ])/\\$1/ig;
			$data =~ s/\\\*/\(\.\*\?\)/ig;
			$trigger = $data;
			$self->debug ("Trigger: $trigger");

			# Set the trigger's topic.
			$self->{_replies}->{$topic}->{$trigger}->{topic} = $topic;
			$self->{_syntax}->{$topic}->{$trigger}->{ref} = "$file line $num";
		}
		elsif ($command eq '~') {
			$self->debug ("~ Command - Regexp Trigger!");
			if ($inReply == 1) {
				# Reset the topics?
				if ($topic =~ /^_that_/i) {
					$topic = 'random';
				}

				# New reply.
				$inReply = 0;
				$trigger = '';
				$counter = 0;
				$holder = 0;
			}

			# Reply trigger.
			$inReply = 1;

			$data =~ s/^\s//g;
			$trigger = $data;
			$self->debug ("Trigger: $trigger");

			# Set the trigger's topic.
			$self->{_replies}->{$topic}->{$trigger}->{topic} = $topic;
			$self->{_syntax}->{$topic}->{$trigger}->{ref} = "$file line $num";
		}
		elsif ($command eq '%') {
			$self->debug ("% Command - That!");
			if ($inReply != 1) {
				# Error.
				$self->debug ("Syntax error at $file line $num");
				return -2;
			}

			# That tag.
			$data =~ s/^\s//g;

			# Set the topic to "_that_$data"
			$topic = "_that_$data";
		}
		elsif ($command eq '-') {
			$self->debug ("- Command - Reply Response!");
			if ($inReply != 1) {
				# Error.
				$self->debug ("Syntax Error at $file line $num");
				return -2;
			}

			# Reply response.
			$counter++;
			$data =~ s/^\s//g;

			$self->{_replies}->{$topic}->{$trigger}->{$counter} = $data;
			$self->debug ("Reply #$counter : $data");
			$self->{_syntax}->{$topic}->{$trigger}->{$counter}->{ref} = "$file line $num";
		}
		elsif ($command eq '^') {
			$self->debug ("^ Command - Reply Continuation");
			$data =~ s/^\s//g;
			$self->{_replies}->{$topic}->{$trigger}->{$counter} .= $data;
		}
		elsif ($command eq '@') {
			# A redirect.
			$self->debug ("\@ Command - A Redirect!");
			if ($inReply != 1) {
				# Error.
				$self->debug ("Syntax Error at $file line $num");
				return -2;
			}
			$data =~ s/^\s//g;
			$self->{_replies}->{$topic}->{$trigger}->{redirect} = $data;
			$self->{_syntax}->{$topic}->{$trigger}->{redirect}->{ref} = "$file line $num";
		}
		elsif ($command eq '*') {
			# A conditional.
			$self->debug ("* Command - A Conditional!");
			if ($inReply != 1) {
				# Error.
				$self->debug ("Syntax Error at $file line $num");
				return -2;
			}
			# Get the conditional's data.
			$data =~ s/^\s//g;
			$self->debug ("Counter: $ccount");
			$self->{_replies}->{$topic}->{$trigger}->{conditions}->{$ccount} = $data;
			$self->{_syntax}->{$topic}->{$trigger}->{conditions}->{$ccount}->{ref} = "$file line $num";
			$ccount++;
		}
		elsif ($command eq '&') {
			# A conversation holder.
			$self->debug ("\& Command - A Conversation Holder!");
			if ($inReply != 1) {
				# Error.
				$self->debug ("Syntax Error at $file line $num");
				return -2;
			}

			# Save this.
			$data =~ s/^\s//g;
			$self->debug ("Holder: $holder");
			$self->{_replies}->{$topic}->{$trigger}->{convo}->{$holder} = $data;
			$self->{_syntax}->{$topic}->{$trigger}->{convo}->{$holder}->{ref} = "$file line $num";
			$holder++;
		}
		elsif ($command eq '#') {
			# A system command.
			$self->debug ("\# Command - A System Command!");
			if ($inReply != 1) {
				# Error.
				$self->debug ("Syntax Error at $file line $num");
				return -2;
			}

			# Save this.
			$data =~ s/^\s//g;
			$self->debug ("System Command: $data");
			$self->{_replies}->{$topic}->{$trigger}->{system}->{codes} .= $data;
			$self->{_syntax}->{$topic}->{$trigger}->{system}->{codes}->{ref} = "$file line $num";
		}
	}

	return 1;
}

sub sortReplies {
	my $self = shift;

	# Reset loop.
	$self->{loops} = 0;

	# Fail if replies hadn't been loaded.
	return 0 unless exists $self->{_replies};

	# Delete the replies array (if it exists).
	if (exists $self->{_array}) {
		delete $self->{_array};
	}

	$self->debug ("Sorting the replies...");

	# Count replies.
	my $count = 0;

	# Go through each reply.
	foreach my $topic (keys %{$self->{_replies}}) {
		# Sort by number of whole words.
		my $sort = {
			def => [],
			0 => [],
			1 => [],
			2 => [],
			3 => [],
			4 => [],
			5 => [],
			6 => [],
			7 => [],
			8 => [],
			9 => [],
			10 => [],
			11 => [],
			12 => [],
			13 => [],
			14 => [],
			15 => [],
			16 => [],
			unknown => [],
		};

		my @trigNorm = ();
		my @trigWild = ();
		foreach my $key (keys %{$self->{_replies}->{$topic}}) {
			$self->debug ("Sorting key $key");
			$count++;
			# If it's a wildcard...
			if ($key =~ /\*/) {
				# See how many full words it has.
				my @words = split(/\s/, $key);
				my $cnt = 0;
				foreach my $word (@words) {
					$word =~ s/\s//g;
					next unless length $word;
					if ($word !~ /\*/) {
						# A whole word.
						$cnt++;
					}
				}

				# Save to wildcard array.
				$self->debug ("Key $key has a wildcard ($cnt words)!");

				if (exists $sort->{$cnt}) {
					push (@{$sort->{$cnt}}, $key);
				}
				else {
					push (@{$sort->{unknown}}, $key);
				}
			}
			else {
				# Save to normal array.
				$self->debug ("Key $key is normal!");
				push (@{$sort->{def}}, $key);
			}
		}

		# Merge the arrays.
		$self->{_array}->{$topic} = [
			@{$sort->{def}},
			@{$sort->{16}},
			@{$sort->{15}},
			@{$sort->{14}},
			@{$sort->{13}},
			@{$sort->{12}},
			@{$sort->{11}},
			@{$sort->{10}},
			@{$sort->{9}},
			@{$sort->{8}},
			@{$sort->{7}},
			@{$sort->{6}},
			@{$sort->{5}},
			@{$sort->{4}},
			@{$sort->{3}},
			@{$sort->{2}},
			@{$sort->{1}},
			@{$sort->{unknown}},
			@{$sort->{0}},
		];
	}

	# Save the count.
	$self->{replycount} = $count;

	# Return true.
	return 1;
}

sub setVariable {
	my ($self,$var,$value) = @_;
	return 0 unless defined $var;
	return 0 unless defined $value;

	$self->{vars}->{$var} = $value;
	return 1;
}

sub removeVariable {
	my ($self,$var) = @_;
	return 0 unless defined $var;

	delete $self->{vars}->{$var};
	return 1;
}

sub clearVariables {
	my $self = shift;

	delete $self->{vars};
	return 1;
}

sub search {
	my ($self,$msg) = @_;

	my @results = ();

	# Sort replies if it hasn't already been done.
	if (!exists $self->{_array}) {
		$self->sortReplies;
	}

	# Too many loops?
	if ($self->{loops} >= 15) {
		$self->{loops} = 0;
		my $topic = 'random';
		return "ERR: Deep Recursion (15+ loops in reply set) at $self->{_syntax}->{$topic}->{$msg}->{redirect}->{ref}";
	}

	my %star;
	my $reply;

	# Make sure some replies are loaded.
	if (!exists $self->{_replies}) {
		return "ERROR: No replies have been loaded!";
	}

	# Go through each reply.
	foreach my $topic (keys %{$self->{_array}}) {
		$self->debug ("On Topic: $topic");

		foreach my $in (@{$self->{_array}->{$topic}}) {
			$self->debug ("On Reply Trigger: $in");

			if ($msg =~ /^$in$/i) {
				# Add to the results.
				my $t = $in;
				$t =~ s/\(\.\*\?\)/\*/g;
				push (@results, "+ $t (topic: $topic) at $self->{_syntax}->{$topic}->{$in}->{ref}");
			}
		}
	}

	return @results;
}

sub reply {
	my ($self,$id,$msg) = @_;

	# Sort replies if it hasn't already been done.
	if (!exists $self->{_array}) {
		$self->sortReplies;
	}

	# Create history.
	if (!exists $self->{users}->{$id}->{history}) {
		$self->{users}->{$id}->{history}->{input} = [ '', 'undefined', 'undefined', 'undefined', 'undefined',
			'undefined', 'undefined', 'undefined', 'undefined', 'undefined' ];
		$self->{users}->{$id}->{history}->{reply} = [ '', 'undefined', 'undefined', 'undefined', 'undefined',
			'undefined', 'undefined', 'undefined', 'undefined', 'undefined' ];
	}

	# Too many loops?
	if ($self->{loops} >= 15) {
		$self->{loops} = 0;
		my $topic = $self->{users}->{$id}->{topic} || 'random';
		return "ERR: Deep Recursion (15+ loops in reply set) at $self->{_syntax}->{$topic}->{$msg}->{redirect}->{ref}";
	}

	my %star;
	my $reply;

	for (my $i = 1; $i <= 9; $i++) {
		$star{$i} = '';
	}

	# Topics?
	$self->{users}->{$id}->{topic} ||= 'random';

	$self->{users}->{$id}->{last} = '' unless exists $self->{users}->{$id}->{last};
	$self->{users}->{$id}->{that} = '' unless exists $self->{users}->{$id}->{that};

	$self->debug ("User Topic: $self->{users}->{$id}->{topic}");

	$self->debug ("Message: $msg");

	# Make sure some replies are loaded.
	if (!exists $self->{_replies}) {
		return "ERROR: No replies have been loaded!";
	}

	# See if this topic has any "that's" associated with it.
	my $thatTopic = "_that_$self->{users}->{$id}->{that}";
	my $isThat = 0;
	my $keepTopic = '';

	# Go through each reply.
	foreach my $topic (keys %{$self->{_array}}) {
		$self->debug ("On Topic: $topic");

		my $lastSent = $self->{users}->{$id}->{that};

		if ($isThat != 1 && length $lastSent > 0 && exists $self->{_replies}->{$thatTopic}->{$msg}) {
			# It does exist. Set this as the topic so this reply should be matched.
			$isThat = 1;
			$keepTopic = $self->{users}->{$id}->{topic};
			$self->{users}->{$id}->{topic} = $thatTopic;
		}

		next unless $topic eq $self->{users}->{$id}->{topic};

		foreach my $in (@{$self->{_array}->{$topic}}) {
			$self->debug ("On Reply Trigger: $in");

			# Conversations?
			my $found_convo = 0;
			$self->debug ("Checking for conversation holders...");
			if (exists $self->{_replies}->{$topic}->{$in}->{convo}) {
				$self->debug ("This reply has a convo holder!");
				# See if this was our conversation.
				my $h = 0;
				for ($h = 0; exists $self->{_replies}->{$topic}->{$in}->{convo}->{$h}; $h++) {
					last if $found_convo == 1;
					$self->debug ("On Holder #$h");

					my $next = $self->{_replies}->{$topic}->{$in}->{convo}->{$h};

					$self->debug ("Last Msg: $self->{users}->{$id}->{last}");

					# See if this was for their last message.
					if ($self->{users}->{$id}->{last} =~ /^$in$/i) {
						if (!exists $self->{_replies}->{$topic}->{$in}->{convo}->{$self->{users}->{$id}->{hold}}) {
							delete $self->{users}->{$id}->{hold};
							$self->{users}->{$id}->{last} = $msg;
							last;
						}

						# Give the reply.
						$reply = $self->{_replies}->{$topic}->{$in}->{convo}->{$self->{users}->{$id}->{hold}};
						$self->{users}->{$id}->{hold}++;
						$star{msg} = $msg;
						$msg = $in;
						$found_convo = 1;
					}
				}
			}
			last if defined $reply;

			if ($msg =~ /^$in$/i) {
				$self->debug ("Reply Matched!");
				$star{1} = $1; $star{2} = $2; $star{3} = $3; $star{4} = $4; $star{5} = $5;
				$star{6} = $6; $star{7} = $7; $star{8} = $8; $star{9} = $9;

				# A redirect?
				$self->debug ("Checking for a redirection...");
				if (exists $self->{_replies}->{$topic}->{$in}->{redirect}) {
					$self->debug ("Redirection found! Getting new reply for $self->{_replies}->{$topic}->{$in}->{redirect}...");
					my $redirect = $self->{_replies}->{$topic}->{$in}->{redirect};

					# Filter in wildcards.
					for (my $s = 0; $s <= 9; $s++) {
						$redirect =~ s/<star$s>/$star{$s}/ig;
					}

					$redirect =~ s/<star>/$star{1}/ig if exists $star{1};

					$self->{loops}++;
					$reply = $self->reply ($id,$redirect);
					return $reply;
				}

				# Conditionals?
				$self->debug ("Checking for conditionals...");
				if (exists $self->{_replies}->{$topic}->{$in}->{conditions}) {
					$self->debug ("This response DOES have conditionals!");
					# Go through each one.
					my $c = 0;
					for ($c = 0; exists $self->{_replies}->{$topic}->{$in}->{conditions}->{$c}; $c++) {
						$self->debug ("On Condition #$c");
						last if defined $reply;

						my $conditional = $self->{_replies}->{$topic}->{$in}->{conditions}->{$c};
						my ($condition,$happens) = split(/::/, $conditional, 2);
						$self->debug ("Condition: $condition");
						my ($var,$value) = split(/=/, $condition, 2);
						$self->debug ("var = $var; value = $value");

						if (exists $self->{vars}->{$var}) {
							$self->debug ("Variable asked for exists!");
							# Check values.
							if (($var =~ /^[0-9]/ && $self->{vars}->{$var} eq $value) || ($self->{vars}->{$var} eq $value)) {
								$self->debug ("Values match!");
								# True. This is the reply.
								$reply = $happens;
								$self->debug ("Reply = $reply");
							}
						}
					}
				}

				last if defined $reply;

				# A reply?
				return "ERROR: No reply set for \"$msg\"!" unless exists $self->{_replies}->{$topic}->{$in}->{1};

				my @replies;
				foreach my $key (keys %{$self->{_replies}->{$topic}->{$in}}) {
					next if $key =~ /[^0-9]/;
					push (@replies,$self->{_replies}->{$topic}->{$in}->{$key});
				}

				$reply = 'INFLOOP';
				while ($reply =~ /^(INFLOOP|HASH|SCALAR|ARRAY)/i) {
					$self->{loops}++;
					$reply = $replies [ int(rand(scalar(@replies))) ];
					if ($self->{loops} >= 20) {
						$reply = "ERR: Infinite Loop near $self->{_syntax}->{$topic}->{$in}->{ref}";
					}
				}

				$self->debug ("Checking system commands...");
				# Execute system commands?
				if (exists $self->{_replies}->{$topic}->{$in}->{system}->{codes}) {
					$self->debug ("Found System: $self->{_replies}->{$topic}->{$in}->{system}->{codes}");
					my $eval = eval ($self->{_replies}->{$topic}->{$in}->{system}->{codes}) || $@;
					$self->debug ("Eval Result: $eval");
				}
			}
		}
	}

	# Reset "That" topics.
	if ($isThat == 1) {
		$self->{users}->{$id}->{topic} = $keepTopic;
		$self->{users}->{$id}->{that} = '<<undef>>';
	}

	# A reply?
	if (defined $reply) {
		# Filter in stars...
		my $i;
		for ($i = 1; $i <= 9; $i++) {
			$reply =~ s/<star$i>/$star{$i}/ig;
		}
		$reply =~ s/<star>/$star{1}/ig if exists $star{1};
		$reply =~ s/<msg>/$star{msg}/ig if exists $star{msg};
	}
	else {
		# Were they in a topic?
		if ($self->{users}->{$id}->{topic} ne 'random') {
			if (exists $self->{_array}->{$self->{users}->{$id}->{topic}}) {
				$reply = "ERR: No Reply Matched in Topic $self->{users}->{$id}->{topic}";
			}
			else {
				$self->{users}->{$id}->{topic} = 'random';
				$reply = "ERR: No Reply (possibly void topic?)";
			}
		}
		else {
			$reply = "ERR: No Reply Found";
		}
	}

	# History tags.
	$reply =~ s/<input(\d)>/$self->{users}->{$id}->{history}->{input}->[$1]/g;
	$reply =~ s/<reply(\d)>/$self->{users}->{$id}->{history}->{reply}->[$1]/g;

	# String modifiers.
	while ($reply =~ /\{(formal|uppercase|lowercase|sentence)\}(.*?)\{\/(formal|uppercase|lowercase|sentence)\}/i) {
		my ($type,$string) = ($1,$2);
		$type = lc($type);
		my $o = $string;
		$string = &stringUtil ($type,$string);
		$o =~ s/([^A-Za-z0-9 =<>])/\\$1/g;
		$reply =~ s/\{$type\}$o\{\/$type\}/$string/ig;
	}

	# A topic setter?
	if ($reply =~ /\{topic=(.*?)\}/i) {
		my $to = $1;
		if ($to eq 'random') {
			$self->{users}->{$id}->{topic} = '';
		}
		else {
			$self->{users}->{$id}->{topic} = $to;
		}
		$reply =~ s/\{topic=(.*?)\}//g;
	}

	# Sub-replies?
	while ($reply =~ /\{\@(.*?)\}/i) {
		my $o = $1;
		my $trig = $o;
		$trig =~ s/^\s+//g;
		$trig =~ s/\s$//g;

		my $resp = $self->reply ($id,$trig);

		$reply =~ s/\{\@$o\}/$resp/i;
	}

	# Randomness?
	while ($reply =~ /\{random\}(.*?)\{\/random\}/i) {
		my $text = $1;
		my @options = ();

		# Pipes?
		if ($text =~ /\|/) {
			@options = split(/\|/, $text);
		}
		else {
			@options = split(/\s+/, $text);
		}

		my $rep = $options [ int(rand(scalar(@options))) ];
		$reply =~ s/\{random\}(.*?)\{\/random\}/$rep/i;
	}

	# Update history.
	shift (@{$self->{users}->{$id}->{history}->{input}});
	shift (@{$self->{users}->{$id}->{history}->{reply}});
	unshift (@{$self->{users}->{$id}->{history}->{input}}, $msg);
	unshift (@{$self->{users}->{$id}->{history}->{reply}}, $reply);
	unshift (@{$self->{users}->{$id}->{history}->{input}}, '');
	unshift (@{$self->{users}->{$id}->{history}->{reply}}, '');
	pop (@{$self->{users}->{$id}->{history}->{input}});
	pop (@{$self->{users}->{$id}->{history}->{reply}});

	# Format the bot's reply.
	my $simple = lc($reply);
	$simple =~ s/[^A-Za-z0-9 ]//g;
	$simple =~ s/^\s+//g;
	$simple =~ s/\s$//g;

	# Save this message.
	$self->debug ("Saving this as last msg...");
	$self->{users}->{$id}->{that} = $simple;
	$self->{users}->{$id}->{last} = $msg;
	$self->{users}->{$id}->{hold} ||= 0;

	# Reset the loop timer.
	$self->{loops} = 0;

	# There SHOULD be a reply now.
	# So, return it.
	return $reply;
}

sub stringUtil {
	my ($type,$string) = @_;

	if ($type eq 'uppercase') {
		return uc($string);
	}
	elsif ($type eq 'lowercase') {
		return lc($string);
	}
	elsif ($type eq 'sentence') {
		$string = lc($string);
		return ucfirst($string);
	}
	elsif ($type eq 'formal') {
		$string = lc($string);
		my @words = split(/ /, $string);
		my @out = ();
		foreach my $word (@words) {
			push (@out, ucfirst($word));
		}
		return join (" ", @out);
	}
	else {
		return $string;
	}
}

1;
__END__

=head1 NAME

Chatbot::Alpha - A simple chatterbot brain.

=head1 SYNOPSIS

  use Chatbot::Alpha;
  
  # Create a new Alpha instance.
  my $alpha = new Chatbot::Alpha();
  
  # Load replies from a directory.
  $alpha->loadFolder ("./replies");
  
  # Load an additional response file.
  $alpha->loadFile ("./more_replies.txt");
  
  # Input even more replies directly from Perl.
  $alpha->stream ("+ what is alpha\n"
                . "- Alpha, aka Chatbot::Alpha, is a chatterbot brain created by AiChaos Inc.\n\n"
                . "+ who created alpha\n"
                . "- Chatbot::Alpha was created by Cerone Kirsle.");
  
  # Get a response.
  my $reply = $alpha->reply ("user", "hello alpha");

=head1 DESCRIPTION

The Alpha brain was developed by AiChaos, Inc. for our chatterbots. The Alpha brain's language is line-by-line,
command-driven. Alpha is a simplistic brain yet is very powerful for making impressive response systems.

B<Note: This module is obsolete!> Alpha was superceded by a more powerful language, rewritten from scratch,
called L<RiveScript>. Chatbot::Alpha was allowed (and will be allowed) to remain here only because there are
a few incompatibilities in the reply files. If you haven't used Alpha yet, I urge you to use RiveScript instead.
If you've already invested time in writing reply files for Alpha, know that this module isn't going anywhere.
However, this module is no longer actively maintained (and hasn't been in a number of years).

See L<RiveScript>.

=head1 METHODS

=head2 new (ARGUMENTS)

Creates a new Chatbot::Alpha object. Pass in any default arguments (in hash form). Default arguments are
B<debug> (debug mode; defaults to 0) and B<verify> (to run syntax checking, defaults to 1).

Returns a Chatbot::Alpha instance.

=head2 version

Returns the version number of the module.

=head2 loadFolder (DIRECTORY[, TYPES])

Loads a directory of response files. The directory name is required. TYPES is the file extension of your response files.
If TYPES is omitted, every file is considered a response file.

Just as a side note, the extension agreed upon for Alpha files is .CBA, but the extension is not important.

=head2 loadFile (FILE_PATH[, STREAM])

Loads a single file. The "loadFolder" method calls this for each valid file. If STREAM is 1, the current contents of
the stream cache will be loaded (assuming FILE_PATH is omitted). You shouldn't need to worry about using STREAM, see
the "stream" method below.

=head2 stream (ALPHA_CODE)

Inputs a set of Alpha code directly into the module ("streaming") rather than loading it from an external document.
See synopsis for an example.

=head2 sortReplies

Sorts the replies already loaded: solid triggers go first, followed by triggers containing wildcards. If you fail to
call this method yourself, it will be called automatically when "reply" is called.

B<Update with v 1.7> - Reply sorting method reprogrammed: items are sorted with solid triggers first, then those with
wildcards and 16 whole words, then 15 whole words, 14, etc. and then unknown triggers, followed lastly by those that
contain NO full words.

=head2 setVariable (VARIABLE, VALUE)

Sets an internal variable. These are used primarily in conditionals in your Alpha responses.

=head2 removeVariable (VARIABLE)

Removes an internal variable.

=head2 clearVariables

Clears all internal variables (only those set with set_variable).

=head2 reply (ID, MESSAGE)

Scans the loaded replies to find a response to MESSAGE. ID is a unique ID for the particular person requesting a response.
The ID is used for things such as topics and conversation holders. Returns a reply, or one of default_reply if a better
response wasn't found.

=head2 search (MESSAGE)

Scans the loaded replies to find any triggers that match MESSAGE. Will return an array containing every trigger that
matched the message, including their filenames and line numbers.

=head2 stringUtil (TYPE, STRING)

Called on internally for the string modification tags. TYPE would be uppercase, lowercase, formal, or sentence. String
would be the string to modify. Returns the modified string.

=head1 ALPHA LANGUAGE TUTORIAL

The Alpha response language is a line-by-line command-driven language. The first character on each line is the command
(prepent white spaces are ignored). Everything following the command are the command's arguments. The commands are as
follows:

=head2 + (Plus)

The + symbol indicates a trigger. Every Alpha reply begins with this command. The arguments are what the trigger is
(i.e. "hello chatbot"). If the message matches this trigger, then the rest of the response code is considered. Else,
the triggers are skipped over until a good match is found for the message.

=head2 ~ (Tilde)

The ~ command is another version of the trigger, added in version 2.03. The contents of this command would be a regexp
pattern. Any parts that would normally be put into $1 to $9 can be obtained in <star1> to <star9>.

Example:

  ~ i (would have|would\'ve) done it
  - Do you really think you <star1> done it?

Use either +TRIGGER B<or> ~REGEXP, but not both. If you use both for the same reply, the latter one will override.

=head2 % (Percent)

This is used as a "that" -- that is, an emulation of the <that> tag in AIML. The value of this would be Alpha's last
reply, lowercase and without any punctuation. There's an example of this in the example reply code below.

=head2 - (Minus)

The - symbol indicates a response to a trigger. This and all other commands (except for > and <) always go below the +
command. A single + and a single - will be a one-way question/answer scenario. If more than one - is used, they will
become random replies to the trigger. If conditionals are used, the -'s will be considered if each conditional is false.
If a conversation holder is used, the - will be the first reply sent in the conversation. See the example code below
for examples.

=head2 ^ (Carat)

The ^ symbol indicates a continuation of your last - reply. This command can only be used after a - command, and adds
its arguments to the end of the arguments of the last - command. See the example code for an example.

=head2 @ (At)

The @ symbol indicates a redirection. Alpha triggers are "dead-on" triggers, meaning pipes can't be used to make multiple
matchibles for one reply. In the case you would want more than one trigger (i.e. "hello" and "hey"), you use the @ command
to redirect them to eachother. See the example code below.

=head2 * (Asterisk)

The * command is for conditionals. At this time conditionals are very primative:

  * variable=value::this reply is sent back

More/better support for conditionals may or may not be added in the future.

=head2 & (Amperstand)

The & command is for conversation holders. Each & will be called in succession once the trigger has been matched. Each
message, no matter what it is, will call the next one down the line. This is also the rare case in which a "<msg>" tag
can be included in the response, for capturing the user's message. See the example code.

=head2 # (Pound)

The # command is for executing actual Perl codes within your Alpha responses. The # commands are executed last, after
all the other reply handling mechanisms are completed. So in this sense, it's always a good idea to include at least one
reply (-) to fall back on in case the Perl code fails.

=head2 > (Greater Than)

The > starts a labeled piece of code. At this time, the only label supported is "topic" -- see "TOPICS" below.

=head2 < (Less Than)

This command closes a label.

=head2 / (Forward Slash)

The / command is used for comments (actually two /'s is the standard, as in Java and C++).

=head1 ALPHA TAGS

These tags can be used within Alpha -REPLIES, some of which may be used also in @REDIRECTS.

=head2 <star>, <star1> - <star9>

Captures the patterns matched by wildcards in a reply trigger, from left to right. B<<star>> is an alias for
B<<star1>>.

=head2 <input1> - <input9>

Inserts the last 1 to 9 messages the user sent (1 being most recent).

=head2 <reply1> - <reply9>

Inserts the last 1 to 9 messages the BOT sent in reply (1 being most recent).

=head2 {topic=...}

Sets a topic. Set topic to B<random> to return to the default topic.

=head2 {@trigger}

Include a redirection within another response. Example:

  + * or something
  - Or something. {@<star1>}
  
  "Your stupid or something?"
  "Or something. At least I know the difference between "your" and "you're.""

=head2 {formal}...{/formal}

Formalizes A String (Makes Every Word Capitalized)

=head2 {sentence}...{/sentence}

Sentence-cases a string (only the first word is capitalized). Don't pass in multiple sentences if at all
possible. :)

=head2 {uppercase}...{/uppercase}

UPPERCASES A STRING.

=head2 {lowercase}...{/lowercase}

lowercases a string

=head2 {random}...{/random}

Inserts a bit of randomness within the reply. This has two uses: to insert a random single-word or to
insert a random sentence. If the pipe symbol is used, the latter will be the case.

Examples:

  + random test one
  - This {random}reply trigger command  {/random} has a random noun.

  + random test two
  - Fortune Cookie: {random}You will be rich and famous.|You will 
  ^ go to the moon.|You will suffer an agonizing death.{/random}

=head2 <msg>

This can only be used in &HOLDERS, it inserts the user's message (for example a knock-knock joke convo).

=head1 EXAMPLE ALPHA CODE

  // Test Replies

  // Chatbot-Alpha 2.0 - Mid-sentence redirections.
  + redirect test
  - If you said hello I would've said: {@hello} But if you said whats up I'd say: {@whats up}

  // Redirect test with <star1>.
  + i say *
  - Indeed you do say. {@<star1>}

  // Chatbot-Alpha 1.7 - A reply with continuation...
  + tell me a poem
  - Little Miss Muffet,\n
    ^ sat on her tuffet,\n
    ^ in a nonchalant sort of way.\n\n
    ^ With her forcefield around her,\n
    ^ the spider, the bounder\n
    ^ is not in the picture today.

  // Chatbot-Alpha 1.7 - Check syntax errors on deep recursion.
  + one
  @ two

  + two
  @ one

  // A standard reply to "hello", with multiple responses.
  + hello
  - Hello there!
  - What's up?
  - This is random, eh?

  // A "that" test.
  + i hate you
  - You're really mean... =(

  + sorry
  % youre really mean
  - Don't worry--it's okay. :-)

  // A test of having two of the same trigger in different topics.
  + sorry
  - Why are you sorry?

  // A simple one-reply response to "what's up"
  + whats up
  - Not much, you?

  // A test using <star1>
  + say *
  - Um.... "<star1>"

  // This reply is referred to below.
  + identify yourself
  - I am Alpha.

  // Refers the asker back to the reply above.
  + who are you
  @ identify yourself

  // Wildcard Tests
  + my name is *
  - Nice to meet you <star1>.
  + i am * years old
  - Many people are <star1>.

  // Conditionals Tests
  + am i your master
  * master=1::Yes, you are my master.
  - No, you are not my master.

  + is my name bob
  * name=bob::Yes, that's your name.
  - No your name is not Bob.

  // Perl Evaluation Test
  + what is 2 plus 2
  # $reply = "2 + 2 = 4";

  // A Conversation Holder: Knock Knock!
  + knock knock
  - Who's there?
  & <msg> who?
  & Ha! <msg>! That's a good one!

  // A Conversation Holder: Rambling!
  + are you crazy
  - I was crazy once.
  & They locked me away...
  & In a room with padded walls.
  & There were rats there...
  & Did I mention I was crazy once?

  // Regexp Trigger Tests
  ~ i (would have|would\'ve) done it
  - Do you really think you <star1> done it?

  ~ i am (\d) years old
  - A lot of people are <star1> years old.

  ~ i am ([^0-9]) years old
  - You're a "word" years old?

  // Random tests.
  + random test one
  - This {random}reply trigger command  {/random} has a random noun.

  + random test two
  - Fortune Cookie: {random}You will be rich and famous.|You will 
  ^ go to the moon.|You will suffer an agonizing death.{/random}

  // Topic Test
  + you suck
  - And you're very rude. Apologize now!{topic=apology}

  // 1.71 Test - Single wildcards should sort LAST, so this could be
  // used as a "I can't reply to that" reply.
  + *
  - Hm, I'm going to have to think about that one for a minute.
  - I'm sorry, but I can't answer that!
  - I really don't know what to say to that one...

  > topic apology

    + *
    - No, apologize for being so rude to me.

    // Set {topic=random} to return to the default topic.
    + sorry
    - See, that wasn't too hard. I'll forgive you.{topic=random}

  < topic

=head1 TOPICS

As seen in the example code, Chatbot::Alpha has support for topics.

=head2 Setting a Topic

To set a topic, use the {topic} tag in a response:

  + play hangman
  - Alright, let's play hangman.{topic=hangman}

Use the > and < commands (labels) to specify a section of code for the topic to exist in.

  > topic hangman
    + *
    - 500 Internal Error. Type "quit" to quit.
    # $reply = &main::hangman ($msg);

    + quit
    - Done playing hangman.{topic=random}
  < topic

The default topic is "random" -- setting the topic to random breaks out of code-defined
topics. When in a topic, any triggers that aren't in that topic are not available for
reply matching. In this way, you can have the same trigger many times but under different
topics without them interfering with one another.

=head1 PERL COMMANDS

The Perl command #CODE can be used to enhance your replies to perform things too complex for
Alpha alone to handle. The "hangman" example under TOPICS above is an example of how to call
on a subroutine from your main process and put its output into the reply.

=head2 Chatbot::Alpha Internal Variables

Here are the main variables you should be interested in when making complex replies with
the #CODE command:

  $reply - The final reply that the brain is going to return.
  $id    - The user ID of the one making the request.
  $msg   - The message that the user sent in.

=head1 CONTRADICTIONS

It's possible to run into errors with contradicting or conflicting code. For example, some
types of replies are very strict in how they're formatted. For example, a %THAT command must
come immediately following a trigger command. And a +TRIGGER and ~REGEXP should not both be
used at the same time, the latter call would override any others.

If you follow the syntax provided in the examples on this page, you should not expect to
run into any contradictions in your code. Perhaps in a later release of Chatbot::Alpha the
syntax checker will look for common errors such as these.

=head1 ERROR CATCHING

With Chatbot::Alpha 1.7, the module keeps filenames and line numbers with each command it finds
(kept in $alpha->{_syntax} in the same order as $alpha->{_replies}). In this way, internal errors
such as deep recursion can return filenames and line numbers. See the example code for a way to
provoke this error.

  ERR: Deep Recursion (15+ loops in reply set) at ./testreplies.txt line 17

=head1 CHATBOT-ALPHA 2.X

The following changes have been made from Chatbot-Alpha 1.x to 2.x

  - Methods have been renamed:
    load_folder     => loadFolder
    load_file       => loadFile
    sort_replies    => sortReplies
    set_variable    => setVariable
    remove_variable => removeVariable
    clear_variables => clearVariables

  - Methods that have been REMOVED:
    default_reply*

  - Alpha commands added:
    %THAT

  - Alpha commands changed:
    *CONDITION
    New format:
      *VAR=VALUE::REPLY

  * Set a trigger of just an asterisk to set up a fallback for when no better
    response is found. Example:

    + *
    - I don't know how to reply to your message!

=head1 KNOWN BUGS

  - Conversation holders aren't always perfect. If a different trigger
    was matched 100% dead-on, the conversation may become broken.
  - If a bogus topic is started (a topic with no responses) there is
    no handler for repairing the topic.

=head1 CHANGES

  Version 2.05
  - Added a mention that Alpha has been superceded by RiveScript.

  Version 2.04
  - Fixed up some Perl warnings within the code.
  - Renamed the example script to 'example.pl' to not confuse Makefile.

  Version 2.03
  - Added ~REGEXP command.
  - Added {random} tag.
  - Added more information about #CODE on manpage.
  - Updated Chatbot::Alpha::Syntax to support the new ~REGEXP command.
  - Applied a patch to Syntax.pm to hopefully make automatic installation
    run more smoothly.

  Version 2.02
  - Mostly bug fixes in this release:
  - Added 'verify' argument to the new() constructor. If 1 (default),
    Chatbot::Alpha::Syntax is run on all files loaded. Set to 0 to avoid
    syntax checking (not recommended).
  - Fixed regexp bug with {formal}, {sentence}, {uppercase}, and {lowercase}.
    They should now function correctly even if their values have odd characters
    in them that would've previously screwed up the regexp parser.
  - Chatbot::Alpha::Syntax updated. See its manpage for details.
  - Rearranged a bit of the code so that <input> and <reply> would process
    before string tags.

  Version 2.01
  - Added string tags {formal}, {sentence}, {uppercase}, {lowercase}
  - Added tags <input> and <reply> and alias <star>.
  - Fixed conditionals bug (conditionals wouldn't increment correctly so
    only the last condition remained in memory. Now multiple conditions
    can be used for one trigger... i.e. comparing gender to male/female
    in two different conditions).

  Version 2.00
  - Added some AIML emulation:
    - In-reply redirections (like <srai>):
         + * or something
         - Or something. {@<star1>}
    - "That" kind of support.
         + i hate you
         - You're really mean... =(

         + sorry
         % youre really mean
         - Don't worry--it's okay. :-)
  - Renamed all methods to be alternatingCaps instead of with underscores.
  - Chatbot::Alpha::Syntax supports the newly-added commands.
  - Fixed conditionals, should work more efficiently now:
    - Format changed to *VARIABLE=VALUE::HAPPENS
    - Does numeric == for numbers, or eq for strings... = better matching.

  Version 1.71
  - Redid sorting method. Sometimes triggers such as I AM * would match
    before I AM * YEARS OLD.

  Version 1.7
  - Chatbot::Alpha::Syntax added.
  - ^ command added.
  - Module keeps filenames and line numbers internally, so on internal
    errors such as 'Deep Recursion' and 'Infinite Loop' it can point you
    to the source of the problem.
  - $alpha->search() method added.

  Version 1.61
  - Chatbot::Alpha::Sort completed.

  Version 1.6
  - Created Chatbot::Alpha::Sort for sorting your Alpha documents.

  Version 1.5
  - Added "stream" method, revised POD.

  Version 1.4
  - Fixed bug with wildcard subsitutitons.

  Version 1.3
  - Added the ">" and "<" commands, now used for topics.

  Version 1.2
  - "sortReplies" method added

  Version 1.1
  - Fixed a bug in reply matching with wildcards.
  - Added a "#" command for executing System Commands.

  Version 1.0
  - Initial release.

=head1 SEE ALSO

L<RiveScript>, the successor to Alpha.

L<Chatbot::Alpha::Tutorial>

L<Chatbot::Alpha::Sort>

=head1 AUTHOR

Casey Kirsle, http://www.cuvou.com/

=head1 COPYRIGHT AND LICENSE

    Chatbot::Alpha - A simple chatterbot brain.
    Copyright (C) 2005  Casey Kirsle

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program; if not, write to the Free Software
    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

=cut
