#!/usr/bin/env perl

use feature 'say';
use open qw(:std :utf8);
use strict;
use warnings;
use warnings qw(FATAL utf8);

use Getopt::Long;

use HTML::Entities;
use HTML::TreeBuilder;

use Path::Tiny; # For path().

use Pod::Usage;

# ----------------------------------------------

sub process
{
	my(%options)   = @_;
	my($root)      = HTML::TreeBuilder -> new();
	my($file_name) = path($options{in_file});
	my $content    = $file_name -> slurp_utf8;

	decode_entities $content;

	my($result) = $root -> parse_content($content);
	my($store)  = $root -> look_down(_tag => 'div', id => 'storeArea');
	my(@div)    = $store -> look_down(_tag => 'div');
	my($count)  = 0;

	open(OUT, '>', $options{out_file});

	my(@line);
	my($main_menu, %main_menu);
	my($title, %title);

	for my $div (@div)
	{
		$title = $div -> attr('title');

		next if ( (! defined $title) || ($title =~ /(?:DefaultTiddlers|SiteTitle|SiteSubtitle)/) );

		$title{$title} = 1;

		for my $child ($div -> content_list)
		{
			@line = map{s/[\s]+/ /gs; s/ [oO] /\no /g; s/ - /\n\t-/g; $_} $child -> as_text;
		}

		if ($title eq 'MainMenu')
		{
			$count++;

			$main_menu = [grep{! /GettingStarted/} map{s/^\[\[//; s/]]$//; $_} split(/ /, $line[0])];
		}
		else
		{
			say OUT $title;
			say OUT @line;
			say OUT '';
		}
	}

	close OUT;

	@$main_menu = sort ('uaAD', @$main_menu);

	#say 'Main Menu:';
	#say map{"<$_>\n"} @$main_menu;
	#say '';

	for $title (@$main_menu)
	{
		if (! $title{$title})
		{
			say "In main menu, but no title: $title";
		}
	}

	@main_menu{@$main_menu} = (1) x @$main_menu;

	for $title (sort keys %title)
	{
		if (! $main_menu{$title})
		{
			say "In title, but no main menu: $title.";
		}
	}

	return 0;

} # End of process.

# ----------------------------------------------

say "tiddly2text.pl - Converts a TiddlyWiki HTML file into a text file\n";

my(%options);

$options{help}	 	= 0;
$options{in_file}	= 'data/in.html';
$options{out_file}	= 'data/out.txt';
my(%opts)			=
(
	'help'			=> \$options{help},
	'in_file=s'		=> \$options{in_file},
	'out_file=s'	=> \$options{out_file},
);

GetOptions(%opts) || die("Error in options. Options: " . Dumper(%opts) );

if ($options{help} == 1)
{
	pod2usage(1);

	exit 0;
}

exit process(%options);

__END__

=pod

=head1 NAME

tiddly2text.pl - Converts a TiddlyWiki HTML file into a text file

=head1 SYNOPSIS

tiddly2text.pl [options]

	Options:
	-help
	-in_file In-file-name
	-out_file Out-file-name

All switches can be reduced to a single letter.

Exit value: 0.

=head1 OPTIONS

=over 4

=item -help

Print help and exit.

=item -in_file In-file-name

Default: data/in.html.

=item -out_file Out-file-name

Default:  data/out.txt.

=back

=cut
