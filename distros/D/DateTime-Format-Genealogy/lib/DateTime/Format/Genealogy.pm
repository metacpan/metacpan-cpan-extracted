package DateTime::Format::Genealogy;

# Author Nigel Horne: njh@bandsman.co.uk
# Copyright (C) 2018-2023, Nigel Horne

# Usage is subject to licence terms.
# The licence terms of this software are as follows:
# Personal single user, single computer use: GPL2
# All other users (including Commercial, Charity, Educational, Government)
#	must apply in writing for a licence for use from Nigel Horne at the
#	above e-mail.

use strict;
use warnings;
# use diagnostics;
# use warnings::unused;
use 5.006_001;

use namespace::clean;
use Carp;
use DateTime::Format::Natural;
use Genealogy::Gedcom::Date 2.01;

our %months = (
	'January' => 'Jan',
	'February' => 'Feb',
	'March' => 'Mar',
	'April' => 'Apr',
	# 'May' => 'May',
	'June' => 'Jun',
	'July' => 'Jul',
	'August' => 'Aug',
	'September' => 'Sep',
	'Sept' => 'Sep',
	'Sept.' => 'Sep',
	'October' => 'Oct',
	'November' => 'Nov',
	'December' => 'Dec'
);

=head1 NAME

DateTime::Format::Genealogy - Create a DateTime object from a Genealogy Date

=head1 VERSION

Version 0.05

=cut

our $VERSION = '0.05';

=head1 SYNOPSIS

    use DateTime::Format::Genealogy;
    my $dtg = DateTime::Format::Genealogy->new();
    # ...

=head1 SUBROUTINES/METHODS

=head2 new

Creates a DateTime::Format::Genealogy object.

=cut

sub new {
	my($proto, %args) = @_;
	my $class = ref($proto) || $proto;

	if(!defined($class)) {
		# FIXME: this only works when no arguments are given
		$class = __PACKAGE__;
	} elsif(ref($class)) {
		# clone the given object
		return bless { %{$class}, %args }, ref($class);
	}
	return bless {}, $class;
}

=head2 parse_datetime($string)

Given a date,
runs it through L<Genealogy::Gedcom::Date> to create a L<DateTime> object.
If a date range is given, return a two element array in array context, or undef in scalar context

Returns undef if the date can't be parsed,
is before AD100,
is just a year or if it is an approximate date starting with "c", "ca" or "abt".
Can be called as a class or object method.

    my $dt = DateTime::Format::Genealogy('25 Dec 2022');
    $dt = $dtg->(date => '25 Dec 2022');

date: the date to be parsed
quiet: set to fail silently if there is an error with the date
strict: more strictly enforce the Gedcom standard, for example don't allow long month names

=cut

