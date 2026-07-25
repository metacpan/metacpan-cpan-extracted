#!/usr/bin/env perl

use feature 'say';
use open qw(:std :utf8);
use strict;
use warnings;
use warnings qw(FATAL utf8);

use CPAN::MetaCurator::Export;

use Data::Dumper::Concise; # For Dumper.

use Getopt::Long;

use Pod::Usage; # For pod2usage().

# ------------------------------------------------

sub process
{
	my(%options) = @_;

	return CPAN::MetaCurator::Export
			-> new(dag_nodetree_path => $options{dag_nodetree_path}, home_path => $options{home_path}, include_packages => $options{include_packages},
				jstree_html_path => $options{jstree_html_path}, log_level => $options{log_level})
			-> export_tree;

} # End of process.

# ------------------------------------------------

say "export.tree.pl - Export cpan.metacurator.sqlite as HTML + jsTree\n";

my(%options);

$options{dag_nodetree_path}	= '/tmp/dag_node.tree.txt';
$options{help}				= 0;
$options{home_path}			= "$ENV{HOME}/perl.modules/CPAN-MetaCurator";
$options{include_packages}	= 0;
$options{jstree_html_path}	= 'html/cpan.metacurator.tree.html';
$options{log_level}			= 'info';
my(%opts)					=
(
	'dag_nodetree_path'		=> \$options{dag_nodetree_path},
	'help'					=> \$options{help},
	'home_path=s'			=> \$options{home_path},
	'include_packages=i'	=> \$options{include_packages},
	'jstree_html_path=s'	=> \$options{jstree_html_path},
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

export.tree.pl - Export cpan.metacurator.sqlite as HTML + jsTree

=head1 SYNOPSIS

export.as.tree.pl [options]

	Options:
	-dag_nodetree_path Path
	-help
	-home_path
	-include_packages
	-jstree_html_path Path
	-log_level info

All switches can be reduced to a single letter, except of course -he and -ho.

Exit value: 0.

=head1 OPTIONS

=over 4

=item o dag_nodetree_path Path

The path for the output of the DAG_Node::Tree.

Default: '/tmp/dag_node.tree.txt'.

=item o help

Print help and exit.

=item o home_path String

The path to the directory containing data/ and html/. Unpack distro to populate.

Default: $ENV{HOME}/perl.modules/CPAN-MetaCurator.

=item o include_packages Boolean

Allow CPAN::MetaCurator to include or exclude the table 'packages' from CPAN::MetaPackager.
If the table is included in processing, the code then recognizes all known module names.

scripts/export.tree.sh looks for an env var called INCLUDE_PACKAGES.

Default: 0 (exclude).

=item o jstree_html_path Path

The path for the output HTML + jsTree.

Default: 'html/cpan.metacurator.tree.html'.

=item o log_level String

Available log levels are trace, debug, info, warn, error and fatal, in that order.

Default: info.

=back

=cut
