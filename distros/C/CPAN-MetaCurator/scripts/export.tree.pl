#!/usr/bin/env perl

use 5.36.0;

use CPAN::MetaCurator::Export;

use Data::Dumper::Concise; # For Dumper.

use Getopt::Long;

use Pod::Usage; # For pod2usage().

# ------------------------------------------------

sub process
{
	my(%options) = @_;

	return CPAN::MetaCurator::Export
			-> new(home_path => $options{home_path}, include_packages => $options{include_packages}, log_level => $options{log_level}, output_path => $options{output_path})
			-> export_tree;

} # End of process.

# ------------------------------------------------

say "export.as.tree.pl - Export cpan.metacurator.sqlite as HTML + jsTree\n";

my(%options);

$options{help}				= 0;
$options{home_path}			= "$ENV{HOME}/perl.modules/CPAN-MetaCurator";
$options{include_packages}	= 0;
$options{log_level}			= 'debug';
$options{output_path}		= 'html/cpan.metacurator.tree.html';
my(%opts)					=
(
	'help'					=> \$options{help},
	'home_path=s'			=> \$options{home_path},
	'include_packages=i'	=> \$options{include_packages},
	'log_level=s'			=> \$options{log_level},
	'output_path=s'			=> \$options{output_path},
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

export.as.tree.pl - Export cpan.metacurator.sqlite as HTML + jsTree

=head1 SYNOPSIS

export.as.tree.pl [options]

	Options:
	-help
	-home_path
	-include_packages
	-log_level info
	-output_path Path

All switches can be reduced to a single letter, except of course -he and -ho.

Exit value: 0.

=head1 OPTIONS

=over 4

=item -help

Print help and exit.

=item home_path String

The path to the directory containing data/ and html/. Unpack distro to populate.

Default: $ENV{HOME}/perl.modules/CPAN-MetaCurator.

=item include_packages Boolean

Allow CPAN::MetaCurator to include or exclude the table 'packages' from CPAN::MetaPackager.
If the table is included in processing, the code then recognizes all known module names.

scripts/export.tree.sh looks for an env var called INCLUDE_PACKAGES.

Default: 0 (exclude).

=item -log_level String

Available log levels are trace, debug, info, warn, error and fatal, in that order.

Default: info.

=item output_path Path

The path for the output HTML + jsTree.

Default: 'html/cpan.metacurator.tree.html'.

=back

=cut
