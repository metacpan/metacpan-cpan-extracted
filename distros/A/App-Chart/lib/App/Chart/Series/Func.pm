# Copyright 2008, 2009, 2010 Kevin Ryde

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

package App::Chart::Series::Func;
use 5.010;
use strict;
use warnings;
use Carp;
use List::Util qw(min max);
use Scalar::Util;

use App::Chart::Database;
use App::Chart::TZ;
use base 'App::Chart::Series';

# uncomment this to run the ### lines
#use Smart::Comments '###';

sub new {
  my ($class, $parent, $func) = @_;
  ### Func new: "@_"
  return $class->SUPER::new (parent => $parent,
                             func   => $func);
}

sub fill_part {
  ### Func fill_part(): "@_"
  my ($self, $lo, $hi) = @_;
  my $parent = $self->{'parent'};
  my $func = $self->{'func'};

  $parent->fill ($lo, $hi);
  my $arrays = $self->{'arrays'};
  while (my ($aname, $s) = each %$arrays) {
    my $p = $parent->array($aname);

    my $hi = min ($hi, $#$p);
    if ($#$s < $hi) { $#$s = $hi; }  # pre-extend

    foreach my $i ($lo .. $hi) {
      if (defined $p->[$i]) {
        $s->[$i] = &$func ($p->[$i]);
      }
    }
  }
}

1;
__END__

=head1 NAME

App::Chart::Series::Func -- ...

=for test_synopsis my ($parent, $subr)

=head1 SYNOPSIS

 use App::Chart::Series::Func;
 my $series = App::Chart::Series::Func->new ($parent, $subr);

=head1 DESCRIPTION

...

=head1 SEE ALSO

L<App::Chart::Series>

=cut
