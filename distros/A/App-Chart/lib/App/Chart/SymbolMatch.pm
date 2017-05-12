# Copyright 2008, 2009, 2010, 2011, 2015, 2016 Kevin Ryde

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

package App::Chart::SymbolMatch;
use 5.006;
use strict;
use warnings;
use App::Chart;
use App::Chart::Gtk2::Symlist;


sub find {
  my ($target, $preferred_symlist) = @_;
  if ($target eq '') { return; }
  my @symlists = App::Chart::Gtk2::Symlist->all_lists;

  # elevate $preferred_symlist to first in @symlists
  if ($preferred_symlist) {
    @symlists = grep {$_ != $preferred_symlist} @symlists;
    splice @symlists, 0,0, $preferred_symlist;
  }

  # exclude subset lists like "Alerts"
  # @symlists = grep {! $_->is_subset} @symlists;

  foreach my $proc (\&eq, \&eq_ci,
                    \&eq_sans_suffix, \&eq_ci_sans_suffix,
                    \&eq_ci_sans_hat,
                    \&prefix_ci_sans_hat) {
    foreach my $symlist (@symlists) {
      my $listref = $symlist->symbol_listref;
      foreach my $symbol (@$listref) {
        if ($proc->($target, $symbol)) {
          return ($symbol, $symlist);
        }
      }
    }
  }
  return undef;
}

sub eq {
  my ($x, $y) = @_;
  return $x eq $y;
}
sub eq_ci {
  my ($x, $y) = @_;
  return uc($x) eq uc($y);
}
sub eq_sans_suffix {
  my ($x, $y) = @_;
  $x = App::Chart::symbol_sans_suffix ($x);
  $y = App::Chart::symbol_sans_suffix ($y);
  return $x eq $y;
}
sub eq_ci_sans_suffix {
  my ($x, $y) = @_;
  $x = App::Chart::symbol_sans_suffix ($x);
  $y = App::Chart::symbol_sans_suffix ($y);
  return uc($x) eq uc($y);
}
sub eq_ci_sans_hat {
  my ($x, $y) = @_;
  $x =~ s/^\^//;
  $y =~ s/^\^//;
  return uc($x) eq uc($y);
}
sub prefix_ci_sans_hat {
  my ($part, $str) = @_;
  $part =~ s/^\^//;
  $str  =~ s/^\^//;
  return ($str =~ /^\U\Q$part/);
}

1;
__END__

=for stopwords symlist bh BHP BHP.AX gsp

=head1 NAME

App::Chart::SymbolMatch -- loose matching of symbols

=head1 SYNOPSIS

 use App::Chart::SymbolMatch;

=head1 DESCRIPTION

This module is used for loose symbol entry on the command line and in the
Open dialog (see L<App::Chart::Gtk2::OpenDialog>).  It's only a separate
module to keep a tricky bit of code away from other things.

=head1 FUNCTIONS

=over 4

=item C<< ($symbol, $symlist) = App::Chart::SymbolMatch::find ($target) >>

=item C<< ($symbol, $symlist) = App::Chart::SymbolMatch::find ($target, $preferred_symlist) >>

Find a symbol for the partial string C<$target> in the symlists and return
the symbol and symlist, or return no values if nothing matches (which
include when C<$target> is the empty string C<"">).

Progressively looser matches are attempted.  So first an exact match in the
given C<$preferred_symlist>, otherwise other lists.  Otherwise a
case-insensitive match, or a match without suffix (but always following an
explicit suffix on C<$target>), or a partial match at the start of the
symbol, and possibly without the index "^" marker.

The effect is that for instance a C<$target> "bh" might match "BHP.AX", or
"gsp" might match "^GSPC".  Note that an exact match anywhere is preferred
over a partial match in the current list, because otherwise you could type
an exact full symbol like "FOO" and still be left on a "FOO.AX" in the
current list.

=back

=head1 SEE ALSO

L<App::Chart>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/chart/index.html>

=head1 LICENCE

Copyright 2008, 2009, 2010, 2011, 2015, 2016 Kevin Ryde

Chart is free software; you can redistribute it and/or modify it under the
terms of the GNU General Public License as published by the Free Software
Foundation; either version 3, or (at your option) any later version.

Chart is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
details.

You should have received a copy of the GNU General Public License along with
Chart; see the file F<COPYING>.  Failing that, see
L<http://www.gnu.org/licenses/>.

=cut
