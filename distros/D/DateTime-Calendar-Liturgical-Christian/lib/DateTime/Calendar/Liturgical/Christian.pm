# DateTime::Calendar::Liturgical::Christian         -*- cperl -*-
#
# This program is free software; you may distribute it under the same
# conditions as Perl itself.
#
# Copyright (c) 2006 Thomas Thurman <thomas@thurman.org.uk>
#
################################################################

package DateTime::Calendar::Liturgical::Christian;

##########################################################################

use strict;
use integer;
use vars qw(@ISA $VERSION);

##########################################################################

use Date::Calc qw(Date_to_Days Add_Delta_Days Day_of_Week Date_to_Text
        Add_Delta_DHMS);
use Storable qw(dclone);
use Exporter qw(import);

##########################################################################

$VERSION = '0.10';

##########################################################################

my %feasts = (

  # Dates relative to Easter are encoded as the number of
  # days after Easter.

  # Principal Feasts (precedence is 9)

  0  => { name => 'Easter', prec=>9 },
  39 => { name => 'Ascension', prec=>9 },
  49 => { name => 'Pentecost', colour => 'red', prec=>9 },
  56 => { name => 'Trinity', prec=>9 },

  # And others:
  -46 => { name => 'Ash Wednesday', colour=>'purple', prec=>7 },
  # is the colour of Shrove Tuesday right?
  -47 => { name => 'Shrove Tuesday', colour=>'white', prec=>7 }, 
  # Actually, Easter Eve doesn't have a colour
  -1 => { name => 'Easter Eve', colour=>'purple', prec=>7 },
  -2 => { name => 'Good Friday', colour=>'purple', prec=>7 },

  50 => { name => 'Book of Common Prayer', prec=>3 },

  # Dates relative to Christmas are encoded as 10000 + 100*m + d
  # for simplicity.

  # Principal Feasts (precedence is 9)

  10106 => {name=>'Epiphany', prec=>9},
  11101 => {name=>'All Saints', prec=>9},
  11225 => {name=>'Christmas', prec=>9},

  # Days which can take priority over Sundays (precedence is 7)

  10101 => {name=>'Holy Name', prec=>7},
  10202 => {name=>'Presentation of our Lord', prec=>7},
  10806 => {name=>'Transfiguration', prec=>7},
  
  # (Precendence of Sundays is 5)
  
  # Days which cannot take priorities over Sundays (precedence is 4
  # if major, 3 otherwise)

  10110 => {name=>'William Laud', prec=>3},
  10113 => {name=>'Hilary', prec=>3},
  10117 => {name=>'Antony', prec=>3},
  10118 => {name=>'Confession of Saint Peter', prec=>4},
  10119 => {name=>'Wulfstan', prec=>3},
  10120 => {name=>'Fabian', prec=>3},
  10121 => {name=>'Agnes', prec=>3},
  10122 => {name=>'Vincent', martyr=>1, prec=>3},
  10123 => {name=>'Phillips Brooks', prec=>3},
  10125 => {name=>'Conversion of Saint Paul', prec=>4},
  10126 => {name=>'Timothy and Titus', prec=>3},
  10127 => {name=>'John Chrysostom', prec=>3},
  10128 => {name=>'Thomas Aquinas', prec=>3},

  10203 => {name=>'Anskar', prec=>3},
  10204 => {name=>'Cornelius', prec=>3},
  10205 => {name=>'Martyrs of Japan', martyr=>1, prec=>3},
  10213 => {name=>'Absalom Jones', prec=>3},
  10214 => {name=>'Cyril and Methodius', prec=>3},
  10215 => {name=>'Thomas Bray', prec=>3},
  10223 => {name=>'Polycarp', martyr=>1, prec=>3},
  10224 => {name=>'Matthias', prec=>4},
  10227 => {name=>'George Herbert', prec=>3},

  10301 => {name=>'David', prec=>3},
  10302 => {name=>'Chad', prec=>3},
  10303 => {name=>'John and Charles Wesley', prec=>3},
  10307 => {name=>'Perpetua and her companions', martyr=>1, prec=>3},
  10308 => {name=>'Gregory of Nyssa', prec=>3},
  10309 => {name=>'Gregory the Great', prec=>3},
  10317 => {name=>'Patrick', prec=>3},
  10318 => {name=>'Cyril', prec=>3},
  10319 => {name=>'Joseph', prec=>4},
  10320 => {name=>'Cuthbert', prec=>3},
  10321 => {name=>'Thomas Ken', prec=>3},
  10322 => {name=>'James De Koven', prec=>3},
  10323 => {name=>'Gregory the Illuminator', prec=>3},
  10325 => {name=>'Annunciation of our Lord', bvm=>1, prec=>4},
  10327 => {name=>'Charles Henry Brent', prec=>3},
  10329 => {name=>'John Keble', prec=>3},
  10331 => {name=>'John Donne', prec=>3},

  10401 => {name=>'Frederick Denison Maurice', prec=>3},
  10402 => {name=>'James Lloyd Breck', prec=>3},
  10403 => {name=>'Richard of Chichester', prec=>3},
  10408 => {name=>'William Augustus Muhlenberg', prec=>3},
  10409 => {name=>'William Law', prec=>3},
  10411 => {name=>'George Augustus Selwyn', prec=>3},
  10419 => {name=>'Alphege', martyr=>1, prec=>3},
  10421 => {name=>'Anselm', prec=>3},
  10425 => {name=>'Mark the Evangelist', prec=>4},
  10429 => {name=>'Catherine of Siena', prec=>3},

  10501 => {name=>'Philip and James', prec=>4},
  10502 => {name=>'Athanasius', prec=>3},
  10504 => {name=>'Monnica', prec=>3},
  10508 => {name=>'Julian of Norwich', prec=>3},
  10509 => {name=>'Gregory of Nazianzus', prec=>3},
  10519 => {name=>'Dustan', prec=>3},
  10520 => {name=>'Alcuin', prec=>3},
  10524 => {name=>'Jackson Kemper', prec=>3},
  10525 => {name=>'Bede', prec=>3},
  10526 => {name=>'Augustine of Canterbury', prec=>3},
  10531 => {name=>'Visitation of Mary', bvm=>1, prec=>4},

  10601 => {name=>'Justin', prec=>3},
  10602 => {name=>'Martyrs of Lyons', martyr=>1, prec=>3},
  10603 => {name=>'Martyrs of Uganda', martyr=>1, prec=>3},
  10605 => {name=>'Boniface', prec=>3},
  10609 => {name=>'Columba', prec=>3},
  10610 => {name=>'Ephrem of Edessa', prec=>3},
  10611 => {name=>'Barnabas', prec=>4},
  10614 => {name=>'Basil the Great', prec=>3},
  10616 => {name=>'Joseph Butler', prec=>3},
  10618 => {name=>'Bernard Mizeki', prec=>3},
  10622 => {name=>'Alban', martyr=>1, prec=>3},
  10624 => {name=>'Nativity of John the Baptist', prec=>3},
  10628 => {name=>'Irenaeus', prec=>3},
  10629 => {name=>'Peter and Paul', martyr=>1, prec=>3},
  10704 => {name=>'Independence Day', prec=>3},
  10711 => {name=>'Benedict of Nursia', prec=>3},
  10717 => {name=>'William White', prec=>3},
  10722 => {name=>'Mary Magdalene', prec=>4},
  10724 => {name=>'Thomas a Kempis', prec=>3},
  10725 => {name=>'James the Apostle', prec=>4},
  10726 => {name=>'Parents of the Blessed Virgin Mary', bvm=>1, prec=>3},
  10727 => {name=>'William Reed Huntington', prec=>3},
  10729 => {name=>'Mary and Martha', prec=>4},
  10730 => {name=>'William Wilberforce', prec=>3},
  10731 => {name=>'Joseph of Arimathaea', prec=>3},
  
  10806 => {name=>'Transfiguration', prec=>4},
  10807 => {name=>'John Mason Neale', prec=>3},
  10808 => {name=>'Dominic', prec=>3},
  10810 => {name=>'Lawrence', martyr=>1, prec=>3},
  10811 => {name=>'Clare', prec=>3},
  10813 => {name=>'Jeremy Taylor', prec=>3},
  10815 => {name=>'Mary the Virgin', bvm=>1, prec=>4},
  10818 => {name=>'William Porcher DuBose', prec=>3},
  10820 => {name=>'Bernard', prec=>3},
  10824 => {name=>'Bartholemew', prec=>4},
  10825 => {name=>'Louis', prec=>3},
  10828 => {name=>'Augustine of Hippo', prec=>3},
  10801 => {name=>'Aidan', prec=>3},

  10902 => {name=>'Martyrs of New Guinea', martyr=>1, prec=>3},
  10912 => {name=>'John Henry Hobart', prec=>3},
  10913 => {name=>'Cyprian', prec=>3},
  10914 => {name=>'Holy Cross', prec=>4},
  10916 => {name=>'Ninian', prec=>3},
  10918 => {name=>'Edward Bouverie Pusey', prec=>3},
  10919 => {name=>'Theodore of Tarsus', prec=>3},
  10920 => {name=>'John Coleridge Patteson and companions', martyr=>1, prec=>3},
  10921 => {name=>'Matthew', martyr=>1, prec=>4},
  10925 => {name=>'Sergius', prec=>3},
  10926 => {name=>'Lancelot Andrewes', prec=>3},
  10929 => {name=>'Michael and All Angels', prec=>4},
  10930 => {name=>'Jerome', prec=>3},

  11001 => {name=>'Remigius', prec=>3},
  11004 => {name=>'Francis of Assisi', prec=>3},
  11006 => {name=>'William Tyndale', prec=>3},
  11009 => {name=>'Robert Grosseteste', prec=>3},
  11015 => {name=>'Samuel Isaac Joseph Schereschewsky', prec=>3},
  11016 => {name=>'Hugh Latimer, Nicholas Ridley, Thomas Cranmer', martyr=>1, prec=>3},
  11017 => {name=>'Ignatius', martyr=>1, prec=>3},
  11018 => {name=>'Luke', prec=>4},
  11019 => {name=>'Henry Martyn', prec=>3},
  11023 => {name=>'James of Jerusalem', martyr=>1, prec=>4},
  11026 => {name=>'Alfred the Great', prec=>3},
  11028 => {name=>'Simon and Jude', prec=>4},
  11029 => {name=>'James Hannington and his companions', martyr=>1, prec=>3},

  11101 => {name=>'All Saints', prec=>4},
  11102 => {name=>'All Faithful Departed', prec=>3},
  11103 => {name=>'Richard Hooker', prec=>3},
  11107 => {name=>'Willibrord', prec=>3},
  11110 => {name=>'Leo the Great', prec=>3},
  11111 => {name=>'Martin of Tours', prec=>3},
  11112 => {name=>'Charles Simeon', prec=>3},
  11114 => {name=>'Consecration of Samuel Seabury', prec=>3},
  11116 => {name=>'Margaret', prec=>3},
  11117 => {name=>'Hugh', prec=>3},
  11118 => {name=>'Hilda', prec=>3},
  11119 => {name=>'Elizabeth of Hungary', prec=>3},
  11123 => {name=>'Clement of Rome', prec=>3},
  11130 => {name=>'Andrew', prec=>4},

  11201 => {name=>'Nicholas Ferrar', prec=>3},
  11202 => {name=>'Channing Moore Williams', prec=>3},
  11204 => {name=>'John of Damascus', prec=>3},
  11205 => {name=>'Clement of Alexandria', prec=>3},
  11206 => {name=>'Nicholas', prec=>3},
  11207 => {name=>'Ambrose', prec=>3},
  11221 => {name=>'Thomas', prec=>4},
  # Christmas is dealt with above
  11226 => {name=>'Stephen', martyr=>1, prec=>4},
  11227 => {name=>'John the Apostle', prec=>4},
  11228 => {name=>'Holy Innocents', martyr=>1, prec=>4},

); 

