#!/usr/bin/env perl

use feature 'say';
use open qw(:std :utf8);
use strict;
use warnings;
use warnings qw(FATAL utf8);

use Getopt::Long;

use CPAN::MetaCurator::Export;

use Pod::Usage; # For pod2usage().

# ------------------------------------------------

sub process
{
	my(%options) = @_;

	return CPAN::MetaCurator::Export
			-> new(home_path => $options{home_path}, log_level => $options{log_level}, output_path => $options{output_path})
			-> export_modules_table;

} # End of process.

# ------------------------------------------------

say "export.module2csv.pl - Export modules table to csv file\n";

my(%options);

$options{help}	 		= 0;
$options{home_path}		= "$ENV{HOME}/perl.modules/CPAN-MetaCurator";
$options{log_level}		= 'debug';
$options{output_path}	= 'data/modules.table.csv';
my(%opts)				=
(
	'help'			=> \$options{help},
	'home_path'		=> \$options{home_path},
	'log_level=s'	=> \$options{log_level},
	'output_path=s'	=> \$options{output_path},
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

export.module2csv.pl - Export modules table to csv file

=head1 SYNOPSIS

export.module2csv.pl [options]

	Options:
	-help
	-home_path A dir name
	-log_level info
	-output_path A file name

All switches can be reduced to a single letter, except of course -he and -ho.

Exit value: 0.

=head1 OPTIONS

=over 4

=item -help

Print help and exit.

=item home_path A dir name

The path to the directory containing data/ and html/.

Default: $ENV{HOME}/perl.modules/CPAN-MetaCurator.

=item -log_level String

Available log levels are trace, debug, info, warn, error and fatal, in that order.

Default: info.

=item output_path A file name

The path for the output CSV file.

Default: 'data/modules_table.csv'.

=back

=cut
