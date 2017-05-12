#!/usr/bin/env perl

use strict;
use utf8;
use warnings;
use open qw(:std :utf8); # Undeclared streams in UTF-8.

use Getopt::Long;

use App::Office::Contacts::Util::Export;

use Pod::Usage;

# -----------------------------------------------

my($option_parser) = Getopt::Long::Parser -> new();

my(%option);

if ($option_parser -> getoptions
(
	\%option,
	'help',
	'output_file=s',
) )
{
	pod2usage(1) if ($option{'help'});

	exit App::Office::Contacts::Util::Export -> new(%option) -> as_csv;
}
else
{
	pod2usage(2);
}

__END__

=pod

=head1 NAME

export.as.csv.pl - Parsing any SVG file

=head1 SYNOPSIS

test.file.pl [options]

	Options:
	-help
	-output_file aCSVFileName

All switches can be reduced to a single letter.

Exit value: 0.

=head1 OPTIONS

=over 4

=item o -help

Print help and exit.

=item o -output_file aCSVFileName

The name of a CSV file to write.

By default, nothing is written.

Default: ''.

=back

=cut
