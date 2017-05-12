#!/usr/bin/perl -w

# Copyright 2008, 2009, 2010 Kevin Ryde

# This file is part of Chart.
#
# Chart is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Chart is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Chart.  If not, see <http://www.gnu.org/licenses/>.


use strict;
use warnings;
use Test::More 0.82 tests => 111;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

require App::Chart::Gtk2::Ex::TreeRowPosition;


#-----------------------------------------------------------------------------
# my $want_version
# is ($App::Chart::Gtk2::Ex::TreeRowPosition::VERSION, $want_version, 'VERSION variable');
# is (App::Chart::Gtk2::Ex::TreeRowPosition->VERSION,  $want_version, 'VERSION class method');
# { ok (eval { App::Chart::Gtk2::Ex::TreeRowPosition->VERSION($want_version); 1 },
#       "VERSION class check $want_version");
#   my $check_version = $want_version + 1000;
#   ok (! eval { App::Chart::Gtk2::Ex::TreeRowPosition->VERSION($check_version); 1 },
#       "VERSION class check $check_version");
# }

#------------------------------------------------------------------------------
# new()

{ 
  my $p = App::Chart::Gtk2::Ex::TreeRowPosition->new;
  isa_ok ($p, 'App::Chart::Gtk2::Ex::TreeRowPosition');
  
  # is ($p->VERSION, $want_version, 'VERSION object method');
  # ok (eval { $p->VERSION($want_version); 1 },
  #     "VERSION object check $want_version");
  # ok (! eval { $p->VERSION($want_version + 1000); 1 },
  #     "VERSION object check " . ($want_version + 1000));
}

#------------------------------------------------------------------------------
# key-column

{ my $store = Gtk2::ListStore->new ('Glib::String');
  $store->set ($store->insert(0), 0 => 'zero');
  $store->set ($store->insert(1), 0 => 'one');
  $store->set ($store->insert(2), 0 => 'two');

  my $p = App::Chart::Gtk2::Ex::TreeRowPosition->new
    (model      => $store,
     type       => 'at',
     path        => Gtk2::TreePath->new_from_indices(1),
     key_column => 0);
  # diag explain $p;
  $store->remove ($store->iter_nth_child(undef,1));

  $store->set ($store->insert(0), 0 => 'one');
  is ($p->get('type'), 'at',
      'key-column followed from index 1 to index 0');
  is ($p->get('path')->to_string, 0,
      'key-column followed from index 1 to index 0');
}

#------------------------------------------------------------------------------
# new

# ok (! eval { App::Chart::Gtk2::Ex::TreeRowPosition->new; 1 },
#     'error no model');
# ok (! eval { App::Chart::Gtk2::Ex::TreeRowPosition->new (model => 123); 1 },
#     'error not a model');

require Gtk2;
Gtk2->disable_setlocale;  # leave LC_NUMERIC alone for version nums
my $have_display = Gtk2->init_check;

{ my $store = Gtk2::ListStore->new ('Glib::String');
  my $pos = App::Chart::Gtk2::Ex::TreeRowPosition->new (model => $store);
  my $path = $pos->next;
  is ($path, undef);
}

{ my $store = Gtk2::ListStore->new ('Glib::String');
  $store->set ($store->insert(0), 0 => 'zero');
  $store->set ($store->insert(1), 0 => 'one');
  $store->set ($store->insert(2), 0 => 'two');
  my $pos = App::Chart::Gtk2::Ex::TreeRowPosition->new (model => $store);
  {
    my $path = $pos->next;
    isa_ok ($path, 'Gtk2::TreePath');
    is ($path->to_string, '0');
  }
  {
    my $path = $pos->next;
    isa_ok ($path, 'Gtk2::TreePath');
    is ($path->to_string, '1');
  }
  {
    my $path = $pos->next;
    isa_ok ($path, 'Gtk2::TreePath');
    is ($path->to_string, '2');
  }
  {
    my $path = $pos->next;
    is ($path, undef);
  }
}

#------------------------------------------------------------------------------
# delete first

