#!/usr/bin/perl

use strict;
use warnings;

use AnyEvent::Tickit;
use Getopt::Long;

my $widgetclass;
my $file;
GetOptions(
   'widget=s' => \$widgetclass,
   'file=s'   => \$file,
) or exit 1;

my $tickit = AnyEvent::Tickit->new;

defined $file or ( $file = "$widgetclass.pm" ) =~ s{::}{/}g;

require $file;

my $widget = $widgetclass->new;

$tickit->set_root_widget( $widget );

$tickit->run;
