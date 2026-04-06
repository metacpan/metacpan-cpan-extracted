#!/usr/bin/perl

use 5.36.0;

use File::Slurper 'read_text';

use Text::Balanced qw/extract_tagged gen_extract_tagged/;

# -----------------

my($visual_break_1)	= '-' x 20;
my($visual_break_2)	= '=' x 20;
my($in_file_name)	= './data/topic.txt'; # Topic CommandLineStuff contains 3 <pre>...</pre> pairs.
my($text)			= read_text($in_file_name);
my($open_tag)		= '<pre>';
my($close_tag)		= '</pre>';

say "Tags: $open_tag & $close_tag";
print 'Using gen_extract_tagged(): ';

my($matcher)				= gen_extract_tagged($open_tag, $close_tag);
my($extracted, $remainder)	= $matcher -> ($text);

say $extracted ? "Found: $extracted." : "No tags found";
say $visual_break_2;
print 'Using extract_tagged(): ';

($extracted, $remainder) = extract_tagged($text, $open_tag, $close_tag, '/.*/', undef);

say $extracted ? "Found: $extracted." : 'No tags found';

say $visual_break_2;
print 'Using regexp: ';
my($regexp)		= qr/(.*?)$open_tag(.*?)$close_tag/s;
$text			=~ $regexp;
my($prefix)		= $1 || '';
my($match)		= $2 || '';
my($suffix)		= $3 || '';
my(@lines)		= split(/\n/, $match);
my($line_count)	= $#lines + 1;

if ($match)
{
	say "Found. Line count: $line_count. And text:";
	say join("\n", @lines);
}
else
{
	say 'No <pre>...</pre> tags found';
}

say $visual_break_2;
say 'Using while: ';

my($count) = 0;

while ($text =~ /$regexp/g)
{
	$count++;

	say "Found $count: $2";
	say $visual_break_1;
}
