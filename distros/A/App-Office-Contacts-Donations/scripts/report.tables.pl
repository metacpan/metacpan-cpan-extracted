#!/usr/bin/perl
#
# Name:
#	report.tables.pl.
#
# Description:
#	Report sizes of all tables in the 'contacts' database.

use strict;
use warnings;

use Getopt::Long;
use Pod::Usage;

use App::Office::Contacts::Donations::Util::Create;

# --------------------

my($option_parser) = Getopt::Long::Parser -> new;

my(%option);

if ($option_parser -> getoptions
(
 \%option,
 'help',
 'verbose+',
) )
{
	pod2usage(1) if ($option{'help'});

	exit App::Office::Contacts::Donations::Util::Create -> new(%option) -> report_all_tables;
}
else
{
	pod2usage(2);
}

__END__

=pod

=head1 NAME

report.tables.pl - Report sizes of all tables in the 'contacts' database

=head1 SYNOPSIS

report.tables.pl [options]

	Options:
	-help
	-verbose

All switches can be reduced to a single letter.

Exit value: 0.

=head1 OPTIONS

=over 4

=item -help

Print help and exit.

=item -verbose

Print progress messages.

If -v -v is used, print even more progress messages.

=back

=head1 DESCRIPTION

report.tables.pl reports the sizes of all tables in the 'contacts' database.

=cut