{ my $store = Gtk2::ListStore->new ('Glib::String');
  $store->set ($store->insert(0), 0 => 'zero');
  $store->set ($store->insert(1), 0 => 'one');
  $store->set ($store->insert(2), 0 => 'two');

  my $p_start = App::Chart::Gtk2::Ex::TreeRowPosition->new (model => $store,
                                                type  => 'start');
  my $p_end   = App::Chart::Gtk2::Ex::TreeRowPosition->new (model => $store,
                                                type  => 'end');

  my $p_at_0 = App::Chart::Gtk2::Ex::TreeRowPosition->new (model => $store,
                                               type  => 'at',
                                               path => Gtk2::TreePath->new_from_indices(0));
  my $p_at_1 = App::Chart::Gtk2::Ex::TreeRowPosition->new (model => $store,
                                               type  => 'at',
                                               path => Gtk2::TreePath->new_from_indices(1));
  my $p_at_2 = App::Chart::Gtk2::Ex::TreeRowPosition->new (model => $store,
                                               type  => 'at',
                                               path => Gtk2::TreePath->new_from_indices(2));

  my $p_before_0 = App::Chart::Gtk2::Ex::TreeRowPosition->new (model => $store,
                                                   type  => 'before',
                                                   path => Gtk2::TreePath->new_from_indices(0));
  my $p_before_1 = App::Chart::Gtk2::Ex::TreeRowPosition->new (model => $store,
                                                   type  => 'before',
                                                   path => Gtk2::TreePath->new_from_indices(1));
  my $p_before_2 = App::Chart::Gtk2::Ex::TreeRowPosition->new (model => $store,
                                                   type  => 'before',
                                                   path => Gtk2::TreePath->new_from_indices(2));

  my $p_after_0 = App::Chart::Gtk2::Ex::TreeRowPosition->new (model => $store,
                                                  type  => 'after',
                                                  path => Gtk2::TreePath->new_from_indices(0));
  my $p_after_1 = App::Chart::Gtk2::Ex::TreeRowPosition->new (model => $store,
                                                  type  => 'after',
                                                  path => Gtk2::TreePath->new_from_indices(1));
  my $p_after_2 = App::Chart::Gtk2::Ex::TreeRowPosition->new (model => $store,
                                                  type  => 'after',
                                                  path => Gtk2::TreePath->new_from_indices(2));

  $store->remove ($store->iter_nth_child(undef,0));

  is ($p_start->get('type'), 'start', 'delete first');
  is ($p_end->get('type'),   'end');

  is ($p_at_0->get('type'), 'before');
  is ($p_at_0->get('path')->to_string, 0);
  is ($p_at_1->get('type'), 'at');
  is ($p_at_1->get('path')->to_string, 0);
  is ($p_at_2->get('type'), 'at');
  is ($p_at_2->get('path')->to_string, 1);

  is ($p_before_0->get('type'), 'before');
  is ($p_before_0->get('path')->to_string, 0);
  is ($p_before_1->get('type'), 'before');
  is ($p_before_1->get('path')->to_string, 0);
  is ($p_before_2->get('type'), 'before');
  is ($p_before_2->get('path')->to_string, 1);

  is ($p_after_0->get('type'), 'before');
  is ($p_after_0->get('path')->to_string, 0);
  is ($p_after_1->get('type'), 'after');
  is ($p_after_1->get('path')->to_string, 0);
  is ($p_after_2->get('type'), 'after');
  is ($p_after_2->get('path')->to_string, 1);
}

#------------------------------------------------------------------------------
# delete middle