# This returns the date easter occurs on for a given year as ($month,$day).
# This is from the Calendar FAQ.
# Taken from Date::Manip.
sub Date_Easter {
  my($y)=@_;

  my($c) = $y/100;
  my($g) = $y % 19;
  my($k) = ($c-17)/25;
  my($i) = ($c - $c/4 - ($c-$k)/3 + 19*$g + 15) % 30;
  $i     = $i - ($i/28)*(1 - ($i/28)*(29/($i+1))*((21-$g)/11));
  my($j) = ($y + $y/4 + $i + 2 - $c + $c/4) % 7;
  my($l) = $i-$j;
  my($m) = 3 + ($l+40)/44;
  my($d) = $l + 28 - 31*($m/4);
  return ($m,$d);
}

sub advent_sunday {
    my ($y) = @_;
    return -(Day_of_Week($y,12,25) + 4*7);
}

##########################################################################

sub new {
  my ($class, %opts) = @_;
  
  my $y = $opts{year};
  my $m = $opts{month};
  my $d = $opts{day};

  die "Need to specify year, month and day" unless $y and $m and $d;

  my $days = Date_to_Days($y, $m, $d);
  my $easter = Date_to_Days($y, Date_Easter($y));

  my @possibles;

  # "The Church Year consists of two cycles of feasts and holy days: one is
  #  dependent upon the movable date of the Sunday of the Resurrection or
  #  Easter Day; the other, upon the fixed date of December 25, the Feast
  #  of our Lord's Nativity or Christmas Day."

  my $easter_point = $days-$easter;
  my $christmas_point;

  # We will store the amount of time until (-ve) or since (+ve) Christmas in
  # $christmas_point. Let's make the cut-off date the end of February,
  # since we'll be dealing with Easter-based dates after that, and it
  # avoids the problems of considering leap years.

  if ($m>2) {
      $christmas_point = $days - Date_to_Days($y, 12, 25);
  } else {
      $christmas_point = $days - Date_to_Days($y-1, 12, 25);
  }

  # First, figure out the season.
  my ($season, $weekno);

  my $advent_sunday = advent_sunday($y);

  if ($easter_point>-47 && $easter_point<0) {
      $season = 'Lent';
      $weekno = ($easter_point+50)/7;
      # FIXME: The ECUSA calendar seems to indicate that Easter Eve ends
      # Lent *and* begins the Easter season. I'm not sure how. Maybe it's
      # in both? Maybe the daytime is in Lent and the night is in Easter?
  } elsif ($easter_point>=0 && $easter_point<=49) {
      # yes, this is correct: Pentecost itself is in Easter season;
      # Pentecost season actually begins on the day after Pentecost.
      # Its proper name is "The Season After Pentecost".
      $season = 'Easter';
      $weekno = $easter_point/7;
  } elsif ($christmas_point>=$advent_sunday && $christmas_point<=-1) {
      $season = 'Advent';
      $weekno = 1+($christmas_point-$advent_sunday)/7;
  } elsif ($christmas_point>=0 && $christmas_point<=11) {
      # The Twelve Days of Christmas.
      $season = 'Christmas';
      $weekno = 1+$christmas_point/7;
  } elsif ($christmas_point>=12 && $easter_point <= -47) {
      $season = 'Epiphany';
      $weekno = 1+($christmas_point-12)/7;
  } else {
      $season = 'Pentecost';
      $weekno = 1+($easter_point-49)/7;
  }

  # Now, look for feasts.

  my $feast_from_Easter    = $feasts{$easter_point};
  my $feast_from_Christmas = $feasts{10000+100*$m+$d};

  push @possibles, $feast_from_Easter if $feast_from_Easter;
  push @possibles, $feast_from_Christmas if $feast_from_Christmas;

  # Maybe transferred from yesterday.

  unless ($opts{transferred}) { # don't go round infinitely
      my ($yestery, $yesterm, $yesterd) = Add_Delta_Days(1, 1, 1, $days-2);
      my $transferred = $class->new(
          %opts,
          year => $yestery,
          month => $yesterm,
          day => $yesterd,
          transferred=>1,
      );

      if ($transferred) {
          $transferred->{name} .= ' (transferred)';
          push @possibles, $transferred;
      }
  }

  # Maybe a Sunday.

  push @possibles, { prec=>5, name=>"$season $weekno" }
        if Day_of_Week($y, $m, $d)==7;

  # So, which event takes priority?

  @possibles = sort { $b->{prec} <=> $a->{prec} } @possibles;

  if ($opts{transferred}) {
      # If two feasts coincided today, we were asked to find
      # the one which got transferred.
      # But Sundays don't get transferred!
      return undef if $possibles[1] && $possibles[1]->{prec}==5;
      return $possibles[1];
  }
  
  my $result = ${dclone(\($possibles[0]))};
  $result = { name=>'', prec=>1 } unless $result;
  $result = { %opts, %$result, season=>$season, weekno=>$weekno };

  if ($opts{rose}) {
      my %rose_days = ( 'Advent 2'=>1, 'Lent 3'=>1 );
      $result->{colour} = 'rose' if $rose_days{$result->{name}};
  }

  if (!defined $result->{colour}) {
      if ($result->{prec}>2 && $result->{prec}!=5) {
          # feasts are generally white,
          # unless marked differently.
          # But martyrs are red, and Marian
          # feasts *might* be blue.
          if ($result->{martyr}) {
              $result->{colour} = 'red';
          } elsif ($opts{bvm_blue} && $result->{bvm}) {
              $result->{colour} = 'blue';
          } else {
              $result->{colour} = 'white';
          }
      } else {
          # Not a feast day.
          if ($season eq 'Lent') {
              $result->{colour} = 'purple';
          } elsif ($season eq 'Advent') {
              if ($opts{advent_blue}) {
                  $result->{colour} = 'blue';
              } else {
                  $result->{colour} = 'purple';
              }
          } else {
              # The great fallback:
              $result->{colour} = 'green';
          }
      }
  }

  # Two special cases for Christmas-based festivals which
  # depend on the day of the week.

  if ($result->{prec} == 5) { # An ordinary Sunday
      if ($christmas_point == $advent_sunday) {
          $result->{name} = 'Advent Sunday';
          $result->{colour} = 'white';
      } elsif ($christmas_point == $advent_sunday-7) {
          $result->{name} = 'Christ the King';
          $result->{colour} = 'white';
      }
  }

  return bless($result, $class);
}
 
