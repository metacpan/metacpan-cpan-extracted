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

package App::Chart::Gtk2::Ex::NotebookLazyPages;
use 5.008;
use strict;
use warnings;
use Carp;
use Gtk2;

# uncomment this to run the ### lines
#use Smart::Comments;

sub set_init {
  my ($notebook, $pagewidget, $func, $userdata) = @_;
  $notebook->signal_connect ('notify::page' => \&_do_notify_page);
  $pagewidget->{(__PACKAGE__)} = [ $func, $userdata ];
}

# 'notify::page' signal handler
sub _do_notify_page {
  my ($notebook) = @_;
  my $pagenum = $notebook->get_current_page;
  my $pagewidget = $notebook->get_nth_page ($pagenum);

  if (my $aref = delete $pagewidget->{(__PACKAGE__)}) {
    ### NotebookLazyPages initialize: $pagenum
    my ($func, $userdata) = @$aref;
    &$func ($notebook, $pagewidget, $pagenum, $userdata);
  }
}

1;
__END__

=head1 NAME

App::Chart::Gtk2::Ex::NotebookLazyPages -- lazy initialization of notebook pages

=for test_synopsis my ($notebook, $pagewidget)

=head1 SYNOPSIS

 use App::Chart::Gtk2::Ex::NotebookLazyPages;
 App::Chart::Gtk2::Ex::NotebookLazyPages::set_init ($notebook, $pagewidget,
                                        \&my_init_func);

=head1 DESCRIPTION

C<App::Chart::Gtk2::Ex::NotebookLazyPages> ...

=head1 FUNCTIONS

=over 4

=item C<< App::Chart::Gtk2::Ex::NotebookLazyPages::set_init ($notebook, $pagewidget, $func) >>

=back

=head1 SEE ALSO

L<Gtk2::Notebook>

=cut
