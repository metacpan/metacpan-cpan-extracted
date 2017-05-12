package DateTime::BusinessHours;

use strict;
use warnings;

use DateTime;
use Class::MethodMaker [
    scalar => [
        qw( datetime1 datetime2 worktiming weekends holidayfile holidays )
    ],
];

our $VERSION = '2.03';

sub new {
    my ( $class, %args ) = @_;

    die 'datetime1 parameter required' if !$args{ datetime1 };
    die 'datetime2 parameter required' if !$args{ datetime2 };

    $args{ worktiming } ||= [ [ 9, 17 ] ];
    $args{ weekends }   ||= [ 6, 7 ];
    $args{ holidays }   ||= [ ];

    if( !ref @{ $args{ worktiming } }[ 0 ] ) {
        $args{ worktiming } = [ [ @{ $args{ worktiming } } ] ];
    }

    my $obj = bless \%args, $class;

    # initialize holiday map on this object
    $obj->_set_holidays();
    my %holiday_map = map { $_ => 1 }
        grep { $_ ge $obj->datetime1->ymd && $_ le $obj->datetime2->ymd }
        @{$obj->holidays};
    $obj->{_holiday_map} = \%holiday_map;

    return $obj;
}

sub calculate {
    my $self = shift;
    $self->{ _result } = undef;
    $self->_calculate;
}

sub _calculate {
    my $self = shift;

    return $self->{ _result } if defined $self->{ _result };
    $self->{ _result } = { days => 0, hours => 0 };

    # number of hours in a work day
    my $length = $self->_calculate_day_length;
    my $d1 = $self->datetime1->clone;
    my $d2 = $self->datetime2->clone;

    # swap if "start" is more recent than "end"
    ( $d1, $d2 ) = ( $d2, $d1 ) if $d1 > $d2;

    my $start = $d1->clone->truncate( to => 'day' );
    my $end   = $d2->clone->truncate( to => 'day' );

    # deal with everything non-inclusive to the start/end
    $start->add( days => 1 );
    $end->subtract( days => 1 );

    while( $start <= $end ) {
        if( $self->_is_business_day($start) ) {
            $self->{ _result }->{ hours } += $length;
        }
        $start->add( days => 1 );
    }

    # handle start and end days
    for( reverse @{ $self->{ _timing_norms } } ) {
        last if $d1 >= $d1->clone->set( %{ $_->[ 1 ] } ); #start >= end time of same day
        last if $d2 <= $d1->clone->set( %{ $_->[ 0 ] } ); #end <= start time of same day
        last if ! $self->_is_business_day($d1); #it's possible we start on a non-bus day

        my $r1 = $d1->clone->set( %{ $_->[ 0 ] } );
        my $r2 = $d1->clone->set( %{ $_->[ 1 ] } );

        # full or partial range
        $r1 = $d1 if $d1 > $r1;
        $r2 = $d2 if $d2 < $r2; # only happens when $d1 and $d2 are on the same day

        my $dur = $r2 - $r1;
        $self->{ _result }->{ hours } += $dur->in_units( 'minutes' ) / 60;
    }

    # if start and end aren't on the same day
    if( $d1->truncate( to => 'day' ) != $d2->clone->truncate( to => 'day' ) ) {
        for( @{ $self->{ _timing_norms } } ) {
            last if $d2 <= $d2->clone->set( %{ $_->[ 0 ] } ); #end <= start of same day
            last if $d1 >= $d2->clone->set( %{ $_->[ 1 ] } ); #start >= end of same day
            last if ! $self->_is_business_day($d2); #it's possible we end on a non-bus day

            my $r1 = $d2->clone->set( %{ $_->[ 0 ] } );
            my $r2 = $d2->clone->set( %{ $_->[ 1 ] } );

            # full or partial range
            $r2 = $d2 if $d2 < $r2;

            my $dur = $r2 - $r1;
            $self->{ _result }->{ hours } += $dur->in_units( 'minutes' ) / 60;
        }
    }

    $self->{ _result }->{ days } = $self->{ _result }->{ hours } / $length;
    return $self->{ _result };
}

# determine how many hours are in a business day
sub _calculate_day_length {
    my $self = shift;

    $self->{ _day_length } = 0;
    $self->{ _timing_norms } = [];

    for my $i ( @{ $self->worktiming } ) {
        push @{ $self->{ _timing_norms } }, [];
        for( @$i ) {
            # normalize input times
            $_ = sprintf( '%02s00', $_ ) if length == 1 || length == 2;
            $_ = sprintf( '%04s', $_ );

            my( $h, $m ) = m{(..)(..)};

            # normalize input times for use with DateTime
            push @{ $self->{ _timing_norms }->[ -1 ] }, { hour => $h, minute => $m };
        }
    }

    for my $tn ( @{ $self->{ _timing_norms } } ) {
        my $dur = DateTime->new( year => 2012, %{ $tn->[ 1 ] } )
            - DateTime->new( year => 2012, %{ $tn->[ 0 ] } );
        $self->{ _day_length } += $dur->in_units( 'minutes' ) / 60;
    }

    return $self->{ _day_length };
}

