# NAME

Data::Random::String::Matches - Generate random strings matching a regex

# SYNOPSIS

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

# DESCRIPTION

This module generates random strings that match a given regular expression pattern.
It parses the regex pattern and intelligently builds matching strings, supporting
a wide range of regex features.

# SUPPORTED REGEX FEATURES

## Character Classes

- Basic classes: `[a-z]`, `[A-Z]`, `[0-9]`, `[abc]`
- Negated classes: `[^a-z]`
- Ranges: `[a-zA-Z0-9]`
- Escape sequences in classes: `[\d\w]`

## Escape Sequences

- `\d` - digit \[0-9\]
- `\w` - word character \[a-zA-Z0-9\_\]
- `\s` - whitespace
- `\D` - non-digit
- `\W` - non-word character
- `\t`, `\n`, `\r` - tab, newline, carriage return

## Quantifiers

- `{n}` - exactly n times
- `{n,m}` - between n and m times
- `{n,}` - n or more times
- `+` - one or more (1-5 times)
- `*` - zero or more (0-5 times)
- `?` - zero or one

## Grouping and Alternation

- `(...)` - capturing group
- `(?:...)` - non-capturing group
- `|` - alternation (e.g., `cat|dog|bird`)
- `\1`, `\2`, etc. - backreferences

## Other

- `.` - any character (printable ASCII)
- Literal characters
- `^` and `$` anchors (stripped during parsing)

# LIMITATIONS

- Lookaheads and lookbehinds ((?=...), (?!...)) are not supported
- Named groups ((?&lt;name>...)) are not supported
- Possessive quantifiers (\*+, ++) are not supported
- Unicode properties (\\p{L}, \\p{N}) are not supported
- Some complex nested patterns may not work correctly with smart parsing

# EXAMPLES

        # Email-like pattern
        my $gen = Data::Random::String::Matches->new(qr/[a-z]+@[a-z]+\.com/);

        # API key pattern
        my $gen = Data::Random::String::Matches->new(qr/^AIza[0-9A-Za-z_-]{35}$/);

        # Phone number
        my $gen = Data::Random::String::Matches->new(qr/\d{3}-\d{3}-\d{4}/);

        # Repeated pattern
        my $gen = Data::Random::String::Matches->new(qr/(\w{4})-\1/);

# METHODS

## new($regex, $length)

Creates a new generator. `$regex` can be a compiled regex (qr//) or a string.
`$length` is optional and defaults to 10 (used for fallback generation).

## generate($max\_attempts)

Generates a random string matching the regex. First tries smart parsing, then
falls back to brute force if needed. Tries up to `$max_attempts` times
(default 1000) before croaking.

## generate\_smart()

Parses the regex and builds a matching string directly. Faster and more reliable
than brute force, but may not handle all edge cases.

## generate\_many($count, $unique)

Generates multiple random strings matching the regex.

    my @strings = $gen->generate_many(10);           # 10 strings (may have duplicates)
    my @strings = $gen->generate_many(10, 1);        # 10 unique strings
    my @strings = $gen->generate_many(10, 'unique'); # 10 unique strings

    # Generate until you have 1000 unique codes
    my $gen = Data::Random::String::Matches->new(qr/[A-Z]{3}\d{4}/);
    my @codes = $gen->generate_many(1000, 'unique');

Parameters:

- `$count` - Number of strings to generate (required, must be positive)
- `$unique` - If true, ensures all generated strings are unique. May return fewer
than `$count` strings if uniqueness cannot be achieved within reasonable attempts.
Accepts any true value (1, 'unique', etc.)

Returns: List of generated strings

Dies: If count is not a positive integer

Warns: If unable to generate the requested number of unique strings

## get\_seed()

Gets the random seed for reproducible generation

## set\_seed($seed)

Sets the random seed for reproducible generation

## suggest\_simpler\_pattern()

Analyzes patterns and suggests improvements.

    my $suggestion = $gen->suggest_simpler_pattern();

    if ($suggestion) {
      print "Reason: $suggestion->{reason}\n";
      print "Better pattern: $suggestion->{pattern}\n" if $suggestion->{pattern};
      print "Tips:\n";
      print "  - $_\n" for @{$suggestion->{tips}};
    }

## validate($string)

Checks if a string matches the pattern without generating.

    if ($gen->validate('1234')) {
      print "Valid!\n";
    }

## pattern\_info()

Returns detailed information about the pattern.

    my $info = $gen->pattern_info();
    print "Complexity: $info->{complexity}\n";
    print "Min length: $info->{min_length}\n";
    print "Has Unicode: ", $info->{features}{has_unicode} ? "Yes" : "No", "\n";

`pattern_info` analyzes a regular expression to produce a structured summary of its characteristics,
including estimated string lengths, detected features, and an overall complexity rating.
It first calls `_estimate_length` to heuristically compute the minimum and maximum possible lengths of strings matching the pattern by scanning for literals,
character classes, and quantifiers.
It then detects the presence of advanced regex constructions such as alternation, lookahead or lookbehind assertions, named groups, and Unicode properties, storing them in a feature hash.
Finally, it calculates a rough "complexity" classification based on pattern length and detected features-returning a hash reference that describes the regex's structure, estimated lengths, and complexity level.

## create\_random\_string

For consistency with [Data::Random::String](https://metacpan.org/pod/Data%3A%3ARandom%3A%3AString).

    print Data::Random::String::Matches->create_random_string(length => 3, regex => '\d{3}'), "\n";

# AUTHOR

Nigel Horne, `<njh at nigelhorne.com>`

# SEE ALSO

- Test coverage report: [https://nigelhorne.github.io/Data-Random-String-Matches/coverage/](https://nigelhorne.github.io/Data-Random-String-Matches/coverage/)
- [String::Random](https://metacpan.org/pod/String%3A%3ARandom)
- [Regexp::Genex](https://metacpan.org/pod/Regexp%3A%3AGenex)

# LICENCE AND COPYRIGHT

Copyright 2025 Nigel Horne.

Usage is subject to licence terms.

The licence terms of this software are as follows:

- Personal single user, single computer use: GPL2
- All other users (including Commercial, Charity, Educational, Government)
  must apply in writing for a licence for use from Nigel Horne at the
  above e-mail.
