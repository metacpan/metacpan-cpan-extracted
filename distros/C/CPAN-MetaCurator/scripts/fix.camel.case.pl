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
			-> new(home_path => $options{home_path}, log_level => $options{log_level}) -> fix_camel_case;

} # End of process.

# ------------------------------------------------

say "fix.camel.case.pl - Ensure all topics are embedded in [[...]]\n";

my(%options);

$options{help}	 			= 0;
$options{home_path}			= "$ENV{HOME}/perl.modules/CPAN-MetaCurator";
$options{include_packages}	= 0;
$options{log_level}			= 'info';
my(%opts)					=
(
	'help'					=> \$options{help},
	'home_path'				=> \$options{home_path},
	'log_level=s'			=> \$options{log_level},
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

fix.camel.case.pl - Ensure all topics are embedded in [[...]]

=head1 SYNOPSIS

check.module.names.pl [options]

	Options:
	-help
	-home_path string
	-log_level info

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

=back

=cut
