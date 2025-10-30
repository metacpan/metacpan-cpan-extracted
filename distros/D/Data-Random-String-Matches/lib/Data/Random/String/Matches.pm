package Data::Random::String::Matches;

use 5.010;

use strict;
use warnings;

use Carp qw(carp croak);
use Params::Get;
use utf8;

our $VERSION = '0.03';

=head1 NAME

Data::Random::String::Matches - Generate random strings matching a regex

=head1 SYNOPSIS

	use Data::Random::String::Matches;

	# Create a generator with regex and optional length
	my $gen = Data::Random::String::Matches->new(qr/[A-Z]{3}\d{4}/, 7);

	# Generate a matching string
	my $str = $gen->generate();
	print $str;  # e.g., "XYZ1234"

	# Alternation
	my $gen2 = Data::Random::String::Matches->new(qr/(cat|dog|bird)/);
	my $animal = $gen2->generate_smart();  # "cat", "dog", or "bird"

	# Backreferences
	my $gen3 = Data::Random::String::Matches->new(qr/(\w{3})-\1/);
	my $str3 = $gen3->generate_smart();  # e.g., "abc-abc"

	# Groups and quantifiers
	my $gen4 = Data::Random::String::Matches->new(qr/(ha){2,4}/);
	my $laugh = $gen4->generate_smart();  # "haha", "hahaha", or "hahahaha"

	# Unicode
	$gen = Data::Random::String::Matches->new(qr/\p{L}{5}/);

	# Named captures
	$gen = Data::Random::String::Matches->new(qr/(?<year>\d{4})-\k<year>/);

	# Possessive
	$gen = Data::Random::String::Matches->new(qr/\d++[A-Z]/);

	# Lookaheads
	$gen = Data::Random::String::Matches->new(qr/\d{3}(?=[A-Z])/);

	# Combined
	$gen = Data::Random::String::Matches->new(
    		qr/(?<prefix>\p{Lu}{2})\d++\k<prefix>(?=[A-Z])/
	);

	# Consistency with Legacy software
	print Data::Random::String::Matches->create_random_string(length => 3, regex => '\d{3}'), "\n";

=head1 DESCRIPTION

This module generates random strings that match a given regular expression pattern.
It parses the regex pattern and intelligently builds matching strings, supporting
a wide range of regex features.

=head1 SUPPORTED REGEX FEATURES

=head2 Character Classes

=over 4

=item * Basic classes: C<[a-z]>, C<[A-Z]>, C<[0-9]>, C<[abc]>

=item * Negated classes: C<[^a-z]>

=item * Ranges: C<[a-zA-Z0-9]>

=item * Escape sequences in classes: C<[\d\w]>

=back

=head2 Escape Sequences

=over 4

=item * C<\d> - digit [0-9]

=item * C<\w> - word character [a-zA-Z0-9_]

=item * C<\s> - whitespace

=item * C<\D> - non-digit

=item * C<\W> - non-word character

=item * C<\t>, C<\n>, C<\r> - tab, newline, carriage return

=back

=head2 Quantifiers

=over 4

=item * C<{n}> - exactly n times

=item * C<{n,m}> - between n and m times

=item * C<{n,}> - n or more times

=item * C<+> - one or more (1-5 times)

=item * C<*> - zero or more (0-5 times)

=item * C<?> - zero or one

=back

=head2 Grouping and Alternation

=over 4

=item * C<(...)> - capturing group

=item * C<(?:...)> - non-capturing group

=item * C<|> - alternation (e.g., C<cat|dog|bird>)

=item * C<\1>, C<\2>, etc. - backreferences

=back

=head2 Other

=over 4

=item * C<.> - any character (printable ASCII)

=item * Literal characters

=item * C<^> and C<$> anchors (stripped during parsing)

=back

=head1 LIMITATIONS

=over 4

=item * Lookaheads and lookbehinds ((?=...), (?!...)) are not supported

=item * Named groups ((?<name>...)) are not supported

=item * Possessive quantifiers (*+, ++) are not supported

=item * Unicode properties (\p{L}, \p{N}) are not supported

=item * Some complex nested patterns may not work correctly with smart parsing

=back

=head1 EXAMPLES

	# Email-like pattern
	my $gen = Data::Random::String::Matches->new(qr/[a-z]+@[a-z]+\.com/);

	# API key pattern
	my $gen = Data::Random::String::Matches->new(qr/^AIza[0-9A-Za-z_-]{35}$/);

	# Phone number
	my $gen = Data::Random::String::Matches->new(qr/\d{3}-\d{3}-\d{4}/);

	# Repeated pattern
	my $gen = Data::Random::String::Matches->new(qr/(\w{4})-\1/);

