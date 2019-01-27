package DateTime::Format::Text;

use strict;
use warnings;
use DateTime;
use Carp;

=head1 NAME

DateTime::Format::Text - Find a Date in Text

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';

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

	return unless(defined($class));

	return bless { }, $class;
}

=head2 parse_datetime

Synonym for parse().

=cut

sub parse_datetime {
	my $self = shift;
	my %params;

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

Creates a DateTime::Format::Text object.
Returns a L<DateTime> object constructed from a date/time string embedding in aribitrary text.

Can be called as a class or object method.

=cut

sub parse {
	my $self = shift;
	my %params;

	if(!ref($self)) {
		if(scalar(@_)) {
			return(__PACKAGE__->new()->parse(@_));
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
		my $day;
		my $month;
		my $year;

		if($string =~ /([0-9]?[0-9])[\.\-\/ ]+([0-1]?[0-9])[\.\-\/ ]+([0-9]{2,4})/) {
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
		}

		if(!defined($month)) {
			#  Match month name
			if($string =~ /($m|$sm)/) {
				$month = $1;
			}
		}

		if(!defined($year)) {
			# Match Year if not already set
			if($string =~ /(\d{4})/) {
				$year = $1;
			}
		}

		if(defined($month) && defined($year) && !defined($day)) {
			# Match "Sunday 1st"
			if($string =~ /($d|$sd)[,\s\-\/]+(\d?\d)[,\-\/]*($o)/i) {
				$day = $1;
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

Based on https://github.com/etiennetremel/PHP-Find-Date-in-String.
Here's the author information from that:

    author   Etienne Tremel
    license  https://creativecommons.org/licenses/by/3.0/ CC by 3.0
    link     http://www.etiennetremel.net
    version  0.2.0

=head1 BUGS

=head1 SEE ALSO

    L<DateTime::Format::Natural>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc DateTime::Format::Text

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=DateTime-Format-Text>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/DateTime-Format-Text>

=item * Search CPAN

L<http://search.cpan.org/dist/DateTime-Format-Text/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2019 Nigel Horne.

This program is released under the following licence: GPL2

=cut

1;
