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

package App::Chart::Gtk2::Main;
use 5.010;
use strict;
use warnings;
use Carp;
use File::Spec;
use List::Util qw(min max);
use POSIX ();
use Locale::TextDomain 1.19 ('App-Chart');  # 1.19 for N__() in scalar context

use Glib 1.220;
use Gtk2 1.220;
use Glib::Ex::ConnectProperties;
use Gtk2::Ex::WidgetCursor;

use Gtk2::Ex::ActionTooltips;
use Gtk2::Ex::History;
use Gtk2::Ex::History::Action;
use App::Chart::Gtk2::Ex::ToplevelBits;
use App::Chart;
use App::Chart::Database;
use App::Chart::Gtk2::GUI;
use App::Chart::Gtk2::Symlist;
use App::Chart::Gtk2::View;

# uncomment this to run the ### lines
#use Smart::Comments;

use base 'App::Chart::Gtk2::Ex::ToplevelSingleton';

use Glib::Object::Subclass
  'Gtk2::Window',
  signals => { destroy => \&_do_destroy,
               symbol_changed => { param_types   => ['Glib::String'],
                                   return_type   => undef,
                                   class_closure => \&_do_symbol_changed },
             },
  properties => [ Glib::ParamSpec->object
                  ('statusbar',
                   'statusbar',
                   'The Gtk2::Statusbar at the bottom of the window.',
                   'Gtk2::Statusbar',
                   ['readable']),
                ];

#------------------------------------------------------------------------------

