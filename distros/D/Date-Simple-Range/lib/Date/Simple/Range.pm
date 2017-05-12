package Date::Simple::Range;

use Date::Simple;
use Time::Seconds ();
use Carp;

use base qw/ Class::Accessor /;

__PACKAGE__->mk_accessors(qw/ start end index /);

our $VERSION = '1.1'; 

use overload
	'fallback'	=> 1,
	'bool'		=> 'bool',
	'<>'		=> 'iterator',
	'@{}'		=> 'array',
	'>>'		=> 'shiftr',
	'<<'		=> 'shiftl',
	'='		=> 'clone',
	'""'		=> 'stringify';

sub new
{
	my $proto = shift;
	my $class = ref($proto) || $proto;

	my $self = bless $proto->SUPER::new(), $class;

	my ($start, $end) = @_;

	$self->start($start);
	$self->end($end);

	return $self;
}

sub to_date_simple
{
	my ($self, $arg) = @_;

	return undef
		unless defined $arg;

	if (ref($arg)) {
		return $arg
			if $arg->isa('Date::Simple');

		$arg = $arg->ymd
			if $arg->isa('DateTime')
			or $arg->isa('Time::Piece');

		$arg = Date::Simple->new($arg->date(0))
			if $arg->isa('Date::Calc::Object');
	}

	return Date::Simple->new($arg);
}

sub start
{
	my ($self, $arg) = @_;
	
	return $self->_start_accessor
		unless defined $arg;

	$arg = $self->to_date_simple($arg)
		or croak('invalid start date: ', $arg);

	croak('start date (', $arg, ') is past end date (', $self->end, ')')
		if defined $self->end
		and $arg > $self->end;

	return $self->_start_accessor($arg);
}

sub end
{
	my ($self, $arg) = @_;
	
	return $self->_end_accessor
		unless defined $arg;

	$arg = $self->to_date_simple($arg)
		or croak('invalid end date: ', $arg);

	croak('end date (', $arg, ') is before start date (', $self->start, ')')
		if defined $self->start
		and $arg < $self->start;

	return $self->_end_accessor($arg);
}

sub duration
{
	my $self = shift;

	return undef unless $self;

	return Time::Seconds->new(($self->end - $self->start + 1) * (60 * 60 * 24));
}

sub array
{
	my $self = shift;

	return [] unless $self;

	my @a;

	for ($i = $self->start; $i <= $self->end; $i++) {
		push(@a, Date::Simple->new($i));
	}

	return \@a;
}

sub iterator
{
	my $self = shift;

	return undef unless $self;

	$self->index($self->start->prev)
		unless defined $self->index;

	return $self->index(undef)
		if $self->index == $self->end;

	return $self->index($self->index->next);
}

sub bool
{
	my $self = shift;
	return defined $self->start && defined $self->end;
}

sub stringify
{
	my $self = shift;

	if ($self) {
		$self->start . ' - ' . $self->end;
	} else {
		return 'incomplete range';
	}
}

sub shiftr
{
	my ($self, $amount) = @_;

	$self->start($self->start + $amount);
	$self->end($self->end + $amount);

	return $self;
}

sub shiftl
{
	my ($self, $amount) = @_;

	$self->start($self->start - $amount);
	$self->end($self->end - $amount);

	return $self;
}

sub clone
{
	my $self = shift;

	return new Date::Simple::Range(
		new Date::Simple($self->start),
		new Date::Simple($self->end));
}

1;

=head1 NAME

Date::Simple::Range - A range of Date::Simple objects

=head1 SYNOPSIS

 use Date::Simple::Range;

 # the new, start and end methods accept Date::Simple, DateTime, Time::Piece,
 # Date::Calc::Object objects, ISO 8601 strings and undef values.

 my $range = new Date::Simple::Range('2008-01-01', '2008-01-05');

 my $incomplete = new Date::Simple::Range(undef, '2008-01-05');
 my $start = new Date::Simple('2008-01-01');
 $incomplete->start($start);	# now complete


 if ($range) { ...		# start and end dates are both valid

 print $range;			# stringifies as '2008-01-01 - 2008-01-05'
				# or 'incomplete range'

 $range->start			# start date
 $range->end			# end date

 $range->start('2008-01-02')	# change start date
 $range->end($anotherobj)	# change end date

 $range >>= 2			# shift range two days in the future...
 $range <<= 4			# ...and 4 days in the past

 $range->duration		# duration as a Time::Seconds object
 $range->duration->days 	# duration in days
 scalar @$range			# duration in days (ugly!)

 foreach (@$range) { ...	# iterate thru the range
 while (<$range>) { ...		# another way, less memory hungry

 $range->clone			# a new, independent, cloned range object

=head1 DESCRIPTION

A range of Date::Simple objects.

=head1 SEE ALSO

Date::Simple, Time::Seconds

=head1 AUTHOR

Alessandro Zummo, E<lt>a.zummo@towertech.itE<gt>

=head1 COPYRIGHT

Copyright (C) 2008 by Alessandro Zummo

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License version 2 as
published by the Free Software Foundation.

=cut
