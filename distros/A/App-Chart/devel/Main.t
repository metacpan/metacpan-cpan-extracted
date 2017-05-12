#!/usr/bin/perl -w

# Copyright 2008, 2009, 2010, 2011, 2012 Kevin Ryde

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

use 5.008;
use strict;
use warnings;

use Test::More 0.82 tests => 18;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }
use AppChartTestHelpers;

require App::Chart::Gtk2::Main;

#-----------------------------------------------------------------------------

require Gtk2;
Gtk2->disable_setlocale;  # leave LC_NUMERIC alone for version nums
my $have_display = Gtk2->init_check;

# Test::Weaken 3 for "contents"
my $have_test_weaken = eval "use Test::Weaken 3; 1";
if (! $have_test_weaken) {
  diag "Test::Weaken 3 not available -- $@";
}


#-----------------------------------------------------------------------------
# actions (those which should always run at least)

SKIP: {
  $have_display or skip 'due to no DISPLAY available', 15;

  my $main = App::Chart::Gtk2::Main->new;
  $main->show;
  my $actiongroup = $main->{'actiongroup'};
  foreach my $name ('Open', 'Intraday', 'ViewStyle', 'Watchlist', 'Download',
                    'Vacuum', 'Errors', 'Diagnostics', 'About',
                    'Cross', 'Ticker', 'Toolbar',
                    'Daily', 'Weekly', 'Monthly') {
    diag "action $name";
    my $action = $actiongroup->get_action ($name);
    ok ($action, "action $name");
    $action->activate;
  }
  $main->destroy;
  foreach my $toplevel (Gtk2::Window->list_toplevels) {
    $toplevel->destroy;
  }
  MyTestHelpers::main_iterations();
}

#-----------------------------------------------------------------------------
# weakening

require Scalar::Util;
sub my_ignore {
  my ($ref) = @_;
  return (Scalar::Util::blessed($ref)
          && $ref->isa('Glib::Flags'));
}

SKIP: {
  $have_display or skip 'due to no DISPLAY available', 1;
  $have_test_weaken or skip 'due to Test::Weaken 3 not available', 1;

  require Test::Weaken::Gtk2;

  my $leaks = Test::Weaken::leaks
    ({ constructor => sub {
         my $main = App::Chart::Gtk2::Main->new;
         return $main;
       },
       destructor => \&Test::Weaken::Gtk2::destructor_destroy,
       contents => \&Test::Weaken::Gtk2::contents_container,
       # ignore => \&my_ignore,
       # trace_following => 1,
     });
  is ($leaks, undef, 'Test::Weaken deep garbage collection');
  if ($leaks) {
    diag "Test-Weaken ", explain $leaks;

    my $unfreed = $leaks->unfreed_proberefs;
    foreach my $proberef (@$unfreed) {
      diag "  unfreed $proberef";
    }
    foreach my $proberef (@$unfreed) {
      diag "  search $proberef";
      MyTestHelpers::findrefs($proberef);
    }
  }
}

SKIP: {
  $have_display or skip 'due to no DISPLAY available', 1;
  $have_test_weaken or skip 'due to Test::Weaken 3 not available', 1;

  my $leaks = Test::Weaken::leaks
    ({ constructor => sub {
         my $main = App::Chart::Gtk2::Main->new;
         $main->show_all;
         return $main;
       },
       destructor => \&Test::Weaken::Gtk2::destructor_destroy,
       contents => \&Test::Weaken::Gtk2::contents_container,
     });
  is ($leaks, undef, 'Test::Weaken deep garbage collection -- with show_all');
  if ($leaks) {
    diag "Test-Weaken ", explain $leaks;
  }
}

SKIP: {
  $have_display or skip 'due to no DISPLAY available', 1;
  $have_test_weaken or skip 'due to Test::Weaken 3 not available', 1;

  my $leaks = Test::Weaken::leaks
    ({ constructor => sub {
         my $main = App::Chart::Gtk2::Main->new;
         $main->show_all;
         $main->get_or_create_ticker;
         $main->symbol_history;
         return $main;
       },
       destructor => \&Test::Weaken::Gtk2::destructor_destroy,
       contents => \&Test::Weaken::Gtk2::contents_container,
       ignore => \&AppChartTestHelpers::ignore_symlists
     });
  is ($leaks, undef, 'Test::Weaken deep garbage collection');
  if ($leaks) {
    diag "Test-Weaken ", explain $leaks;

    my $unfreed = $leaks->unfreed_proberefs;
    foreach (@$unfreed) {
      diag "  unfreed $_";
    }
    foreach (@$unfreed) {
      diag "  unfreed $_";
      MyTestHelpers::findrefs($_);
    }
  }
}


# my $x = \&Glib::Object::DESTROY;
# *Glib::Object::DESTROY = sub {
#   my $str = "$_[0]";
#   print "start DESTROY $str\n";
#   if ($_[0]->isa('Gtk2::Toolbar')) {
#     print "  parent ",$_[0]->get_parent,"\n";
#   }
#   $x->(@_);
#   print "end DESTROY $str\n";
# };
# {
#   my $main = App::Chart::Gtk2::Main->new;
#   #  print "main $main\n";
#   $main->goto_next;
#   $main->destroy;
#
#   #   my $c = Glib::Object::all_closures();
#   #   diag $c, scalar @$c;
#   # my $d = $c->[0];
#   #   diag $d, scalar @$d;
#
#   MyTestHelpers::main_iterations();
#   Scalar::Util::weaken ($main);
#   is ($main, undef,
#       'garbage collect after destroy -- after goto_next');
#   MyTestHelpers::findrefs($main);
# }

# {
#   my $leaks = Test::Weaken::leaks
#     ({ constructor => sub {
#          my $main = App::Chart::Gtk2::Main->new;
#          $main->show_all;
#          # $main->symbol_history;
#          # $main->get_or_create_ticker;
#          #         $main->{'view'}->crosshair;
#
#          my $symbol = 'BHP.AX';
#          require App::Chart::Gtk2::Symlist::All;
#          my $symlist = App::Chart::Gtk2::Symlist::All->instance;
#          $main->{'view'}->set_symbol ($symbol);
#
#          # $main->smarker->goto ($symbol, $symlist);
#          #          #  $main->goto_symbol ('BHP.AX');
#          return [ $main, container_children_recursively($main) ];
#        },
#        destructor => sub {
#          my ($aref) = @_;
#          my $main = $aref->[0];
#          $main->destroy;
#        }
#      });
#   my $unfreed = (defined $leaks ? $leaks->unfreed_proberefs : []);
#   # FIXME
#   $unfreed = [ grep {Scalar::Util::blessed($_)}
#                @$unfreed ];
#   $unfreed = [ grep {! (Scalar::Util::blessed($_)
#                         && ($_->isa('App::Chart::Gtk2::Symlist')
#                             || $_->isa('App::Chart::Gtk2::SymlistListModel')
#                             || $_->isa('DBI::db')
#                             || $_->isa('DBI::st')))}
#                @$unfreed ];
#   is_deeply ($unfreed, [], 'Test::Weaken deep garbage collection');
#
#   foreach (@$unfreed) {
#     diag "  unfreed $_";
#   }
#   foreach (@$unfreed) {
#     diag "  unfreed $_";
#     MyTestHelpers::findrefs($_);
#   }
# }


exit 0;
