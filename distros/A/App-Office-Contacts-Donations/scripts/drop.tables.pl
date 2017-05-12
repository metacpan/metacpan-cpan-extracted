#!/usr/bin/perl
#
# Name:
#	drop.tables.pl.
#
# Description:
#	Drop all donation tables in the 'contacts' database.

use lib '/home/ron/perl.modules/CGI-Office-Contacts/lib';
use lib '/home/ron/perl.modules/CGI-Office-Contacts-Donations/lib';
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
 'verbose',
) )
{
	pod2usage(1) if ($option{'help'});

	exit App::Office::Contacts::Donations::Util::Create -> new(%option) -> drop_all_tables;
}
else
{
	pod2usage(2);
}

__END__

=pod

=head1 NAME

drop.tables.pl - Drop all donation tables in the 'contacts' database

=head1 SYNOPSIS

drop.tables.pl [options]

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

drop.tables.pl drops all donation tables in the 'contacts' database.

=cut
