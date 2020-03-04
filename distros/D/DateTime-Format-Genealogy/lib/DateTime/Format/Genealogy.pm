package DateTime::Format::Genealogy;

# Author Nigel Horne: njh@bandsman.co.uk
# Copyright (C) 2018-2020, Nigel Horne

# Usage is subject to licence terms.
# The licence terms of this software are as follows:
# Personal single user, single computer use: GPL2
# All other users (including Commercial, Charity, Educational, Government)
#	must apply in writing for a licence for use from Nigel Horne at the
#	above e-mail.

use strict;
use warnings;
use autodie qw(:all);
# use diagnostics;
# use warnings::unused;
use 5.006_001;

use namespace::clean;
use Carp;
use DateTime::Format::Natural;
use Genealogy::Gedcom::Date 2.01;

=head1 NAME

DateTime::Format::Genealogy - Create a DateTime object from a Genealogy Date

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';

=head1 SYNOPSIS

=head1 SUBROUTINES/METHODS

=head2 new

Creates a DateTime::Format::Genealogy object.

=cut

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;

	return unless(defined($class));

	return bless {}, $class;
}

=head2 parse_datetime($string)

Given a date,
runs it through L<Genealogy::Gedcom::Date> to create a L<DateTime> object.
If a date range is given, return a two element array in array context, or undef in scalar context

Returns undef if the date can't be parsed, is just a year or if it is an appoximate date starting with "c", "ca" or "abt".
Can be called as a class or object method.

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

	if(my $date = $params{'date'}) {
		# TODO: Needs much more sanity checking
		if(($date =~ /^bef\s/i) || ($date =~ /^aft\s/i)) {
			Carp::carp("$date is invalid, need an exact date to create a DateTime");
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
			if(($date =~ /^\d/) && (my $d = $self->_date_parser_cached($date))) {
				return $dfn->parse_datetime($d->{'canonical'});
			}
			if(($date !~ /^(Abt|ca?)/i) && ($date =~ /^[\w\s]+$/)) {
				# ACOM exports full month names and non-standard format dates e.g. U.S. format MMM, DD YYYY
				if(my $rc = $dfn->parse_datetime($date)) {
					return $rc;
				}
				Carp::croak("Can't parse date '$date'");
			}
		}
	} else {
		Carp::croak('Usage: parse_datetime(date => $date)');
	}
}

# Parse Gedcom format dates
# Genealogy::Gedcom::Date is expensive, so cache results
sub _date_parser_cached
{
	my $self = shift;
	my %params;

	if(ref($_[0]) eq 'HASH') {
		%params = %{$_[0]};
	} elsif(ref($_[0])) {
		Carp::croak('Usage: _date_parser_cached(date => $date)');
	} elsif(scalar(@_) % 2 == 0) {
		%params = @_;
	} else {
		$params{'date'} = shift;
	}

	my $date = $params{'date'};

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

Copyright 2018-2020 Nigel Horne.

This program is released under the following licence: GPL

=cut

1;
