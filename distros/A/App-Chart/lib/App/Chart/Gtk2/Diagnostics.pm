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


package App::Chart::Gtk2::Diagnostics;
use 5.010;
use strict;
use warnings;
use List::Util qw(min max);
use Scalar::Util;
use Gtk2;
use Locale::TextDomain ('App-Chart');

use Gtk2::Ex::Units;
use App::Chart;

# uncomment this to run the ### lines
#use Smart::Comments;

use Glib::Object::Subclass 'Gtk2::Dialog';

sub popup {
  my ($class, $parent) = @_;
  require App::Chart::Gtk2::Ex::ToplevelBits;
  my $self = App::Chart::Gtk2::Ex::ToplevelBits::popup ($class,
                                                        screen => $parent);
  $self->refresh;
  return $self;
}

Gtk2::Rc->parse_string (<<'HERE');
style "Chart_fixed_width_font" {
  font_name = "Courier 12"
}
widget_class "App__Chart__Gtk2__Diagnostics.*.GtkTextView" style:gtk "Chart_fixed_width_font"
HERE

use constant RESPONSE_REFRESH => 0;

sub INIT_INSTANCE {
  my ($self) = @_;
  my $vbox = $self->vbox;

  $self->set_title (__('Chart: Diagnostics'));
  $self->add_buttons ('gtk-close'   => 'close',
                      'gtk-refresh' => RESPONSE_REFRESH);
  $self->signal_connect (response => \&_do_response);

  my $scrolled = Gtk2::ScrolledWindow->new;
  $scrolled->set_policy ('never', 'automatic');
  $vbox->pack_start ($scrolled, 1,1,0);

  my $textbuf = $self->{'textbuf'} = Gtk2::TextBuffer->new;
  $textbuf->set_text ('');

  my $textview = $self->{'textview'}
    = Gtk2::TextView->new_with_buffer ($textbuf);
  $textview->set (wrap_mode => 'char',
                  editable => 0);
  $scrolled->add ($textview);

  $vbox->show_all;

  # with a sensible rows and columns size for the TextView
  Gtk2::Ex::Units::set_default_size_with_subsizes
      ($self,
       [$textview, '60 ems', -1],
       [$scrolled, -1, '40 lines']);

  # limit to 80% screen height
  my ($width, $height) = $self->get_default_size;
  $height = min ($height, 0.8 * $self->get_screen->get_height);
  $self->set_default_size ($width, $height);
}

sub _do_response {
  my ($self, $response) = @_;

  if ($response eq RESPONSE_REFRESH) {
    $self->refresh;

  } elsif ($response eq 'close') {
    # close signal as per a keyboard Esc close; it defaults to raising
    # 'delete-event', which in turn defaults to a destroy
    $self->signal_emit ('close');
  }
}

sub refresh {
  my ($self) = @_;
  ### refresh: "$self"
  my $textview = $self->{'textview'};

  # can be a bit slow counting the database the first time, so show busy
  require Gtk2::Ex::WidgetCursor;
  Gtk2::Ex::WidgetCursor->busy;

  require Gtk2::Ex::TextBufferBits;
  Gtk2::Ex::TextBufferBits::replace_lines
      ($textview->get_buffer, $self->str());
}