=head1 METHODS

=head2 new($regex, $length)

Creates a new generator. C<$regex> can be a compiled regex (qr//) or a string.
C<$length> is optional and defaults to 10 (used for fallback generation).

=cut

sub new {
	my ($class, $regex, $length) = @_;

	croak 'Regex pattern is required' unless defined $regex;

	# Convert string to regex if needed
	my $regex_obj = ref($regex) eq 'Regexp' ? $regex : qr/$regex/;

	my $self = {
		regex	 => $regex_obj,
		regex_str => "$regex",
		length	=> $length || 10,
		backrefs	=> {},  # Store backreferences
		named_refs => {},	 # Store named captures
	};

	return bless $self, $class;
}

=head2 generate($max_attempts)

Generates a random string matching the regex. First tries smart parsing, then
falls back to brute force if needed. Tries up to C<$max_attempts> times
(default 1000) before croaking.

=cut

sub generate {
	my ($self, $max_attempts) = @_;
	$max_attempts //= 1000;

	my $regex = $self->{regex};
	my $length = $self->{length};

	# First try the smart approach
	my $str = eval { $self->_build_from_pattern($self->{regex_str}) };
	if (defined $str && $str =~ /^$regex$/) {
		return $str;
	}

	# If smart approach failed, show warning in debug mode
	if ($ENV{DEBUG_REGEX_GEN} && $@) {
		warn "Smart generation failed: $@";
	}

	# Fall back to brute force with character set matching
	for (1 .. $max_attempts) {
		$str = $self->_random_string_smart($length);
		return $str if $str =~ /^$regex$/;
	}

	croak "Failed to generate matching string after $max_attempts attempts. Pattern: $self->{regex_str}";
}

sub _random_string_smart {
	my ($self, $len) = @_;

	my $regex_str = $self->{regex_str};

	# Detect common patterns and generate appropriate characters
	my @chars;

	if ($regex_str =~ /\\d/ || $regex_str =~ /\[0-9\]/ || $regex_str =~ /\[\^[^\]]*[A-Za-z]/) {
		# Digit patterns
		@chars = ('0'..'9');
	} elsif ($regex_str =~ /\[A-Z\]/ || $regex_str =~ /\[A-Z[^\]]*\]/) {
		# Uppercase patterns
		@chars = ('A'..'Z');
	} elsif ($regex_str =~ /\[a-z\]/ || $regex_str =~ /\[a-z[^\]]*\]/) {
		# Lowercase patterns
		@chars = ('a'..'z');
	} elsif ($regex_str =~ /\\w/ || $regex_str =~ /\[a-zA-Z0-9_\]/) {
		# Word characters
		@chars = ('a'..'z', 'A'..'Z', '0'..'9', '_');
	} else {
		# Default to printable ASCII
		@chars = map { chr($_) } (33 .. 126);
	}

	my $str = '';
	$str .= $chars[int(rand(@chars))] for (1 .. $len);

	return $str;
}

=head2 generate_smart()

Parses the regex and builds a matching string directly. Faster and more reliable
than brute force, but may not handle all edge cases.

=cut

sub generate_smart {
	my $self = $_[0];
	return $self->_build_from_pattern($self->{regex_str});
}

=head2 generate_many($count, $unique)

Generates multiple random strings matching the regex.

    my @strings = $gen->generate_many(10);           # 10 strings (may have duplicates)
    my @strings = $gen->generate_many(10, 1);        # 10 unique strings
    my @strings = $gen->generate_many(10, 'unique'); # 10 unique strings

    # Generate until you have 1000 unique codes
    my $gen = Data::Random::String::Matches->new(qr/[A-Z]{3}\d{4}/);
    my @codes = $gen->generate_many(1000, 'unique');

Parameters:

=over 4

=item * C<$count> - Number of strings to generate (required, must be positive)

=item * C<$unique> - If true, ensures all generated strings are unique. May return fewer
than C<$count> strings if uniqueness cannot be achieved within reasonable attempts.
Accepts any true value (1, 'unique', etc.)

=back

Returns: List of generated strings

Dies: If count is not a positive integer

Warns: If unable to generate the requested number of unique strings

=cut

sub generate_many {
	my ($self, $count, $unique) = @_;

	croak 'Count must be a positive integer' unless defined $count && $count > 0;

	my @results;

	if ($unique) {
		# Generate unique strings
		my %seen;
		my $attempts = 0;
		my $max_attempts = $count * 100;	# Reasonable limit

		while (keys %seen < $count && $attempts < $max_attempts) {
			my $str = $self->generate();
			$seen{$str} = 1;
			$attempts++;
		}

		if (keys %seen < $count) {
			carp 'Only generated ', (scalar keys %seen), " unique strings out of $count requested";
		}

		@results = keys %seen;
	} else {
		# Generate any strings (may have duplicates)
		push @results, $self->generate() for (1 .. $count);
	}

	return @results;
}

