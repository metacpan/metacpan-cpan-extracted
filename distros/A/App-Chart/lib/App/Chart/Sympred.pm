# Symbol predicates.

# Copyright 2007, 2008, 2009, 2010, 2013, 2015, 2016 Kevin Ryde

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

package App::Chart::Sympred;
use 5.005;
use strict;
use warnings;
use Carp;
use Scalar::Util;
use List::Util;

use App::Chart;

sub validate {
  my ($obj) = @_;
  if (! (Scalar::Util::blessed ($obj) && $obj->isa (__PACKAGE__))) {
    croak 'Not a symbol predicate: ' . ($obj||'undef');
  }
}


#------------------------------------------------------------------------------

package App::Chart::Sympred::Equal;
use strict;
use warnings;
use base 'App::Chart::Sympred';

sub new {
  my ($class, $suffix) = @_;
  return bless { suffix => $suffix }, $class;
}
sub match {
  my ($self, $symbol) = @_;
  return ($symbol eq $self->{'suffix'});
}

#------------------------------------------------------------------------------

package App::Chart::Sympred::Suffix;
use 5.006;
use strict;
use warnings;
use base 'App::Chart::Sympred';

sub new {
  my ($class, $suffix) = @_;
  if ($suffix =~ /\..*\./) {
    # two or more dots
    return App::Chart::Sympred::Regexp->new (qr/\Q$suffix\E$/);
  } else {
    return bless { suffix => $suffix }, $class;
  }
}
sub match {
  my ($self, $symbol) = @_;
  return (App::Chart::symbol_suffix ($symbol) eq $self->{'suffix'});
}

#------------------------------------------------------------------------------

package App::Chart::Sympred::Prefix;
use strict;
use warnings;
use base 'App::Chart::Sympred';

sub new {
  my ($class, $prefix) = @_;
  return bless { prefix => $prefix }, $class;
}

sub match {
  my ($self, $symbol) = @_;
  return ($symbol =~ /^\Q$self->{'prefix'}\E/);
}

#------------------------------------------------------------------------------

package App::Chart::Sympred::Regexp;
use strict;
use warnings;
use base 'App::Chart::Sympred';

sub new {
  my ($class, $pattern) = @_;
  return bless { pattern => $pattern }, $class;
}

sub match {
  my ($self, $symbol) = @_;
  return ($symbol =~ m/$self->{'pattern'}/);
}

#------------------------------------------------------------------------------

package App::Chart::Sympred::Proc;
use strict;
use warnings;
use base 'App::Chart::Sympred';

sub new {
  my ($class, $proc) = @_;
  return bless { proc => $proc }, $class;
}

sub match {
  my ($self, $symbol) = @_;
  return &{$self->{'proc'}} ($symbol);
}

#------------------------------------------------------------------------------

package App::Chart::Sympred::Any;
use strict;
use warnings;
use base 'App::Chart::Sympred';

sub new {
  my ($class, @preds) = @_;
  foreach my $pred (@preds) { App::Chart::Sympred::validate ($pred); }
  return bless { preds => \@preds }, $class;
}

sub add {
  my ($self, @newpreds) = @_;
  foreach my $pred (@newpreds) { App::Chart::Sympred::validate ($pred); }
  push @{$self->{'preds'}}, @newpreds;
}

sub match {
  my ($self, $symbol) = @_;
  return List::Util::first { $_->match($symbol) } @{$self->{'preds'}};
}

1;
__END__

=for stopwords ie Eg

=head1 NAME

App::Chart::Sympred -- symbol predicate objects

=head1 SYNOPSIS

 use App::Chart::Sympred;
 my $sympred = App::Chart::Sympred::Suffix->new ('.AX');
 $sympred->match('FOO.AX')  # returns true

=head1 DESCRIPTION

A C<App::Chart::Sympred> object represents a predicate for use on stock and
commodity symbols, ie. a test of whether a symbol has a certain suffix or
similar.

=head1 FUNCTIONS

=head2 Constructors

=over

=item C<< $sympred = App::Chart::Sympred::Equal->new ($suffix) >>

Return a new C<App::Chart::Sympred> object which matches only the given
symbol exactly.  Eg.

    my $sympred = App::Chart::Sympred::Equal->new ('FOO.BAR')

=item C<< $sympred = App::Chart::Sympred::Suffix->new ($suffix) >>

Return a new C<App::Chart::Sympred> object which matches the given symbol
suffix.  Eg.

    my $sympred = App::Chart::Sympred::Suffix->new ('.FOO')

=item C<< $sympred = App::Chart::Sympred::Prefix->new ($prefix) >>

Return a new C<App::Chart::Sympred> object which matches the given symbol
prefix.  Eg.

    my $sympred = App::Chart::Sympred::Prefix->new ('^NZ')

=item C<< $sympred = App::Chart::Sympred::Regexp->new (qr/.../) >>

Return a new C<App::Chart::Sympred> object which matches the given regexp
pattern.  Eg.

    my $sympred = App::Chart::Sympred::Regexp->new (qr/^\^BV|\.SA$/);

=item C<< $sympred = App::Chart::Sympred::Proc->new (\&proc) >>

Return a new C<App::Chart::Sympred> object which calls the given C<proc>
subroutine to test for a match.  Eg.

    sub my_fancy_test {
      my ($symbol) = @_;
      return (some zany test on $symbol);
    }
    my $sympred = App::Chart::Sympred::Proc->new (\&my_fancy_test);

=item C<< $sympred = App::Chart::Sympred::Any->new ($pred,...) >>

Return a new C<App::Chart::Sympred> object which is true if any of the given
C<$pred> predicates is true.  Eg.

    my $nz = App::Chart::Sympred::Suffix->new ('.NZ')
    my $bc = App::Chart::Sympred::Suffix->new ('.BC')

    my $sympred = App::Chart::Sympred::Any->new ($nz, $bc);

=back

=head2 Methods

=over

=item C<< $sympred->match ($symbol) >>

Return true if C<$symbol> is matched by the C<$sympred> object.

=item C<< $sympred->add ($pred,...) >>

Add additional predicates to a C<App::Chart::Sympred::Any> object.

=item C<< App::Chart::Sympred::validate ($obj) >>

Check that C<$obj> is a C<App::Chart::Sympred> object, throw an error if not.

=back

=head1 HOME PAGE

L<http://user42.tuxfamily.org/chart/index.html>

=head1 LICENCE

Copyright 2007, 2008, 2009, 2010, 2013, 2015, 2016 Kevin Ryde

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
