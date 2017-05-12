# Copyright 2007, 2008, 2009, 2010, 2011, 2016 Kevin Ryde

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

package App::Chart::Manual;
use 5.008;
use strict;
use warnings;
# use Locale::TextDomain ('App-Chart');

use App::Chart;

sub open {
  my ($class, $node, $parent_widget) = @_;
  my $uri;
  if (defined $node && $node =~ /^http:/) {
    $uri = $node;
  } else {
    require URI::file;
    $uri = URI::file->new (App::Chart::datafilename('doc', 'chart.html'));
    if (defined $node) {
      require App::Chart::Texinfo::Util;
      $uri->fragment (App::Chart::Texinfo::Util::node_to_html_anchor($node));
    }
  }
  require App::Chart::Gtk2::GUI;
  App::Chart::Gtk2::GUI::browser_open ($uri, $parent_widget);
}

sub open_for_symbol {
  my ($class, $symbol, $parent_widget) = @_;
  my $node = App::Chart::symbol_source_help ($symbol);
  if (defined $node) {
    $class->open ($node, $parent_widget);
  } else {
    if ($parent_widget) {
      $parent_widget->error_bell;
    } elsif (Gtk2::Gdk::Display->can('get_default')) {
      Gtk2::Gdk::Display->get_default->beep;
    }
  }
}

1;
__END__

=for stopwords undef

=head1 NAME

App::Chart::Manual -- open the Chart manual

=for test_synopsis my ($node)

=head1 SYNOPSIS

 use App::Chart::Manual;
 App::Chart::Manual->open;          # start of manual
 App::Chart::Manual->open ($node);  # particular node

=head1 FUNCTIONS

=over 4

=item C<< App::Chart::Manual->open () >>

=item C<< App::Chart::Manual->open ($node) >>

=item C<< App::Chart::Manual->open ($node, $parent_widget) >>

Open the Chart manual.  Optional C<$node> is a node name like "Main Window",
or if undef or omitted then open the manual at the start.

C<$parent_widget> (if given, and not undef) is used as the parent window for
an error bell or dialog if a help browser can't be opened.  Or at least
that's the intention.

=back

=head1 SEE ALSO

L<App::Chart>,
L<App::Chart::Gtk2::GUI>,
L<App::Chart::Texinfo::Util>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/chart/index.html>

=head1 LICENCE

Copyright 2007, 2008, 2009, 2010, 2011, 2016 Kevin Ryde

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
