#!/usr/bin/perl -w

use strict;
use Glib ':constants';
use Gtk2 -init;

use Data::TreeDumper::Renderer::GTK ; # Gtk2::TreeView derived class

# some silly test data
my %data = (
	foo => 'bar',
	whee => [ qw(a b c d e f g) ],
	fluffy => {
		a => 'b',
		c => ['foo', [qw(one two three)], {one=>1, two=>2}],
		d => { red => 'blue' },
	},
	'something undefined' => undef,
	'empty array' => [],
	'empty hash' => {},
);

my $treedumper = Data::TreeDumper::Renderer::GTK->new
			(
			data => \%data,
			title => 'Test Data',
			dumper_setup => {DISPLAY_PERL_SIZE => 1}
			);
			
$treedumper->modify_font(Gtk2::Pango::FontDescription->from_string ('monospace'));
$treedumper->expand_all;

# some boilerplate to get the widget onto the screen...
my $window = Gtk2::Window->new;
$window->set_default_size (400, 500);
$window->signal_connect (destroy => sub { Gtk2->main_quit });

my $scroller = Gtk2::ScrolledWindow->new;
$scroller->set_policy ('automatic', 'automatic');
$scroller->set_shadow_type ('in');
$scroller->add ($treedumper);

$window->add ($scroller);
$window->show_all;

Gtk2->main;

