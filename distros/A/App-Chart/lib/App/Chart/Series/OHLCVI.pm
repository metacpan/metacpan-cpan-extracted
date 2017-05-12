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

package App::Chart::Series::OHLCVI;
use 5.010;
use strict;
use warnings;
use Carp;
use base 'App::Chart::Series';

use constant default_linestyle => 'Candles';


sub new {
  my $class = shift;
  my @opens    = ();
  my @highs    = ();
  my @lows     = ();
  my @closes   = ();
  my @volumes  = ();
  my @openints = ();
  my $self = $class->SUPER::new (opens    => \@opens,
                                 highs    => \@highs,
                                 lows     => \@lows,
                                 closes   => \@closes,
                                 volumes  => \@volumes,
                                 openints => \@openints,
                                 arrays => { opens    => \@opens,
                                             highs    => \@highs,
                                             lows     => \@lows,
                                             closes   => \@closes,
                                             volumes  => \@volumes,
                                             openints => \@openints },
                                 array_aliases => { 'values' => 'closes'},
                                 @_);
  return $self;
}

use constant range_default_names => ('opens', 'highs', 'lows', 'closes');

1;
__END__

=for stopwords OHLCVI

=head1 NAME

App::Chart::Series::OHLCVI -- series with open, high, low, close, ...

=head1 SYNOPSIS

 use App::Chart::Series::OHLCVI;

=head1 CLASS HIERARCHY

    App::Chart::Series
      App::Chart::Series::OHLCVI

=over 4

=item C<< $series->values_array >>

For an OHLCVI series the C<values> method of C<App::Chart::Series> is the
C<closes>.

=back

=head1 SEE ALSO

L<App::Chart::Series>, L<App::Chart::Series::Database>

=cut


# =head1 FUNCTIONS
# 
# =over 4
# 
# =item C<< $series->opens >>
# 
# =item C<< $series->array('highs') >>
# 
# =item C<< $series->lows >>
# 
# =item C<< $series->closes >>
# 
# =item C<< $series->volumes >>
# 
# =item C<< $series->openints >>
# 
# Return an array reference for the respective data, being daily opening
# price, day's high, day's low, close, traded volume, and open interest (for
# futures contracts).
# 
# These are like the C<values> method (see L<App::Chart::Series>).  Data is
# only loaded into the arrays (into all of them at once) when the C<fill>
# method is called.  So for example
# 
#     $series->fill (100, 150);
#     my $volumes = $series->volumes;
#     foreach my $t (100 .. 150) {
#       my $volume = $volumes->[$t];
#       if (defined $volume) { print "$volume\n"; }
#     }

# sub opens {
#   my ($self) = @_;
#   return $self->array('opens');
# }
# sub highs {
#   my ($self) = @_;
#   return $self->array('highs');
# }
# sub lows {
#   my ($self) = @_;
#   return $self->array('lows');
# }
# sub closes {
#   my ($self) = @_;
#   return $self->array('closes');
# }
# sub volumes {
#   my ($self) = @_;
#   return $self->array('volumes');
# }
# sub openints {
#   my ($self) = @_;
#   return $self->array('openints');
# }

# *values = \&closes;

