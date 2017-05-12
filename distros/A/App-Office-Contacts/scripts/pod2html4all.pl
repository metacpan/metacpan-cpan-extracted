#!/usr/bin/env perl

use feature 'say';
use strict;
use utf8;
use warnings;
use warnings  qw(FATAL utf8);    # Fatalize encoding glitches.
use open      qw(:std :utf8);    # Undeclared streams in UTF-8.
use charnames qw(:full :short);  # Unneeded in v5.16.

use Path::Iterator::Rule;

# -----------------------

my($basename);
my(@html_file, $html_file);

for my $pm_file (Path::Iterator::Rule -> new -> perl_module -> all)
{
	# Ignore Module::Install stuff.

	next if ($pm_file =~ m|^\./inc/|);

	say $pm_file;

	# Convert ./lib/App/Office/Contacts.pm into
	# $DR/Perl-modules/html/App/Office/Contacts.html.
	# Note: $DR is my web server's doc root.

	@html_file = split(m|/|, $pm_file);

	# Discard '.' and 'lib'.

	shift @html_file;
	shift @html_file;

	$basename  = pop @html_file;
	$basename  =~ s/pm$/html/;
	$html_file = join('/', $ENV{DR}, 'Perl-modules', 'html', @html_file);

	`mkdir -p $html_file`;

	$html_file = "$html_file/$basename";

	say $html_file;

	`pod2html.pl -i $pm_file -o $html_file`;
}
