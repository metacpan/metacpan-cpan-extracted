package Date::Simple::Month;

use strict;
use base qw (Date::Range);
use vars qw($VERSION);
$VERSION = '0.02';

use Date::Simple;

sub new {
	my $class = shift;
	my $ds = eval{ _ds(@_) } or return;
	my $first = $ds - $ds->day + 1;
	my $last  = $first + Date::Simple::days_in_month($first->year, $first->month) -1;
	return $class->SUPER::new($first, $last);
}

sub _ds{
	if ( @_ == 1 ) {
		if (UNIVERSAL::isa($_[0], 'Date::Simple')) {
			return Date::Simple->new( $_[0] );
		} else {
			return Date::Simple->new(Date::Simple->new->year, $_[0], 1);
		}
	} elsif ( @_ == 2 ) {
		return Date::Simple->new($_[0], $_[1], 1);
	}
	return Date::Simple->new;
}

sub year  {shift->start->year}
sub month {shift->start->month}

sub prev_month {
	my $self = shift;
	$self->new( $self->start - 1 );
}

sub next_month {
	my $self = shift;
	$self->new( $self->end + 1 );
}

sub wraparound_dates {
	my $self = shift;
	my $start_day = shift || 0;

	my $nof_preceed = $self->_nof_preceed($start_day);
	my @preceed = $nof_preceed ? ($self->prev_month->dates)[ 0 - $nof_preceed .. -1] : ();

	my $nof_follow = $self->_nof_follow($start_day);
	my @follow = $nof_follow ? ($self->next_month->dates)[0 .. $nof_follow -1] : ();
	return @preceed , ($self->dates), @follow;
}

sub _nof_preceed {
	my ($self, $start_day) = @_;
	my $nof_preceed = $self->start->day_of_week - $start_day;
	$nof_preceed += 7 if $nof_preceed < 0;
	return $nof_preceed;
}

sub _nof_follow{
	my ($self, $start_day) = @_;
	my $nof_follow = $start_day + 6 - $self->end->day_of_week;
	$nof_follow -= 7 if $nof_follow > 6;
	return $nof_follow;
}

1;
__END__

=head1 NAME

Date::Simple::Month - a month of Date::Simple objects

=head1 SYNOPSIS

  use Date::Simple::Month;

    my $month = Date::Simple::Month->new(Date::Simple $ds); # the month includes $ds
    my $month = Date::Simple::Month->new(); # this year, this month
    my $month = Date::Simple::Month->new(int $month); # this year, $month
    my $month = Date::Simple::Month->new(int $year, int $month); # $year, $month
    
    my Date::Simple::Month $prev = $month->prev_month;
    my Date::Simple::Month $next = $month->next_month;
    
    my $cur_year   = $month->year;
    my $cur_month  = $month->month;
    
    my @dates = $month->dates;
    my @wraparound_dates = $month->wraparound_dates; # From Sunday (default)
    my @wraparound_dates_from_monday = $month->wraparound_dates(1);
    my @wraparound_dates_from_tuesday = $month->wraparound_dates(2);


=head1 DESCRIPTION

Date::Simple::Month is a subclass of Date::Range that represents a complete calendar month
consisted of Date::Simple objects.

=head1 METHOD

=head2 new

    my $month = Date::Simple::Month->new(Date::Simple $ds); # the month includes $ds
    my $month = Date::Simple::Month->new(); # this year, this month
    my $month = Date::Simple::Month->new(int $month); # this year, $month
    my $month = Date::Simple::Month->new(int $year, int $month); # $year, $month

note: This constructor return undef if this couldn't parse date.

=head2 prev_month / next_month

    my Date::Simple::Month $prev = $month->prev_month;
    my Date::Simple::Month $next = $month->next_month;

The next and previous months.

=head2 year / month

    my $cur_year  = $month->year;
    my $cur_month = $month->month;

year and month of the object.


=head2 dates

    my @dates = $month->dates;

a list of Date::Simple objecs representing each day in the month.

=head2 wraparound_dates

    my @wraparound_dates = $month->wraparound_dates; # From Sunday (default)
    my @wraparound_dates_from_monday = $month->wraparound_dates(1);
    my @wraparound_dates_from_tuesday = $month->wraparound_dates(2);
    .....

a list of Date::Simple objecs representing each day in the month including
the days on either side that ensure that the full list runs.
The start day of week can control by argument.
If no argument is given a list starts from Sunday.

=head1 AUTHOR

Yasuhiro Horiuchi E<lt>horiuchi@vcube.comE<gt>

=head1 SEE ALSO

L<Time::Piece::Month>,L<Date::Range>,L<Date::Simple>

=cut