sub str {
  my ($class_or_self) = @_;
  my $self = ref $class_or_self ? $class_or_self : undef;

  # mallinfo and mstats before loading other stuff, mallinfo first since
  # mstats is quite likely not available, and mallinfo first then avoids
  # counting Devel::Peek
  my $mallinfo;
  if (eval { require Devel::Mallinfo; }) {
    $mallinfo = Devel::Mallinfo::mallinfo();
  }

  # mstats_fillhash() croaks if no perl malloc in the running perl
  my %mstats;
  require Devel::Peek;
  ## no critic (RequireCheckingReturnValueOfEval)
  eval { Devel::Peek::mstats_fillhash(\%mstats) };
  ## use critic

  my $str = '';

  if (App::Chart::DBI->can('has_instance') # if loaded
      && App::Chart::DBI->has_instance) {  # and DBI connected
    my $dbh = App::Chart::DBI->instance;

    require DBI::Const::GetInfoType;
    $str .= "Database: "
      . $dbh->get_info($DBI::Const::GetInfoType::GetInfoType{'SQL_DBMS_NAME'})
        . " "
          . $dbh->get_info($DBI::Const::GetInfoType::GetInfoType{'SQL_DBMS_VER'})
            . "\n";
    {
      # as per App::Chart::DBI code
      my ($dbversion) = $dbh->selectrow_array
        ("SELECT value FROM extra WHERE key='database-schema-version'");
      $str .= "  schema version: @{[$dbversion//'undef']}\n";
    }
    {
      my ($count) = $dbh->selectrow_array('SELECT COUNT(*) FROM info');
      $str .= "  symbols: $count\n";
      my ($daily) = $dbh->selectrow_array('SELECT COUNT(*) FROM daily');
      $str .= sprintf ("  daily records: %d (%d per symbol)\n",
                       $daily, $daily / $count);
    }
    {
      my ($count) = $dbh->selectrow_array('SELECT COUNT(*) FROM latest');
      $str .= "  latest records: $count\n";
    }
    {
      my ($count) = $dbh->selectrow_array('SELECT COUNT(*) FROM intraday_image');
      $str .= "  intraday images: $count\n";
    }
  } else {
    $str .= "Database not connected yet\n";
  }

  if (App::Chart::DBI->can('database_filename')) { # when loaded
    require File::Basename;
    require File::stat;
    foreach my $filename (App::Chart::DBI::database_filename(),
                          App::Chart::DBI::notes_filename()) {
      my $st = File::stat::stat ($filename);
      my $size = $st->blocks * 512;
      $str .= sprintf ("  %.1f Mb%s in %s\n",
                       $size/1e6,
                       $st->size > $size ? ' (sparse)' : '',
                       Glib::filename_display_name($filename));
    }
  }

  $str .= "\n";

  {
    my $count = (App::Chart::Series::Database->can('new')
                 ? keys %App::Chart::Series::Database::cache
                 : 'not loaded yet');
    $str .= "Cached series:     $count\n";
  }
  {
    my $count;
    if (! App::Chart::Latest->can('get')) {
      $count = 'not loaded yet';
    } elsif (my $t = tied %App::Chart::Latest::get_cache) {
      $count = scalar(keys %App::Chart::Latest::get_cache)
        . " of " . $t->{'max_count'};
    } else {
      $count = 'uninitialized';
    }
    $str .= "Cached latest LRU: $count\n";
  }
  $str .= "\n";

  # if BSD::Resource available, only selected info bits
  if (eval { require BSD::Resource; }) {
    my ($usertime, $systemtime,
        $maxrss, $ixrss, $idrss, $isrss, $minflt, $majflt, $nswap,
        $inblock, $oublock, $msgsnd, $msgrcv,
        $nsignals, $nvcsw, $nivcsw)
      = BSD::Resource::getrusage ();
    $str .= "getrusage (BSD::Resource)\n";
    $str .= "  user time:      $usertime (seconds)\n";
    $str .= "  system time:    $systemtime (seconds)\n";
    # linux kernel 2.6.22 doesn't give memory info
    if ($maxrss) { $str .= "  max resident:   $maxrss\n"; }
    if ($ixrss)  { $str .= "  shared mem:     $ixrss\n"; }
    if ($idrss)  { $str .= "  unshared mem:   $idrss\n"; }
    if ($isrss)  { $str .= "  unshared stack: $isrss\n"; }
    # linux kernel 2.4 didn't count context switches
    if ($nvcsw)  { $str .= "  voluntary yields:   $nvcsw\n"; }
    if ($nivcsw) { $str .= "  involuntary yields: $nivcsw\n"; }
  }
  $str .= "\n";

  if ($mallinfo) {
    $str .= "mallinfo (Devel::Mallinfo)\n" . hash_format ($mallinfo);
  } else {
    $str .= "(Devel::Mallinfo not available.)\n";
  }
  $str .= "\n";

  if (%mstats) {
    $str .= "mstat (Devel::Peek)\n" . hash_format (\%mstats);
  } else {
    $str .= "(Devel::Peek -- no mstat() in this perl)\n";
  }

  if (eval { require Devel::Arena; }) {
    $str .= "\n";
    my $stats = Devel::Arena::sv_stats();
    my $magic = $stats->{'magic'};
    $stats->{'magic'}  # mung to reduce verbosity
      = scalar(keys %$magic) . ' total '
        . List::Util::sum (map {$magic->{$_}->{'total'}} keys %$magic);
    $str .= "SV stats (Devel::Arena)\n" . hash_format ($stats);

    my $shared = Devel::Arena::shared_string_table_effectiveness();
    $str .= "Shared string effectiveness:\n" . hash_format ($shared);
  } else {
    $str .= "(Devel::Arena -- module not available)\n";
  }

  if (eval { require Devel::SawAmpersand; 1 }) {
    $str .= 'PL_sawampersand is '
      . (Devel::SawAmpersand::sawampersand()
         ? "true, which is bad!"
         : "false, good")
        . " (Devel::SawAmpersand)\n";
  } else {
    $str .= "(Devel::SawAmpersand -- module not available.)\n";
  }
  $str .= "\n";

  $str .= "Modules loaded: " . (scalar keys %INC) . "\n";
  {
    $str .= "Module versions:\n";
    my @modulenames = ('Gtk2',
                       'Glib',
                       'DBI',
                       'DBD::SQLite',
                       'LWP',
                       'Devel::Arena',
                       # 'Devel::Mallinfo',
                       'Devel::Peek',
                       'Devel::StackTrace',
                       'Gtk2::Ex::Datasheet::DBI',
                       # 'Gtk2::Ex::NoShrink',
                       'Gtk2::Ex::TickerView',
                       'HTML::TableExtract',
                       'Number::Format',
                       'Set::IntSpan::Fast',
                       ['Compress::Raw::Zlib', 'ZLIB_VERSION'],
                       ['Finance::TA', 'TA_GetVersionString'],
                       # no apparent version number in geniustrader
                      );
    my $width = max (map {length} @modulenames);
    $str .= sprintf ("  %-*s%s\n", $width+2, 'Perl', $^V);
    foreach my $modulename (@modulenames) {
      my $funcname;
      if (ref($modulename)) {
        ($modulename,$funcname) = @$modulename;
      }
      my $version = $modulename->VERSION;
      if (defined $version && defined $funcname) {
        my $func = $modulename->can($funcname);
        $version .= "\n" . ($func
                            ? "    and $funcname " . $func->()
                            : "    (no $funcname)");
      }
      if (defined $version) {
        $str .= sprintf ("  %-*s%s\n", $width+2, $modulename, $version);
      } else {
        $version = '(not loaded)';
      }
    }
  }
  # Full report is a bit too big:
  #   if (eval { require Module::Versions::Report; }) {
  #     $str .= Module::Versions::Report::report()
  #       . "\n";
  #   }

  $str .= "\n";
  $str .= objects_report();
  {
    $str .= "GdkColorAlloc cells: ";
    if (! App::Chart::Gtk2::Ex::GdkColorAlloc->can('new')) {
      $str .= "not loaded\n";
    } else {
      my $obj_count = scalar keys %App::Chart::Gtk2::Ex::GdkColorAlloc::color_to_colormap;
      $str .= "$obj_count\n";
      #       on $pix_count pixels\n";
      #       my %pixels;
      #       $pixels{map {$_->pixel} values %App::Chart::Gtk2::Ex::GdkColorAlloc::color_to_colormap}
      #         = 1;
      #       my $pix_count = scalar keys %pixels;
      #       $str .= "$obj_count on $pix_count pixels\n";
    }
  }

  if ($self) {
    $str .= "\n";
    $str .= $self->Xresource_report;
  }

  return $str;
}

