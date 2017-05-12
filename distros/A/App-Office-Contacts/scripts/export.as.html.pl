#!/usr/bin/env perl

use strict;
use warnings;

use Getopt::Long;

use App::Office::Contacts::Util::Export;

# -------------------------------

my($option_parser) = Getopt::Long::Parser -> new();

my(%option);

if ($option_parser -> getoptions
(
 \%option,
 'help',
 'standalone_page:i',
) )
{
	pod2usage(1) if ($option{'help'});

	print App::Office::Contacts::Util::Export -> new(%option) -> as_html;

	exit 0;
}
else
{
	pod2usage(2);
}

__END__

=pod

=head1 NAME

export.as.html.pl - Export wines as a table or a whole page.

=head1 SYNOPSIS

export.as.html.pl [options]

	Options:
	-help
	-standalone_page

All switches can be reduced to a single letter.

Exit value: 0.

=head1 OPTIONS

=over 4

=item -help

Print help and exit.

=item -standalone_page

Output a standalone web page.

If omitted (the default) a HTML table is output for incorporation into a web page.

=back

=cut
