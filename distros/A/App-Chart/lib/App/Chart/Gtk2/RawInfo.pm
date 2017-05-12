# Copyright 2007, 2008, 2009, 2010, 2011 Kevin Ryde

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

package App::Chart::Gtk2::RawInfo;
use 5.010;
use strict;
use warnings;
use Gtk2;
use List::Util;
use Locale::TextDomain ('App-Chart');

# uncomment this to run the ### lines
#use Smart::Comments;

use Glib::Object::Subclass
  'Gtk2::Label',
  properties => [Glib::ParamSpec->string
                 ('symbol',
                   __('Symbol'),
                  'Blurb.',
                  '',
                  Glib::G_PARAM_READWRITE),
                ];


sub INIT_INSTANCE {
  my ($self) = @_;
  $self->set_alignment (0, 0);
  App::Chart::chart_dirbroadcast()->connect_for_object
      ('data-changed', \&_do_data_changed, $self);
}

sub SET_PROPERTY {
  my ($self, $pspec, $newval) = @_;
  my $pname = $pspec->get_name;
  ### RawInfo: $pname, $newval
  $self->{$pname} = $newval;  # per default GET_PROPERTY

  if ($pname eq 'symbol') {
    $self->refresh;
  }
}

# 'data-changed' handler
sub _do_data_changed {
  my ($self, $symbol_hash) = @_;
  my $symbol = $self->{'symbol'} // return;
  if (exists $symbol_hash->{$symbol}) {
    $self->refresh;
  }
}

sub refresh {
  my ($self) = @_;
  my $symbol = $self->{'symbol'};
  my $str;
  if (defined $symbol) {
    ### RawInfo refresh: $symbol
    require App::Chart::DBI;
    my $dbh = App::Chart::DBI->instance;
    my $sth = $dbh->prepare_cached ('SELECT * FROM info WHERE symbol=?');
    my $h = $dbh->selectrow_hashref ($sth, undef, $symbol);

    require Data::Dumper;
    my $dumper = Data::Dumper->new ([$h],['info']);
    $dumper->Sortkeys(1);
    $dumper->Quotekeys(0);
    $str = $dumper->Dump;
  }
  $self->set_text ($str);
}

1;
__END__

=for stopwords RawInfo

=head1 NAME

App::Chart::Gtk2::RawInfo -- raw symbol info display widget

=head1 SYNOPSIS

 use App::Chart::Gtk2::RawInfo;
 my $raw = App::Chart::Gtk2::RawInfo->new (symbol => 'FOO');

=head1 WIDGET HIERARCHY

C<App::Chart::Gtk2::RawInfo> is a subclass of C<Gtk2::Label>.

    Gtk2::Widget
      Gtk2::Misc
        Gtk2::Label
          App::Chart::Gtk2::RawInfo

=head1 DESCRIPTION

A C<App::Chart::Gtk2::RawInfo> widget displays a raw info record for a given
symbol.  It updates with new info records.

=head1 FUNCTIONS

=over 4

=item C<< App::Chart::Gtk2::RawInfo->new (key=>value,...) >>

Create and return a new RawInfo widget.

=back

=head1 PROPERTIES

=over 4

=item C<symbol> (string, default none)

The stock symbol whose info record to display.

=back

=head1 SEE ALSO

L<App::Chart::Gtk2::RawDialog>

=cut
