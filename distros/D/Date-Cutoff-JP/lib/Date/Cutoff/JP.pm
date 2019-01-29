package Date::Cutoff::JP;
use 5.008001;
use strict;
use warnings;

our $VERSION = "0.05";

use Carp;
use Time::Seconds;
use Time::Piece;
my $tp = Time::Piece->new();
use Calendar::Japanese::Holiday;
use Date::DayOfWeek;

use Moose;

has cutoff => ( is => 'rw', isa => 'Int', default => 0 );
has payday => ( is => 'rw', isa => 'Int', default => 0 );
has late    => ( is => 'rw', isa => 'Int', default => 1 );

before 'cutoff' => sub {
    my $self = shift;
    my $value = shift;
    return super() unless defined $value;
    croak "unvalid cutoff was set: $value" if $value < 0 or 31 < $value;
    return super();
};

before 'payday' => sub {
    my $self = shift;
    my $value = shift;
    return super() unless defined $value;
    croak "unvalid payday was set: $value" if $value < 0 or 31 < $value;
    croak "payday must be after cuttoff" if $value < $self->cutoff and $self->late == 0;
    return super();
};

before 'late' => sub {
    my $self = shift;
    my $value = shift;
    return super() unless defined $value;
    croak "unvalid lateness was set: $value" if $value < 0 or 2 < $value;
    return super();
};

__PACKAGE__->meta->make_immutable;

sub isWeekend {
    my $self = shift;
    my ($y, $m, $d ) = split "-", shift;
    my $dow = dayofweek( $d, $m, $y );
    return isHoliday( $y, 0+$m, 0+$d, 1 ) || $dow == 6 || $dow == 0;
}

sub calc_date {
    my $self = shift;
    my $until = shift if @_;
    my $t = $until? $tp->strptime( $until, '%Y-%m-%d' ) : localtime();
    
    my $cutoff = $self->cutoff? $self->cutoff: $t->month_last_day();
    my $str = $t->strftime('%Y-%m-') . sprintf( "%02d", $cutoff );
    my $ref_day = $t->strptime( $str, '%Y-%m-%d');
    my $over = 0;
    if ( $ref_day->epoch() < $t->epoch() ) {
        $over = 1;
        $ref_day += ONE_DAY() * $ref_day->month_last_day();
    }
    
    $cutoff = $ref_day->ymd();
    while( $self->isWeekend($cutoff) ){
        my $ref_day = $t->strptime( $cutoff, '%Y-%m-%d');
        $ref_day += ONE_DAY();
        $cutoff = $ref_day->ymd();
    }
    
    $ref_day += ONE_DAY() * 28 * ( $self->late || 0 );
    $str = $ref_day->strftime('%Y-%m-%d');
    $ref_day = $t->strptime( $str, '%Y-%m-%d');

    my $payday = $self->payday? $self->payday:  $ref_day->month_last_day();
    $str = $ref_day->strftime('%Y-%m-') . sprintf( "%02d", $payday );
    
    my $date = $t->strptime( $str, '%Y-%m-%d' )->ymd();
    while( $self->isWeekend($date) ){
        my $ref_day = $t->strptime( $date, '%Y-%m-%d');
        $ref_day += ONE_DAY();
        $date = $ref_day->ymd();
    }
    return ( cutoff => $cutoff, payday => $date, is_over => $over );
}

1;
__END__

=encoding utf-8

=head1 NAME

Date::CutOff::JP - Get the day cutoff and payday for in Japanese timezone

=head1 SYNOPSIS

 use Date::CutOff::JP;
 my $dco = Date::CutOff::JP->new({ cutoff => 0, late => 1, payday => 0 });
 my %calculated = $dco->calc_date('2019-01-01');
 print $calculated{'cutoff'}; # '2019-01-31'
 print $calculated{'payday'}; # '2019-02-28'


=head1 DESCRIPTION

Date::CutOff::JP provides how to calculate the day cutoff and the payday from Japanese calender.

you can calculate the weekday for cutoff and paying without holiday in Japan.
 
=head2 Accessor Methods
 
=head3 cutoff()
 
get/set the day cutoff in every months. 0 means the end of the month.

=head3 payday()
 
get/set the payday in every months. 0 means the end of the month.
 
=head3 late()
 
get/set the lateness. 0 means the cutoff and payday is at same month.

The all you can set is Int of [ 0 .. 2 ] 3 or more returns error.
 
=head2 Method

=head3 calc_date($date)
 
returns hash value with keys below:

=over
 
 
=item cutoff

The latest cutoff after $date.
 
=item payday
 
The latest payday after $date.

=item is_over ( maybe bad key name )
 
Is or not that the cutoff is pending until next month.

=back
 
=head1 BUGS

=head1 SEE ALSO
 
L<Calendar::Japanese::Holiday>,L<Date::DayOfWeek>
 
L<日本の祝日YAML|https://github.com/holiday-jp/holiday_jp/blob/master/holidays.yml>
 
=head1 LICENSE

Copyright (C) worthmine.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

worthmine E<lt>worthmine@cpan.orgE<gt>
 
=cut
