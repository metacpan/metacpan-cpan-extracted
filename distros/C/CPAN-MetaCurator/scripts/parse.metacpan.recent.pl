#!/usr/bin/env perl

use feature 'say';
use strict;
use warnings;

use File::Slurper 'read_lines';

use Getopt::Long;

#use HTML::ExtractText;
#use HTML::Object::XQuery;
#use HTML::TableContentParser;
#use Text::Balanced;

use Pod::Usage; # For pod2usage().

# ----------------------------------------------

sub process
{
	my($option)	= @_;
	my(@lines)	= read_lines($$option{input_file});

	open(my $fh, ">:encoding(UTF_8)", $$option{output_file});

	my($description);
	my(@fields);
	my($line);
	my($module);
	my($new);
	my($target);

	my($uri) = 'https://metacpan.org/pod/';

	for my $line_number (0 .. $#lines)
	{
		$line = $lines[$line_number];
		$line =~ tr/—/-/;

		next if ($line !~ /class="ellipsis release-name"/);

		$description	= $lines[$line_number + 1];
		$description	= $1 if ($description =~ /.+?>(.+)</);
		@fields			= split('"', $line);
		@fields			= split('/', $fields[1]);
		$target			= ($fields[3] eq 'dist') ? 4 : 5;
		$module			= $fields[$target];
		@fields			= split('-', $module);

		pop @fields if ($fields[$#fields] =~ /TRIAL/);
		pop @fields if ($fields[$#fields] =~ /v?[0-9]/);

		$module	= join('::', @fields);

		print $fh "o $module\n";
		print $fh "- $description\n";
		print $fh "- $uri$module\n";
		print $fh "\n";
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
	'input_file=s',
	'output_file=s',
) )
{
	pod2usage(1) if ($option{'help'});

	process(\%option);
}
else
{
	pod2usage(2);
}

exit 0;

__END__

=pod

=head1 NAME

parse.metacpan.recent.pl - Parse a HTML file from MetaCPAN/recent

=head1 SYNOPSIS

parse.metacpan.recent.pl [options]

	Options:
	-help
	-input_file aHTMLFileName
	-output_file aCSVFileName

All switches can be reduced to a single letter.

Exit value: 0.

=head1 OPTIONS

=over 4

=item o -help

Print help and exit.

=item o -input_file fileName

The name of the input file.

Default: ''.

=item o -output_file aCSVFileName

The name of a CSV file to write.

By default, nothing is written.

Default: ''.

=back

=cut