=head2 get_seed()

Gets the random seed for reproducible generation

=cut

sub get_seed {
	my $self = shift;

	return $self->{seed};
}

=head2 set_seed($seed)

Sets the random seed for reproducible generation

=cut

sub set_seed {
	my $self = shift;
	my $params = Params::Get::get_params('seed', \@_);
	my $seed = $params->{'seed'};

	croak 'Seed must be defined' unless defined $seed;

	srand($seed);
	$self->{seed} = $seed;

	return $self;
}

=head2 suggest_simpler_pattern()

Analyzes patterns and suggests improvements.

  my $suggestion = $gen->suggest_simpler_pattern();

  if ($suggestion) {
    print "Reason: $suggestion->{reason}\n";
    print "Better pattern: $suggestion->{pattern}\n" if $suggestion->{pattern};
    print "Tips:\n";
    print "  - $_\n" for @{$suggestion->{tips}};
  }

=cut

sub suggest_simpler_pattern {
	my $self = $_[0];

	my $pattern = $self->{regex_str};
	my $info = $self->pattern_info();

	# Check for patterns that are too complex
	if ($info->{complexity} eq 'very_complex') {
		return {
			pattern => undef,
			reason  => 'Pattern is very complex. Consider breaking it into multiple simpler patterns.',
			tips    => [
				'Split alternations into separate generators',
				'Avoid deeply nested groups',
				'Use fixed-length patterns when possible',
			],
		};
	}

	# Suggest removing unnecessary backreferences
	if ($info->{features}{has_backreferences} && $pattern =~ /(\(\w+\)).*\\\d+/) {
		my $simpler = $pattern;
		# Can't automatically simplify backreferences, but can suggest
		return {
			pattern => undef,
			reason  => 'Backreferences add complexity. Consider if you really need repeated groups.',
			tips    => [
				'If the repeated part doesn\'t need to match, use two separate patterns',
				'For validation, backreferences are great; for generation, they limit variation',
			],
		};
	}

	# Suggest fixed quantifiers instead of ranges
	if ($pattern =~ /\{(\d+),(\d+)\}/) {
		my ($min, $max) = ($1, $2);
		if ($max - $min > 10) {
			my $mid = int(($min + $max) / 2);
			my $simpler = $pattern;
			$simpler =~ s/\{\d+,\d+\}/\{$mid\}/;
			return {
				pattern => $simpler,
				reason  => "Large quantifier range {$min,$max} creates high variability. Consider fixed length {$mid}.",
				tips    => [
					'Fixed lengths are faster to generate',
					'If you need variety, generate multiple patterns with different fixed lengths',
				],
			};
		}
	}

	# Suggest limiting alternations
	if ($info->{features}{has_alternation}) {
		my @alts = split /\|/, $pattern;
		if (@alts > 10) {
			return {
				pattern => undef,
				reason  => 'Too many alternations (' . scalar(@alts) . '). Consider splitting into multiple patterns.',
				tips    => [
					'Create separate generators for different alternatives',
					'Group similar patterns together',
					'Use character classes [abc] instead of (a|b|c)',
				],
			};
		}

		# Check if alternations could be a character class
		if ($pattern =~ /\(([a-zA-Z])\|([a-zA-Z])\|([a-zA-Z])\)/) {
			my $chars = join('', $1, $2, $3);
			my $simpler = $pattern;
			$simpler =~ s/\([a-zA-Z]\|[a-zA-Z]\|[a-zA-Z]\)/[$chars]/;
			return {
				pattern => $simpler,
				reason  => 'Single-character alternations can be simplified to character classes.',
				tips    => [
					'Use [abc] instead of (a|b|c)',
					'Character classes are faster to process',
				],
			};
		}
	}

	# Suggest removing lookaheads/lookbehinds for generation
	if ($info->{features}{has_lookahead} || $info->{features}{has_lookbehind}) {
		my $simpler = $pattern;
		$simpler =~ s/\(\?[=!].*?\)//g;   # Remove lookaheads
		$simpler =~ s/\(\?<[=!].*?\)//g;  # Remove lookbehinds

		if ($simpler ne $pattern) {
			return {
				pattern => $simpler,
				reason  => 'Lookaheads/lookbehinds add complexity but don\'t contribute to generated strings.',
				tips    => [
					'Lookaheads are great for validation, not generation',
					'The simplified pattern generates the same strings',
				],
			};
		}
	}

	# Check for Unicode when ASCII would work
	if ($info->{features}{has_unicode} && $pattern =~ /\\p\{L\}/) {
		my $simpler = $pattern;
		$simpler =~ s/\\p\{L\}/[A-Za-z]/g;
		return {
			pattern => $simpler,
			reason  => 'Unicode \\p{L} can be simplified to [A-Za-z] if you only need ASCII letters.',
			tips    => [
				'ASCII patterns are faster',
				'Only use Unicode if you need non-ASCII characters',
			],
		};
	}

	# Check for overly long fixed strings
	if ($pattern =~ /([a-zA-Z]{20,})/) {
		return {
			pattern => undef,
			reason  => 'Pattern contains very long fixed literal strings. Consider if you need such specific patterns.',
			tips    => [
				'Use variables instead of long literals',
				'Break into smaller patterns',
			],
		};
	}

	# Pattern seems reasonable
	return undef;
}

