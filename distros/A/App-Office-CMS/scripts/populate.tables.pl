#!/usr/bin/perl
#
# Name:
#	populate.tables.pl.
#
# Description:
#	Populate tables in the 'cms' database.

use strict;
use warnings;

use Getopt::Long;
use Pod::Usage;

use App::Office::CMS::Util::Create;

# --------------------

my($option_parser) = Getopt::Long::Parser -> new;

my(%option);

if ($option_parser -> getoptions
(
 \%option,
 'help',
 'verbose',
) )
{
	pod2usage(1) if ($option{help});

	exit App::Office::CMS::Util::Create -> new(%option) -> populate_all_tables;
}
else
{
	pod2usage(2);
}

__END__

=pod

=head1 NAME

populate.tables.pl - Populate tables in the 'cms' database

=head1 SYNOPSIS

populate.tables.pl [options]

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

=back

=head1 DESCRIPTION

populate.tables.pl populates tables in the 'cms' database.

=cut
