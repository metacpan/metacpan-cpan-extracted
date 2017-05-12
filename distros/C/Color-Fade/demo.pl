#!/usr/bin/perl -w

use strict;
use warnings;
use lib "./lib";
use Color::Fade qw(color_fade format_color);

print "Choose output HTML file to write to [./demo.html] ";
chomp (my $page = <STDIN>);
$page = "./demo.html" unless length $page;

open (OUT, ">$page");
print OUT "<body bgcolor=\"#000000\">\n";

# Demo 1: Using format_html to generate <font>...</font> output.
# String: The quick brown fox jumps over the lazy dog.
# Colors: Red, Green, Blue
print OUT "<font color=\"#FFFFFF\"><u>Demo 1: Using <b>format_html()</b> to generate &lt;font&gt; tags.</u></font><p>\n";
print OUT format_color ('html',
	color_fade (
		"The quick brown fox jumps over the lazy dog.",
		'#FF0000',
		'#00FF00',
		'#0000FF',
	)
);
print OUT "<p>\n";

# Demo 2: Using format_css to generate HTML 4 compliant <span>...</span> output.
# String: Jackdaws love my big sphynx of quartz.
# Colors: Cyan, Yellow, Magenta
print OUT "<span style=\"color: #FFFFFF\"><u>Demo 2: Using <b>format_css()</b> to generate HTML 4 compliant &lt;span&gt; tags.</u></span><p>\n";
print OUT format_color ('css',
	color_fade (
		'Jackdaws love my big sphynx of quartz.',
		'#00FFFF',
		'#FFFF00',
		'#FF00FF',
	)
);

print OUT "<p>\n\n<span style=\"color: #FFFFFF\"><u>More Demonstrations</u></span><p>\n\n";

# Demo 3: Just another example.
# String: Just another Perl hacker.
# Colors: pink, light blue
print OUT format_color ('html',
	color_fade (
		'Just another Perl hacker.',
		'#FF99FF',
		'#0099FF',
	)
);

print OUT "<p>";

# Demo 4: Yet another example.
# String: something very long
# Colors: rainbow
print OUT format_color ('html',
	color_fade (
		'And as this paragraph shows, the module can support strings of any length you want, and '
		. 'can fade that string using as many different colors as you want. This one uses all the '
		. 'colors of the rainbow, and tops it off with white edges. That\'s 9 colors!',
		'#FFFFFF',
		'#FF0000',
		'#FF9900',
		'#FFFF00',
		'#00FF00',
		'#0099FF',
		'#0000FF',
		'#FF99FF',
		'#FFFFFF',
	)
);
