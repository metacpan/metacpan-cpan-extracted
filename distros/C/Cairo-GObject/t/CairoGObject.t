#!/usr/bin/perl
#
# Copyright (c) 2011 by the cairo perl team (see the file README)
#
# Licensed under the LGPL, see LICENSE file for more information.
#

use strict;
use warnings;

use Test::More tests => 7;

use Cairo::GObject;

my $drawer = Drawer->new;

# Put some Cairo objects into the Drawer.
my $orig_surf = Cairo::ImageSurface->create ('argb32', 10, 10);
$drawer->set (surface => $orig_surf);

my $orig_cr = Cairo::Context->create ($orig_surf);
$orig_cr->set_antialias ('gray');
$drawer->set (context => $orig_cr);

my $orig_pattern = Cairo::LinearGradient->create (1, 2, 3, 4);
$orig_pattern->set_extend ('repeat');
$drawer->set (pattern => $orig_pattern);

# Now get them back and see if they're unscathed.
my $cr = $drawer->get ('context');
isa_ok ($cr, 'Cairo::Context');
is ($cr->get_antialias, 'gray');

my $surf = $drawer->get ('surface');
isa_ok ($surf, 'Cairo::ImageSurface');
is ($surf->get_content, 'color-alpha');
is ($surf->get_width, 10);

my $pattern = $drawer->get ('pattern');
isa_ok ($pattern, 'Cairo::LinearGradient');
is ($pattern->get_extend, 'repeat');

# --------------------------------------------------------------------------- #

package Drawer;

use strict;
use warnings;
use Cairo::GObject;

use Glib::Object::Subclass
  Glib::Object::,
  properties => [
    Glib::ParamSpec->boxed ('context', 'context', 'context',
                            Cairo::Context::,
                            [qw/readable writable/]),
    Glib::ParamSpec->boxed ('surface', 'surface', 'surface',
                            Cairo::Surface::,
                            [qw/readable writable/]),
    Glib::ParamSpec->boxed ('pattern', 'pattern', 'pattern',
                            Cairo::Pattern::,
                            [qw/readable writable/]),
  ];