use constant _ACTION_DATA =>
  [ # name,       stock id,     label,  accelerator,  tooltip
   
   { name => 'FileMenu',  label => '_File'  },
   { name => 'EditMenu',  label => '_Edit'  },
   { name => 'ViewMenu',  label => '_View'  },
   { name => 'ToolsMenu', label => '_Tools' },
   { name => 'HelpMenu',  label => '_Help'  },
   
   { name        => 'Open',
     stock_id    => 'gtk-open',
     accelerator =>  __p('Main-accelerator-key','O'),
     tooltip     => __('View chart for a symbol, or add new symbol to the database'),
     callback    => sub {
       my ($action, $self) = @_;
       App::Chart::Gtk2::Ex::ToplevelBits::popup
           ('App::Chart::Gtk2::OpenDialog',
            transient_for  => $self,
            hide_on_delete => 1);
     },
   },
   { name     => 'Delete',
     stock_id => 'gtk-delete',
     tooltip  => __('Delete this symbol from the database.'),
     callback => sub {
       my ($action, $self) = @_;
       require App::Chart::Gtk2::DeleteDialog;
       App::Chart::Gtk2::DeleteDialog->popup ($self->get_symbol, $self);
     },
   },
   { name        => 'AddFavourite',
     label       => __('_Add Favourite'),
     accelerator => __p('Main-accelerator-key','exclam'),
     tooltip     => __('Add this symbol to your Favourites list, or elevate in that list.'),
     callback => sub {
       my ($action, $self) = @_;
       require App::Chart::Gtk2::Symlist::Favourites;
       my $symlist = App::Chart::Gtk2::Symlist::Favourites->instance;
       my $symbol = $self->get_symbol;
       my $message = (($symlist->append_or_elevate($symbol) eq 'elevated')
                      ? N__('{symbol} raised in {symlist}')
                      : N__('{symbol} added to {symlist}'));
       _message ($self, __x($message,
                            symbol => $symbol,
                            symlist => $symlist->name));
     },
   },
   { name        => 'RemoveFavourite',
     label       => __('_Remove Favourite'),
     accelerator => __p('Main-accelerator-key','<Ctrl>exclam'),
     tooltip     => __('Remove this symbol from your Favourites list.'),
     callback    => sub {
       my ($action, $self) = @_;
       require App::Chart::Gtk2::Symlist::Favourites;
       my $symlist = App::Chart::Gtk2::Symlist::Favourites->instance;
       $symlist->delete_symbol ($self->get_symbol);
     },
   },
   { name        => 'Next',
     stock_id    => 'gtk-media-next',
     accelerator => __p('Main-accelerator-key','N'),
     tooltip     => __('Go to the next symbol (in the current symlist, or the next symlist).'),
     callback    => sub {
       my ($action, $self) = @_;
       $self->goto_next;
     },
   },
   { name        => 'Prev',
     stock_id    => 'gtk-media-previous',
     accelerator => __p('Main-accelerator-key','P'),
     tooltip     => __('Go to the previous symbol (in the current symlist, or the previous symlist).'),
     callback    => sub {
       my ($action, $self) = @_;
       $self->go_prev;
     },
   },
   { name     => 'Quit',
     stock_id => 'gtk-quit',
     # no accelerator -- don't really want the usual Control-Q
     callback => sub {
       my ($action, $self) = @_;
       if (App::Chart::Gtk2::JobQueue->can('instance')) { # if loaded
         require App::Chart::Gtk2::JobsRunningDialog;
         App::Chart::Gtk2::JobsRunningDialog->query_and_quit ($self);
       } else {
         $self->destroy;
       }
     },
   },
   { name     => 'Preferences',
     stock_id => 'gtk-preferences',
     callback => sub {
       my ($action, $self) = @_;
       App::Chart::Gtk2::Ex::ToplevelBits::popup
           ('App::Chart::Gtk2::PreferencesDialog', screen => $self);
     },
   },
   
   { name        => 'Centre',
     label       => __('_Centre'),
     accelerator => __p('Main-accelerator-key','<Ctrl>C'),
     callback    => sub { my ($action, $self) = @_;
                          $self->{'view'}->centre; }
   },
   { name        => 'ZoomInX',
     label       => __('Zoom Wider'),
     accelerator => __p('Main-accelerator-key','W'),
     callback    => sub { my ($action, $self) = @_;
                          $self->{'view'}->zoom (1.5, 1) }
   },
   { name        => 'ZoomOutX',
     label       => __('Zoom Narrower'),
     accelerator => __p('Main-accelerator-key','<Shift>W'),
     callback    => sub { my ($action, $self) = @_;
                          $self->{'view'}->zoom (0.75, 1) }
   },
   { name        => 'ZoomInY',
     stock_id    => 'gtk-zoom-in',
     accelerator => __p('Main-accelerator-key','Z'),
     callback    => sub { my ($action, $self) = @_;
                          $self->{'view'}->zoom (1, 1.5) }
   },
   { name        => 'ZoomOutY',
     stock_id    => 'gtk-zoom-out',
     accelerator => __p('Main-accelerator-key','<Shift>Z'),
     callback    => sub { my ($action, $self) = @_;
                          $self->{'view'}->zoom (1, 1/1.5) }
   },
   { name        => 'Redraw',
     label       => __('_Redraw'),
     accelerator => __p('Main-accelerator-key','<Ctrl>L'),
     tooltip     => __('Force a redraw of the entire Chart display.'),
     callback    => sub { my ($action, $self) = @_;
                          $self->queue_draw; }
   },
   { name     => 'Intraday',
     label    => __('_Intraday'),
     tooltip  => __p('Main-accelerator-key','<Ctrl>I'),
     callback => sub {
       my ($action, $self) = @_;
       require App::Chart::Gtk2::IntradayDialog;
       App::Chart::Gtk2::IntradayDialog->popup ($self->get_symbol, $self);
     },
   },
   { name     => 'Annotations',
     label    => __('_Annotations'),
     callback => sub {
       my ($action, $self) = @_;
       require App::Chart::Gtk2::AnnotationsDialog;
       App::Chart::Gtk2::AnnotationsDialog->popup ($self->get_symbol, $self);
     },
   },
   { name     => 'ViewStyle',
     label    => __('_View Style'),
     callback => sub { my ($action, $self) = @_;
                       Gtk2::Ex::WidgetCursor->busy;
                       require App::Chart::Gtk2::ViewStyleDialog;
                       my $vs = App::Chart::Gtk2::ViewStyleDialog->instance_for_screen($self);
                       $vs->present;
                       my $view = $self->{'view'};
                       $vs->set (view => $view,
                                 viewstyle => $view->get('viewstyle'));
                     }
   },
   { name     => 'Raw',
     label    => __('_Raw data'),
     callback => sub { my ($action, $self) = @_;
                       require App::Chart::Gtk2::RawDialog;
                       App::Chart::Gtk2::RawDialog->popup ($self->get_symbol, $self); }
   },
   { name  => "WebMenuItem",
     label => __('_Web')
   },
   
   # Tools menu
   
   { name     => 'Watchlist',
     label    => __('_Watchlist'),
     callback => sub {
       my ($action, $self) = @_;
       App::Chart::Gtk2::Ex::ToplevelBits::popup
           ('App::Chart::Gtk2::WatchlistDialog',
            screen => $self,
            hide_on_delete => 1);
     },
   },
   { name     => 'Download',
     label    => __('_Download'),
     callback => sub { my ($action, $self) = @_;
                       require App::Chart::Gtk2::DownloadDialog;
                       App::Chart::Gtk2::DownloadDialog->popup ($self->get_symbol, $self); }
   },
   { name        => 'DownloadUpdate',
     label       => __('Download _Update'),
     accelerator => __p('Main-accelerator-key','<Ctrl>U'),
     callback    => sub {
       my ($action, $self) = @_;
       # meant to be sensitive only with a symbol, but check anyway
       my $symbol = $self->get_symbol || return;
       require App::Chart::Gtk2::DownloadDialog;
       my $dialog = App::Chart::Gtk2::DownloadDialog->instance_for_screen($self);
       my $job = $dialog->start ($symbol, undef);
       my $jobmsg = ($self->{'jobmsg'} ||= do {
         require App::Chart::Gtk2::JobStatusbarMessage;
         App::Chart::Gtk2::JobStatusbarMessage->new
             (statusbar => $self->{'statusbar'});
       });
       $jobmsg->add_job ($job);
     } },
   { name        => 'History',
     label       => __('_History'),
     tooltip     => __('Dialog of back/forward symbols.'),
     callback    => sub {
       my ($action, $self) = @_;
       App::Chart::Gtk2::Ex::ToplevelBits::popup
           ('Gtk2::Ex::History::Dialog',
            screen => $self,
            properties => { history => $self->{'history'} });
     },
   },
   { name     => 'Vacuum',
     label    => __('_Vacuum'),
     tooltip  => __('Compact and clean up the database.'),
     callback => sub {
       my ($action, $self) = @_;
       App::Chart::Gtk2::Ex::ToplevelBits::popup ('App::Chart::Gtk2::VacuumDialog',
                                                  screen => $self);
     },
   },
   { name     => 'Errors',
     label    => __('_Errors'),
     tooltip  => __('Open the errors dialog (it automatically popups up when there\'s an error to see)'),
     callback => sub { my ($action, $self) = @_;
                       require Gtk2::Ex::ErrorTextDialog;
                       my $dialog = Gtk2::Ex::ErrorTextDialog->instance;
                       $dialog->set_screen ($self->get_screen);
                       $dialog->present;
                     }
   },
   { name     => 'Diagnostics',
     label    => __('Dia_gnostics'),
     tooltip  => __('Some diagnostic information about the program and the databases.'),
     callback => sub { my ($action, $self) = @_;
                       require App::Chart::Gtk2::Diagnostics;
                       App::Chart::Gtk2::Diagnostics->popup ($self); }
   },
   
   { name     => 'About',
     stock_id => 'gtk-about',
     callback => sub {
       my ($action, $self) = @_;
       App::Chart::Gtk2::Ex::ToplevelBits::popup
           ('App::Chart::Gtk2::AboutDialog', screen => $self);
     },
   },

   { name        => 'Manual',
     label       => __('_Manual'),
     accelerator => 'F1',
     callback    => sub { my ($action, $self) = @_;
                          require App::Chart::Manual;
                          App::Chart::Manual->open (undef, $self); },
   },
   { name     => 'ManualDataSource',
     label    => __('This _Data Source'),
     # tooltip generated dynamically
     callback => sub { my ($action, $self) = @_;
                       require App::Chart::Manual;
                       App::Chart::Manual->open_for_symbol ($self->get_symbol, $self); }
   },
   { name     => 'ManualMovingAverage',
     label    => __('This _Moving Average'),
     tooltip  => __('Open the manual at the section about the moving average shown in the upper graph'),
     callback => sub {
       my ($action, $self) = @_;
       require App::Chart::Manual;
       App::Chart::Manual->open(manual_for_graph_n($self,0), $self);
     }
   },
   { name     => 'ManualIndicator',
     label    => __('This _Indicator'),
     tooltip  => __('Open the manual at the section about the indicator shown in the lower graph'),
     callback => sub {
       my ($action, $self) = @_;
       require App::Chart::Manual;
       App::Chart::Manual->open(manual_for_graph_n($self,1), $self);
     }
   },
  ];