{ my $store = Gtk2::ListStore->new ('Glib::String');
  $store->set ($store->insert(0), 0 => 'zero');
  $store->set ($store->insert(1), 0 => 'one');
  $store->set ($store->insert(2), 0 => 'two');

  my $p_start = App::Chart::Gtk2::Ex::TreeRowPosition->new (model => $store,
                                             type  => 'start');
  my $p_end   = App::Chart::Gtk2::Ex::TreeRowPosition->new (model => $store,
                                             type  => 'end');

  my $p_at_0 = App::Chart::Gtk2::Ex::TreeRowPosition->new (model => $store,
                                            type  => 'at',
                                            path => Gtk2::TreePath->new_from_indices(0));
  my $p_at_1 = App::Chart::Gtk2::Ex::TreeRowPosition->new (model => $store,
                                            type  => 'at',
                                            path => Gtk2::TreePath->new_from_indices(1));
  my $p_at_2 = App::Chart::Gtk2::Ex::TreeRowPosition->new (model => $store,
                                            type  => 'at',
                                            path => Gtk2::TreePath->new_from_indices(2));

  my $p_before_0 = App::Chart::Gtk2::Ex::TreeRowPosition->new (model => $store,
                                                type  => 'before',
                                                path => Gtk2::TreePath->new_from_indices(0));
  my $p_before_1 = App::Chart::Gtk2::Ex::TreeRowPosition->new (model => $store,
                                                type  => 'before',
                                                path => Gtk2::TreePath->new_from_indices(1));
  my $p_before_2 = App::Chart::Gtk2::Ex::TreeRowPosition->new (model => $store,
                                                type  => 'before',
                                                path => Gtk2::TreePath->new_from_indices(2));

  my $p_after_0 = App::Chart::Gtk2::Ex::TreeRowPosition->new (model => $store,
                                               type  => 'after',
                                               path => Gtk2::TreePath->new_from_indices(0));
  my $p_after_1 = App::Chart::Gtk2::Ex::TreeRowPosition->new (model => $store,
                                               type  => 'after',
                                               path => Gtk2::TreePath->new_from_indices(1));
  my $p_after_2 = App::Chart::Gtk2::Ex::TreeRowPosition->new (model => $store,
                                               type  => 'after',
                                               path => Gtk2::TreePath->new_from_indices(2));

  $store->remove ($store->iter_nth_child(undef,1));

  is ($p_start->get('type'), 'start', 'delete middle');
  is ($p_end->get('type'),   'end');

  is ($p_at_0->get('type'), 'at');
  is ($p_at_0->get('path')->to_string, 0);
  is ($p_at_1->get('type'), 'after');
  is ($p_at_1->get('path')->to_string, 0);
  is ($p_at_2->get('type'), 'at');
  is ($p_at_2->get('path')->to_string, 1);

  is ($p_before_0->get('type'), 'before');
  is ($p_before_0->get('path')->to_string, 0);
  is ($p_before_1->get('type'), 'before');
  is ($p_before_1->get('path')->to_string, 1);
  is ($p_before_2->get('type'), 'before');
  is ($p_before_2->get('path')->to_string, 1);

  is ($p_after_0->get('type'), 'after');
  is ($p_after_0->get('path')->to_string, 0);
  is ($p_after_1->get('type'), 'after');
  is ($p_after_1->get('path')->to_string, 0);
  is ($p_after_2->get('type'), 'after');
  is ($p_after_2->get('path')->to_string, 1);
}

#------------------------------------------------------------------------------
# delete last

{ my $store = Gtk2::ListStore->new ('Glib::String');
  $store->set ($store->insert(0), 0 => 'zero');
  $store->set ($store->insert(1), 0 => 'one');
  $store->set ($store->insert(2), 0 => 'two');

  my $p_start = App::Chart::Gtk2::Ex::TreeRowPosition->new (model => $store,
                                             type  => 'start');
  my $p_end   = App::Chart::Gtk2::Ex::TreeRowPosition->new (model => $store,
                                             type  => 'end');

  my $p_at_0 = App::Chart::Gtk2::Ex::TreeRowPosition->new (model => $store,
                                            type  => 'at',
                                            path => Gtk2::TreePath->new_from_indices(0));
  my $p_at_1 = App::Chart::Gtk2::Ex::TreeRowPosition->new (model => $store,
                                            type  => 'at',
                                            path => Gtk2::TreePath->new_from_indices(1));
  my $p_at_2 = App::Chart::Gtk2::Ex::TreeRowPosition->new (model => $store,
                                            type  => 'at',
                                            path => Gtk2::TreePath->new_from_indices(2));

  my $p_before_0 = App::Chart::Gtk2::Ex::TreeRowPosition->new (model => $store,
                                                type  => 'before',
                                                path => Gtk2::TreePath->new_from_indices(0));
  my $p_before_1 = App::Chart::Gtk2::Ex::TreeRowPosition->new (model => $store,
                                                type  => 'before',
                                                path => Gtk2::TreePath->new_from_indices(1));
  my $p_before_2 = App::Chart::Gtk2::Ex::TreeRowPosition->new (model => $store,
                                                type  => 'before',
                                                path => Gtk2::TreePath->new_from_indices(2));

  my $p_after_0 = App::Chart::Gtk2::Ex::TreeRowPosition->new (model => $store,
                                               type  => 'after',
                                               path => Gtk2::TreePath->new_from_indices(0));
  my $p_after_1 = App::Chart::Gtk2::Ex::TreeRowPosition->new (model => $store,
                                               type  => 'after',
                                               path => Gtk2::TreePath->new_from_indices(1));
  my $p_after_2 = App::Chart::Gtk2::Ex::TreeRowPosition->new (model => $store,
                                               type  => 'after',
                                               path => Gtk2::TreePath->new_from_indices(2));

  $store->remove ($store->iter_nth_child(undef,2));

  is ($p_start->get('type'), 'start', 'delete last');
  is ($p_end->get('type'),   'end');

  is ($p_at_0->get('type'), 'at');
  is ($p_at_0->get('path')->to_string, 0);
  is ($p_at_1->get('type'), 'at');
  is ($p_at_1->get('path')->to_string, 1);
  is ($p_at_2->get('type'), 'after');
  is ($p_at_2->get('path')->to_string, 1);

  is ($p_before_0->get('type'), 'before');
  is ($p_before_0->get('path')->to_string, 0);
  is ($p_before_1->get('type'), 'before');
  is ($p_before_1->get('path')->to_string, 1);
  is ($p_before_2->get('type'), 'before');
  is ($p_before_2->get('path')->to_string, 2);

  is ($p_after_0->get('type'), 'after');
  is ($p_after_0->get('path')->to_string, 0);
  is ($p_after_1->get('type'), 'after');
  is ($p_after_1->get('path')->to_string, 1);
  is ($p_after_2->get('type'), 'after');
  is ($p_after_2->get('path')->to_string, 1);
}



