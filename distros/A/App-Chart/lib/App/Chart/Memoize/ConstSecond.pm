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

package App::Chart::Memoize::ConstSecond;
use 5.006;
## no critic (RequireUseStrict RequireUseWarnings)
no warnings;

sub import {
  my @names = @_;
  my $package = caller;
  foreach my $name (@names) {
    if ($name !~ /::/) {
      $name = "${package}::$name";
    }
    my $old = \&$name;
    my $last_time = time() - 1;
    my $last_value;
    *$name = sub {
      my $t = time();
      if ($t == $last_time) {
        return $last_value;
      } else {
        $last_time = $t;
        return ($last_value = $old->(@_));
      }
    };
  }
}

1;
__END__

=head1 NAME

App::Chart::Memoize::ConstSecond -- memoize functions to cache for 1 second

=head1 SYNOPSIS

 sub foo { some_code() };
 use App::Chart::Memoize::ConstSecond 'foo';

 sub bar { some_code() };    # or a set of functions at once
 sub quux { some_code() };
 use App::Chart::Memoize::ConstSecond 'bar','quux';

 use App::Chart::Memoize::ConstSecond 'Some::Other::func';

=head1 DESCRIPTION

C<App::Chart::Memoize::ConstSecond> modifies given functions so that the return value
from the original is cached for 1 second (until C<time()> ticks over).  This
is meant to save work if the original func has to do something slow like a
disk lookup or similar, yet still re-run that later on to allow for changes.

=head1 FUNCTIONS

There are no functions as such, everything is accomplished through the
C<use> import.

=over 4

=item C<< use App::Chart::Memoize::ConstSecond 'func' >>

=item C<< use App::Chart::Memoize::ConstSecond 'Some::Package::func' >>

=back

=head1 OTHER NOTES

C<Memoize::Expire> adds a similar time-based expiry to the C<Memoize> cache.
C<ConstSecond> is a lot smaller.

=head1 SEE ALSO

L<Memoize::Expire>

=cut
