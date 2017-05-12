#!/usr/bin/env perl

use strict;
use warnings;

use Getopt::Long;
use Pod::Usage;

use DBIx::Tree::Persist::Create;

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

	exit DBIx::Tree::Persist::Create -> new(%option) -> drop_all_tables;
}
else
{
	pod2usage(2);
}

__END__

=pod

=head1 NAME

drop.tables.pl - Drop tables in the 'test' database

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

drop.tables.pl drops tables in the 'test' database.

=cut
