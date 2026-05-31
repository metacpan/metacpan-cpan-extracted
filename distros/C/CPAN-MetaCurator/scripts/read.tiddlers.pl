#!/usr/bin/env perl

use feature 'say';
use open qw(:std :utf8);
use strict;
use warnings;
use warnings qw(FATAL utf8);

use Data::Dumper::Concise; # For Dumper().

use CPAN::MetaCurator::Import;

# ---------------------------------

say "read.tiddlers.pl - Read tiddlers file and report some statistics\n";

binmode STDOUT, ':encoding(UTF-8)';

my($log_level)	= 'debug';
my($importer)	= CPAN::MetaCurator::Import -> new(home_path => '.', log_level => $log_level);
my($data)		= $importer -> read_tiddlers_file;
my($count)		= 0;

my($text, $title);

for my $index (0 .. $#$data)
{
	# Node keys: created modified text title.
	# Node keys: created modified text title.

	$text	= $$data[$index]{text};
	$title	= $$data[$index]{title};

	next if ($title =~ /ChangeLog|MainMenu/); # Special case para names.

	$count++;

	say "Record: $count. Missing prefix", next if ($text !~ m/^\"\"\"\no (.+)$/s);
#	say "$$data[$index]{title}: $$data[$index]{text}";
	say $$data[$index]{title};
}