=head2 validate($string)

Checks if a string matches the pattern without generating.

  if ($gen->validate('1234')) {
    print "Valid!\n";
  }

=cut

sub validate {
	my $self = shift;
	my $params = Params::Get::get_params('string', \@_);
	my $string = $params->{'string'};

	croak('String must be defined') unless defined $string;

	my $regex = $self->{regex};
	return $string =~ /^$regex$/;
}

=head2 pattern_info()

Returns detailed information about the pattern.

  my $info = $gen->pattern_info();
  print "Complexity: $info->{complexity}\n";
  print "Min length: $info->{min_length}\n";
  print "Has Unicode: ", $info->{features}{has_unicode} ? "Yes" : "No", "\n";

C<pattern_info> analyzes a regular expression to produce a structured summary of its characteristics,
including estimated string lengths, detected features, and an overall complexity rating.
It first calls C<_estimate_length> to heuristically compute the minimum and maximum possible lengths of strings matching the pattern by scanning for literals,
character classes, and quantifiers.
It then detects the presence of advanced regex constructions such as alternation, lookahead or lookbehind assertions, named groups, and Unicode properties, storing them in a feature hash.
Finally, it calculates a rough "complexity" classification based on pattern length and detected features-returning a hash reference that describes the regex's structure, estimated lengths, and complexity level.

=cut

