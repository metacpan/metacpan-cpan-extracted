#!/usr/bin/perl -w

# Copyright 2008, 2009, 2010, 2011 Kevin Ryde

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
use Test::More 0.82 tests => 106;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

require App::Chart::Gtk2::Ex::ListModelPos;


#------------------------------------------------------------------------------
# new

# ok (! eval { App::Chart::Gtk2::Ex::ListModelPos->new; 1 },
#     'error no model');
# ok (! eval { App::Chart::Gtk2::Ex::ListModelPos->new (model => 123); 1 },
#     'error not a model');

require Gtk2;

{ my $store = Gtk2::ListStore->new ('Glib::String');
  my $pos = App::Chart::Gtk2::Ex::ListModelPos->new (model => $store);
  is ($pos->next_index, undef);

  $store->set ($store->insert(0), 0 => 'zero');
  $store->set ($store->insert(1), 0 => 'one');
  $store->set ($store->insert(2), 0 => 'two');
  is ($pos->next_index, 0);
  is ($pos->next_index, 1);
  is ($pos->next_index, 2);
  is ($pos->next_index, undef);
}

#------------------------------------------------------------------------------
# delete first

{ my $store = Gtk2::ListStore->new ('Glib::String');
  $store->set ($store->insert(0), 0 => 'zero');
  $store->set ($store->insert(1), 0 => 'one');
  $store->set ($store->insert(2), 0 => 'two');

  my $p_start = App::Chart::Gtk2::Ex::ListModelPos->new (model => $store,
                                             type  => 'start');
  my $p_end   = App::Chart::Gtk2::Ex::ListModelPos->new (model => $store,
                                             type  => 'end');

  my $p_at_0 = App::Chart::Gtk2::Ex::ListModelPos->new (model => $store,
                                            type  => 'at',
                                            index => 0);
  my $p_at_1 = App::Chart::Gtk2::Ex::ListModelPos->new (model => $store,
                                            type  => 'at',
                                            index => 1);
  my $p_at_2 = App::Chart::Gtk2::Ex::ListModelPos->new (model => $store,
                                            type  => 'at',
                                            index => 2);

  my $p_before_0 = App::Chart::Gtk2::Ex::ListModelPos->new (model => $store,
                                                type  => 'before',
                                                index => 0);
  my $p_before_1 = App::Chart::Gtk2::Ex::ListModelPos->new (model => $store,
                                                type  => 'before',
                                                index => 1);
  my $p_before_2 = App::Chart::Gtk2::Ex::ListModelPos->new (model => $store,
                                                type  => 'before',
                                                index => 2);

  my $p_after_0 = App::Chart::Gtk2::Ex::ListModelPos->new (model => $store,
                                               type  => 'after',
                                               index => 0);
  my $p_after_1 = App::Chart::Gtk2::Ex::ListModelPos->new (model => $store,
                                               type  => 'after',
                                               index => 1);
  my $p_after_2 = App::Chart::Gtk2::Ex::ListModelPos->new (model => $store,
                                               type  => 'after',
                                               index => 2);

  $store->remove ($store->iter_nth_child(undef,0));

  is ($p_start->{'type'}, 'start', 'delete first');
  is ($p_end->{'type'},   'end');

  is ($p_at_0->{'type'}, 'before');
  is ($p_at_0->{'index'}, 0);
  is ($p_at_1->{'type'}, 'at');
  is ($p_at_1->{'index'}, 0);
  is ($p_at_2->{'type'}, 'at');
  is ($p_at_2->{'index'}, 1);

  is ($p_before_0->{'type'}, 'before');
  is ($p_before_0->{'index'}, 0);
  is ($p_before_1->{'type'}, 'before');
  is ($p_before_1->{'index'}, 0);
  is ($p_before_2->{'type'}, 'before');
  is ($p_before_2->{'index'}, 1);

  is ($p_after_0->{'type'}, 'before');
  is ($p_after_0->{'index'}, 0);
  is ($p_after_1->{'type'}, 'after');
  is ($p_after_1->{'index'}, 0);
  is ($p_after_2->{'type'}, 'after');
  is ($p_after_2->{'index'}, 1);
}

#------------------------------------------------------------------------------
# delete middle

