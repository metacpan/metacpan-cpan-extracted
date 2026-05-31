#!/usr/bin/env perl

use feature 'say';
use open qw(:std :utf8);
use strict;
use warnings;
use warnings qw(FATAL utf8);

use Data::Dumper::Concise; # For Dumper.

use Getopt::Long;

use CPAN::MetaCurator::Search;

use Pod::Usage; # For pod2usage().

# ------------------------------------------------

sub process
{
	my(%options)	= @_;

	return CPAN::MetaCurator::Search
			-> new(home_path => $options{home_path}, log_level => $options{log_level}, names_path => $options{names_path}) -> check;

} # End of process.

# ------------------------------------------------

say "check.module.names.pl - Check the db for the presence/absence of the given module names\n";

my(%options);

$options{help}	 			= 0;
$options{home_path}			= "$ENV{HOME}/perl.modules/CPAN-MetaCurator";
$options{include_packages}	= 0;
$options{log_level}			= 'info';
$options{names_path}		= 'data/names.txt';
my(%opts)					=
(
	'help'					=> \$options{help},
	'home_path'				=> \$options{home_path},
	'log_level=s'			=> \$options{log_level},
	'names_path=s'			=> \$options{names_path},
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

check.module.names.pl - Check for presence of module names

=head1 SYNOPSIS

check.module.names.pl [options]

	Options:
	-help
	-home_path string
	-log_level info
	-names_path string

All switches can be reduced to a single letter, except of course -he and -ho.

Exit value: 0.

=head1 OPTIONS

=over 4

=item -help

Print help and exit.

=item home_path String

The path to the directory containing data/. Unpack distro to populate.

Default: $ENV{HOME}/perl.modules/CPAN-MetaCurator.

=item -log_level String

Available log levels are trace, debug, info, warn, error and fatal, in that order.

Default: info.

=item names_path String

The path which, when prefixed with home_path, specifies the file of module names.

Default: data/names.txt.

=back

=cut
