# Copyright 2007, 2008, 2009, 2010, 2011, 2012, 2014, 2016, 2018 Kevin Ryde

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

package App::Chart::Gtk2::IntradayImage;
use 5.010;
use strict;
use warnings;
use Carp;
use Gtk2 1.220;
use Encode;
use Encode::Locale;  # for coding system "locale"
use List::Util qw(min max);
use Locale::TextDomain ('App-Chart');

use Gtk2::Ex::Units;
use Gtk2::Ex::PixbufBits;
use App::Chart::Database;
use App::Chart::Gtk2::GUI;

# uncomment this to run the ### lines
# use Smart::Comments;


use Glib::Object::Subclass
  'Gtk2::DrawingArea',
  signals => { expose_event => \&_do_expose_event,
               size_request => \&_do_size_request },
  properties => [Glib::ParamSpec->string
                 ('symbol',
                   __('Symbol'),
                  'The symbol of the stock or commodity to be shown.',
                  '',  # default
                  Glib::G_PARAM_READWRITE),

                 Glib::ParamSpec->string
                 ('mode',
                  'Mode',
                  'The intraday mode, such as "1d" for one day.  The possible values here depend on the symbol\'s data source code.',
                  '',  # default
                  Glib::G_PARAM_READWRITE)];

sub INIT_INSTANCE {
  my ($self) = @_;
  $self->{'symbol'} = '';
  $self->{'mode'} = '';

  # Single pixbuf draw operation doesn't need double buffering.
  $self->set_double_buffered (0);
  $self->set_app_paintable (1);

  App::Chart::chart_dirbroadcast()->connect_for_object
      ('intraday-changed', \&_do_intraday_changed, $self);
}

sub SET_PROPERTY {
  my ($self, $pspec, $newval) = @_;
  my $pname = $pspec->get_name;
  ### IntradayImage SET_PROPERTY(): "$pname $newval"

  my $oldval = $self->{$pname};
  $self->{$pname} = $newval;  # per default GET_PROPERTY
  
  ### stored to: ''.\$self->{$pname}

  if ($oldval eq $newval) {
    return;
  }

  if ($pname eq 'symbol' || $pname eq 'mode') {
    # new image (or new no image)
    delete $self->{'xor_background'};  # new colour scheme
    $self->queue_resize;
    $self->queue_draw;
  }
}

# 'size-request' class closure
sub _do_size_request {
  my ($self, $req) = @_;
  ### IntradayImage _do_size_request()
  my $pixbuf = _load_pixbuf ($self);
  if (ref $pixbuf) {
    $req->width ($pixbuf->get_width);
    $req->height ($pixbuf->get_height);
  } else {
    $req->width (35 * Gtk2::Ex::Units::em($self));
    $req->height (6 * Gtk2::Ex::Units::line_height($self));
  }
  ### _do_size_request() decide: $req->width."x".$req->height
}

# 'expose-event' class closure
sub _do_expose_event {
  my ($self, $event) = @_;
  ### IntradayImage _do_expose_event(): $self->get_name.' "'.($self->{'symbol'}||'[nosymbol]').'" "'.($self->{'mode'}||'[nomode]').'"'
  my $win = $self->window;

  # Reading the database on every expose probably isn't fast, but we're not
  # expecting to scroll or anything much, so leaving the data on disk might
  # save a little memory.
  #
  my $pixbuf = _load_pixbuf ($self);
  if (! ref $pixbuf) {
    my $errmsg = $pixbuf;
    ### pixbuf load error: $errmsg
    $win->clear;
    App::Chart::Gtk2::GUI::draw_text_centred ($self, undef, $errmsg);
    return Gtk2::EVENT_PROPAGATE;
  }

  my $pix_width  = $pixbuf->get_width;
  my $pix_height = $pixbuf->get_height;
  ### pixbuf: "${pix_width}x${pix_height}"

  my ($x, $y, $alloc_width, $alloc_height) = $self->allocation->values;
  ### alloc size: "${alloc_width}x${alloc_height} at $x,$y"

  # windowed
  $x = 0; $y = 0;

  # align in allocated space, if alloc bigger than pixbuf
  my $x_offset = max(0, ($alloc_width - $pix_width) / 2);
  my $y_offset = max(0, ($alloc_height - $pix_height) / 2);

  # restrict to alloc width/height, in case pixbuf+pad is bigger than alloc
  my $width  = min ($alloc_width  - $x_offset, $pix_width);
  my $height = min ($alloc_height - $y_offset, $pix_height);

  my $gc = $self->get_style->bg_gc($self->state);
  $gc->set_clip_region ($event->region);
  $win->draw_pixbuf ($gc, $pixbuf,
                     0, 0,                       # source x,y
                     $x+$x_offset, $y+$y_offset, # dest x,y
                     $width, $height,
                     'normal', # dither
                     0, 0);    # dither x,y

  my $region = $event->region->copy;
  $region->subtract (Gtk2::Gdk::Region->rectangle
                     (Gtk2::Gdk::Rectangle->new
                      ($x+$x_offset, $y+$y_offset, $width, $height)));
  $gc->set_clip_region ($region);
  $win->draw_rectangle ($gc, 1, $event->area->values);

  $gc->set_clip_region (undef);
  return Gtk2::EVENT_PROPAGATE;
}

