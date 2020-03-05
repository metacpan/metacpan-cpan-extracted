#!/usr/bin/perl

use strict;
use warnings;

use Tickit;
use Tickit::Widgets qw( VSplit Static );

my $vsplit = Tickit::Widget::VSplit->new(
   left_child => Tickit::Widget::Static->new(
      text => "Left child",
      align => "centre", valign => "middle",
   ),
   right_child => Tickit::Widget::Static->new(
      text => "Right child",
      align => "centre", valign => "middle",
   ),
);

Tickit->new( root => $vsplit )->run;
