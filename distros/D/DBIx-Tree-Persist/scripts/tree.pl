#!/usr/bin/env perl

use strict;
use warnings;

use Getopt::Long;
use Pod::Usage;

use DBIx::Tree::Persist;

# --------------------

my($option_parser) = Getopt::Long::Parser -> new;

my(%option);

if ($option_parser -> getoptions
(
 \%option,
 'copy_name=s',
 'data_structure',
 'help',
 'starting_id=i',
 'table_name=s',
 'verbose',
) )
{
	pod2usage(1) if ($option{help});

	exit DBIx::Tree::Persist -> new(%option) -> run;
}
else
{
	pod2usage(2);
}

__END__

=pod

=head1 NAME

tree.pl - Test Tree and Tree::Persist

=head1 SYNOPSIS

tree.pl [options]

	Options:
	-copy TableName
	-data_structure
	-help
	-starting_id N
	-table_name TableName
	-verbose

All switches can be reduced to a single letter.

Exit value: 0.

=head1 OPTIONS

=over 4

=item -copy TableName

Copy the rows from the table specified by -table_name to the table specified by -copy.

This option causes the -data_structure option to be ignored.

When -copy is not used, the tree is displayed in 1 of 2 ways. See -data_structure for details.

=item -data_structure

This option is only used when the -copy option is not used.

When -data_structure is used, the program displays a data structure suitable for encoding in JSON.

When not used (and -copy is not used), the program pretty-prints the menu. This is the default output.

=item -help

Print help and exit.

=item -starting_id N

The id of the root of the tree.

Defaults to 1.

=item -table_name TableName

The name of the table to process.

This option is mandatory.

=item -verbose

Print progress messages.

=back

=head1 DESCRIPTION

tree.pl Tree and Tree::Persist.

=cut