{ my $store = Gtk2::ListStore->new ('Glib::String');
  $store->set ($store->insert(0), 0 => 'zero');
  $store->set ($store->insert(1), 0 => 'one');
  $store->set ($store->insert(2), 0 => 'two');

  my $p_start = App::Chart::Gtk2::Ex::ListModelPos->new (model => $store,
                                             type  => 'start');
  my $p_end   = App::Chart::Gtk2::Ex::ListModelPos->new (model => $store,
                                             type  => 'end');

  my $p_at_0 = App::Chart::Gtk2::Ex::ListModelPos->new (model => $store,
                                            type  => 'at',
                                            index => 0);
  my $p_at_1 = App::Chart::Gtk2::Ex::ListModelPos->new (model => $store,
                                            type  => 'at',
                                            index => 1);
  my $p_at_2 = App::Chart::Gtk2::Ex::ListModelPos->new (model => $store,
                                            type  => 'at',
                                            index => 2);

  my $p_before_0 = App::Chart::Gtk2::Ex::ListModelPos->new (model => $store,
                                                type  => 'before',
                                                index => 0);
  my $p_before_1 = App::Chart::Gtk2::Ex::ListModelPos->new (model => $store,
                                                type  => 'before',
                                                index => 1);
  my $p_before_2 = App::Chart::Gtk2::Ex::ListModelPos->new (model => $store,
                                                type  => 'before',
                                                index => 2);

  my $p_after_0 = App::Chart::Gtk2::Ex::ListModelPos->new (model => $store,
                                               type  => 'after',
                                               index => 0);
  my $p_after_1 = App::Chart::Gtk2::Ex::ListModelPos->new (model => $store,
                                               type  => 'after',
                                               index => 1);
  my $p_after_2 = App::Chart::Gtk2::Ex::ListModelPos->new (model => $store,
                                               type  => 'after',
                                               index => 2);

  $store->remove ($store->iter_nth_child(undef,1));

  is ($p_start->{'type'}, 'start', 'delete middle');
  is ($p_end->{'type'},   'end');

  is ($p_at_0->{'type'}, 'at');
  is ($p_at_0->{'index'}, 0);
  is ($p_at_1->{'type'}, 'before');
  is ($p_at_1->{'index'}, 1);
  is ($p_at_2->{'type'}, 'at');
  is ($p_at_2->{'index'}, 1);

  is ($p_before_0->{'type'}, 'before');
  is ($p_before_0->{'index'}, 0);
  is ($p_before_1->{'type'}, 'before');
  is ($p_before_1->{'index'}, 1);
  is ($p_before_2->{'type'}, 'before');
  is ($p_before_2->{'index'}, 1);

  is ($p_after_0->{'type'}, 'after');
  is ($p_after_0->{'index'}, 0);
  is ($p_after_1->{'type'}, 'after');
  is ($p_after_1->{'index'}, 0);
  is ($p_after_2->{'type'}, 'after');
  is ($p_after_2->{'index'}, 1);
}

#------------------------------------------------------------------------------
# delete last

