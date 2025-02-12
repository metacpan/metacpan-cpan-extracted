package DateTime::Format::Genealogy;

# Author Nigel Horne: njh@bandsman.co.uk
# Copyright (C) 2018-2025, Nigel Horne

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
use Scalar::Util;

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

our @months = ('Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec');

=head1 NAME

DateTime::Format::Genealogy - Create a DateTime object from a Genealogy Date

=head1 VERSION

Version 0.11

=cut

our $VERSION = '0.11';

=head1 SYNOPSIS

C<DateTime::Format::Genealogy> is a Perl module designed to parse genealogy-style date formats and convert them into L<DateTime> objects.
It uses L<Genealogy::Gedcom::Date> to parse dates commonly found in genealogical records while also handling date ranges and approximate dates.

    use DateTime::Format::Genealogy;
    my $dtg = DateTime::Format::Genealogy->new();
    # ...

=head1 SUBROUTINES/METHODS

=head2 new

Creates a DateTime::Format::Genealogy object.

=cut

sub new
{
	my $class = shift;

	# Handle hash or hashref arguments
	my %args;
	if((@_ == 1) && (ref $_[0] eq 'HASH')) {
		# If the first argument is a hash reference, dereference it
		%args = %{$_[0]};
	} elsif((@_ % 2) == 0) {
		# If there is an even number of arguments, treat them as key-value pairs
		%args = @_;
	} else {
		# If there is an odd number of arguments, treat it as an error
		carp(__PACKAGE__, ': Invalid arguments passed to new()');
		return;
	}

	if(!defined($class)) {
		# FIXME: this only works when no arguments are given
		$class = __PACKAGE__;
	} elsif(Scalar::Util::blessed($class)) {
		# If $class is an object, clone it with new arguments
		return bless { %{$class}, %args }, ref($class);
	}
	# Return the blessed object
	return bless { %args }, $class;
}

=head2 parse_datetime($string)

Given a date,
runs it through L<Genealogy::Gedcom::Date> to create a L<DateTime> object.
If a date range is given, return a two-element array in array context, or undef in scalar context

Returns undef if the date can't be parsed,
is before AD100,
is just a year or if it is an approximate date starting with "c", "ca" or "abt".
Can be called as a class or object method.

    my $dt = DateTime::Format::Genealogy->new()->parse_datetime('25 Dec 2022');

Mandatory arguments:

=over 4

=item * C<date>

The date to be parsed.

=back

Optional arguments:

=over 4

=item * C<quiet>

Set to fail silently if there is an error with the date.

=item * C<strict>

More strictly enforce the Gedcom standard,
for example,
don't allow long month names.

=back

=cut

sub parse_datetime {
	my $self = shift;

	if(!ref($self)) {
		if(scalar(@_)) {
			return(__PACKAGE__->new()->parse_datetime(@_));
		}
		return(__PACKAGE__->new()->parse_datetime($self));
	} elsif(ref($self) eq 'HASH') {
		return(__PACKAGE__->new()->parse_datetime($self));
	}

	my $params = $self->_get_params('date', @_);

	if((!ref($params->{'date'})) && (my $date = $params->{'date'})) {
		my $quiet = $params->{'quiet'};

		# TODO: Needs much more sanity checking
		if(($date =~ /^bef\s/i) || ($date =~ /^aft\s/i) || ($date =~ /^abt\s/i)) {
			Carp::carp("$date is invalid, need an exact date to create a DateTime")
				unless($quiet);
			return;
		}
		if($date =~ /^31\s+Nov/) {
			Carp::carp("$date is invalid, there are only 30 days in November");
			return;
		}
		if($date =~ /^\s*(.+\d\d)\s*\-\s*(.+\d\d)\s*$/) {
			if($date =~ /^(\d{4})\-(\d{2})\-(\d{2})$/) {
				my $month = $months[$2 - 1];
				Carp::carp("Changing date '$date' to '$3 $month $1'") unless($quiet);
				$date = "$3 $month $1";
			} else {
				Carp::carp("Changing date '$date' to 'bet $1 and $2'") unless($quiet);
				$date = "bet $1 and $2";
			}
		}
		if($date =~ /^bet (.+) and (.+)/i) {
			if(wantarray) {
				return $self->parse_datetime($1), $self->parse_datetime($2);
			}
			return;
		}

		my $strict = $params->{'strict'};
		if((!$strict) && ($date =~ /^from (.+) to (.+)/i)) {
			if(wantarray) {
				return $self->parse_datetime($1), $self->parse_datetime($2);
			}
			return;
		}

		if($date !~ /^\d{3,4}$/) {
			if($strict) {
				if($date !~ /^(\d{1,2})\s+([A-Z]{3})\s+(\d{3,4})$/i) {
					Carp::carp("Unparseable date $date - often because the month name isn't 3 letters") unless($quiet);
					return;
				}
			} elsif($date =~ /^(\d{1,2})\s+([A-Z]{4,}+)\.?\s+(\d{3,4})$/i) {
				if(my $abbrev = $months{ucfirst(lc($2))}) {
					$date = "$1 $abbrev $3";
				} elsif($2 eq 'Janv') {
					# I've seen a tree that uses some French months
					$date = "$1 Jan $3";
				} elsif($2 eq 'Juli') {
					$date = "$1 Jul $3";
				} else {
					Carp::carp("Unparseable date $date - often because the month name isn't 3 letters") unless($quiet);
					return;
				}
			} elsif($date =~ /^(\d{1,2})\s+Mai\s+(\d{3,4})$/i) {
				# I've seen a tree that uses some French months
				$date = "$1 May $2";
			} elsif($date =~ /^(\d{1,2})\s+Août\s+(\d{3,4})$/i) {
				# I've seen a tree that uses some French months
				$date = "$1 Aug $2";
			} elsif($date =~ /^(\d{1,2})\-([A-Z]{3})\-(\d{3,4})$/i) {
				# 29-Aug-1938
				$date = "$1 $2 $3";
			}

			my $dfn = $self->{'dfn'};
			if(!defined($dfn)) {
				$self->{'dfn'} = $dfn = DateTime::Format::Natural->new();
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
			}
		}
		return;	# undef
	}
	Carp::croak('Usage: ', __PACKAGE__, '::parse_datetime(date => $date)');
}

# Parse Gedcom format dates
# Genealogy::Gedcom::Date is expensive, so cache results
sub _date_parser_cached
{
	my $self = shift;
	my $params = $self->_get_params('date', @_);
	my $date = $params->{'date'};

	Carp::croak('Usage: _date_parser_cached(date => $date)') unless defined $date;

	# Check and return if the date has already been parsed and cached
	return $self->{'all_dates'}{$date} if exists $self->{'all_dates'}{$date};

	# Initialize the date parser if not already set
	my $date_parser = $self->{'date_parser'} ||= Genealogy::Gedcom::Date->new();

	# Parse the date
	my $parsed_date;
	eval {
		$parsed_date = $date_parser->parse(date => $date);
	};

	# Check for errors
	if(my $error = $date_parser->error()) {
		Carp::carp("$date: '$error'") unless $self->{'quiet'};
		return;
	}

	# Cache and return the first parsed date if it's an array reference
	if((ref($parsed_date) eq 'ARRAY') && @{$parsed_date}) {
		return $self->{'all_dates'}{$date} = $parsed_date->[0];
	}

	return;
}

# Helper routine to parse the arguments given to a function.
# Processes arguments passed to methods and ensures they are in a usable format,
#	allowing the caller to call the function in anyway that they want
#	e.g. foo('bar'), foo(arg => 'bar'), foo({ arg => 'bar' }) all mean the same
#	when called _get_params('arg', @_);
sub _get_params
{
	shift;  # Discard the first argument (typically $self)
	my $default = shift;

	# Directly return hash reference if the first parameter is a hash reference
	return $_[0] if(ref($_[0]) eq 'HASH');

	my %rc;
	my $num_args = scalar @_;

	# Populate %rc based on the number and type of arguments
	if(($num_args == 1) && (defined $default)) {
		# %rc = ($default => shift);
		return { $default => shift };
	} elsif($num_args == 1) {
		Carp::croak('Usage: ', __PACKAGE__, '->', (caller(1))[3], '()');
	} elsif(($num_args == 0) && (defined($default))) {
		Carp::croak('Usage: ', __PACKAGE__, '->', (caller(1))[3], "($default => \$val)");
	} elsif(($num_args % 2) == 0) {
		%rc = @_;
	} elsif($num_args == 0) {
		return;
	} else {
		Carp::croak('Usage: ', __PACKAGE__, '->', (caller(1))[3], '()');
	}

	return \%rc;
}

1;

=head1 AUTHOR

Nigel Horne, C<< <njh at bandsman.co.uk> >>

=head1 BUGS

Please report any bugs or feature requests to the author.
This module is provided as-is without any warranty.

I can't get L<DateTime::Format::Natural> to work on dates before AD100,
so this module rejects dates that are that old.

=head1 SEE ALSO

L<Genealogy::Gedcom::Date> and
L<DateTime>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc DateTime::Format::Genealogy

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=DateTime-Format-Genealogy>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2018-2025 Nigel Horne.

This program is released under the following licence: GPL2

=cut

1;
