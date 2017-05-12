package CPAN::Digger::Run;
use strict;
use warnings;

use Cwd qw(abs_path);
use Data::Dumper qw(Dumper);
use File::Basename qw(dirname);
use File::Spec;
use Getopt::Long qw(GetOptions);

use CPAN::Digger::Index;
use CPAN::Digger::Index::Projects;

our $VERSION = '0.08';

sub run {

	my $root = dirname dirname abs_path $0;

	my %opt;
	GetOptions(
		\%opt,
		'output=s',
		'dbfile=s',

		'cpan=s',
		'filter=s',

		'projects=s',

		'whois',
		'collect',
		'static',
		'process',


		'prepare',
		'pod',
		'syn',
		'outline',
		'critic=s',

		'full',
	) or usage();


	usage('--dbfile required')                            if not $opt{dbfile};
	usage('--cpan or --projects required')                if not $opt{cpan} and not $opt{projects};
	usage("Directory '$opt{cpan}' not found")             if $opt{cpan} and not -d $opt{cpan};
	usage("File '$opt{projects}' not found")              if $opt{projects} and not -e $opt{projects};
	usage('--output required')                            if not $opt{output};
	usage('--output must be given an existing directory') if not -d $opt{output};

	usage('On or more of --collect, --whois  or --process is needed')
		if not $opt{collect}
			and not $opt{whois}
			and not $opt{static}
			and not $opt{process};

	if ( $opt{process} ) {
		usage('On or more of --syn, --pod, --prepare, --outline or --full is needed')
			if not $opt{full}
				and not $opt{syn}
				and not $opt{pod}
				and not $opt{prepare}
				and not $opt{outline};
	}

	$opt{root} = $root;

	if ( delete $opt{full} ) {
		$opt{$_} = 1 for qw(prepare syn pod outline);
	}

	my %run;
	$run{$_} = delete $opt{$_} for qw(collect whois process static);

	$ENV{CPAN_DIGGER_DBFILE} = $opt{dbfile};

	my $cpan =
		$opt{cpan}
		? CPAN::Digger::Index->new(%opt)
		: CPAN::Digger::Index::Projects->new(%opt);

	if ( $run{whois} ) {
		$cpan->update_from_whois;
	}

	if ( $run{collect} ) {
		$cpan->collect_distributions;
	}

	if ( $run{process} ) {
		$cpan->process_all_distros();
	}

	if ( $run{static} ) {
		$cpan->generate_central_files;
	}
}


sub usage {
	my $msg = shift;
	if ($msg) {
		print "\n*** $msg\n\n";
	}
	die <<"END_USAGE";
Usage: perl $0
Required:
   --output PATH_TO_OUTPUT_DIRECTORY
   --dbfile path/to/database.db

One of these is required:
   --cpan PATH_TO_CPAN_MIRROR
   --projects PATH_TO_CONGIG.yml

Optional:
   --filter REGEX   only packages that match the regex will be indexed (can be used with --cpan)

One of these is required:
   --whois          update authors table of the database from the 00whois.xml file
   --collect        go over the CPAN mirror and add the name of each file to the 'distro' table
   --static         copy the static files

   --process  process all distros

If --process is given then one or more of the steps:
   --prepare
   --pod              generate HTML pages from POD
   --syn              generate syntax highlighted source files
   --outline
   --full             do all the steps one by one in the process
   --critic profile   Run Perl::Critic on every file using the give profile (e.g. public/critic-core.ini)

Examples:
$0 --cpan /var/www/cpan --output /var/www/digger --dbfile /var/www/digger/digger.db --collect --whois
$0 --cpan /var/www/cpan --output /var/www/digger --dbfile /var/www/digger/digger.db --filter CPAN-Digger

END_USAGE
}

1;
