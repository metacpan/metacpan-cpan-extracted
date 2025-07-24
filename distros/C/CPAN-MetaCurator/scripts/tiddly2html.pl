#!/usr/bin/perl

use 5.40.0;
use open qw(:std :utf8);
use strict;
use warnings;
use warnings qw(FATAL utf8);

use Getopt::Long;

use Path::Tiny; # For path().

use Pod::Usage;

# ----------------------------------------------

sub process
{
	my(%options)   = @_;
	my($file_name) = path("$ENV{HOME}/Documents/wiki/$options{in_file}");

	open(my $fh, '>', "$ENV{HOME}/Documents/wiki/$options{out_file}");
	say $fh <<EOS;
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">

<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
<head>
	<title>Some Perl modules cross-referenced by Purpose</title>
	<meta http-equiv="Content-Type" content="text/html;charset=utf-8" />
	<meta http-equiv="cache-control" content="no-cache">
	<meta http-equiv="pragma" content="no-cache">
	<link rel="stylesheet" type="text/css" href="/assets/css/local/default.css">
</head>

<body>
	<h1 align = 'center'>Some Perl modules cross-referenced by Purpose</h1>

EOS

	my($heading);
	my($new_heading);
	my(@table, $text);

	for my $line ($file_name -> lines_utf8)
	{
		next if ($line eq '');

		if ($line =~ /^o\s(.+):$/)
		{
			$new_heading = $1;

			if ($#table >= 0)
			{
				$heading = shift @table;

				say $fh <<EOS;
<table align = 'center'>
	<tr>
		<td><span class="global_toc_text">$heading</span></td>
	</tr>
EOS

				for (@table)
				{
					say $fh <<EOS;
	<tr>
		<td>$_</td>
	</tr>
EOS
				}

				say $fh '</table><br>';

			}

			@table = $new_heading;
		}
		elsif ($line =~ /^\t-(.+)/)
		{
			$text = $1;

			if ($text =~ m|(.*)(https?://.+.html)(.*)|)
			{
				$text = qq|$1<a href = '$2'>$2</a>$3|;
			}
			elsif ($text =~ m|(.*)(https?://.+)$|)
			{
				$text = qq|$1<a href = '$2'>$2</a>|;
			}

			push @table, "o $text";
		}
	}

	close $fh;

} # End of process.

# ----------------------------------------------

my($option_parser) = Getopt::Long::Parser -> new();

my(%option);

if ($option_parser -> getoptions
(
 \%option,
 'help',
 'in_file=s',
 'out_file=s',
) )
{
	pod2usage(1) if ($option{'help'});

	exit process(%option);
}
else
{
	pod2usage(2);
}

__END__

=pod

=head1 NAME

tiddly2html.pl - Converts a TiddlyWiki text file into a HTML file

=head1 SYNOPSIS

tiddly2html.pl [options]

	Options:
	-help
	-in_file (/home/ron/Documents/wiki/$x)
	-out_file (/home/ron/Documents/wiki/$y)

All switches can be reduced to a single letter.

Exit value: 0.

=head1 OPTIONS

=over 4

=item -help

Print help and exit.

=item -in_file (/home/ron/Documents/wiki/$x)

Just provide $x. E.g.: Perl.text.

There is no default.

=item -out_file (/home/ron/Documents/wiki/$y)

Just provide $y. E.g.: Modules.html.

There is no default.

=back

=cut
