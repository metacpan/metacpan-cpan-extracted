package Data::Validate::DNS::NAPTR::Regexp;

our $VERSION = '0.007';

use 5.008000;

use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

our @EXPORT_OK = qw(is_naptr_regexp naptr_regexp_error);

our @EXPORT = @EXPORT_OK;

my $last_error;

sub new {
	my ($class) = @_;

	return bless {}, $class;
}

sub _set_error {
	my ($where, $error) = @_;

	if ($where) {
		$where->{error} = $error;
	} else {
		$last_error = $error;
	}
}

sub error {
	my ($self) = @_;

	if ($self) {
		return $self->{error};
	} else {
		return $last_error;
	}
}

sub naptr_regexp_error {
	goto &error;
}

sub is_naptr_regexp {
	my ($self, $string) = @_;

	# Called as a function?
	if (defined $self && !ref $self) {
		$string = $self;

		$self = undef;

		$last_error = undef;
	} else {
		$self->{error} = undef;
	}

	if (!defined $string) {
		return 1;
	}

	if ($string =~ /\n/) {
		_set_error($self, "Contains new-lines");

		return 0;
	}

	# Convert from master-file format
	$string = _cstring_from_text($self, $string);

	if (!defined $string) {
		return 0;
	}

	# Empty string okay
	if (length $string == 0) {
		return 2;
	}

	if ($string =~ /\0/) {
		_set_error($self, "Contains null bytes");

		return 0;
	}

	$string =~ s/^(.)//;

	my $delim = $1;

	if ($delim =~ /^[0-9\\i\0]$/) {
		_set_error($self, "Delimiter ($delim) cannot be a flag, digit or null");

		return 0;
	}

	$delim = qr/\Q$delim\E/;

	# Convert double-backslashes to \0 for easy parsing.
	$string =~ s/\\\\/\0/g;

	# Now anything preceeded by a '\' is an escape sequence and can be 
	# ignored.

	unless ($string =~ /^
		(.*) (?<!\\) $delim
		(.*) (?<!\\) $delim
		(.*)$/x
	) {
		_set_error($self, "Bad syntax, missing replace/end delimiter");

		return 0;
	}

	my ($find, $replace, $flags) = ($1, $2, ($3 || ''));

	# Extra delimiters? Broken
	for my $f ($find, $replace, $flags) {
		if ($f =~ /(?<!\\)$delim/) {
			_set_error($self, "Extra delimiters");

			return 0;
		}
	}

	# Count backrefs in replace and make sure it matches up.
	my %brefs = map { $_ => 1 } $replace=~ /\\([0-9])/g;

	# And so ends our fun with escapes. Convert those nulls back to double 
	# backslashes
	$_ =~ s/\0/\\\\/g for ($find, $replace, $flags);

	# Validate flags
	for my $f (split //, $flags) {
		if ($f eq 'i') {
			# Ok!
		} else {
			_set_error($self, "Bad flag: $f");

			return 0;
		}
	}

	if ($brefs{0}) {
		_set_error($self, "Bad backref '0'");

		return 0;
	}

	# Validate capture count
	my $nsubs = _count_nsubs($find);

	my ($highest) = sort {$a <=> $b} keys %brefs;
	$highest ||= 0;

	if ($nsubs < $highest) {
		_set_error($self, "More backrefs in replacement than captures in match");

		return 0;
	}

	return 3;
}

# Convert master-file character string to data
sub _cstring_from_text {
	my ($self, $string) = @_;

	my $ret;

	# look for escape sequences, one at a time.
	# $1 is data before escape, $2 is \ if found, $3 is what's escaped
	while ($string =~ /\G(.*?)(\\(\d{1,3}|.)?)?/g) {
		my $before = $1;

		# Unescaped double quote?
		if ($before =~ /"/) {
			_set_error($self, 'Unescaped double quote');

			return;
		}

		$ret .= $before;

		# Got an escape
		if ($2) {
			my $seq = $3;

			if (!defined $seq) {
				_set_error($self, 'Trailing backslash');

				return;
			}

			# Some byte? Take it
			if ($seq !~ /\d/) {
				$ret .= $seq;
			} elsif ($seq !~ /\d\d\d/) {
				_set_error($self, "Bad escape sequence '\\$seq'");

				return;
			} elsif ($seq > 255) {
				_set_error($self, "Escape sequence out of range '\\$seq'");

				return;
			} else {
				# Good, take it
				$ret .= chr($seq);
			}
		}
	}

	if (length $ret > 255) {
		_set_error($self, "Must be less than 256 bytes");

		return;
	}

	return $ret;
}