sub year   { my ($self)=@_; return $self->{year};   }
sub month  { my ($self)=@_; return $self->{month};  }
sub day    { my ($self)=@_; return $self->{day};    }
sub colour { my ($self)=@_; return $self->{colour}; }
sub color  { goto &colour; }
sub season { my ($self)=@_; return $self->{season}; }
sub name   { my ($self)=@_; return $self->{name};   }
sub bvm    { my ($self)=@_; return $self->{bvm};    }


sub utc_rd_values {
    my ($self)=@_;
    return (
        Date_to_Days($self->{year}, $self->{month}, $self->{day})-1,
        0,
        0,
    );
}

sub from_object {
    my ($class, $object)=@_;
    my ($days, $secs, $nanosecs) = $object->utc_rd_values();

    my ($y, $m, $d, $hour, $min, $seconds) =
        Add_Delta_DHMS(1, 1, 1, 0, 0, 0, $days-1, 0, 0, $secs);

    return $class->new(
        day => $d,
        month => $m,
        year => $y,
        hour => $hour,
        minute => $min,
        seconds => $seconds,
        nanosecond => $nanosecs,
    );
}

1;

__END__

=head1 NAME

DateTime::Calendar::Liturgical::Christian - calendar of the church year

=head1 SYNOPSIS

 $dtclc = DateTime::Calendar::Liturgical::Christian->new(
    day=>4,
    month=>6,
    year=>2006);

 print $dtclc->name();    # 'Pentecost'
 print $dtclc->colour();  # 'red'