sub objects_report {
  if (! eval { require Devel::FindBlessedRefs; 1 }) {
    return "(Devel::FindBlessedRefs not available)\n";
  }
  my $str = "Glib/Gtk objects (Devel::FindBlessedRefs)\n";
  my %seen = ('Glib::Object' => {},
              'Glib::Boxed'  => {});
  Devel::FindBlessedRefs::find_refs_by_coderef
      (sub {
         my ($obj) = @_;
         my $class = Scalar::Util::blessed($obj) || return;
         ($obj->isa('Glib::Object') || $obj->isa('Glib::Boxed')) or return;
         my $addr = Scalar::Util::refaddr ($obj);
         $seen{$class}->{$addr} = 1;
       });
  my @classes = sort keys %seen;
  my $traverse;
  $traverse = sub {
    my ($depth, $class_list) = @_;
    my @toplevels = grep {is_toplevel_class ($_,$class_list)} @$class_list;
    foreach my $class (@toplevels) {
      my $count = scalar keys %{$seen{$class}};
      $str .= sprintf "%*s%s %d\n", 2*$depth, '', $class, $count;
      my @subclasses = grep {$_ ne $class && $_->isa($class)} @$class_list;
      $traverse->($depth+1, \@subclasses);
    }
  };
  $traverse->(1, \@classes);
  return $str;
}

