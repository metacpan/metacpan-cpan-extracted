package DateTime::Format::Text;

use strict;
use warnings;
use DateTime;
use Carp;

=head1 NAME

DateTime::Format::Text - Find a Date in Text

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';

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
our @short_month_names = map { _shortenize($_) } @month_names;
our @short_day_names = map { _shortenize($_) } @day_names;

our $d = join('|', @day_names);
our $sd = join('|', @short_day_names);
our $o = join('|', @ordinal_number);
our $m = join('|', @month_names);
our $sm = join('|', @short_month_names);

sub _shortenize {
	return substr(shift, 0, 3);
};

=head1 SYNOPSIS

Find a date in any text.

    use DateTime::Format::Text;
    my $dft = DateTime::Format::Text->new();
    # ...

=head1 SUBROUTINES/METHODS

=head2 new

Creates a DateTime::Format::Text object.
Takes no arguments

=cut

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;

	if(!defined($class)) {
		# Using DateTime::Format->new(), not DateTime::Format()
		# carp(__PACKAGE__, ' use ->new() not ::new() to instantiate');
		# return;

		# FIXME: this only works when no arguments are given
		return bless { }, __PACKAGE__;
	} elsif(ref($class)) {
		# clone the given object
		return bless { }, ref($class);
	}
	return bless { }, $class;
}

=head2 parse_datetime

Synonym for parse().

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

Returns a L<DateTime> object constructed from a date/time string embedded in
arbitrary text.

Can be called as a class or object method.

When called in an array context, returns an array containing all of the matches

=cut

sub parse {
	my $self = shift;
	my %params;

	if(!ref($self)) {
		if(scalar(@_)) {
			return(__PACKAGE__->new()->parse(@_));
		} elsif($self eq __PACKAGE__) {
			# Date::Time::Format->parse()
			Carp::croak('Usage: ', $self, '::parse(string => $string)');
		}
		return(__PACKAGE__->new()->parse($self));
	} elsif(ref($self) eq 'HASH') {
		return(__PACKAGE__->new()->parse($self));
	} elsif(ref($_[0]) eq 'HASH') {
		%params = %{$_[0]};
	} elsif(ref($_[0])) {
		Carp::croak('Usage: ', __PACKAGE__, '::parse(string => $string)');
	} elsif(scalar(@_) && (scalar(@_) % 2 == 0)) {
		%params = @_;
	} else {
		$params{'string'} = shift;
	}

	if(my $string = $params{'string'}) {
		# Allow the text to be an object
		if(ref($string)) {
			$string = $string->as_string();
		}

		if(wantarray) {
			# Return an array with all of the dates which match
			my @rc;
		
			while($string =~ /([0-9]?[0-9])[\.\-\/ ]+?([0-1]?[0-9])[\.\-\/ ]+?([0-9]{2,4})/g) {
				# Match dates: 01/01/2012 or 30-12-11 or 1 2 1985
				my $r = $self->parse("$1 $2 $3");
				push @rc, $r;
			}
			while($string =~ /($d|$sd)[\s,\-_\/]*?(\d?\d)[,\-\/]*($o)?[\s,\-\/]*($m|$sm)[\s,\-\/]+(\d{4})/ig) {
				#  Match dates: Sunday 1st March 2015; Sunday, 1 March 2015; Sun 1 Mar 2015; Sun-1-March-2015
				my $r = $self->parse("$2 $4 $5");
				push @rc, $r;
			}
			while($string =~ /($m|$sm)[\s,\-_\/]*?(\d?\d)[,\-\/]*($o)?[\s,\-\/]+(\d{4})/ig) {
				my $r = $self->parse("$1 $2 $4");
				push @rc, $r;
			}
			return @rc if(scalar(@rc));
			while($string =~ /(\d{1,2})\s($m|$sm)\s(\d{4})/ig) {
				my $r = $self->parse("$1 $2 $3");	# Force scalar context
				push @rc, $r;
			}
			return @rc if(scalar(@rc));
		}

		# !wantarray
		my $day;
		my $month;
		my $year;

		if($string =~ /([0-9]?[0-9])[\.\-\/ ]+?([0-1]?[0-9])[\.\-\/ ]+?([0-9]{2,4})/) {
			# Match dates: 01/01/2012 or 30-12-11 or 1 2 1985
			$day = $1;
			$month = $2;
			$year = $3;
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

		if(!defined($month)) {
			#  Match month name
			if($string =~ /($m|$sm)/i) {
				$month = $1;
			}
		}

		if(!defined($year)) {
			# Match Year if not already set
			if($string =~ /(\d{4})/) {
				$year = $1;
			}
		}

		# We've managed to dig out a month and year, is there anything that looks like a day?
		if(defined($month) && defined($year) && !defined($day)) {
			# Match "Sunday 1st"
			if($string =~ /($d|$sd)[,\s\-\/]+(\d?\d)[,\-\/]*($o)\s+$year/i) {
				$day = $1;
			} elsif($string =~ /[\s\(](\d{1,2})\s+($m|$sm)/i) {
				$day = $1;
			} elsif($string =~ /^(\d{1,2})\s+($m|$sm)\s/i) {
				$day = $1;
			} elsif($string =~ /\s(\d{1,2})th\s/) {
				$day = $1;
			} elsif($string =~ /\s1st\s/i) {
				$day = 1;
			} elsif($string =~ /\s2nd\s/i) {
				$day = 2;
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
			} else {
				return DateTime->new(day => $day, month => $month, year => $year);
			}
		}
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

In array mode, it would be good to find more than one date in the string

=head1 SEE ALSO

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

Copyright 2019-2023 Nigel Horne.

This program is released under the following licence: GPL2

=cut

1;
