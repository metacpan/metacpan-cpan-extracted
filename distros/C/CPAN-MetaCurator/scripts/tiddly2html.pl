#!/usr/bin/env perl

use feature 'say';
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
	my($file_name) = path($options{in_file});

	open(my $fh, '>', $options{out_file});
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

	return 0;

} # End of process.

# ----------------------------------------------

say "tiddly2html.pl - Converts a TiddlyWiki text file into a HTML file\n";

my($option_parser) = Getopt::Long::Parser -> new();

my(%options);

$options{help}	 	= 0;
$options{in_file}	= 'data/in.txt';
$options{out_file}	= 'data/out.html';
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

tiddly2html.pl - Converts a TiddlyWiki text file into a HTML file

=head1 SYNOPSIS

tiddly2html.pl [options]

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

Default: data/in.txt.

=item -out_file Out-file-name

Default:  data/out.html.

=back

=cut
