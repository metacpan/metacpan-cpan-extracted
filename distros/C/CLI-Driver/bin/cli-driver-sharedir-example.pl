#!/usr/bin/env perl

# vim: tabstop=4 expandtab

=head1 NAME

cli-driver-sharedir-example.pl - a CLI::Driver example with File::ShareDir

Quickstart:  
  - cd to your project dir (typically where the Makefile.PL lives)
  - create bin/ dir
  - copy this to bin/<yournewcliname.pl> 
  - create 'share/' dir
  - create 'share/cli-driver.yml' file (you can use the cli-driver.yml example
    included with this distro
  - find the TODO(s) in this file and update those section(s) appropriately
  
  - Dist::Zilla users:
    - add [ExecDir] to your dist.ini (assuming you want to bundle your new cli)
    - add [ShareDir] to your dist.ini
    
  - ExtUtils::MakeMaker users:
    - add EXE_FILES => ['bin/yournewcliname.pl'] to your Makefile.PL
    - refer to File::ShareDir docs for remaining config

=cut

###### PACKAGES ######

use Modern::Perl;
use Data::Printer alias => 'pdump';
use CLI::Driver;
use File::ShareDir 'dist_file';
use File::Basename;
use Getopt::Long;
Getopt::Long::Configure('no_ignore_case');
Getopt::Long::Configure('pass_through');
Getopt::Long::Configure('no_auto_abbrev');

###### CONSTANTS ######

# TODO: change to your distribution name (using hyphens)
use constant DIST_NAME => 'YOUR-DIST-NAME-WITH-HYPHENS';

# TODO: change to your cli-driver filename IF it differs
use constant CLI_DRIVER_FILE => 'cli-driver.yml';

###### GLOBALS ######

use vars qw(
  $Action
  $CliDriver
);

###### MAIN ######

$| = 1;

$CliDriver = CLI::Driver->new( path => get_cli_driver_path() );

parse_cmd_line();

my $action = $CliDriver->get_action( name => $Action );

if ($action) {
	$action->do;
}
else {
	$CliDriver->fatal("failed to find action in config file");
}

###### END MAIN ######

sub get_repo_dir {
	
	my $bindir = dirname $0;
	my $devdir = dirname $bindir;		
	
	return $devdir;
}

sub get_cli_driver_path {

	#
	# first attempt to find the driver file in the git repo location
	#
	my $sharedir = sprintf "%s/share", get_repo_dir();
	if ( -f sprintf "%s/%s", $sharedir, CLI_DRIVER_FILE() ) {
		# local development location
		return $sharedir;
	}

	#
	# try the installed location
	#

	# TODO
	my $file = dist_file( DIST_NAME(), CLI_DRIVER_FILE());

	return dirname $file;
}

sub check_required {
	my $opt = shift;
	my $arg = shift;

	print_usage("missing arg $opt") if !$arg;
}

sub parse_cmd_line {

	my $help;
	GetOptions( "help|?" => \$help );

	if ( !@ARGV ) {
		print_usage();
	}
	elsif (@ARGV) {
		$Action = shift @ARGV;
	}

	if ($help) {
		if ($Action) {
			help_action();
		}
		else {
			print_usage();
		}
	}
}

sub help_action {

	my $action = $CliDriver->get_action( name => $Action );
	$action->usage;
}

sub print_actions {

	my $actions = $CliDriver->get_actions;
	my @list;

	foreach my $action (@$actions) {

		next if $action->name =~ /dummy/i;
		my $display = $action->name;

		if ( $action->is_deprecated ) {
			$display .= " (deprecated)";
		}

		push @list, $display;
	}

	say "\tACTIONS:";

	foreach my $action ( sort @list ) {
		print "\t\t$action\n";
	}
}

sub print_usage {
	print STDERR "@_\n\n" if @_;

	my $basename = basename($0);

	printf "\nusage: %s <action> [opts] [-?]\n\n", basename($0);
	print_actions();
	print "\n";

	exit 1;
}
