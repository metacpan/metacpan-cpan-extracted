package DateTime::Event::Holiday::US;

use warnings;
use strict;

use Carp 'croak';
use DateTime::Format::ICal;
use DateTime::Set;


our $VERSION = '0.02';


{  # Make the hash private

  # How do I do this?
  #Kwanzaa
  #December 26 through January 1

  my %holiday = (

    # January
    'New Years Day'                   => 'RRULE:FREQ=YEARLY;BYMONTH=1;BYMONTHDAY=1',   # January 1
    'Martin Luther King, Jr Birthday' => 'RRULE:FREQ=YEARLY;BYMONTH=1;BYMONTHDAY=15',  # January 15
    'Martin Luther King Day'          => 'RRULE:FREQ=YEARLY;BYMONTH=1;BYDAY=3mo',      # Third Monday in January

    # February
    'Groundhog Day'                   => 'RRULE:FREQ=YEARLY;BYMONTH=2;BYMONTHDAY=2',   # February 2
    'Super Bowl Sunday'               => 'RRULE:FREQ=YEARLY;BYMONTH=2;BYDAY=1su',      # First Sunday in February
    'Lincolns Birthday'               => 'RRULE:FREQ=YEARLY;BYMONTH=2;BYMONTHDAY=12',  # February 12
    'Valentines Day'                  => 'RRULE:FREQ=YEARLY;BYMONTH=2;BYMONTHDAY=14',  # February 14
    'Susan B. Anthony Day'            => 'RRULE:FREQ=YEARLY;BYMONTH=2;BYMONTHDAY=15',  # February 15
    'Washingtons Birthday (observed)' => 'RRULE:FREQ=YEARLY;BYMONTH=2;BYDAY=3mo',      # Third Monday in February
    'Washingtons Birthday'            => 'RRULE:FREQ=YEARLY;BYMONTH=2;BYMONTHDAY=22',  # February 22

    # March
    'St. Patricks Day' => 'RRULE:FREQ=YEARLY;BYMONTH=3;BYMONTHDAY=17',                 # March 17
    'Cesar Chavez Day' => 'RRULE:FREQ=YEARLY;BYMONTH=3;BYMONTHDAY=31',                 # March 31
    'Sewards Day'      => 'RRULE:FREQ=YEARLY;BYMONTH=3;BYDAY=-1mo',                    # Last Monday in March

    # April
    'Confederate Memorial Day' => 'RRULE:FREQ=YEARLY;BYMONTH=4;BYDAY=4mo',             # Fourth Monday in April
    'April Fools Day'          => 'RRULE:FREQ=YEARLY;BYMONTH=4;BYMONTHDAY=1',          # April 1
    'Earth Day'                => 'RRULE:FREQ=YEARLY;BYMONTH=4;BYMONTHDAY=22',         # April 22
    'Emancipation Day'         => 'RRULE:FREQ=YEARLY;BYMONTH=4;BYMONTHDAY=16',         # April 16

    # May
    'Primary Election Day' => 'RRULE:FREQ=YEARLY;BYMONTH=5;BYDAY=TU;BYMONTHDAY=2,3,4,5,6,7,8',  # First Tuesday after 1st Monday in May
    'Mothers Day'          => 'RRULE:FREQ=YEARLY;BYMONTH=5;BYDAY=2su',                          # Second Sunday in May
    'Memorial Day'         => 'RRULE:FREQ=YEARLY;BYMONTH=5;BYDAY=-1mo',                         # Last Monday in May

    # June
    'Jefferson Davis Day' => 'RRULE:FREQ=YEARLY;BYMONTH=6;BYDAY=1mo',                           # First Monday in June
    'Flag Day'            => 'RRULE:FREQ=YEARLY;BYMONTH=6;BYMONTHDAY=14',                       # June 14
    'Fathers Day'         => 'RRULE:FREQ=YEARLY;BYMONTH=6;BYDAY=3su',                           # Third Sunday in June

    # July
    'Independence Day' => 'RRULE:FREQ=YEARLY;BYMONTH=7;BYMONTHDAY=4',                           # July 4

    # August
    'Womens Equality Day' => 'RRULE:FREQ=YEARLY;BYMONTH=8;BYMONTHDAY=26',                       # August 26

    # September
    'Labor Day'       => 'RRULE:FREQ=YEARLY;BYMONTH=9;BYDAY=1mo',                               # First Monday in September
    'Patriot Day'     => 'RRULE:FREQ=YEARLY;BYMONTH=9;BYMONTHDAY=11',                           # September 11
    'Citizenship Day' => 'RRULE:FREQ=YEARLY;BYMONTH=9;BYMONTHDAY=17',                           # September 17

    # October
    'Columbus Day'     => 'RRULE:FREQ=YEARLY;BYMONTH=10;BYDAY=2mo',                             # Second Monday in October
    'Leif Erikson Day' => 'RRULE:FREQ=YEARLY;BYMONTH=10;BYMONTHDAY=9',                          # October 9
    'Alaska Day'       => 'RRULE:FREQ=YEARLY;BYMONTH=10;BYMONTHDAY=18',                         # October 18
    'Halloween'        => 'RRULE:FREQ=YEARLY;BYMONTH=10;BYMONTHDAY=31',                         # October 31

    # November
    'Election Day'     => 'RRULE:FREQ=YEARLY;BYMONTH=11;BYDAY=TU;BYMONTHDAY=2,3,4,5,6,7,8',         # First Tuesday after 1st Monday in November
    'Veterans Day'     => 'RRULE:FREQ=YEARLY;BYMONTH=11;BYMONTHDAY=11',                             # November 11
    'Thanksgiving Day' => 'RRULE:FREQ=YEARLY;BYMONTH=11;BYDAY=4th',                                 # Fourth Thursday in November
    'Black Friday'     => 'RRULE:FREQ=YEARLY;BYMONTH=11;BYDAY=FR;BYMONTHDAY=23,24,25,26,27,28,29',  # Friday after Thanksgiving Day

    # December
    'Pearl Harbor Remembrance Day' => 'RRULE:FREQ=YEARLY;BYMONTH=12;BYMONTHDAY=7',                  # December 7
    'Winter Solstice'              => 'RRULE:FREQ=YEARLY;BYMONTH=12;BYMONTHDAY=21',                 # December 21
    'Christmas Eve'                => 'RRULE:FREQ=YEARLY;BYMONTH=12;BYMONTHDAY=24',                 # December 24
    'Christmas'                    => 'RRULE:FREQ=YEARLY;BYMONTH=12;BYMONTHDAY=25',                 # December 25
    'New Years Eve'                => 'RRULE:FREQ=YEARLY;BYMONTH=12;BYMONTHDAY=31',                 # December 31

  );

  # Aliases

  $holiday{ 'Fourth of July' } = $holiday{ 'Independence Day' };
  $holiday{ 'Presidents Day' } = $holiday{ 'Washingtons Birthday (observed)' };
  $holiday{ 'Thanksgiving' }   = $holiday{ 'Thanksgiving Day' };


  sub known { my @keys = sort keys %holiday; return wantarray ? @keys : \@keys }


  sub holiday {

    my ( $holiday ) = @_;

    croak "Unknown holiday ($holiday)"
      unless exists $holiday{ $holiday };

    return DateTime::Format::ICal->parse_recurrence( 'recurrence' => $holiday{ $holiday } );

  }


  sub holidays {

    my @holidays = @_;

    my %h;

    $h{ $_ } = holiday( $_ ) for @holidays;

    return \%h;

  }


  sub holidays_as_set {

    my @holidays = values %{ holidays( @_ ) };

    my $set = shift @holidays;

    $set = $set->union( $_ ) for @holidays;

    return $set;

  }

};


