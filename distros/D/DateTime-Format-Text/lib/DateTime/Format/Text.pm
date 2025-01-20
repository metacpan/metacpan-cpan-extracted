package DateTime::Format::Text;

# TODO: Add localization

use strict;
use warnings;

use Carp;
use DateTime;
use Scalar::Util;

=head1 NAME

DateTime::Format::Text - Find a Date in Text

=head1 VERSION

Version 0.10

=cut

our $VERSION = '0.10';

our @month_names = (
	'january',
	'february',
	'march',
	'april',
	'may',
	'june',
	'july',
	'august',
	'september',
	'october',
	'november',
	'december'
);

our @day_names = (
	'monday',
	'tuesday',
	'wednesday',
	'thursday',
	'friday',
	'saturday',
	'sunday'
);

our @ordinal_number = ('st', 'nd', 'rd', 'th');
our @short_month_names = map { _shorten($_) } @month_names;
our @short_day_names = map { _shorten($_) } @day_names;

our $d = join('|', @day_names);
our $sd = join('|', @short_day_names);
our $o = join('|', @ordinal_number);
our $m = join('|', @month_names);
our $sm = join('|', @short_month_names);

# Helper routine: Shorten strings to their first three characters
sub _shorten {
	return substr(shift, 0, 3);
};

=head1 SYNOPSIS

Extract and parse date strings from arbitrary text.

    use DateTime::Format::Text;
    my $dft = DateTime::Format::Text->new();
    # ...

=head1 SUBROUTINES/METHODS

=head2 new

Creates a DateTime::Format::Text object.
Takes no arguments

=cut

sub new {
	my $class = shift;

	# If the class is undefined, fallback to the current package name
	if(!defined($class)) {
		# Using DateTime::Format::Text::new(), not DateTime::Format::Text->new()
		# carp(__PACKAGE__, ' use ->new() not ::new() to instantiate');
		# return;

		# FIXME: this only works when no arguments are given
		return bless { }, __PACKAGE__;
	} elsif(Scalar::Util::blessed($class)) {
		# If $class is an object, clone it with new arguments
		return bless { }, ref($class);
	}
	return bless { }, $class;
}

=head2 parse_datetime

A synonym for parse().

=cut

sub parse_datetime {
	my $self = shift;

	if(!ref($self)) {
		if(scalar(@_)) {
			return(__PACKAGE__->new()->parse(@_));
		}
		return(__PACKAGE__->new()->parse($self));
	} elsif(ref($self) eq 'HASH') {
		return(__PACKAGE__->new()->parse($self));
	} elsif(ref($_[0])) {
		Carp::croak('Usage: ', __PACKAGE__, '::parse_datetime(string => $string)');
	}

	return $self->parse(@_);
}

=head2 parse

Core function for extracting and parsing dates from text returning a L<DateTime> object.
It handles various date formats, such as:

=over 4

=item *

dd/mm/yyyy, dd-mm-yy, d m yyyy

=item *

Sunday, 1 March 2015

=item *

1st March 2015

=back

If direct parsing fails, attempt to use the L<DateTime::Format::Flexible> module as a last resort.

Can be called as a class or object method.

When called in an array context, returns an array containing all of the matches.

If the given test is an object, it's sent the message as_string() and that is parsed

    use Class::Simple;
    my $foo = Class::Simple->new();
    $foo->as_string('25/12/2022');
    my $dt = $dft->parse($foo);

    # or

    print DateTime::Format::Text->parse('25 Dec 2021, 11:00 AM UTC')->epoch(), "\n";

=cut

