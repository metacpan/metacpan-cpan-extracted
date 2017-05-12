# Timezone objects.

# Copyright 2007, 2008, 2009, 2010 Kevin Ryde

# This file is part of Chart.
#
# Chart is free software; you can redistribute it and/or modify it under the
# terms of the GNU General Public License as published by the Free Software
# Foundation; either version 3, or (at your option) any later version.
#
# Chart is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
# details.
#
# You should have received a copy of the GNU General Public License along
# with Chart.  If not, see <http://www.gnu.org/licenses/>.

package App::Chart::TZ;
use 5.010;
use strict;
use warnings;
use Carp;
use List::Util;
use POSIX ();
use Scalar::Util;
use Locale::TextDomain ('App-Chart');

use App::Chart;
use base 'Time::TZ';



#------------------------------------------------------------------------------
# maybe for Time::TZ ...

sub tm_localtime {
  my ($self, $timet) = @_;
  require Time::localtime;
  if (! defined $timet) { $timet = time(); }
  local $Tie::TZ::TZ = $self->tz;
  return Time::localtime ($timet);
}

# rolling century means they're not the reverse of localtime :-(.
#
# =item C<$time_t = $tz-E<gt>timelocal ($sec,$min,$hour,$mday,$mon,$year)>
# 
# =item C<$time_t = $tz-E<gt>timelocal_nocheck ($sec,$min,$hour,$mday,$mon,$year)>
# 
# Call C<Time::Local::timelocal()> in the given C<$tz> timezone.  C<$time_t>
# is a value from C<time()>, or defaults to the current C<time()>.  The return
# is the usual list of 9 localtime values (see L<perlfunc/localtime>).
# 
#     my $t = $tz->timelocal (0,0,12, 1,0,99);
# 
sub timelocal {
  my $self = shift;
  require Time::Local;
  local $Tie::TZ::TZ = $self->tz;
  return Time::Local::timelocal (@_);
}
sub timelocal_nocheck {
  my $self = shift;
  require Time::Local;
  local $Tie::TZ::TZ = $self->tz;
  return Time::Local::timelocal_nocheck (@_);
}

# =item C<$tz-E<gt>ymd ()>
# 
# Return three values C<($year, $month, $day)> which is today's date in
# C<$tz>.  Eg.
# 
#     my ($year, $month, $day) = $tz->ymd;
# 
sub ymd {
  my ($self, $timet) = @_;
  if (defined $timet) {
    my (undef,undef,undef,$mday,$mon,$year) = $self->localtime ($timet);
    return ($year+1900, $mon+1, $mday);

  } else {
    # cache against current time() to perhaps save some TZ switches (which
    # read a file every time in glibc, circa version 2.7 at least)
    $timet = time();
    if (! defined $self->{'ymd_now_timet'}
        || $timet != $self->{'ymd_now_timet'}) {
      my (undef,undef,undef,$mday,$mon,$year) = $self->localtime ($timet);
      $self->{'ymd_now'} = [ $year+1900, $mon+1, $mday ];
      $self->{'ymd_now_timet'} = $timet;
    }
    return @{$self->{'ymd_now'}};
  }
}

sub iso_date {
  my ($self) = @_;
  return sprintf '%04d-%02d-%02d', $self->ymd;
}
sub iso_datetimezone {
  my ($self, $timet) = @_;
  my ($sec,$min,$hour,$mday,$mon,$year) = $self->localtime ($timet);
  my $zone_offset = 0; # $timet - timegm($sec,$min,$hour,$mday,$mon,$year);
  return (sprintf ('%04d-%02d-%02dT%02d:%02d:%02dZ',
                   $year+1900, $mon+1, $mday,
                   $hour, $min, $sec,
                   int($zone_offset / 60), abs($zone_offset) % 60));
}


# =item $tz->iso_date_time ($timet)
# 
# Return two values C<($isodate, $isotime)> which is the given time_t value
# (as from the C<time()> func) as an ISO date and time like C<2008-06-08> and
# C<10:55:00>, in C<$tz>.  Eg.
# 
#     my ($isodate, $isotime) = $tz->iso_date_time (time());
#
sub iso_date_time {
  my ($self, $timet) = @_;
  my ($sec,$min,$hour,$mday,$mon,$year) = $self->localtime ($timet);
  return (sprintf ('%04d-%02d-%02d', $year+1900, $mon+1, $mday),
          sprintf ('%02d:%02d:%02d', $hour, $min, $sec));
}