sub pattern_info {
	my $self = $_[0];

	return $self->{'_pattern_info_cache'} if $self->{'_pattern_info_cache'};

	my $pattern = $self->{'regex_str'};

	# Calculate approximate min/max lengths
	my ($min_len, $max_len) = $self->_estimate_length($pattern);

	# Detect pattern features
	my %features = (
		has_alternation     => ($pattern =~ /\|/ ? 1 : 0),
		has_backreferences  => ($pattern =~ /(\\[1-9]|\\k<)/ ? 1 : 0),
		has_unicode         => ($pattern =~ /\\p\{/ ? 1 : 0),
		has_lookahead       => ($pattern =~ /\(\?[=!]/ ? 1 : 0),
		has_lookbehind      => ($pattern =~ /\(\?<[=!]/ ? 1 : 0),
		has_named_groups    => ($pattern =~ /\(\?</ ? 1 : 0),
		has_possessive      => ($pattern =~ /(?:[+*?]\+|\{\d+(?:,\d*)?\}\+)/ ? 1 : 0),
	);

	my $info = {
		pattern             => $pattern,
		min_length          => $min_len,
		max_length          => $max_len,
		estimated_length    => int(($min_len + $max_len) / 2),
		features            => \%features,
		complexity          => $self->_calculate_complexity(\%features, $pattern),
	};

	$self->{'_pattern_info_cache'} = $info;

	return $info;
}

sub _estimate_length {
	my ($self, $pattern) = @_;

	# Remove anchors and modifiers
	$pattern =~ s/^\(\?\^?[iumsx-]*:(.*)\)$/$1/;
	$pattern =~ s/^\^//;
	$pattern =~ s/\$//;

	my $min = 0;
	my $max = 0;

	# Simple heuristic - count fixed characters and quantifiers
	my $last_was_atom = 0;	# Handle cases like \d{3} where the quantifier modifies the atom count
	while ($pattern =~ /([^+*?{}\[\]\\])|\\[dwsWDN]|\[([^\]]+)\]|\{(\d+)(?:,(\d+))?\}/g) {
		if (defined $1 || (defined $2 && $2)) {
			$min++;
			$max++;
			$last_was_atom = 1;
		} elsif (defined $3) {
			if ($last_was_atom) {
				# Replace the last atom’s contribution
				$min += $3 - 1;
				$max += (defined $4 ? $4 : $3) - 1;
				$last_was_atom = 0;
			} else {
				# No preceding atom? assume standalone
				$min += $3;
				$max += defined $4 ? $4 : $3;
			}
		}
	}

	# Account for +, *, ?
	my $plus_count = () = $pattern =~ /\+/g;
	my $star_count = () = $pattern =~ /\*/g;
	my $question_count = () = $pattern =~ /\?/g;

	$min += $plus_count;  # + means at least 1
	$max += ($plus_count * 5) + ($star_count * 5);  # Assume max 5 repetitions
	$min -= $question_count;  # ? makes things optional

	$min = 0 if $min < 0;
	$max = $min + 50 if $max < $min;  # Ensure max >= min

	return ($min, $max);
}

sub _calculate_complexity {
	my ($self, $features, $pattern) = @_;

	my $score = 0;

	# Base complexity from pattern length
	$score += length($pattern) / 10;

	# Add complexity for features
	$score += 2 if $features->{has_alternation};
	$score += 3 if $features->{has_backreferences};
	$score += 2 if $features->{has_unicode};
	$score += 2 if $features->{has_lookahead};
	$score += 2 if $features->{has_lookbehind};
	$score += 1 if $features->{has_named_groups};
	$score += 1 if $features->{has_possessive};

	# Classify
	return 'simple'   if $score < 3;
	return 'moderate' if $score < 7;
	return 'complex'  if $score < 12;
	return 'very_complex';
}

sub _build_from_pattern {
	my ($self, $pattern) = @_;

	# Reset backreferences for each generation
	$self->{backrefs} = {};
	$self->{named_refs} = {};
	$self->{group_counter} = 0;

	# Remove regex delimiters and modifiers
	# Handle (?^:...), (?i:...), (?-i:...) etc
	$pattern =~ s/^\(\?\^?[iumsx-]*:(.*)\)$/$1/;

	# Remove anchors (they're handled by the regex match itself)
	$pattern =~ s/^\^//;
	$pattern =~ s/\$//;

	return $self->_parse_sequence($pattern);
}

sub _parse_sequence {
	my ($self, $pattern) = @_;

	my $result = '';
	my $i = 0;
	my $len = length($pattern);

	while ($i < $len) {
		my $char = substr($pattern, $i, 1);

		if ($char eq '\\') {
			# Escape sequence
			$i++;
			my $next = substr($pattern, $i, 1);

			if ($next =~ /[1-9]/) {
				# Backreference
				my $ref_num = $next;
				if (exists $self->{backrefs}{$ref_num}) {
					$result .= $self->{backrefs}{$ref_num};
				} else {
					croak "Backreference \\$ref_num used before group defined";
				}
			} elsif ($next eq 'k' && substr($pattern, $i+1, 1) eq '<') {
				# Named backreference \k<name>
				my $end = index($pattern, '>', $i+2);
				my $name = substr($pattern, $i+2, $end-$i-2);
				if (exists $self->{named_refs}{$name}) {
					$result .= $self->{named_refs}{$name};
				} else {
					croak "Named backreference \\k<$name> used before group defined";
				}
				$i = $end;
			} elsif ($next eq 'p' && substr($pattern, $i+1, 1) eq '{') {
				# Unicode property \p{L}, \p{N}, etc.
				my $end = index($pattern, '}', $i+2);
				my $prop = substr($pattern, $i+2, $end-$i-2);
				my ($generated, $new_i) = $self->_handle_quantifier($pattern, $end, sub {
					$self->_unicode_property_char($prop);
				});
				$result .= $generated;
				$i = $new_i;
			} elsif ($next eq 'd') {
				my ($generated, $new_i) = $self->_handle_quantifier($pattern, $i, sub { int(rand(10)) }, 1);
				$result .= $generated;
				$i = $new_i;
			} elsif ($next eq 'w') {
				my ($generated, $new_i) = $self->_handle_quantifier($pattern, $i, sub {
					my @chars = ('a'..'z', 'A'..'Z', '0'..'9', '_');
					$chars[int(rand(@chars))];
				}, 1);
				$result .= $generated;
				$i = $new_i;
			} elsif ($next eq 's') {
				my ($generated, $new_i) = $self->_handle_quantifier($pattern, $i, sub { ' ' }, 1);
				$result .= $generated;
				$i = $new_i;
			} elsif ($next eq 'D') {
				my ($generated, $new_i) = $self->_handle_quantifier($pattern, $i, sub {
					my @chars = map { chr($_) } grep { chr($_) !~ /\d/ } (33..126);
					$chars[int(rand(@chars))];
				});
				$result .= $generated;
				$i = $new_i;
			} elsif ($next eq 'W') {
				my ($generated, $new_i) = $self->_handle_quantifier($pattern, $i, sub {
					my @chars = map { chr($_) } grep { chr($_) !~ /\w/ } (33..126);
					$chars[int(rand(@chars))];
				});
				$result .= $generated;
				$i = $new_i;
			} elsif ($next eq 't') {
				$result .= "\t";
			} elsif ($next eq 'n') {
				$result .= "\n";
			} elsif ($next eq 'r') {
				$result .= "\r";
			} else {
				$result .= $next;
			}
			$i++;
		} elsif ($char eq '[') {
			# Character class
			my $end = $self->_find_matching_bracket($pattern, $i);
			croak 'Unmatched [' if $end == -1;

			my $class = substr($pattern, $i+1, $end-$i-1);
			my ($generated, $new_i) = $self->_handle_quantifier($pattern, $end, sub {
				$self->_random_from_class($class);
			}, 1);
			$result .= $generated;
			$i = $new_i + 1;
		} elsif ($char eq '(') {
			# Group - could be various types
			my $end = $self->_find_matching_paren($pattern, $i);
			croak 'Unmatched (' if $end == -1;

			my $group_content = substr($pattern, $i+1, $end-$i-1);

			# Check for special group types
			my $is_capturing = 1;
			my $is_lookahead = 0;
			my $is_lookbehind = 0;
			my $is_negative = 0;
			my $group_name = undef;

			if ($group_content =~ /^\?:/) {
				# Non-capturing group
				$is_capturing = 0;
				$group_content = substr($group_content, 2);
			} elsif ($group_content =~ /^\?<([^>]+)>/) {
				# Named capture (?<name>...)
				$group_name = $1;
				$group_content = substr($group_content, length($1) + 3);
			} elsif ($group_content =~ /^\?=/) {
				# Positive lookahead (?=...)
				$is_lookahead = 1;
				$is_capturing = 0;
				$group_content = substr($group_content, 2);
			} elsif ($group_content =~ /^\?!/) {
				# Negative lookahead (?!...)
				$is_lookahead = 1;
				$is_negative = 1;
				$is_capturing = 0;
				$group_content = substr($group_content, 2);
			} elsif ($group_content =~ /^\?<=/) {
				# Positive lookbehind (?<=...)
				$is_lookbehind = 1;
				$is_capturing = 0;
				$group_content = substr($group_content, 3);
			} elsif ($group_content =~ /^\?<!/) {
				# Negative lookbehind (?<!...)
				$is_lookbehind = 1;
				$is_negative = 1;
				$is_capturing = 0;
				$group_content = substr($group_content, 3);
			}

			# Handle lookaheads/lookbehinds
			if ($is_lookahead) {
				# For positive lookahead, generate the pattern but don't advance
				# For negative lookahead, avoid the pattern
				if (!$is_negative) {
					# Generate what the lookahead expects but don't consume it
					# This is a simplification - we just note the constraint
				}
				# Lookaheads don't add to the result
				$i = $end + 1;
				next;
			} elsif ($is_lookbehind) {
				# Lookbehinds check what came before
				# For generation, we can mostly ignore them
				$i = $end + 1;
				next;
			}

			# Check for alternation
			my $generated;
			if ($group_content =~ /\|/) {
				$generated = $self->_handle_alternation($group_content);
			} else {
				$generated = $self->_parse_sequence($group_content);
			}

			# Store backreference if capturing
			if ($is_capturing) {
				$self->{group_counter}++;
				$self->{backrefs}{$self->{group_counter}} = $generated;

				if (defined $group_name) {
					$self->{named_refs}{$group_name} = $generated;
				}
			}

			# Handle quantifier after group (including possessive)
			my ($final_generated, $new_i) = $self->_handle_quantifier($pattern, $end, sub { $generated }, 1);
			$result .= $final_generated;
			$i = $new_i + 1;
		} elsif ($char eq '.') {
			# Any character (except newline)
			my ($generated, $new_i) = $self->_handle_quantifier($pattern, $i, sub {
				my @chars = map { chr($_) } (33 .. 126);
				$chars[int(rand(@chars))];
			});
			$result .= $generated;
			$i = $new_i + 1;
		} elsif ($char eq '|') {
			# Alternation at top level - just return what we have
			# (This is handled by _handle_alternation for groups)
			last;
		} elsif ($char =~ /[+*?]/ || $char eq '{') {
			# Quantifier without preceding element - shouldn't happen in valid regex
			croak "$pattern: Quantifier '$char' without preceding element";
		} elsif ($char =~ /[\w ]/) {
			# Literal character
			my ($generated, $new_i) = $self->_handle_quantifier($pattern, $i, sub { $char });
			$result .= $generated;
			$i = $new_i + 1;
		} else {
			# Other literal characters
			$result .= $char;
			$i++;
		}
	}

	return $result;
}

sub _handle_quantifier {
	my ($self, $pattern, $pos, $generator, $check_possessive) = @_;
	$check_possessive //= 1;  # Default to checking for possessive

	my $next = substr($pattern, $pos + 1, 1);
	my $is_possessive = 0;

	# Check for possessive quantifier (+)
	if ($check_possessive && $pos + 2 < length($pattern)) {
		my $after_next = substr($pattern, $pos + 2, 1);
		if (($next =~ /[+*?]/ || $next eq '}') && $after_next eq '+') {
			$is_possessive = 1;
		}
	}

	if ($next eq '{') {
		my $end = index($pattern, '}', $pos + 2);
		croak "Unmatched '{' at position $pos in pattern: $pattern" if ($end == -1);
		my $quant = substr($pattern, $pos + 2, $end - $pos - 2);

		# Check for possessive after }
		if ($check_possessive && $end + 1 < length($pattern) && substr($pattern, $end + 1, 1) eq '+') {
			$is_possessive = 1;
			$end++;
		}

		my $result = '';
		if ($quant =~ /^(\d+)$/) {
			# Exact: {n}
			$result .= $generator->() for (1 .. $1);
		} elsif ($quant =~ /^(\d+),(\d+)$/) {
			# Range: {n,m}
			my $count = $1 + int(rand($2 - $1 + 1));
			$result .= $generator->() for (1 .. $count);
		} elsif ($quant =~ /^(\d+),$/) {
			# Minimum: {n,}
			my $count = $1 + int(rand(5));
			$result .= $generator->() for (1 .. $count);
		}
		return ($result, $end);
	} elsif ($next eq '+') {
		# One or more (possessive: ++)
		my $actual_end = $pos + 1;
		if ($is_possessive) {
			$actual_end++;
		}
		my $count = 1 + int(rand(5));
		my $result = '';
		$result .= $generator->() for (1 .. $count);
		return ($result, $actual_end);
	} elsif ($next eq '*') {
		# Zero or more (possessive: *+)
		my $actual_end = $pos + 1;
		if ($is_possessive) {
			$actual_end++;
		}
		my $count = int(rand(6));
		my $result = '';
		$result .= $generator->() for (1 .. $count);
		return ($result, $actual_end);
	} elsif ($next eq '?') {
		# Zero or one (possessive: ?+)
		my $actual_end = $pos + 1;
		if ($is_possessive) {
			$actual_end++;
		}
		my $result = rand() < 0.5 ? $generator->() : '';
		return ($result, $actual_end);
	} else {
		# No quantifier
		return ($generator->(), $pos);
	}
}

sub _handle_alternation {
	my ($self, $pattern) = @_;

	# Split on | but respect groups
	my @alternatives;
	my $current = '';
	my $depth = 0;

	for my $char (split //, $pattern) {
		if ($char eq '(') {
			$depth++;
			$current .= $char;
		} elsif ($char eq ')') {
			$depth--;
			$current .= $char;
		} elsif ($char eq '|' && $depth == 0) {
			push @alternatives, $current;
			$current = '';
		} else {
			$current .= $char;
		}
	}
	push @alternatives, $current if length($current);

	# Choose one alternative randomly
	my $chosen = $alternatives[int(rand(@alternatives))];
	return $self->_parse_sequence($chosen);
}

sub _find_matching_bracket {
	my ($self, $pattern, $start) = @_;

	my $depth = 0;
	for (my $i = $start; $i < length($pattern); $i++) {
		my $char = substr($pattern, $i, 1);
		if ($char eq '[' && ($i == $start || substr($pattern, $i-1, 1) ne '\\')) {
			$depth++;
		} elsif ($char eq ']' && substr($pattern, $i-1, 1) ne '\\') {
			$depth--;
			return $i if $depth == 0;
		}
	}
	return -1;
}

sub _find_matching_paren {
	my ($self, $pattern, $start) = @_;

	my $depth = 0;
	for (my $i = $start; $i < length($pattern); $i++) {
		my $char = substr($pattern, $i, 1);
		my $prev = $i > 0 ? substr($pattern, $i-1, 1) : '';

		if ($char eq '(' && $prev ne '\\') {
			$depth++;
		} elsif ($char eq ')' && $prev ne '\\') {
			$depth--;
			return $i if $depth == 0;
		}
	}
	return -1;
}

sub _random_from_class {
	my ($self, $class) = @_;

	my @chars;

	# Handle negation
	my $negate = 0;
	if (substr($class, 0, 1) eq '^') {
		$negate = 1;
		$class = substr($class, 1);
	}

	# Parse character class with escape sequences
	my $i = 0;
	while ($i < length($class)) {
		my $char = substr($class, $i, 1);

		if ($char eq '\\') {
			$i++;
			my $next = substr($class, $i, 1);
			if ($next eq 'd') {
				push @chars, ('0'..'9');
			} elsif ($next eq 'w') {
				push @chars, ('a'..'z', 'A'..'Z', '0'..'9', '_');
			} elsif ($next eq 's') {
				push @chars, (' ', "\t", "\n");
			} elsif ($next eq 'p' && substr($class, $i+1, 1) eq '{') {
				# Unicode property in character class
				my $end = index($class, '}', $i+2);
				my $prop = substr($class, $i+2, $end-$i-2);
				push @chars, $self->_unicode_property_chars($prop);
				$i = $end;
			} else {
				push @chars, $next;
			}
		} elsif ($i + 2 < length($class) && substr($class, $i+1, 1) eq '-') {
			# Range
			my $end = substr($class, $i+2, 1);
			push @chars, ($char .. $end);
			$i += 2;	# Will be incremented again by loop, total +3
		} else {
			push @chars, $char;
		}
		$i++;
	}

	if ($negate) {
		my %excluded = map { $_ => 1 } @chars;
		@chars = grep { !$excluded{$_} } map { chr($_) } (33 .. 126);
	}

	return @chars ? $chars[int(rand(@chars))] : 'X';
}

sub _unicode_property_char {
	my ($self, $prop) = @_;
	my @chars = $self->_unicode_property_chars($prop);
	return @chars ? $chars[int(rand(@chars))] : 'X';
}

sub _unicode_property_chars {
	my ($self, $prop) = @_;

	# Common Unicode properties
	if ($prop eq 'L' || $prop eq 'Letter') {
		# Letters, skip × and ÷ which are symbols
		return ('a' .. 'z', 'A' .. 'Z', map { chr($_) } ((ord'À')..ord('Ö'), ord('Ø')..ord('ö'), ord('ø')..ord('ÿ')));
	} elsif ($prop eq 'N' || $prop eq 'Number') {
		# Numbers
		# return ('0' .. '9', map { chr($_) } (ord('①').. ord('⑳')));
		return ('0' .. '9');
	} elsif ($prop eq 'Lu' || $prop eq 'Uppercase_Letter') {
		# Uppercase letters, skip × which is not a letter
		return ('A' .. 'Z', map { chr($_) } (ord('À') .. ord('Ö'), ord('Ø') .. ord('Þ')));
	} elsif ($prop eq 'Ll' || $prop eq 'Lowercase_Letter') {
		# Lowercase letters, skip ÷ which is not a letter
		return ('a' .. 'z', map { chr($_) } (ord('à') .. ord('ö'), ord('ø') .. ord('ÿ')));
	} elsif ($prop eq 'P' || $prop eq 'Punctuation') {
		# Punctuation
		return ('.', ',', '!', '?', ';', ':', '-', '—', '…');
	} elsif ($prop eq 'S' || $prop eq 'Symbol') {
		# Symbols
		return ('$', '€', '£', '¥', '©', '®', '™', '°', '±', '×', '÷');
	} elsif ($prop eq 'Z' || $prop eq 'Separator') {
		# Separators
		return (' ', "\t", "\n");
	} elsif ($prop eq 'Nd' || $prop eq 'Decimal_Number') {
		# Decimal numbers
		return ('0'..'9');
	} else {
		# Unknown property - return letters as default
		return ('a'..'z', 'A'..'Z');
	}
}

=head2 create_random_string

For consistency with L<Data::Random::String>.

  print Data::Random::String::Matches->create_random_string(length => 3, regex => '\d{3}'), "\n";

=cut

sub create_random_string
{
	my $class = shift;
	my $params = Params::Get::get_params(undef, @_);

	my $regex = $params->{'regex'};
	my $length = $params->{'length'};

	return $class->new($regex, $length)->generate();
}

=head1 AUTHOR

Nigel Horne, C<< <njh at nigelhorne.com> >>

=head1 SEE ALSO

=over 4

=item * Test coverage report: L<https://nigelhorne.github.io/Data-Random-String-Matches/coverage/>

=item * L<String::Random>

=item * L<Regexp::Genex>

=back

=head1 LICENCE AND COPYRIGHT

Copyright 2025 Nigel Horne.

Usage is subject to licence terms.

The licence terms of this software are as follows:

=over 4

=item * Personal single user, single computer use: GPL2

=item * All other users (including Commercial, Charity, Educational, Government)
  must apply in writing for a licence for use from Nigel Horne at the
  above e-mail.

=back

=cut

1;