=head1 DESCRIPTION

This module will return the name, season, week number and liturgical colour
for any day in the Gregorian calendar. It will eventually support the
liturgical calendars of several churches (hopefully at least Anglican,
Lutheran, Orthodox and Roman Catholic). At present it only knows the calendar
for the Episcopal Church of the USA.

If you find bugs, or if you have information on the calendar of another
liturgical church, please do let me know (thomas at thurman dot org dot uk).

=head1 OVERVIEW

Some churches use a special church calendar. Days and seasons within the year
may be either "fasts" (solemn times) or "feasts" (joyful times). The year is
structured around the greatest feast in the calendar, the festival of the
Resurrection of Jesus, known as Easter, and the second greatest feast, the
festival of the Nativity of Jesus, known as Christmas. Before Christmas and
Easter there are solemn fast seasons known as Advent and Lent respectively.
After Christmas comes the feast of Epiphany, and after Easter comes the feast
of Pentecost. These days have the adjacent seasons named after them.

The church's new year falls on Advent Sunday, which occurs around the start of
December. Then follows the four-week fast season of Advent, then comes the
Christmas season, which lasts twelve days; then comes Epiphany, then the
forty days of Lent. Then comes Easter, then the long season of Pentecost
(which some churches call Trinity, after the feast which falls soon after
Pentecost). Then the next year begins and we return to Advent again.