sub parse_datetime {
	my $self = shift;
	my %params;

	if(!ref($self)) {
		if(scalar(@_)) {
			return(__PACKAGE__->new()->parse_datetime(@_));
		}
		return(__PACKAGE__->new()->parse_datetime($self));
	} elsif(ref($self) eq 'HASH') {
		return(__PACKAGE__->new()->parse_datetime($self));
	} elsif(ref($_[0]) eq 'HASH') {
		%params = %{$_[0]};
	} elsif(ref($_[0])) {
		Carp::croak('Usage: ', __PACKAGE__, '::parse_datetime(date => $date)');
	} elsif(scalar(@_) && (scalar(@_) % 2 == 0)) {
		%params = @_;
	} else {
		$params{'date'} = shift;
	}
	my $quiet = $params{'quiet'};

	if(my $date = $params{'date'}) {
		# TODO: Needs much more sanity checking
		if(($date =~ /^bef\s/i) || ($date =~ /^aft\s/i) || ($date =~ /^abt\s/i)) {
			Carp::carp("$date is invalid, need an exact date to create a DateTime")
				unless($quiet);
			return;
		}
		if($date =~ /^31 Nov/) {
			Carp::carp("$date is invalid, there are only 30 days in November");
			return;
		}
		my $dfn = $self->{'dfn'};
		if(!defined($dfn)) {
			$self->{'dfn'} = $dfn = DateTime::Format::Natural->new();
		}
		if($date =~ /^\s*(.+\d\d)\s*\-\s*(.+\d\d)\s*$/) {
			Carp::carp("Changing date '$date' to 'bet $1 and $2'");
			$date = "bet $1 and $2";
		}
		if($date =~ /^bet (.+) and (.+)/i) {
			if(wantarray) {
				return $self->parse_datetime($1), $self->parse_datetime($2);
			}
			return;
		}

		if($date !~ /^\d{3,4}$/) {
			my $strict = $params{'strict'};
			if($strict) {
				if($date !~ /^(\d{1,2})\s+([A-Z]{3})\s+(\d{3,4})$/i) {
					Carp::carp("Unparseable date $date - often because the month name isn't 3 letters") unless($quiet);
					return;
				}
			} elsif($date =~ /^(\d{1,2})\s+([A-Z]{4,}+)\.?\s+(\d{3,4})$/i) {
				if(my $abbrev = $months{ucfirst(lc($2))}) {
					$date = "$1 $abbrev $3";
				} else {
					Carp::carp("Unparseable date $date - often because the month name isn't 3 letters") unless($quiet);
					return;
				}
			}
			if(($date =~ /^\d/) && (my $d = $self->_date_parser_cached($date))) {
				# D:T:Natural doesn't seem to work before AD100
				return if($date =~ /\s\d{1,2}$/);
				return $dfn->parse_datetime($d->{'canonical'});
			}
			if(($date !~ /^(Abt|ca?)/i) && ($date =~ /^[\w\s,]+$/)) {
				# ACOM exports full month names and non-standard format dates e.g. U.S. format MMM, DD YYYY
				# TODO: allow that when not in strict mode
				if(my $rc = $dfn->parse_datetime($date)) {
					if($dfn->success()) {
						return $rc;
					}
					Carp::carp($dfn->error()) unless($quiet);
				} else {
					Carp::carp("Can't parse date '$date'") unless($quiet);
				}
				return;
			}
		} else {
			return;	# undef
		}
	} else {
		Carp::croak('Usage: ', __PACKAGE__, '::parse_datetime(date => $date)');
	}
}

# Parse Gedcom format dates
# Genealogy::Gedcom::Date is expensive, so cache results
sub _date_parser_cached
{
	my $self = shift;
	my $date = shift;

	if(!defined($date)) {
		Carp::croak('Usage: _date_parser_cached(date => $date)');
	}

	if($self->{'all_dates'}{$date}) {
		return $self->{'all_dates'}{$date};
	}
	my $date_parser = $self->{'date_parser'};
	if(!defined($date_parser)) {
		$date_parser = $self->{'date_parser'} = Genealogy::Gedcom::Date->new();
	}

	my $d;
	eval {
		$d = $date_parser->parse(date => $date);
	};
	if(my $error = $date_parser->error()) {
		Carp::carp("$date: '$error'");
		return;
	}
	if($d && (ref($d) eq 'ARRAY')) {
		$d = @{$d}[0];
		$self->{'all_dates'}{$date} = $d;
	}
	return $d;
}

1;

=head1 AUTHOR

Nigel Horne, C<< <njh at bandsman.co.uk> >>

=head1 BUGS

I can't get L<DateTime::Format::Natural> to work on dates before AD100,
so this module rejects dates that old.

=head1 SEE ALSO

L<Genealogy::Gedcom::Date> and
L<DateTime>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc DateTime::Format::Gedcom

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=DateTime-Format-Gedcom>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/DateTime-Format-Gedcom>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2018-2023 Nigel Horne.

This program is released under the following licence: GPL2

=cut

1;