# Count the number of captures in the RE
sub _count_nsubs {
	my ($regex) = @_;

	# Assume any ( not preceded by a \ is a capture start
	my @captures = $regex =~ /(?<!\\)\(/g;

	return 0+@captures;
}

1;
__END__

=head1 NAME

Data::Validate::DNS::NAPTR::Regexp - Validate the NAPTR Regexp field per RFC 2915 / RFC 3403 Section 4

=head1 VERSION

version 0.007

=head1 SYNOPSIS

Functional API (uses globals!!):

  use Data::Validate::DNS::NAPTR::Regexp;

  # Using <<'EOF' to mirror master-file format exactly
  my $regexp = <<'EOF';
  !test(something)!\\1!i
  EOF

  # Kill newline
  $regexp =~ s/\n//;

  if (is_naptr_regexp($regexp)) {
    print "Regexp '$regexp' is okay!"; 
  } else {
    print "Regexp '$regexp' is invalid: " . naptr_regexp_error();
  }

  # Output:
  # Regexp '!test(something)!\\1!i' is okay!

Object API:

  use Data::Validate::DNS::NAPTR::Regexp ();

  my $v = Data::Validate::DNS::NAPTR::Regexp->new();

  # Using <<'EOF' to mirror master-file format exactly
  my $regexp = <<'EOF';
  !test(something)!\\1!i
  EOF

  # Kill newline
  $regexp =~ s/\n//;

  if ($v->is_naptr_regexp($regexp)) {
    print "Regexp '$regexp' is okay!";
  } else {
    print "Regexp '$regexp' is invalid: " . $v->naptr_regexp_error();
  }

  # Output:
  # Regexp '!test(something)!\\1!i' is okay!

  # $v->error() also works

=head1 DESCRIPTION

This module validates the Regexp field in the NAPTR DNS Resource Record as 
defined by RFC 2915 / RFC 3403 Section 4.

It assumes that the data is in master file format and suitable for use in a ISC 
BIND zone file.

It validates as much as possible, except the actual POSIX extended regular 
expression.

=head1 EXPORT

By default, L</is_naptr_regexp> and L</naptr_regexp_error> will be exported. If 
you're using the L</OBJECT API>, importing an empty list is recommended.

=head1 FUNCTIONAL API

=head2 Methods

=head3 is_naptr_regexp

  is_naptr_regexp('some-string');

Returns a true value if the provided string is a valid Regexp for an NAPTR 
record. Returns false otherwise. To determine why a Regexp is invalid, see 
L</naptr_regexp_error> below.

=head3 naptr_regexp_error

  naptr_regexp_error();

Returns the last string error from a call to L</is_naptr_regexp> above. This is 
only valid if L</is_naptr_regexp> failed and returns a false value.

=head1 OBJECT API

This is the preferred method as the functional API uses globals.

=head2 Constructor

=head3 new

  Data::Validate::DNS::NAPTR::Regexp->new(%args)

Currently no C<%args> are available but this may change in the future.

=head3 is_naptr_regexp

  $v->is_naptr_regexp('some-string');

See L</is_naptr_regexp> above.

=head3 naptr_regexp_error

  $v->naptr_regexp_error();

See L</naptr_regexp_error> above.

=head3 error

  $v->error();

See L</naptr_regexp_error> above.

=head1 NOTES

This lib validates the data in master-file format. In RFC 2915, there are 
examples like: 

  IN NAPTR 100   10   ""  ""  "/urn:cid:.+@([^\.]+\.)(.*)$/\2/i"    .

To enter the above into a master-file, all backslashes must be escaped, and so 
it would look like this:

  IN NAPTR 100   10   ""  ""  "/urn:cid:.+@([^\\.]+\\.)(.*)$/\\2/i"    .

To enter this manually into a Perl script and check it, you'd have to escape all 
backslashes AGAIN:

  my $regexp = '/urn:cid:.+@([^\\\\.]+\\\\.)(.*)$/\\\\2/i';

Or, if you use a here doc, you can enter it just as you would if putting it in a 
zone file (but you must clean up the newline):

  my $regexp = <<'EOF';
  /urn:cid:.+@([^\\.]+\\.)(.*)$/\\2/i
  EOF

  $regexp =~ s/\n//;

The single-quote characters around "EOF" above are necessary or the backslashes 
will be interpolated!

=head1 SEE ALSO

RFC 2915 - L<https://tools.ietf.org/html/rfc2915>

RFC 3403 - Obsoletes RFC 2915 - L<https://tools.ietf.org/html/rfc3403>

=head1 AUTHOR

Matthew Horsfall (alh) - <wolfsage@gmail.com>

=head1 CREDITS

The logic for this module was adapted from ISC's BIND - 
L<https://www.isc.org/software/bind>.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 Dyn, Inc.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.9 or,
at your option, any later version of Perl 5 you may have available.

=cut