{ my $store = Gtk2::ListStore->new ('Glib::String');
  $store->set ($store->insert(0), 0 => 'zero');
  $store->set ($store->insert(1), 0 => 'one');
  $store->set ($store->insert(2), 0 => 'two');

  my $p_start = App::Chart::Gtk2::Ex::ListModelPos->new (model => $store,
                                             type  => 'start');
  my $p_end   = App::Chart::Gtk2::Ex::ListModelPos->new (model => $store,
                                             type  => 'end');

  my $p_at_0 = App::Chart::Gtk2::Ex::ListModelPos->new (model => $store,
                                            type  => 'at',
                                            index => 0);
  my $p_at_1 = App::Chart::Gtk2::Ex::ListModelPos->new (model => $store,
                                            type  => 'at',
                                            index => 1);
  my $p_at_2 = App::Chart::Gtk2::Ex::ListModelPos->new (model => $store,
                                            type  => 'at',
                                            index => 2);

  my $p_before_0 = App::Chart::Gtk2::Ex::ListModelPos->new (model => $store,
                                                type  => 'before',
                                                index => 0);
  my $p_before_1 = App::Chart::Gtk2::Ex::ListModelPos->new (model => $store,
                                                type  => 'before',
                                                index => 1);
  my $p_before_2 = App::Chart::Gtk2::Ex::ListModelPos->new (model => $store,
                                                type  => 'before',
                                                index => 2);

  my $p_after_0 = App::Chart::Gtk2::Ex::ListModelPos->new (model => $store,
                                               type  => 'after',
                                               index => 0);
  my $p_after_1 = App::Chart::Gtk2::Ex::ListModelPos->new (model => $store,
                                               type  => 'after',
                                               index => 1);
  my $p_after_2 = App::Chart::Gtk2::Ex::ListModelPos->new (model => $store,
                                               type  => 'after',
                                               index => 2);

  $store->remove ($store->iter_nth_child(undef,2));

  is ($p_start->{'type'}, 'start', 'delete last');
  is ($p_end->{'type'},   'end');

  is ($p_at_0->{'type'}, 'at');
  is ($p_at_0->{'index'}, 0);
  is ($p_at_1->{'type'}, 'at');
  is ($p_at_1->{'index'}, 1);
  is ($p_at_2->{'type'}, 'before');
  is ($p_at_2->{'index'}, 2);

  is ($p_before_0->{'type'}, 'before');
  is ($p_before_0->{'index'}, 0);
  is ($p_before_1->{'type'}, 'before');
  is ($p_before_1->{'index'}, 1);
  is ($p_before_2->{'type'}, 'before');
  is ($p_before_2->{'index'}, 2);

  is ($p_after_0->{'type'}, 'after');
  is ($p_after_0->{'index'}, 0);
  is ($p_after_1->{'type'}, 'after');
  is ($p_after_1->{'index'}, 1);
  is ($p_after_2->{'type'}, 'after');
  is ($p_after_2->{'index'}, 1);
}



#------------------------------------------------------------------------------
# insert first

{ my $store = Gtk2::ListStore->new ('Glib::String');
  $store->set ($store->insert(0), 0 => 'zero');
  $store->set ($store->insert(1), 0 => 'one');
  $store->set ($store->insert(2), 0 => 'two');

  my $p_start = App::Chart::Gtk2::Ex::ListModelPos->new (model => $store,
                                             type  => 'start');
  my $p_end   = App::Chart::Gtk2::Ex::ListModelPos->new (model => $store,
                                             type  => 'end');

  my $p_at_0 = App::Chart::Gtk2::Ex::ListModelPos->new (model => $store,
                                            type  => 'at',
                                            index => 0);
  my $p_at_1 = App::Chart::Gtk2::Ex::ListModelPos->new (model => $store,
                                            type  => 'at',
                                            index => 1);
  my $p_at_2 = App::Chart::Gtk2::Ex::ListModelPos->new (model => $store,
                                            type  => 'at',
                                            index => 2);

  my $p_before_0 = App::Chart::Gtk2::Ex::ListModelPos->new (model => $store,
                                                type  => 'before',
                                                index => 0);
  my $p_before_1 = App::Chart::Gtk2::Ex::ListModelPos->new (model => $store,
                                                type  => 'before',
                                                index => 1);
  my $p_before_2 = App::Chart::Gtk2::Ex::ListModelPos->new (model => $store,
                                                type  => 'before',
                                                index => 2);

  my $p_after_0 = App::Chart::Gtk2::Ex::ListModelPos->new (model => $store,
                                               type  => 'after',
                                               index => 0);
  my $p_after_1 = App::Chart::Gtk2::Ex::ListModelPos->new (model => $store,
                                               type  => 'after',
                                               index => 1);
  my $p_after_2 = App::Chart::Gtk2::Ex::ListModelPos->new (model => $store,
                                               type  => 'after',
                                               index => 2);

  $store->set ($store->insert(0), 0=>'new row');

  is ($p_start->{'type'}, 'start', 'delete first');
  is ($p_end->{'type'},   'end');

  is ($p_at_0->{'type'}, 'at');
  is ($p_at_0->{'index'}, 1);
  is ($p_at_1->{'type'}, 'at');
  is ($p_at_1->{'index'}, 2);
  is ($p_at_2->{'type'}, 'at');
  is ($p_at_2->{'index'}, 3);

  is ($p_before_0->{'type'}, 'before');
  is ($p_before_0->{'index'}, 0);
  is ($p_before_1->{'type'}, 'before');
  is ($p_before_1->{'index'}, 2);
  is ($p_before_2->{'type'}, 'before');
  is ($p_before_2->{'index'}, 3);

  is ($p_after_0->{'type'}, 'after');
  is ($p_after_0->{'index'}, 1);
  is ($p_after_1->{'type'}, 'after');
  is ($p_after_1->{'index'}, 2);
  is ($p_after_2->{'type'}, 'after');
  is ($p_after_2->{'index'}, 3);
}


#------------------------------------------------------------------------------
# insert middle

{ my $store = Gtk2::ListStore->new ('Glib::String');
  $store->set ($store->insert(0), 0 => 'zero');
  $store->set ($store->insert(1), 0 => 'one');
  $store->set ($store->insert(2), 0 => 'two');

  my $p_start = App::Chart::Gtk2::Ex::ListModelPos->new (model => $store,
                                             type  => 'start');
  my $p_end   = App::Chart::Gtk2::Ex::ListModelPos->new (model => $store,
                                             type  => 'end');

  my $p_at_0 = App::Chart::Gtk2::Ex::ListModelPos->new (model => $store,
                                            type  => 'at',
                                            index => 0);
  my $p_at_1 = App::Chart::Gtk2::Ex::ListModelPos->new (model => $store,
                                            type  => 'at',
                                            index => 1);
  my $p_at_2 = App::Chart::Gtk2::Ex::ListModelPos->new (model => $store,
                                            type  => 'at',
                                            index => 2);

  my $p_before_0 = App::Chart::Gtk2::Ex::ListModelPos->new (model => $store,
                                                type  => 'before',
                                                index => 0);
  my $p_before_1 = App::Chart::Gtk2::Ex::ListModelPos->new (model => $store,
                                                type  => 'before',
                                                index => 1);
  my $p_before_2 = App::Chart::Gtk2::Ex::ListModelPos->new (model => $store,
                                                type  => 'before',
                                                index => 2);

  my $p_after_0 = App::Chart::Gtk2::Ex::ListModelPos->new (model => $store,
                                               type  => 'after',
                                               index => 0);
  my $p_after_1 = App::Chart::Gtk2::Ex::ListModelPos->new (model => $store,
                                               type  => 'after',
                                               index => 1);
  my $p_after_2 = App::Chart::Gtk2::Ex::ListModelPos->new (model => $store,
                                               type  => 'after',
                                               index => 2);

  $store->set ($store->insert(1), 0=>'new row');

  is ($p_start->{'type'}, 'start', 'delete first');
  is ($p_end->{'type'},   'end');

  is ($p_at_0->{'type'}, 'at');
  is ($p_at_0->{'index'}, 0);
  is ($p_at_1->{'type'}, 'at');
  is ($p_at_1->{'index'}, 2);
  is ($p_at_2->{'type'}, 'at');
  is ($p_at_2->{'index'}, 3);

  is ($p_before_0->{'type'}, 'before');
  is ($p_before_0->{'index'}, 0);
  is ($p_before_1->{'type'}, 'before');
  is ($p_before_1->{'index'}, 1);
  is ($p_before_2->{'type'}, 'before');
  is ($p_before_2->{'index'}, 3);

  is ($p_after_0->{'type'}, 'after');
  is ($p_after_0->{'index'}, 0);
  is ($p_after_1->{'type'}, 'after');
  is ($p_after_1->{'index'}, 2);
  is ($p_after_2->{'type'}, 'after');
  is ($p_after_2->{'index'}, 3);
}

#------------------------------------------------------------------------------
# key-column

{ my $store = Gtk2::ListStore->new ('Glib::String');
  $store->set ($store->insert(0), 0 => 'zero');
  $store->set ($store->insert(1), 0 => 'one');
  $store->set ($store->insert(2), 0 => 'two');

  my $p = App::Chart::Gtk2::Ex::ListModelPos->new (model      => $store,
                                                   type       => 'at',
                                                   index      => 1,
                                                   key_column => 0);
  # diag explain $p;
  $store->remove ($store->iter_nth_child(undef,1));
  # diag explain $p;

  $store->set ($store->insert(0), 0 => 'one');
  is ($p->index, 0,
      'key-column followed from index 1 to index 0');
}

exit 0;
