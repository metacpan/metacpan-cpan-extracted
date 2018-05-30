package Memento::TimeTravel;

our $VERSION = '0.10';

use strict;
use Moo;
use JSON;
use Scalar::Util qw(blessed);
use LWP::Simple;

sub find_mementos {
	my ($self,$uri,$date) = @_;

	unless (blessed($self)) {
		$date = $uri;
		$uri  = $self;
	}

	die "usage: find_mementos(uri,date)" unless defined($uri) && defined($date);

	die "usage: date =~ YYYYMMDDHHMMSS" unless ($date =~ /^\d{4,14}$/);

	my $api_call = sprintf "http://timetravel.mementoweb.org/api/json/%s/%s" 
								, $date
								, $uri;

	my $mementos = get($api_call);

	return undef unless defined($mementos) && length($mementos);

	decode_json($mementos);
}

=head1 NAME

Memento::TimeTravel - A time traveler for URLS

=head1 SYNOPSIS

  use Memento::TimeTravel;

  my $traveler = Memento::TimeTravel->new();

  my $mementos = $traveler->find_mementos('http://www.ugent.be/',2013);

=head1 AUTHOR

Patrick Hochstenbach, C<< <patrick.hochstenbach at ugent.be> >>

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut


1;