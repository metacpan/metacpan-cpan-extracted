package Calendar::Slots::Slot;
{
  $Calendar::Slots::Slot::VERSION = '0.15';
}
use Moose;
use Carp;
use Moose::Util::TypeConstraints;
use namespace::autoclean;

has name     => ( is => 'rw', isa => 'Str' );  # the slot given name
has when     => ( is => 'rw', isa => 'Int', required=>1, );  # weekday num or date
has type     => ( is => 'rw', isa => enum([qw/weekday date/]), required=>1 );  # type of slot
has start    => ( is => 'rw', isa => 'Int' );  # start time
has end      => ( is => 'rw', isa => 'Int' );  # end time
has data     => ( is => 'rw', isa => 'Any' );  # free data for your own use
has _weekday => ( is => 'rw', isa => 'Num' );  # cache

use Calendar::Slots::Utils;

around BUILDARGS => sub {
	my $orig = shift;
	my $class = shift;
	my %args = @_ == 1 && ref $_[0] ? %{ $_[0] || {} } : @_;
	%args    = format_args( %args );

	defined $args{date} and check_date( $args{date} );
	defined $args{weekday} and check_weekday( $args{weekday} );
	defined $args{start} and check_time( $args{start} );
	defined $args{end} and check_time( $args{end} );

	$args{type} = $args{date} ? 'date' : $args{weekday} ? 'weekday' : undef;

	$args{type} ||= length($args{when}) == 8 ? 'date' : 'weekday';
    $args{when} = $args{when}
      || ( $args{type} eq 'date' ? $args{date} : $args{weekday} );
	delete $args{date};
	delete $args{weekday};

	$class->$orig(%args);
};


sub BUILD {
	my $self = shift;
    $self->start > $self->end
      and confess 'Invalid slot: start time is after the end time';
}

sub contains {
    my $self  = shift;
    my %args  = format_args(@_);

	defined $args{date} and check_date( $args{date} );
	defined $args{weekday} and check_weekday( $args{weekday} );
	defined $args{'time'} and check_time( $args{'time'} );

    my $type  = $args{type} || ( $args{date} ? 'date' : 'weekday' );
    my $when  = $args{when}
      || ( $type eq 'date' ? $args{date} : $args{weekday} );
    my $time  = $args{'time'};
    my $start = $args{start};
    my $end   = $args{end};

    $time
      and ( $start or $end )
      and croak 'Parameters start/end and time are mutually exclusive';
    $when or croak 'Missing parameter when';

    if ( $type eq $self->type ) {
        return if $when ne $self->when;
    }
    elsif ( $type eq 'date' && $self->type eq 'weekday' ) {
        $when = parse_dt( '%Y%m%d', $when )->wday;
        $when == 0 and $when = 7;
        return if $when ne $self->when;
    }
    elsif( $when ne $self->weekday ) {
        return ;
    }

    if ($time) {
        return $time >= $self->start && $time < $self->end;
    }
    else {
        return $start > $self->start && $end < $self->end;
    }
    return 1;
}

sub same_weekday {
	my $self = shift;
	my $slot = shift;
	return $self->weekday eq $slot->weekday; 
}

sub weekday {
	my $self = shift;
	my $day;
	if( $self->type eq 'date' ) {
        my $wk = $self->_weekday;
        return $wk if defined $wk;
		my $dt = DateTime->new( $self->ymd_hash );
		return $self->_weekday( $dt->strftime('%u') ); # cache
	}
	else {
		return $self->when;
	}
}

sub same_type {
    my $self = shift;
	my $slot = shift;
	return $self->type eq $slot->type;	
}

sub same_day {
    my $self = shift;
	my $slot = shift;
	return $self->when eq $slot->when;	
}

sub ymd_hash {
    my $self = shift;
	my $when = $self->when;
    return (
        year  => substr( $when, 0, 4 ),
        month => substr( $when, 4, 2 ),
        day   => substr( $when, 6, 2 )
    );
}

sub reschedule {
    my $self = shift;
	my %args = @_;
	if( $self->type eq 'weekday' ) {
		if( my $days = $args{days} ) {
			my $weekday = $self->when + $days;
			$weekday = $weekday > 7 ? $weekday - 7 : $weekday;
			$self->when( $weekday );
		}
	} 
	else {
		my $dt = DateTime->new( $self->ymd_hash );
		$dt->add( %args );
		( my $when = $dt->ymd ) =~ s{/|\-}{}g;
		$self->when( $when );
	}
}

sub numeric {
    my $self = shift;
	if( $self->type eq 'date' ) {
		sprintf("%01d%08d%04d%04d", $self->weekday, 0, $self->start, $self->end );
	} else {
		sprintf("%01d%08d%04d%04d", $self->when, 0, $self->start, $self->end );
	}
}

1;
__END__

=pod

=head1 NAME

Calendar::Slots::Slot - the time-slot object

=head1 VERSION

version 0.15

=head1 SYNOPSIS

	use Calendar::Slots::Slot;
	my $slot = new Calendar::Slots::Slot( date=>'2009-10-22', start=>'20:30', end=>'22:30', name=>'birthday' ); 
	print
		$slot->contains( date=>'2009-10-22', time=>'21:00' )
		? 'I'm busy'
		: 'I'm free then';


=head1 DESCRIPTION

This is the basic class defining a calendar slot. 

=head1 ATTRIBUTES

    has name    => ( is => 'rw', isa => 'Str' );
    has data    => ( is => 'rw', isa => 'Any' );
    has when    => ( is => 'rw', isa => 'Int', required=>1, );
    has start   => ( is => 'rw', isa => 'Int' );
    has end     => ( is => 'rw', isa => 'Int' );
    has type    => ( is => 'rw', isa => 'Str', required=>1 );

=head1 METHODS

=head2 contains( { date=>'YYYY-MM-DD' | weekday=>1..7 }, time=>'HH:MM' )

Returns true or false if the parameters match this time slot.

=head2 numeric

Returns a numeric rendition of the date and time parts, good for sorting.

=head2 weekday

Returns a weekday (1 to 7, Monday to Sunday). Works on both date or weekday 
slots.

=head2 reschedule( add=>Int )

Adds or subtract days to a slot. 

=head2 same_day

Compare two slots and return true if the day is the same. 

=head2 same_weekday( $slot )

Compare two slots and return true if the weekday is the same.

=head2 same_type

Compare two slots and return true if types match.

=head2 ymd_hash

Returns a hash suitable to feed to L<DateTime>:

	DateTime->new( $slot->ymd_hash );

=head1 AUTHOR

Rodrigo de Oliveira C<rodrigolive@gmail.com>

=head1 LICENSE

This library is free software. You can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
