#!/usr/bin/env perl

use 5.40.0;

use Getopt::Long;

use CPAN::MetaCurator::Util::Export;

use Pod::Usage; # For pod2usage().

# ------------------------------------------------

sub process
{
	my(%options) = @_;

	return CPAN::MetaCurator::Util::Export
			-> new(home_path => $options{home_path}, log_level => $options{log_level}, output_path => $options{output_path})
			-> export_as_tree;

} # End of process.

# ------------------------------------------------

say "export.as.tree.pl - Export cpan.metacurator.sqlite as HTML + jsTree\n";

my(%options);

$options{help}	 		= 0;
$options{home_path}		= "$ENV{HOME}/perl.modules/CPAN-MetaCurator";
$options{log_level}		= 'info';
$options{output_path}	= 'html/cpan.metacurator.tree.html';
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

=item -log_level String

Available log levels are trace, debug, info, warn, error and fatal, in that order.

Default: info.

=item output_path Path

The path for the output HTML + jsTree.

Default: 'html/cpan.metacurator.tree.html'.

=back

=cut