sub INIT_INSTANCE {
  my ($self) = @_;

  $self->set_title (__('Chart'));

  App::Chart::chart_dirbroadcast()->connect_for_object
      ('delete-symbol', \&_do_delete_symbol, $self);

  my $actiongroup = $self->{'actiongroup'} = Gtk2::ActionGroup->new ("main");
  Gtk2::Ex::ActionTooltips::group_tooltips_to_menuitems ($actiongroup);
  $actiongroup->set_translation_domain ('gtk20'); #fallback for _Edit and _Help
  $actiongroup->add_actions (_ACTION_DATA, $self);

  my $history = $self->{'history'} = Gtk2::Ex::History->new;
  $history->signal_connect (place_to_text => \&_history_place_to_text);
  $history->signal_connect ('notify::current' => \&_history_notify_current,
                            $self);

  # sub new_in_actiongroup {
  #   my $class = shift;
  #   my $actiongroup = shift;
  #   my $self = $class->new (@_);
  #   $actiongroup->add_action_with_accel ($self, $self->accelerator);
  # }
  # sub accelerator {
  #   my ($self) = @_;
  #   return ($self->get('way') eq 'back'
  #           ? __p('accelerator-key','B')
  #           : __p('accelerator-key','F'));
  # }
  $actiongroup->add_action_with_accel
    (Gtk2::Ex::History::Action->new (name    => 'Back',
                                     way     => 'back',
                                     history => $history),
     __p('accelerator-key-back','B'));
  $actiongroup->add_action_with_accel
    (Gtk2::Ex::History::Action->new (name    => 'Forward',
                                     way     => 'forward',
                                     history => $history),
     __p('accelerator-key-forward','F'));

  # initially nothing
  $actiongroup->get_action('AddFavourite')->set_sensitive (0);
  $actiongroup->get_action('RemoveFavourite')->set_sensitive (0);

  # these actions only sensitive when there's a symbol displayed
  $self->{'symbol_sensitive_actions'} = ['AddFavourite', 'RemoveFavourite',
                                         'Delete', 'Centre', 'DownloadUpdate',
                                         'Annotations'];
  _do_symbol_changed ($self, '');  # hack for initial insensitive

  Gtk2::Ex::ActionTooltips::action_tooltips_to_menuitems_dynamic
    ($actiongroup->get_action('ManualDataSource'),
     $actiongroup->get_action('ManualMovingAverage'),
     $actiongroup->get_action('ManualIndicator'));

  $actiongroup->add_toggle_actions
    # name, stock id, label, accel, tooltip, subr, is_active
    ([{ name        => 'Cross',
        label       => __('_Cross'),
        accelerator => __p('Main-accelerator-key','C'),
        tooltip     => __('Show a crosshair of horizontal and vertical lines following the mouse pointer.'),
        is_active   => 0,
        callback    => sub {
          my ($action, $self) = @_;
          $self->{'crosshair_connect'} ||= do {
            my $cross = $self->{'view'}->crosshair;
            Glib::Ex::ConnectProperties->new ([$action,'active'],
                                              [$cross,'active']);
          };
        },
      },
      { name      => 'Ticker',
        label     => __('_Ticker'),
        is_active => 0,
        tooltip   => __('Show a stock ticker of share prices at the bottom of the window.

Mouse button-1 there drags it back or forward.  Button-3 pops up a menu of options, including which symbol list it shows.'),
        callback  => sub {
          my ($action, $self) = @_;
          Gtk2::Ex::WidgetCursor->busy; # can take a moment to load
          $self->get_or_create_ticker;
        },
      },
      { name      => 'Toolbar',
        label     => __('T_oolbar'),
        tooltip   => __('Show (or not) the toolbar.'),
        is_active => 1,
      },
     ],
     $self);

  my @timebases = qw(App::Chart::Timebase::Days
                     App::Chart::Timebase::Weeks
                     App::Chart::Timebase::Months);
  $actiongroup->add_radio_actions
    ([{ name        => 'Daily',
        label       => __('_Daily'),
        accelerator => __p('Main-accelerator-key','<Ctrl>D'),
        tooltip     => __('Display daily data.'),
        value       => 0,
      },
      { name        => 'Weekly',
        label       =>__('_Weekly'),
        accelerator => __p('Main-accelerator-key','<Ctrl>W'),
        tooltip     => __('Display weekly data.'),
        value       => 1,
      },
      { name        => 'Monthly',
        label       =>__('_Monthly'),
        accelerator => __p('Main-accelerator-key','<Ctrl>M'),
        tooltip     => __('Display monthly data.'),
        value       => 2,
      }],
     0, # initial
     sub { my ($action, $current_action, $self) = @_;
           Gtk2::Ex::WidgetCursor->busy;
           $self->{'view'}->set (timebase_class =>
                                 $timebases[$action->get_current_value]);
         },
     $self);

  my $ui = $self->{'ui'} = Gtk2::UIManager->new;
  $ui->insert_action_group ($actiongroup, 0);
  $self->add_accel_group ($ui->get_accel_group);
  $ui->add_ui_from_string (<<'HERE');
<ui>
  <menubar name='MenuBar'>
    <menu action='FileMenu'>
      <menuitem action='Open'/>
      <menuitem action='Delete'/>
      <menuitem action='AddFavourite'/>
      <menuitem action='RemoveFavourite'/>
      <separator/>
      <menuitem action='Prev'/>
      <menuitem action='Next'/>
      <menuitem action='Back'/>
      <menuitem action='Forward'/>
      <separator/>
      <menuitem action='Quit'/>
    </menu>
    <menu action='EditMenu'>
      <menuitem action='Annotations'/>
      <menuitem action='ViewStyle'/>
      <menuitem action='Preferences'/>
      <menuitem action='Raw'/>
    </menu>
    <menu action='ViewMenu'>
      <menuitem action='Daily'/>
      <menuitem action='Weekly'/>
      <menuitem action='Monthly'/>
      <separator/>
      <menuitem action='ZoomInY'/>
      <menuitem action='ZoomOutY'/>
      <menuitem action='ZoomInX'/>
      <menuitem action='ZoomOutX'/>
      <menuitem action='Centre'/>
      <menuitem action='Redraw'/>
      <separator/>
      <menuitem action='Intraday'/>
      <menuitem action='WebMenuItem'/>
    </menu>
    <menu action='ToolsMenu'>
      <menuitem action='Download'/>
      <menuitem action='DownloadUpdate'/>
      <menuitem action='Watchlist'/>
      <menuitem action='Cross'/>
      <menuitem action='Ticker'/>
      <menuitem action='Toolbar'/>
      <menuitem action='History'/>
      <separator/>
      <menuitem action='Vacuum'/>
      <menuitem action='Errors'/>
      <menuitem action='Diagnostics'/>
    </menu>
    <menu action='HelpMenu'>
      <menuitem action='About'/>
      <menuitem action='Manual'/>
      <menuitem action='ManualDataSource'/>
      <menuitem action='ManualMovingAverage'/>
      <menuitem action='ManualIndicator'/>
    </menu>
  </menubar>
  <toolbar  name='ToolBar'>
    <toolitem action='Prev'/>
    <toolitem action='Next'/>
    <toolitem action='Back'/>
    <toolitem action='Forward'/>
  </toolbar>
</ui>
HERE

  my $vbox = $self->{'vbox'} = Gtk2::VBox->new (0, 0);
  $vbox->show;
  $self->add ($vbox);

  my $menubar = $self->menubar;
  $menubar->show;
  $vbox->pack_start ($menubar, 0,0,0);
  if (my $webitem = $ui->get_widget('/MenuBar/ViewMenu/WebMenuItem')) {
    $webitem->signal_connect (map => \&_webmenuitem_submenu, $self);
  }

  {
    my $toolbar = $ui->get_widget ('/ToolBar');
    $vbox->pack_start ($toolbar, 0,0,0);
    my $action = $actiongroup->get_action ('Toolbar');
    Glib::Ex::ConnectProperties->new ([$toolbar,'visible'],
                                      [$action,'active']);
  }

  my $statusbar = $self->{'statusbar'} = Gtk2::Statusbar->new;
  $statusbar->show;

  my $view = $self->{'view'} = App::Chart::Gtk2::View->new (statusbar => $statusbar);
  $view->show;
  $vbox->pack_start ($view, 1,1,0);
  $vbox->pack_end ($statusbar, 0,0,0);

  # default initial size 9/10 of screen, but restrict to aspect ratio 4:3 so
  # as not to use whole width of a wide screen
  my $screen = $self->get_screen;
  my $width  = 0.9 * $screen->get_width_mm;
  my $height = 0.9 * $screen->get_height_mm;
  # aspect ratio in millimetres
  ($width, $height) = shrink_to_aspect_ratio ($width, $height, 4.0/3.0);
  # convert to pixels
  $width  = x_mm_to_pixels ($self, $width);
  $height = y_mm_to_pixels ($self, $height);
  $self->set_default_size ($width, $height);

  foreach (@{$App::Chart::option{'main_hook'}}) { $_->($self) }
}

# 'destroy' class closure
sub _do_destroy {
  my ($self) = @_;
  ### Main destroy

#   {
#     foreach my $child ($self->get_children) {
#       print "remove $child\n";
#       $self->remove ($child);
#     }
#   }
  # break circular references
  delete $self->{'webmenu'};
  delete $self->{'history'};
  delete $self->{'ui'};
  delete $self->{'actiongroup'};
  return shift->signal_chain_from_overridden(@_);

  #   delete $self->{'statusbar'};
  #   delete $self->{'view'};
  #   delete $self->{'symbol_sensitive_actions'};
  #   if (DEBUG) { say "  keys left: ", join(',', keys %$self); }
  #   %$self = ();
  # print "children ",$self->get_children,"\n";

}

sub shrink_to_aspect_ratio {
  my ($width, $height, $ratio) = @_;
  $width  = min ($width,  $ratio * $height);
  $height = min ($height, (1.0/$ratio) * $width);
  return ($width, $height);
}
sub x_mm_to_pixels {
  my ($widget, $x) = @_;
  my $screen = $widget->get_screen
    || croak 'x_mm_to_pixels(): widget not on a screen yet';
  return $x * $screen->get_width / $screen->get_width_mm;
}
sub y_mm_to_pixels {
  my ($widget, $y) = @_;
  my $screen = $widget->get_screen
    || croak 'y_mm_to_pixels(): widget not on a screen yet';
  return $y * $screen->get_height / $screen->get_height_mm;
}

sub _webmenuitem_submenu {
  my ($webitem, $self) = @_;
  ### _webmenuitem_submenu() have: $webitem->get_submenu
  unless ($webitem->get_submenu) {
    require App::Chart::Gtk2::WeblinkMenu;
    my $webmenu = $self->{'webmenu'} = App::Chart::Gtk2::WeblinkMenu->new
      (symbol => $self->{'symbol'});
    $webitem->set_submenu ($webmenu);

    # gtk 2.18 bug -- set_submenu doesn't notify attach-widget
    $webmenu->notify ('attach-widget');
  }
}

#------------------------------------------------------------------------------
# broadcast handlers

# 'delete-symbol' broadcast handler
sub _do_delete_symbol {
  my ($self, $symbol) = @_;
  my $self_symbol = $self->{'symbol'};
  ### Main delete-symbol: $symbol
  ### showing: $self_symbol

  # when currently displayed symbol is deleted goto next, or if no next
  # then previous, or if no previous then go to displaying nothing
  if (defined $self_symbol && $self_symbol eq $symbol) {
    Gtk2::Ex::WidgetCursor->busy;
     ($symbol, my $symlist) = $self->smarker->next ('database');
    if (! defined $symbol) {
      ### next is undef
      ($symbol, $symlist) = $self->smarker->prev ('database');
      ### prev: $symbol
    }
    _goto_with_history ($self, $symbol, $symlist);
  }
}

#------------------------------------------------------------------------------
# misc

sub get_or_create_ticker {
  my ($self) = @_;
  return ($self->{'ticker'} ||= do {
    require App::Chart::Gtk2::Ticker;
    my $ticker = App::Chart::Gtk2::Ticker->new;
    $self->{'vbox'}->pack_start ($ticker, 0,0,0);
    my $action = $self->{'actiongroup'}->get_action ('Ticker');
    Glib::Ex::ConnectProperties->new ([$action,'active'],
                                      [$ticker,'visible']);
    $ticker;
  });
}

# 'symbol-changed' class closure
sub _do_symbol_changed {
  my ($self, $symbol) = @_;
  my $sensitive = (defined $symbol && $symbol ne '');
  my $actiongroup = $self->{'actiongroup'};
  foreach my $name (@{$self->{'symbol_sensitive_actions'}}) {
    my $action = $actiongroup->get_action ($name);
    $action->set_sensitive ($sensitive);
  }

  { my $action = $actiongroup->get_action ('ManualDataSource');
    my $node = $symbol && App::Chart::symbol_source_help ($symbol);
    $action->set_sensitive ($node);
    my $tip = $node && __x('Open the manual at the "{node}" section about this symbol\'s data source', node => $node);
    $action->set (tooltip => $tip);
  }

  { my $action = $actiongroup->get_action ('ManualMovingAverage');
    my $node = manual_for_graph_n($self,0);
    $action->set_sensitive ($node);
    my $tip = $node && __x('Open the manual at the "{node}" section about this moving average', node => $node);
    $action->set (tooltip => $tip);
  }
  { my $action = $actiongroup->get_action ('ManualIndicator');
    my $node = manual_for_graph_n($self,1);
    $action->set_sensitive ($node);
    my $tip = $node && __x('Open the manual at the "{node}" section about this indicator', node => $node);
    $action->set (tooltip => $tip);
  }
}

sub manual_for_graph_n {
  my ($self, $n) = @_;
  my $view = $self->{'view'};
  my $graph = $view->{'graphs'}->[$n] || return;
  my $series = (List::Util::first {! $_->isa('App::Chart::Series::Database')}
                @{$graph->get('series-list')})
    || return;
  my $func = $series->can('manual') || return;
  return $series->$func;
}

#------------------------------------------------------------------------------
# navigation

sub symbol_history {
  my ($self) = @_;
  return $self->{'history'};
}
sub _history_place_to_text {
  my ($history, $place) = @_;
  require App::Chart::Database;
  my ($symbol, $symlist_key) = @$place;
  if (defined (my $name = App::Chart::Database->symbol_name ($symbol))) {
    $symbol .= " - $name";
  }
  return $symbol;
}
sub _history_place_to_symbol_symlist {
  my ($place) = @_;
  my ($symbol, $symlist_key) = @$place;
  require App::Chart::Gtk2::Symlist;
  my $symlist = App::Chart::Gtk2::Symlist->new_from_key_maybe ($symlist_key);
  return ($symbol, $symlist);
}
sub _history_symbol_symlist_to_place {
  my ($symbol, $symlist) = @_;
  return [ $symbol, $symlist && $symlist->key ];
}

sub _goto {
  my ($self, $symbol, $symlist) = @_;
  Gtk2::Ex::WidgetCursor->busy;
  $self->{'symbol'} = $symbol;
  $self->{'symlist'} = $symlist;
  $self->{'view'}->set('symbol', $symbol);
  if (my $webmenu = $self->{'webmenu'}) { $webmenu->set('symbol', $symbol); }
  $self->signal_emit ('symbol-changed', $symbol);

  if ($symbol) {
    require App::Chart::Gtk2::Job::Latest;
    App::Chart::Gtk2::Job::Latest->start_for_view ($symbol, $symlist);
  }
}
sub _goto_with_history {
  my ($self, $symbol, $symlist) = @_;
  ### _goto_with_history: $symbol, $symlist && $symlist->key
  if ($symbol) {
    my $history = $self->symbol_history;
    $history->goto (_history_symbol_symlist_to_place ($symbol, $symlist));
  }
}
sub _history_notify_current {
  my ($history, $pspec, $self) = @_;
  _goto ($self, _history_place_to_symbol_symlist($history->get('current')));
}

sub smarker {
  my ($self) = @_;
  return ($self->{'smarker'} ||= do {
    require App::Chart::Gtk2::Smarker;
    App::Chart::Gtk2::Smarker->new;
  });
}

sub goto_symbol {
  my ($self, $symbol, $symlist) = @_;
  ### Main goto: $symbol, $symlist && $symlist->key
  _goto_with_history ($self, $symbol, $symlist);
  $self->smarker->goto ($symbol, $symlist);
}

sub goto_next {
  my ($self) = @_;
  Gtk2::Ex::WidgetCursor->busy;
  my ($symbol, $symlist) = $self->smarker->next ('database');

  #   require App::Chart::Gtk2::Symlist;
  #   my ($symbol, $symlist)
  #     = App::Chart::Gtk2::Symlist::next ($self->{'symbol'}, $self->{'symlist'});
  if ($symbol) {
    _goto_with_history ($self, $symbol, $symlist);
  } else {
    _message ($self, __('At end of lists'));
  }
}

sub go_prev {
  my ($self) = @_;
  Gtk2::Ex::WidgetCursor->busy;
  my ($symbol, $symlist) = $self->smarker->prev ('database');
  #   require App::Chart::Gtk2::Symlist;
  #   my ($symbol, $symlist)
  #     = App::Chart::Gtk2::Symlist::previous ($self->{'symbol'}, $self->{'symlist'});
  if ($symbol) {
    _goto_with_history ($self, $symbol, $symlist);
  } else {
    _message ($self, __('At start of lists'));
  }
}

sub go_back {
  my ($self) = @_;
  $self->symbol_history->back;
}
sub go_forward {
  my ($self) = @_;
  $self->symbol_history->forward;
}


#------------------------------------------------------------------------------
# other

sub _message {
  my ($self, $str) = @_;
  require Gtk2::Ex::Statusbar::MessageUntilKey;
  Gtk2::Ex::Statusbar::MessageUntilKey->message ($self->{'statusbar'}, $str);
}

# return currently displayed symbol, or undef
sub get_symbol {
  my ($self) = @_;
  return $self->{'view'}->get('symbol');
}

# return the menubar widget
sub menubar {
  my ($self) = @_;
  return $self->{'ui'}->get_widget('/MenuBar');
}

# return App::Chart::Gtk2::Main widget, preferring the transient parent of $dialog,
# if $dialog is given
sub find_for_dialog {
  my ($class, $dialog) = @_;
  if ($dialog
      && $dialog->can('get_transient_for')
      && (my $parent = $dialog->get_transient_for)) {
    if ($parent->isa($class)) {
      return $parent;
    }
  }

  my $screen = $dialog->get_screen;
  foreach my $toplevel (Gtk2::Window->list_toplevels) {
    if ($toplevel->isa($class) && $toplevel->get_screen == $screen) {
      return $toplevel;
    }
  }

  foreach my $toplevel (Gtk2::Window->list_toplevels) {
    if ($toplevel->isa($class)) {
      return $toplevel;
    }
  }
  return $class->new;
}

#------------------------------------------------------------------------------
# mainline

sub main {
  my ($class, $args) = @_;
  ### Main main() args: $args
  ## no critic (ProhibitExit, ProhibitExitInSubroutines)

  my $symbol = $args->[0];
  my $symlist = undef;
  if (@$args > 1 || (Scalar::Util::blessed($symbol)
                     && $symbol->isa('App::Chart::Gtk2::Symlist'))) {
    print STDERR __"chart: only one symbol argument when starting the GUI\n";
    exit 1;
  }

  require Gtk2::Ex::ErrorTextDialog::Handler;
  Glib->install_exception_handler
    (\&Gtk2::Ex::ErrorTextDialog::Handler::exception_handler);
  if (0) {
    ## no critic (RequireLocalizedPunctuationVars)
      $SIG{'__WARN__'} = \&Gtk2::Ex::ErrorTextDialog::Handler::exception_handler;
  }

  Gtk2->disable_setlocale;  # leave LC_NUMERIC alone for version nums
  Gtk2->init;

  Glib::Idle->add
      (sub {
         my $self = $class->instance;
         $self->signal_connect (destroy => sub { Gtk2->main_quit; });

         main::initfile (File::Spec->catfile(App::Chart::chart_directory(),
                                             'gui.pl'));

         $self->show;
         App::Chart::chart_dirbroadcast()->listen;

         if (defined $symbol) {
           my $label = $self->{'view'}->{'initial'}->get_child;
           $label->set_text(__x('Loading {symbol} ...', symbol => $symbol));
           Glib::Idle->add
               (sub {
                  require App::Chart::SymbolMatch;
                  my ($match_symbol, $match_symlist)
                    = App::Chart::SymbolMatch::find ($symbol);
                  if ($match_symbol) {
                    ($symbol, $symlist) = ($match_symbol, $match_symlist);
                  }
                  $self->goto_symbol ($symbol, $symlist);
                  return Glib::SOURCE_REMOVE;
                });
         }
         return Glib::SOURCE_REMOVE;
       },
       Glib::G_PRIORITY_HIGH);
  Gtk2->main;
}

1;
__END__

=for stopwords Eg menubar undef symlist

=head1 NAME

App::Chart::Gtk2::Main -- Chart program main window

=for test_synopsis my ($symbol)

=head1 SYNOPSIS

 use App::Chart::Gtk2::Main;
 App::Chart::Gtk2::Main->open ($symbol)

=head1 WIDGET HIERARCHY

C<App::Chart::Gtk2::Main> is a subclass of C<Gtk2::Window>.

    Gtk2::Widget
      Gtk2::Container
        Gtk2::Bin
          Gtk2::Window
            App::Chart::Gtk2::Main

=head1 DESCRIPTION

A C<App::Chart::Gtk2::Main> widget is the Chart program top-level main window,
displaying the menus, graph, etc.

=head1 BASIC FUNCTIONS

=over 4

=item App::Chart::Gtk2::Main->new (key=>value,...)

Create and return a C<App::Chart::Gtk2::Main> widget.  Optional key/value pairs can
be given to set initial properties (as per C<< Glib::Object->new >>).  The
widget is not displayed, but can be using C<show> in the usual way.  Eg.

    my $main = App::Chart::Gtk2::Main->new;
    $main->show;

=item C<< $main->menubar() >>

Return the menubar widget (a C<Gtk2::MenuBar>).

=back

=head1 SYMBOL NAVIGATION FUNCTIONS

=over 4

=item C<< $main->goto_symbol ($symbol) >>

Display C<$symbol>.  C<$symbol> can be undef to display nothing.

=item C<< $main->goto_next >>

=item C<< $main->goto_prev >>

Go to the next or previous symbol in the current symlist, or next or
previous symlist, etc.  These functions are the "Next" and "Previous" menu
entries and toolbar items.

=item C<< $main->go_back >>

=item C<< $main->go_forward >>

Go back or forward in the history list of displayed symbols.  These
functions are the "Back" and "Forward" menu entries and toolbar items.

=back

=head1 PROPERTIES

...

=head1 SEE ALSO

L<App::Chart::Gtk2::View>, L<App::Chart::Gtk2::WeblinkMenu>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/chart/index.html>

=head1 LICENCE

Copyright 2007, 2008, 2009, 2010, 2011 Kevin Ryde

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