#------------------------------------------------------------------------------
# insert first

{ my $store = Gtk2::ListStore->new ('Glib::String');
  $store->set ($store->insert(0), 0 => 'zero');
  $store->set ($store->insert(1), 0 => 'one');
  $store->set ($store->insert(2), 0 => 'two');

  my $p_start = App::Chart::Gtk2::Ex::TreeRowPosition->new (model => $store,
                                                type  => 'start');
  my $p_end   = App::Chart::Gtk2::Ex::TreeRowPosition->new (model => $store,
                                                type  => 'end');

  my $p_at_0 = App::Chart::Gtk2::Ex::TreeRowPosition->new (model => $store,
                                               type  => 'at',
                                               path => Gtk2::TreePath->new_from_indices(0));
  my $p_at_1 = App::Chart::Gtk2::Ex::TreeRowPosition->new (model => $store,
                                               type  => 'at',
                                               path => Gtk2::TreePath->new_from_indices(1));
  my $p_at_2 = App::Chart::Gtk2::Ex::TreeRowPosition->new (model => $store,
                                               type  => 'at',
                                               path => Gtk2::TreePath->new_from_indices(2));

  my $p_before_0 = App::Chart::Gtk2::Ex::TreeRowPosition->new (model => $store,
                                                   type  => 'before',
                                                   path => Gtk2::TreePath->new_from_indices(0));
  my $p_before_1 = App::Chart::Gtk2::Ex::TreeRowPosition->new (model => $store,
                                                   type  => 'before',
                                                   path => Gtk2::TreePath->new_from_indices(1));
  my $p_before_2 = App::Chart::Gtk2::Ex::TreeRowPosition->new (model => $store,
                                                   type  => 'before',
                                                   path => Gtk2::TreePath->new_from_indices(2));

  my $p_after_0 = App::Chart::Gtk2::Ex::TreeRowPosition->new (model => $store,
                                                  type  => 'after',
                                                  path => Gtk2::TreePath->new_from_indices(0));
  my $p_after_1 = App::Chart::Gtk2::Ex::TreeRowPosition->new (model => $store,
                                                  type  => 'after',
                                                  path => Gtk2::TreePath->new_from_indices(1));
  my $p_after_2 = App::Chart::Gtk2::Ex::TreeRowPosition->new (model => $store,
                                                  type  => 'after',
                                                  path => Gtk2::TreePath->new_from_indices(2));

  $store->set ($store->insert(0), 0=>'new row');

  is ($p_start->get('type'), 'start', 'delete first');
  is ($p_end->get('type'),   'end');

  is ($p_at_0->get('type'), 'at');
  is ($p_at_0->get('path')->to_string, 1);
  is ($p_at_1->get('type'), 'at');
  is ($p_at_1->get('path')->to_string, 2);
  is ($p_at_2->get('type'), 'at');
  is ($p_at_2->get('path')->to_string, 3);

  is ($p_before_0->get('type'), 'before');
  is ($p_before_0->get('path')->to_string, 0);
  is ($p_before_1->get('type'), 'before');
  is ($p_before_1->get('path')->to_string, 2);
  is ($p_before_2->get('type'), 'before');
  is ($p_before_2->get('path')->to_string, 3);

  is ($p_after_0->get('type'), 'after');
  is ($p_after_0->get('path')->to_string, 1);
  is ($p_after_1->get('type'), 'after');
  is ($p_after_1->get('path')->to_string, 2);
  is ($p_after_2->get('type'), 'after');
  is ($p_after_2->get('path')->to_string, 3);
}


