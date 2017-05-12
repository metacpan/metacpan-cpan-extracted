# Copyright 2008, 2009, 2010, 2011 Kevin Ryde

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

package App::Chart::Glib::Ex::MoreUtils;
use 5.008;
use strict;
use warnings;
use Glib;
use Scalar::Util;

use base 'Exporter';
our @EXPORT_OK = qw(ref_weak lang_select);
our %EXPORT_TAGS = (all => \@EXPORT_OK);

sub ref_weak {
  my ($obj) = @_;
  Scalar::Util::weaken ($obj);
  return \$obj;
}

sub lang_select {
  my %choices = @_;
  my $default = $_[1];

  foreach my $lang (Glib::get_language_names()) {
    if (exists $choices{$lang}) {
      return $choices{$lang};
    }
  }
  return $default;
}

1;
__END__

=for stopwords Ryde userdata

=head1 NAME

App::Chart::Glib::Ex::MoreUtils -- more Glib utility functions

=head1 SYNOPSIS

 use App::Chart::Glib::Ex::MoreUtils;

=head1 FUNCTIONS

=over 4

=item C<< App::Chart::Glib::Ex::MoreUtils::ref_weak ($obj) >>

Return a reference to a weak reference to C<$obj>.  This is good for the
"userdata" in signal connections etc when you want some weakening so you
don't keep C<$obj> alive forever due to the connection.  For example,

    $model->signal_connect (row_deleted, \&deleted_handler,
                            App::Chart::Glib::Ex::MoreUtils::ref_weak($self));

    sub deleted_handler {
      my ($model, $path, $ref_weak_self) = @_;
      my $self = $$ref_weak_self || return;
      ...
    }

=item C<< App::Chart::Glib::Ex::MoreUtils::lang_select ($lang => $value, ...) >>

Choose a value according to the user's preferred language.  Each C<$lang>
argument is a two-letter language code like "en".  The C<$value> arguments
are any scalars to return.  For example

    App::Chart::Glib::Ex::MoreUtils::lang_select (de => 'deutsch',
                                      en => 'english')
    # returns either 'deutsch' or 'english'

The user's preferred language is taken from C<Glib::get_language_names> (see
L<Glib::Utils>).  If none of the given C<$lang> values are among the user's
preferences then the first in the call is used as the default and its
C<$value> returned.

This is meant for selecting semi-technical things from a fixed set of
possibilities within the program code, for example different URLs for the
English or German version of some web page which will be parsed.  If it was
in a F<.mo> file (per C<Locale::TextDomain>) the choice would be locked down
by the translator, but C<lang_select> allows a user preference.

=back

=head1 SEE ALSO

L<Glib::Utils>

=cut