Along with all these, the church remembers the women and men who have made
a positive difference in church history by designating feast days for them,
usually on the anniversary of their death. For example, we remember St. Andrew
on the 30th day of November in the Western churches. Every Sunday is the feast
day of Jesus, and if it has no other name is numbered according to the
season in which it falls. So, for example, the third Sunday in Pentecost
season would be called Pentecost 3.

Seasons are traditionally assigned colours, which are used for clothing and
other materials. The major feasts are coloured white or gold. Fasts are
purple. Feasts for martyrs (people who died for their faith) are red.
Other days are green.

=head1 CONSTRUCTOR

=over 4

=item new ([ OPTIONS ])

This constructs a DateTime::Calendar::Liturgical::Christian object. It takes
a series of named options. Possible options are:

B<year> (required). The year AD in the Gregorian calendar.

B<month> (required). The month number in the Gregorian calendar. 1 is January.

B<day> (required). The day of the month.

B<tradition> (recommended). The tradition to use. Currently only C<ECUSA> is known.

B<advent_blue>. It is currently popular in ECUSA to colour Advent blue,
instead of purple, which will happen if this option is set to 1.

B<bvm_blue>. Some people mark feasts of the Blessed Virgin Mary, the mother of
Jesus, with blue instead of white. This will happen if this option is set to
1. To tell the difference between this blue and C<advent_blue>'s blue, see the
C<bvm> method, below.

B<rose>. Some people colour the middle Sundays of Lent and Advent pink, or
"rose", instead of purple. This will happen if this option is set to 1.

=item from_object ( OBJECT )

Constructs a DateTime::Calendar::Liturgical::Christian object from an object
of any other DateTime class.

=back

=head1 METHODS

=over 4

=item name

Returns the name of the feast, if any.

=item season

Returns the season.

=item colour

Returns the colour of the day. Can be C<red>, C<green>, C<white>, or C<purple>,
or C<blue> or C<rose> if the relevant options are set.

=item color

Alternative spelling of C<colour>.

=item bvm

Returns true if the current day is a feast of the Blessed Virgin Mary. This
can be used to distinguish Advent blue from Marian blue.

=item day

Returns the day number which was used to construct the object.

=item month

Returns the month number which was used to construct the object.

=item year

Returns the year number which was used to construct the object.

=back

=head1 SEE ALSO

C<DateTime>.

=head1 COPYRIGHT

Copyright (c) 2006 Thomas Thurman.
This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

If you use this software, please consider sending me an email at
thomas at thurman dot org dot uk, so that I can see where it's being used.

=cut