sub _set_holidays{
    my $self = shift;

    my @holidays = @{ $self->holidays };
    my $filename = $self->holidayfile;

    if( $filename && -e $filename ) {
        open( my $fh, '<', $filename );
        while ( <$fh> ) { chomp; push @holidays, $_ };
        close $fh;
    }

    $self->{holidays} = \@holidays;
}

sub getdays {
    return shift->_calculate->{ days };
}

sub gethours {
    return shift->_calculate->{ hours };
}

# return 1 if day is not a weekend and it's not a holiday
# return 0 otherwise
sub _is_business_day {
  my $self = shift;
  my $dt = shift;
  return 0 if ($self->_is_weekend($dt) || $self->_is_holiday($dt));
  return 1;
}

# Returns 1 if the datetime provided is a weekend day perl the weekend option
# Returns 0 otherwise
sub _is_weekend {
  my $self = shift;
  my $day_of_week  = (shift)->day_of_week;
  for my $defined_we (@{$self->{weekends}}) {
    return 1 if ($defined_we == $day_of_week);
  }
  return 0;
}

# Returns 1 if the datetime provided is in the holiday map
sub _is_holiday {
  my $self = shift;
  my $date  = (shift)->ymd;

  return exists($self->{_holiday_map}->{$date});
}

1;

__END__

=head1 NAME

DateTime::BusinessHours - An object that calculates business days and hours 

=head1 SYNOPSIS

    my $d1 = DateTime->new( year => 2007, month => 10, day => 15 );
    my $d2 = DateTime->now;

    my $test = DateTime:::BusinessHours->new(
        datetime1 => $d1,
        datetime2 => $d2,
        worktiming => [ 9, 17 ], # 9am to 5pm
        # lunch from 12 to 1
        # worktiming => [ [ 9, 12 ], [ 13, 17 ] ],
        weekends => [ 6, 7 ], # Saturday and Sunday
        holidays => [ '2007-10-31', '2007-12-24' ],
        holidayfile => 'holidays.txt'
        # holidayfile is a text file with each date in a new line
        # in the format yyyy-mm-dd  
    );

    # total business hours
    print $test->gethours, "\n";
    # total business days, based on the number of business hours in a day
    print $test->getdays, "\n"; 

=head1 DESCRIPTION

BusinessHours a class for caculating the business hours between two DateTime 
objects. It can be useful in situations like escalation where an action has to 
happen after a certain number of business hours.

=head1 METHODS

=head2 new( %args )

This class method accepts the following arguments as parameters:

=over 4

=item * datetime1 - Starting Date 

=item * datetime2 - Ending Date

=item * worktiming - May be one of the following:

=over 4

=item * An array reference with two values: starting and ending hour of the day

=item * An array reference of array references. Each reference being a slice of the 24-hour clock where business is conducted. Useful if you want to leave a "lunch hour" out of the calculation. Defaults to [ [ 9, 17 ] ]

=back

=item * weekends - An array reference with values of the days that must be considered as non-working in a week. Defaults to [6,7] (Saturday & Sunday)

=item * holidays - An array reference with holiday dates in 'yyyy-mm-dd' format

=item * holidayfile - The name of a file from which predefined holidays can be excluded from business days/hours calculation. Defaults to no file

=back

=head2 calculate( )

This will force a recalculation of the business hours and days. useful if you've changed any values (datetime1, datetime2, worktiming, etc) or updated the holiday file

=head2 getdays( )

Returns the number of business days

=head2 gethours( )

Returns the number of business hours.

=head1 INSTALLATION

To install this module, run the following commands:

	perl Makefile.PL
	make
	make test
	make install

=head1 SUPPORT AND DOCUMENTATION

After installing, you can find documentation for this module with the
perldoc command.

    perldoc DateTime::BusinessHours

You can also look for information at:

    RT, CPAN's request tracker
        http://rt.cpan.org/NoAuth/Bugs.html?Dist=DateTime-BusinessHours

    AnnoCPAN, Annotated CPAN documentation
        http://annocpan.org/dist/DateTime-BusinessHours

    CPAN Ratings
        http://cpanratings.perl.org/d/DateTime-BusinessHours

    Search CPAN
        http://search.cpan.org/dist/DateTime-BusinessHours

=head1 AUTHOR

Antano Solar John <solar345@gmail.com>

=head1 MAINTAINER

Brian Cassidy <bricas@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2007-2011 Antano Solar John, 2012-2013 by Brian Cassidy

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

