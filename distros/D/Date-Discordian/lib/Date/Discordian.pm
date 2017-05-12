#$Header: /home/cvs/date-discordian/lib/Date/Discordian.pm,v 1.36 2003/06/08 01:54:03 rbowen Exp $
package Date::Discordian;
use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK @SEASONS @DAYS @HOLYDAYS);
require Exporter;
use Time::Local;
use Date::Leapyear qw();
use Date::ICal;
use Memoize;

@ISA       = qw(Exporter Date::ICal);
@EXPORT    = qw( discordian inverse_discordian );
@EXPORT_OK = qw( @SEASONS @DAYS );
$VERSION   = (qw'$Revision: 1.36 $')[1];

@SEASONS = qw(Chaos Discord Confusion Bureaucracy Aftermath);
@DAYS =
  ( 'Sweetmorn', 'Boomtime', 'Pungenday', 'Prickle Prickle', 'Setting Orange' );

@HOLYDAYS = (
  [ 'Mungoday', 'Chaoflux' ],  [ 'Mojoday', 'Discoflux' ],
  [ 'Syaday',   'Confuflux' ], [ 'Zaraday', 'Bureflux' ],
  [ 'Maladay',  'Afflux' ],
);

# sub new  {{{

sub new {    # There is nothing new under the sun.
    my $class = shift;
    my %args  = @_;
    my $self;

    $args{discordian} = $args{disco} if defined $args{disco};
    $args{epoch}      = $args{EPOCH} if defined $args{EPOCH};

    # Discordian date?
    if ( $args{discordian} ) {

        $self = $class->SUPER::new( 
            epoch => from_discordian( $args{discordian} ) );
      } else {

        $self = $class->SUPER::new(%args);
    }

    bless $self, $class;
    return $self;
}    #}}}

# sub discordian {{{

sub discordian {    # Not to be confused with sub genius.
    if ( ref $_[0] ) {
        my $self = shift;
        my $d = discohash( $self->year, $self->month, $self->day );
        return $d->{disco};
      } else {
        return to_discordian( $_[0] );
    }
    # Fnord!
}    #}}}

# sub to_discordian {{{

sub to_discordian { # Be careful. It's hard to get back.
    my $datetime = shift;
    $datetime = time unless defined $datetime;
    my $d = Date::ICal->new( epoch => $datetime );

    my $discohash = discohash( $d->year, $d->month, $d->day );
    return $discohash->{disco};
}

memoize('discohash');
sub discohash {    # Is that something you smoke at a disco?
    my ( $year, $month, $d ) = @_;

    # my $datetime = shift;
    my ( $season, $day, $dow, $yold, $holyday, $datestring );

    my $yday = Date::ICal::days_this_year( $d, $month, $year ) + 1;

    # It *says* it's an internal method, but I'm not buying it.

    if ( Date::Leapyear::isleap($year) ) {
        if ( $yday <= 59 ) {

            # nothing changes
          } elsif ( $yday == 60 )
        {

            # leap day!
            $datestring = "St. Tibb's Day";
          } else {

            # The rest of the year after leap day
            $yday--;
        }
    }    # End leap year stuff

    $season = int( ( $yday - 1 ) / 73 );
    $day    = ( $yday % 73 ) || 73;
    $dow    = $yday % 5;
    $yold   = $year + 1166;

    if ( $day == 5 )     { $holyday = $HOLYDAYS[$season][0]; }
    elsif ( $day == 50 ) { $holyday = $HOLYDAYS[$season][1]; }
    else { $holyday = undef; }

    unless ($datestring) {
        if ($holyday) {
            $datestring =
              $DAYS[ $dow - 1 ] . ' (' . $holyday . '), ' . $SEASONS[$season]
              . ' ' . $day;
          } else {
            $datestring =
              $DAYS[ $dow - 1 ] . ', ' . $SEASONS[$season] . ' ' . $day;
        }
    }

    $datestring .= " YOLD $yold";

    my $discohash = {
        disco     => $datestring,
        season    => $SEASONS[$season],
        yold      => $yold,
        holyday   => $holyday,
        seasonday => $day,
        discoday  => $DAYS[ $dow - 1 ],
    };

    return $discohash;
}    #}}}

# sub inverse_discordian {{{

sub inverse_discordian {    # Sounds like a wrestling hold.
    if ( ref $_[0] ) {
        my $self = shift;
        return $self->epoch;
      } else {
        return from_discordian( $_[0] );
    }
}    #}}}

# sub from_discordian {{{

sub from_discordian {    # You only think it's possible.
    my $discordian = shift;
    my $epoch;

    for ($discordian) {

        # The day does not really matter ...
        s/sweetmorn|boomtime|setting orange|prickle prickle|pungenday//i;
        s/,//g;
        s/YOLD//i;
        s/\s+/ /g;
        s/\(.*?\)//;    # Holydays
        s/^\s+//;
    }

    # Special case - St. Tibb's Day
    if ( $discordian =~ /st\.? tibb'?s day/i ) {
        $discordian =~ m/(\d{4})/;
        my $year = $1;
        $year -= 1166;
        $epoch = timegm( 0, 0, 0, 29, 1, $year );
      } else {

        # With any luck, we now have "season day year"
        my ( $season, $day, $year ) = split / /, $discordian;
        $year -= 1166;
        $season = lc($season);
        my %seasons = (
          chaos       => 0,
          discord     => 1,
          confusion   => 2,
          bureaucracy => 3,
          aftermath   => 4
        );
        my $doy = $seasons{$season} * 73 + $day;
        $doy++ if ( $doy >= 60 && Date::Leapyear::isleap($year) );
        $epoch = ( $doy - 1 ) * 86400 + timegm( 0, 0, 0, 1, 0, $year );
    }

    return $epoch;
}    #}}}