#------------------------------------------------------------------------------
# insert middle

{ my $store = Gtk2::ListStore->new ('Glib::String');
  $store->set ($store->insert(0), 0 => 'zero');
  $store->set ($store->insert(1), 0 => 'one');
  $store->set ($store->insert(2), 0 => 'two');

  my $p_start = App::Chart::Gtk2::Ex::TreeRowPosition->new (model => $store,
                                             type  => 'start');
  my $p_end   = App::Chart::Gtk2::Ex::TreeRowPosition->new (model => $store,
                                             type  => 'end');

  my $p_at_0 = App::Chart::Gtk2::Ex::TreeRowPosition->new (model => $store,
                                            type  => 'at',
                                            path => Gtk2::TreePath->new_from_indices(0));
  my $p_at_1 = App::Chart::Gtk2::Ex::TreeRowPosition->new (model => $store,
                                            type  => 'at',
                                            path => Gtk2::TreePath->new_from_indices(1));
  my $p_at_2 = App::Chart::Gtk2::Ex::TreeRowPosition->new (model => $store,
                                            type  => 'at',
                                            path => Gtk2::TreePath->new_from_indices(2));

  my $p_before_0 = App::Chart::Gtk2::Ex::TreeRowPosition->new (model => $store,
                                                type  => 'before',
                                                path => Gtk2::TreePath->new_from_indices(0));
  my $p_before_1 = App::Chart::Gtk2::Ex::TreeRowPosition->new (model => $store,
                                                type  => 'before',
                                                path => Gtk2::TreePath->new_from_indices(1));
  my $p_before_2 = App::Chart::Gtk2::Ex::TreeRowPosition->new (model => $store,
                                                type  => 'before',
                                                path => Gtk2::TreePath->new_from_indices(2));

  my $p_after_0 = App::Chart::Gtk2::Ex::TreeRowPosition->new (model => $store,
                                               type  => 'after',
                                               path => Gtk2::TreePath->new_from_indices(0));
  my $p_after_1 = App::Chart::Gtk2::Ex::TreeRowPosition->new (model => $store,
                                               type  => 'after',
                                               path => Gtk2::TreePath->new_from_indices(1));
  my $p_after_2 = App::Chart::Gtk2::Ex::TreeRowPosition->new (model => $store,
                                               type  => 'after',
                                               path => Gtk2::TreePath->new_from_indices(2));

  $store->set ($store->insert(1), 0=>'new row');

  is ($p_start->get('type'), 'start', 'delete first');
  is ($p_end->get('type'),   'end');

  is ($p_at_0->get('type'), 'at');
  is ($p_at_0->get('path')->to_string, 0);
  is ($p_at_1->get('type'), 'at');
  is ($p_at_1->get('path')->to_string, 2);
  is ($p_at_2->get('type'), 'at');
  is ($p_at_2->get('path')->to_string, 3);

  is ($p_before_0->get('type'), 'before');
  is ($p_before_0->get('path')->to_string, 0);
  is ($p_before_1->get('type'), 'before');
  is ($p_before_1->get('path')->to_string, 1);
  is ($p_before_2->get('type'), 'before');
  is ($p_before_2->get('path')->to_string, 3);

  is ($p_after_0->get('type'), 'after');
  is ($p_after_0->get('path')->to_string, 0);
  is ($p_after_1->get('type'), 'after');
  is ($p_after_1->get('path')->to_string, 2);
  is ($p_after_2->get('type'), 'after');
  is ($p_after_2->get('path')->to_string, 3);
}

exit 0;