sub _load_pixbuf {
  my ($self) = @_;
  ### _load_pixbuf() ...

  my $symbol = $self->{'symbol'};
  my $mode = $self->{'mode'};
  if (! $symbol || ! $mode) { return  __('(No data)'); }

  my $dbh = App::Chart::DBI->instance;
  my $sth = $dbh->prepare_cached
    ('SELECT image, error FROM intraday_image WHERE symbol=? AND mode=?');

  # Crib note: Some DBI 1.618 SQLite3 1.35 seems to hold a ref to the
  # scalars passed to selectrow_array() until the next call.  So use the
  # local variables since holding onto $self->{'symbol'} looks like a leak.
  #
  my ($image, $error) = $dbh->selectrow_array ($sth, undef,
                                               $symbol,
                                               $mode);
  $sth->finish();
  if (! defined $image) { # error message in database
    return $error ||  __('(No data)');
  }

  my $loader = Gtk2::Gdk::PixbufLoader->new();
  my $pixbuf;
  if (eval {
    $loader->write ($image);
    $loader->close ();
    $pixbuf = $loader->get_pixbuf;
    1 }) {
    return $pixbuf;
  } else {
    # Should be Glib::Error in $@ thrown by $loader, but allow for plain
    # string too.
    my $err = "$@";
    unless (utf8::is_utf8($err)) { $err = Encode::decode('locale',$err); }
    return $err;
  }
}

sub _do_intraday_changed {
  my ($self, $symbol, $mode) = @_;
  ### IntradayImage _do_intraday_changed(): "\"$symbol\" \"$mode\"\n"
  if ($self->{'symbol'} eq $symbol && $self->{'mode'} eq $mode) {
    # new image (or new no image)
    delete $self->{'xor_background'};  # new colour scheme
    $self->queue_resize;
    $self->queue_draw;
  }
}

#-----------------------------------------------------------------------------
# pixbuf background

sub Gtk2_Ex_Xor_background {
  my ($self) = @_;
  return ($self->{'xor_background'} ||= do {
    require Gtk2::Ex::PixbufBits;
    my $pixbuf = _load_pixbuf ($self);
    if (! ref $pixbuf) {
      # error loading, treat as widget background
      return $self->get_style->bg($self->state);
    }
    my $rgbstr = Gtk2::Ex::PixbufBits::sampled_majority_color ($pixbuf);
    ### IntradayImage xor background: $rgbstr
    require App::Chart::Gtk2::Ex::GdkColorAlloc;
    App::Chart::Gtk2::Ex::GdkColorAlloc->new (widget => $self,
                                              color => $rgbstr);
  });
}

1;
__END__

=for stopwords intraday PNG JPEG GIF

=head1 NAME

App::Chart::Gtk2::IntradayImage -- intraday image display widget

=head1 SYNOPSIS

 my $image = App::Chart::Gtk2::IntradayImage->new;
 $image->set (symbol => 'BHP.AX',
              mode   => '1d');

=head1 WIDGET HIERARCHY

C<App::Chart::Gtk2::IntradayImage> is a subclass of C<Gtk2::DrawingArea>.

    Gtk2::Widget
      Gtk2::DrawingArea
        App::Chart::Gtk2::IntradayImage

=head1 DESCRIPTION

C<App::Chart::Gtk2::IntradayImage> displays an intraday graph image (a PNG, JPEG,
GIF etc) from the database for the given symbol and mode.  The display
updates when a new image download is notified through the
C<App::Chart::Glib::Ex::DirBroadcast> mechanism.  The database can have a
partial image during downloading, in that case as much as available is
displayed, with the effect being to progressively draw more as it downloads.
If there's no image at all then either an error message (from the database)
or simply "No data" is shown.

This widget is just the image part.  See L<App::Chart::Gtk2::IntradayDialog>
for the full interactive display.

=head1 PROPERTIES

=over 4

=item C<symbol> (string)

The stock or commodity symbol to display.

=item C<mode> (string)

The display mode, such as "1d" for a 1-day intraday image.

=back

=head1 SEE ALSO

L<App::Chart::Gtk2::IntradayDialog>, L<Gtk2::Widget>