# sub season {{{

sub season {    # For everything, there is a season.
    my $d = shift;
    my $h;

    if ( ref $d ) {
        $h = discohash( $d->year, $d->month, $d->day );
      } else {
        $h = to_discordian($d);
    }
    return $h->{season};    # turn, turn, turn
}    #}}}

# sub discoday {{{

sub discoday {    # Stayin' alive
    my $d = shift;
    my $h;

    if ( ref $d ) {
        $h = discohash( $d->year, $d->month, $d->day );
        return $h->{discoday};
      } else {
        $h = to_discordian($d);
        return $h->{discoday};
    }
}    # }}}

# sub yold {{{

sub yold {

    # Some folks say the epoch begins in 4000 BC. This is heresy. Spurn
    # these people. Or at least make strange chicken noises at them.

    my $d = shift;
    my $h;

    if ( ref $d ) {
        $h = discohash( $d->year, $d->month, $d->day );
        return $h->{yold};
      } else {
        $h = to_discordian($d);
        return $h->{yold};
    }
}    #}}}

# sub holyday {{{

sub holyday {    # Eat a hot dog
    my $d = shift;
    my $h;

    if ( ref $d ) {
        $h = discohash( $d->year, $d->month, $d->day );
        return $h->{holyday};
      } else {
        $h = to_discordian($d);
        return $h->{holyday};
    }
}    #}}}

'Hail Eris!';

# Docs {{{

=head1 NAME

Date::Discordian - Calculate the Discordian date of a particular day

=head1 SYNOPSIS

  use Date::Discordian;
  $discordian = discordian(time);
  $epochtime = inverse_discordian('bureaucracy 47, 3166');

Or, the OO interface ...

  use Date::Discordian;
  my $disco = Date::Discordian->new( epoch => time );
  $discordian = $disco->discordian;

  my $date = Date::Discordian->new( 
    discordian => 'bureaucracy 47, 3166');
  $epoch = $date->epoch;
  $ical = $date->ical;
  $discordian = $date->discordian;

  $season = $date->season;
  $discoday = $date->discoday; # eg 'Pungenday'
  $yold = $date->yold;
  $holyday = $date->holyday;

Or, for dates outside of the epoch:

  my $disco = Date::Discordian->new( ical => '17760704Z' );
  $discordian = $disco->discordian;

Note that a Date::Discordian object ISA Date::ICal object, so see the
docs for Date::ICal as well.

=head1 DESCRIPTION

Calculate the Discordian date of a particular 'real' date.

Date::Discordian exports two functions - discordian(), and
inverse_discordian. C<discordian()>,
when given a time value, returns a string, giving the Discordian
date for the given day. I<inverse_discordian()>, given a
Discordian date in the same format that C<discordian()> emits,
returns an epoch time value. It is pretty picky about time
format. Pity.

I'm really not sure how this would ever be used, so if you actually use
this, send me a note.

=head1 Bugs/To Do

    There are no bugs. Only misinterpretation of the documentation.
    Accept C<ddate>-style input. And possibly output the same format as
        ddate, since that seems more widely accepted
    Perhaps an option of some variety to be able to create dates to use
        the 4000bc epoch rather than the 1166bc epoch
    Get mentioned in more articles about the cool things you can do with
        Perl (http://www.perl.com/pub/a/2001/10/31/lighter.html)

=head1 General comments

When I first started working on this module, it was purely as an
exercise to get started on Date:: modules in general. Since that time, I
have become alarmingly aware of how the events of real life seem to
follow the Discordian calendrical rhythm. Perhaps this is just because
everything sucks all of the time, but it seems to be a little deeper
than this.

You can find out more about the Discordian Calendar at
http://jubal.westnet.com/hyperdiscordia/discordian_calendar.html
and at a plethora of other sites on the Internet.

It is related to the Principia Discordia 
(http://members.xoom.com/ffungo/titlepage.html)
and the "religion" of Discordianism. I suppose that there are people
that actually take this sort of thing seriously. But then, there are
people that collect Beanie Babies, so what do you expect?

=head1 AUTHOR

	Rich Bowen (DrBacchus) <rbowen@rcbowen.com> 
          -- (doubter of the wisdom of Discordianism)
	Matt Cashner <eek@eekeek.org> 
          -- (Sungo the Funky)

=head1 SEE ALSO

Date::ICal

Reefknot (www.reefknot.org)

datetime@perl.org (http://lists.perl.org/showlist.cgi?name=datetime)

Calendrical Calculations, by Reingold and Dershowitz. Not that it has
anything to do with this calendar, but it is a great resource if you are
interested in algorithmic calendars. And, on that same note, the Oxford
Companion to the Year is a wonderful book too.

=cut

#}}}