# =item C<$tm = $tz-E<gt>tm ()>
# 
# =item C<$tm = $tz-E<gt>tm ($time_t)>
# 
# Call C<Time::localtime::localtime()> in the given C<$tz> timezone.
# C<$time_t> is a value from C<time()>, or defaults to the current C<time()>.
# The return is a C<Time::tm> object (see L<Time::localtime>).
# 
#     my $tm = $tz->tm;
# 
# =item C<$tz-E<gt>iso_date ()>
# 
# =item C<$tz-E<gt>iso_date ($timet)>
# 
# Return today's date in C<$tz> as an ISO format string like
# "2007-12-31".
# 
#     my $str = $tz->iso_date;



#------------------------------------------------------------------------------

# sub new {
#   my ($class, $name, @choices) = @_;
#   return $class->SUPER::new (name   => $name,
#                              choose => \@choices,
#                              defer  => 1);
# }

sub validate {
  my ($obj) = @_;
  (Scalar::Util::blessed ($obj) && $obj->isa (__PACKAGE__))
    or croak 'Not a '.__PACKAGE__.' object';
}

#------------------------------------------------------------------------------

{
  my $local_TZ = $ENV{'TZ'};  # its value at startup
  use constant::defer loco => sub {
    my ($class) = @_;
    return bless { name => __('Local time'),
                   tz => $local_TZ }, $class;
  };
}

use constant::defer chicago => sub {
  return App::Chart::TZ->new (name     => __('Chicago'),
                             choose   => [ 'America/Chicago' ],
                             fallback => 'CST+6');
};
use constant::defer london => sub {
  return App::Chart::TZ->new (name     => __('London'),
                             choose   => [ 'Europe/London' ],
                             fallback => 'GMT');
};
use constant::defer newyork => sub {
  return App::Chart::TZ->new (name     => __('New York'),
                             choose   => [ 'America/New_York' ],
                             fallback => 'EST+5');
};
use constant::defer sydney => sub {
  return App::Chart::TZ->new (name     => __('Sydney'),
                             choose   => [ 'Australia/Sydney' ],
                             fallback => 'EST-10');
};
use constant::defer tokyo => sub {
  return App::Chart::TZ->new (name     => __('Tokyo'),
                             choose   => [ 'Asia/Tokyo' ],
                             fallback => 'JST-9');
};

#------------------------------------------------------------------------------

my @sympred_timezone_list = ();

sub for_symbol {
  my ($class, $symbol) = @_;
  if ($symbol) {
    App::Chart::symbol_setups ($symbol);
    foreach my $elem (@sympred_timezone_list) {
      if ($elem->[0]->match ($symbol)) {
        return $elem->[1];
      }
    }
  }
  return $class->loco;
}

sub setup_for_symbol {
  my ($timezone, $sympred) = @_;
  push @sympred_timezone_list, [$sympred,$timezone];
}


#------------------------------------------------------------------------------

1;
__END__

=for stopwords TZs

=head1 NAME

App::Chart::TZ -- timezone object

=head1 SYNOPSIS

 use App::Chart::TZ;
 my $timezone = App::Chart::TZ->new (name => 'Some Where',
                                     choose => [ 'abc','def', ]);

 print $timezone->name(),"\n";

=head1 DESCRIPTION

A C<App::Chart::TZ> object represents a certain timezone.  It has a
place name and is implemented as a C<TZ> environment variable setting to be
used, with a set of TZs to try.

Stock and commodity symbols have an associated timezones, setup by their
handler code and then looked up here.

=head1 FUNCTIONS

=over 4

=cut

=item App::Chart::TZ::validate ($obj)

Check that C<$obj> is a C<App::Chart::TZ> object, throw an error if
not.

=item C<< App::Chart::TZ->loco >>

Return a timezone object representing the local timezone (which means
leaving C<TZ> at its initial setting).

=item C<< App::Chart::TZ->chicago >>

=item C<< App::Chart::TZ->london >>

=item C<< App::Chart::TZ->newyork >>

=item C<< App::Chart::TZ->sydney >>

=item C<< App::Chart::TZ->tokyo >>

Timezone objects for these respective places.

=back

=head1 TIMEZONES FOR SYMBOLS

=over 4

=item App::Chart::TZ->for_symbol ($symbol)

Return the timezone associated with C<$symbol>.

=item $timezone->setup_for_symbol ($sympred)

Record C<$timezone> as the timezone for symbols matched by the
C<App::Chart::Sympred> object C<$sympred>.

=back