sub Xresource_report {
  my ($self) = @_;

  my $window = $self->window
    || return "(X-Resource -- no window realized, no server connection)\n";
  $window->can('XID')
    || return "(X-Resource -- not running on X11)\n";
  my $xid = $window->XID;
  eval { require X11::Protocol; 1 }
    || return "(X-Resource -- X11::Protocol module not available)\n";

  my $display = $window->get_display;
  my $display_name = $display->get_name;
  my $X = eval { X11::Protocol->new ($display_name) }
    || return "(X-Resource -- cannot connect to \"$display_name\": $@)\n";
  my $ret;
  if (! eval {
    if (! $X->init_extension ('X-Resource')) {
      $ret = "(X-Resource -- server doesn't have this extension\n";
    } else {
      $ret = "X-Resource server resources (X11::Protocol)\n";
      if (my @res = $X->XResourceQueryClientResources ($xid)) {
        my $count_width = 0;
        for (my $i = 1; $i <= $#res; $i++) {
          $count_width = max($count_width, length($res[$i]));
        }
        while (@res) {
          my $type_atom = shift @res;
          my $count = shift @res;
          $ret .= sprintf ("  %*d  %s\n",
                           $count_width,$count, $X->atom_name($type_atom));
        }
      } else {
        $ret = "  no resources in use\n";
      }
    }
    1;
  }) {
    (my $err = $@) =~ s/^/  /mg;
    $ret .= $err;
  }
  return $ret;
}

#------------------------------------------------------------------------------
# generic helpers

# return true if $class is not a subclass of anything in $class_list (an
# arrayref)
sub is_toplevel_class {
  my ($class, $class_list) = @_;
  return ! List::Util::first {$class ne $_ && $class->isa($_)} @$class_list;
}

# return a string of the contents of a hash (passed as a hashref)
sub hash_format {
  my ($h) = @_;
  my $nf = App::Chart::number_formatter();

  require Scalar::Util;
  my %mung;
  foreach my $key (keys %$h) {
    my $value = $h->{$key};
    if (Scalar::Util::looks_like_number ($value)) {
      $mung{$key} = $nf->format_number ($value);
    } elsif (ref ($_) && ref($_) eq 'HASH') {
      $mung{$key} = "subhash, " . scalar(keys %{$_}) . " keys";
    } else {
      $mung{$key} = $value;
    }
  }

  my $field_width = max (map {length} keys   %mung);
  my $value_width = max (map {length} values %mung);

  return join ('', map { sprintf ("  %-*s  %*s\n",
                                  $field_width, $_,
                                  $value_width, $mung{$_})
                       } sort keys %mung);
}

1;
__END__

=head1 NAME

App::Chart::Gtk2::Diagnostics -- diagnostics dialog module

=head1 SYNOPSIS

 use App::Chart::Gtk2::Diagnostics;
 App::Chart::Gtk2::Diagnostics->popup();

=head1 WIDGET HIERARCHY

C<App::Chart::Gtk2::Diagnostics> is a subclass of C<Gtk2::Dialog>.

    Gtk2::Widget
      Gtk2::Container
        Gtk2::Bin
          Gtk2::Window
            Gtk2::Dialog
              App::Chart::Gtk2::Diagnostics

=head1 DESCRIPTION

A C<App::Chart::Gtk2::Diagnostics> dialog shows various bits of diagnostic
information like memory use, database size, etc.

=head1 FUNCTIONS

=over 4

=item C<< App::Chart::Gtk2::Diagnostics->popup() >>

Present a C<Diagnostics> dialog to the user.  C<popup()> creates and then
re-uses a single dialog, re-presenting it (C<< $widget->present() >>) and
refreshing its contents each time.  A single diagnostics dialog like this
will be enough for most uses.

=item C<< $dialog = App::Chart::Gtk2::Diagnostics->new() >>

Create and return a new Diagnostics dialog widget.  Initially it's empty and
C<refresh()> must be called to put some diagnostic information in it.

=item C<< $diagnostics->refresh() >>

Refresh the information displayed in C<$diagnostics>.  The "Refresh" button
in the dialog calls this.

=item C<< $str = App::Chart::Gtk2::Diagnostics->str() >>

Return the diagnostics in string form, as would be shown in a dialog.  This
just makes a string, no dialog is opened, created or updated.

=back

=head1 SEE ALSO

L<App::Chart>, L<Gtk2::Dialog>

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

# Local variables:
# compile-command: "perl -MApp::Chart::Gtk2::Diagnostics -e 'print App::Chart::Gtk2::Diagnostics->str'"
# End:
