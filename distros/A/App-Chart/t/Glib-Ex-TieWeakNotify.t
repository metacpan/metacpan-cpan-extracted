#!/usr/bin/perl -w

# Copyright 2009, 2010 Kevin Ryde

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


use 5.008;
use strict;
use warnings;
use Test::More tests => 8;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

require App::Chart::Glib::Ex::TieWeakNotify;


#------------------------------------------------------------------------------
# tie

{
  package MyObject_tie;
  use strict;
  use warnings;
  use Glib;
  use Glib::Object::Subclass
    'Glib::Object',
      properties => [Glib::ParamSpec->scalar
                     ('myprop',
                      'myprop',
                      'Blurb',
                      Glib::G_PARAM_READWRITE)
                    ];
  sub INIT_INSTANCE {
    my ($self) = @_;
  }
  sub SET_PROPERTY {
    my ($self, $pspec, $newval) = @_;
    my $pname = $pspec->get_name;

    if ($pname eq 'myprop') {
      App::Chart::Glib::Ex::TieWeakNotify->set ($self, $pname, $newval);
    } else {
      $self->{$pname} = $newval;
    }
    # diag $self->{$pname};
  }
}

{
  my $obj = MyObject_tie->new;
  is ($obj->get('myprop'),
      undef);
  my $notify_seen;
  $obj->signal_connect ('notify::myprop' => sub {
                          $notify_seen = 1;
                        });

  my $href = {};
  $notify_seen = 0;
  $obj->set(myprop => $href);
  is ($notify_seen, 1);
  is ($obj->get('myprop'), $href);

  my $values = join (' ', map {defined($_) ? $_ : '[undef]'} values %$obj);
  diag "values: $values";

  $notify_seen = 0;
  require Scalar::Util;
  Scalar::Util::weaken ($href);
  is ($notify_seen, 1);
  is ($href, undef);
  is ($obj->get('myprop'), undef);

  Scalar::Util::weaken ($obj);
  is ($obj, undef, 'object destroyed when weakened');

  is_deeply ([ grep {/^App::Chart::Glib::Ex::TieWeakNotify\./} keys %$obj ],
             [],
             'no leftover fields in object');
}

exit 0;
