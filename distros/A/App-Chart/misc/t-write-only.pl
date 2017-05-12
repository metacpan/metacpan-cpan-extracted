#!/usr/bin/perl -w

# Copyright 2008, 2009, 2010, 2011 Kevin Ryde

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

package TestGetProp;
use strict;
use warnings;
use Gtk2;
use Scalar::Util;
use Locale::TextDomain ('App-Chart');

use App::Chart::Database;
use App::Chart::Gtk2::GUI;

use Glib::Object::Subclass
  'Gtk2::Widget',
  properties => [Glib::ParamSpec->boolean
                 ('foo',
                  'foo',
                  'blurb',
                  0,
                  ['writable'])
                ];


sub INIT_INSTANCE {
  my ($self) = @_;
  $self->{'foo'} = 0;
}

sub SET_PROPERTY {
  my ($self, $pspec, $newval) = @_;
  my $pname = $pspec->get_name;
  $self->{$pname} = $newval;
  $self->notify ($pname);
}

package main;
use strict;
use warnings;
use Data::Dumper;

my $obj = TestGetProp->new;

$obj->signal_connect ('notify::foo' => sub {
                        my ($obj, $param) = @_;
                        print "notify::foo\n";
                      });


print "set 123\n";
$obj->set(foo => 123);

print "get\n";
my $val = $obj->get('foo');
print Dumper ($val);

$val = $obj->get('foo');
print Dumper ($val);

$obj->set(foo => 999);
$val = $obj->get('foo');
print Dumper ($val);


my $label = Gtk2::Label->new ('hello');
$label->signal_connect ('notify::wrap' => sub {
                          my ($obj, $param) = @_;
                          print "label notify::wrap\n";
                        });
$label->set_line_wrap (1);
$val = $label->get('wrap');
print Dumper ($val);


exit 0;