1;  # End of DateTime::Event::Holiday::US

__END__
=pod

=head1 NAME

DateTime::Event::Holiday::US

=head1 VERSION

version 0.02

=head1 SYNOPSIS

# This module handles creating a DateTime::Set::ICal object (see
# DateTime::Event::Recurrence) that you can use as a US holiday.

  use DateTime::Event::Holiday::US;

  my $thanksgiving = DateTime::Event::Holiday::US::holiday( 'Thanksgiving' );
  my @holidays = DateTime::Event::Holiday::US::known();

# $thanksgiving will be a DateTime::Set::ICal object that you can perform
# anything you would do with a DateTime::Set object.

# $holidays will be an array of all holiday names DateTime::Event::Holiday::US
# knows about.

=head1 NAME

DateTime::Event::Holiday::US - US Holiday's as DateTime::Set objects

=head1 VERSION

Version 0.02

=head1 EXPORT

Nothing is exported.

=head1 SUBROUTINES/METHODS

=head2 known

Returns a list of holiday names DateTime::Event::Holiday::US knows about.

  @known = DateTime::Event::Holiday::US::known();

=head2 holiday

Returns the requested holiday as a DateTime::Set::ICal object.

  $thanksgiving = DateTime::Event::Holiday::US::holiday( 'Thanksgiving' );

$thanksgiving will be a DateTime::Set::ICal object that you can perform
anything you would do with a DateTime::Set object.

=head2 holidays

Returns a hash reference of DateTime::Set::ICal objects for each holiday.

  $holidays = DateTime::Event::Holiday::US::holidays( 'Thanksgiving', 'Black Friday' );

$holidays is a hash reference where the key is the name of the holiday and the
value is the object.

=head2 holidays_as_set

Returns requested holidays as a single DateTime::Set object;

  $holidays = DateTime::Event::Holiday::US::holidays_as_set( 'Thanksgiving', 'Black Friday' );

$holidays would be a DateTime::Set containing sets for both Thanksgiving and Black Friday

=head1 AUTHOR

Alan Young, C<< <alansyoungiii at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-datetime-event-holiday-us at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=DateTime-Event-Holiday-US>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc DateTime::Event::Holiday::US

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=DateTime-Event-Holiday-US>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/DateTime-Event-Holiday-US>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/DateTime-Event-Holiday-US>

=item * Search CPAN

L<http://search.cpan.org/dist/DateTime-Event-Holiday-US/>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

Copyright 2010 Alan Young.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=head1 INSTALLATION

See perlmodinstall for information and options on installing Perl modules.

=head1 AUTHOR

Alan Young <harleypig@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Alan Young.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