sub parse {
	my $self = shift;
	my %params;

	if(!ref($self)) {
		if(scalar(@_)) {
			return(__PACKAGE__->new()->parse(@_));
		} elsif(!defined($self)) {
			# DateTime::Format::Text->parse()
			Carp::croak('Usage: ', __PACKAGE__, '::parse(string => $string)');
		} elsif($self eq __PACKAGE__) {
			Carp::croak('Usage: ', $self, '::parse(string => $string)');
		}
		return(__PACKAGE__->new()->parse($self));
	} elsif(ref($self) eq 'HASH') {
		return(__PACKAGE__->new()->parse($self));
	} elsif(ref($_[0]) eq 'HASH') {
		%params = %{$_[0]};
	} elsif(ref($_[0]) eq 'SCALAR') {
		$params{'string'} = $$_[0];
		shift;
	} elsif(ref($_[0]) eq 'ARRAY') {
		# TODO: Return an array of DTs, one for each item in the input array
		Carp::croak('Usage: ', $self, '::parse(string => $string)');
	} elsif(ref($_[0]) && $_[0]->can('as_string')) {
		$params{'string'} = shift;
	} elsif(ref($_[0])) {
		Carp::croak('Usage: ', __PACKAGE__, '::parse(string => $string)');
	} elsif(scalar(@_) && (scalar(@_) % 2 == 0)) {
		%params = @_;
	} elsif(defined($_[0])) {
		$params{'string'} = shift;
	} else {
		Carp::croak('Usage: ', __PACKAGE__, '::parse(string => $string)');
	}

	if(my $string = $params{'string'}) {
		# Allow the text to be an object
		if(ref($string) && $string->can('as_string')) {
			$string = $string->as_string();
		}

		if(wantarray) {
			# Return an array with all of the dates which match
			my @rc;

			# Ensure that the result includes the dates in the
			# same order that they are in the string
			while($string =~ /(^|\D)([0-9]?[0-9])[\.\-\/ ]+?([0-1]?[0-9])[\.\-\/ ]+?([0-9]{2,4})/g) {
				# Match dates: 01/01/2012 or 30-12-11 or 1 2 1985
				$rc[pos $string] = $self->parse("$2 $3 $4");
			}
			while($string =~ /($d|$sd)[\s,\-_\/]*?(\d?\d)[,\-\/]*($o)?[\s,\-\/]*($m|$sm)[\s,\-\/]+(\d{4})/ig) {
				#  Match dates: Sunday 1st March 2015; Sunday, 1 March 2015; Sun 1 Mar 2015; Sun-1-March-2015
				$rc[pos $string] = $self->parse("$2 $4 $5");
			}
			while($string =~ /(\d{1,2})\s($m|$sm)\s(\d{4})/ig) {
				$rc[pos $string] = $self->parse("$1 $2 $3");
			}
			while($string =~ /($m|$sm)[\s,\-_\/]*?(\d?\d)[,\-\/]*($o)?[\s,\-\/]+(\d{4})/ig) {
				$rc[pos $string] = $self->parse("$1 $2 $4");
			}
			if(scalar(@rc)) {
				# Remove empty items and create a well-ordered
				# array to return
				return grep { defined($_) } @rc;
			}
		}

		# !wantarray

		my $day;
		my $month;
		my $year;

		if($string =~ /(^|\D)([0-9]?[0-9])[\.\-\/ ]+?([0-1]?[0-9])[\.\-\/ ]+?([0-9]{2,4})/) {
			# Match dates: 01/01/2012 or 30-12-11 or 1 2 1985
			$day = $2;
			$month = $3;
			$year = $4;
		} elsif($string =~ /($d|$sd)[\s,\-_\/]*?(\d?\d)[,\-\/]*($o)?[\s,\-\/]*($m|$sm)[\s,\-\/]+(\d{4})/i) {
			#  Match dates: Sunday 1st March 2015; Sunday, 1 March 2015; Sun 1 Mar 2015; Sun-1-March-2015
			$day //= $2;
			$month //= $4;
			$year //= $5;
		} elsif($string =~ /($m|$sm)[\s,\-_\/]*?(\d?\d)[,\-\/]*($o)?[\s,\-\/]+(\d{4})/i) {
			$month //= $1;
			$day //= $2;
			$year //= $4;
		# } elsif($string =~ /[^\s,\(](\d{1,2})\s+($m|$sm)[\s,]+(\d{4})/i) {
			# # 12 September 1856
			# $day = $1;
			# $month = $2;
			# $year = $3;
		}

		if((!defined($month)) && ($string =~ /($m|$sm)/i)) {
			#  Match month name
			$month = $1;
		}

		if((!defined($year)) && ($string =~ /(\d{4})/)) {
			# Match Year if not already set
			$year = $1;
		}

		# We've managed to dig out a month and year, is there anything that looks like a day?
		if(defined($month) && defined($year) && !defined($day)) {
			# Match "Sunday 1st"
			if($string =~ /($d|$sd)[,\s\-\/]+(\d?\d)[,\-\/]*($o)\s+$year/i) {
				$day = $1;
			} elsif($string =~ /[\s\(:,](\d{1,2})\s+($m|$sm)/i) {	# Allow '(', ',' or ':' before the date
				$day = $1;
			} elsif($string =~ /^(\d{1,2})\s+($m|$sm)\s/i) {
				$day = $1;
			} elsif($string =~ /($m|$sm)\s+(the\s+)?(\d{1,2})th\s/i) {
				$day = $3;
			} elsif($string =~ /($m|$sm)\s+the\s+(\d{1,2})th\s/) {
				$day = $2;
			} elsif($string =~ /\s1st\s/i) {
				$day = 1;
			} elsif($string =~ /^1st\s/i) {
				$day = 1;
			} elsif($string =~ /\s2nd\s/i) {
				$day = 2;
			} elsif($string =~ /^2nd\s/i) {
				$day = 3;
			} elsif($string =~ /\s3rd\s/i) {
				$day = 2;
			} elsif($string =~ /^3rd\s/i) {
				$day = 3;
			} elsif($string =~ /\s(\d{1,2})th\s/i) {
				$day = $1 if($1 <= 31);
			} elsif($string =~ /^(\d{1,2})th\s/i) {
				$day = $1 if($1 <= 31);
			}
		}

		if($day && $month && $year) {
			if($year < 100) {
				$year += 2000;
			}
			$month = lc($month);
			if($month =~ /[a-z]/i) {
				foreach my $i(0..11) {
					if(($month eq $month_names[$i]) || ($month eq $short_month_names[$i])) {
						return DateTime->new(day => $day, month => $i + 1, year => $year);
					}
				}
				# This code should be unreachable
				Carp::croak(__PACKAGE__, ": unknown month $month");
				return;
			}
			return DateTime->new(day => $day, month => $month, year => $year);
		}
		# Last ditch if all else fails
		eval {
			require DateTime::Format::Flexible;

			my $rc = DateTime::Format::Flexible->parse_datetime($string);

			return $rc if(defined($rc));
		};
	} else {
		Carp::croak('Usage: ', __PACKAGE__, '::parse(string => $string)');
	}
}

=head1 AUTHOR

Nigel Horne, C<< <njh at bandsman.co.uk> >>

Based on L<https://github.com/etiennetremel/PHP-Find-Date-in-String>.
Here's the author information from that:

author   Etienne Tremel
license  L<https://creativecommons.org/licenses/by/3.0/> CC by 3.0
link     L<http://www.etiennetremel.net>
version  0.2.0

=head1 BUGS

=head1 SEE ALSO

L<DateTime::Format::Flexible>,
L<DateTime::Format::Natural>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc DateTime::Format::Text

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=DateTime-Format-Text>

=item * Search CPAN

L<http://search.cpan.org/dist/DateTime-Format-Text/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2019-2025 Nigel Horne.

This program is released under the following licence: GPL2

=cut

1;
