#!/usr/bin/env perl

use 5.40.0;

use Data::Dumper::Concise; # For Dumper().

use CPAN::MetaCurator::Util::Import;

# ---------------------------------
binmode STDOUT, ':encoding(UTF-8)';

my($importer)	= CPAN::MetaCurator::Util::Import -> new(home_path => '.');
my($data)		= $importer -> read_tiddlers_file;
my($count)		= 0;

my($text, $title);

for my $index (0 .. $#$data)
{
	# Node keys: created modified text title.
	# Node keys: created modified text title.

	$text	= $$data[$index]{text};
	$title	= $$data[$index]{title};

	next if ($title =~ 'MainMenu'); # TiddlyWiki special case.

	$count++;

	say "Record: $count. Missing prefix", next if ($text !~ m/^\"\"\"\no (.+)$/s);
#	say "$$data[$index]{title}: $$data[$index]{text}";
	say $$data[$index]{title};
}