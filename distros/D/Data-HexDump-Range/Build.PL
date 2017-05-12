
use strict ;
use warnings ;

use Module::Build;

my %all_modules ;
my @split_modules ;

my @pm_files = qw(
lib/Data/HexDump//Range.pm
lib/Data/HexDump/Range/Gather.pm
lib/Data/HexDump/Range/Split.pm
lib/Data/HexDump/Range/Format.pm
lib/Data/HexDump/Range/Object.pm
);

for(@pm_files)
	{
	$all_modules{$_} = $_ ;
	push @split_modules, $_ ;
	}

sub GetVersionAndRevisionFrom
{
my ($file) = @_ ;

my $version_from = File::Spec->catfile( split '/', $file );
my $version      = Module::Build->version_from_file($version_from);

if($ENV{'Data_HexDump_Range_USE_GIT_VERSION_FOR_DIST'})
	{
	my $number_of_commits = `git log | grep -E 'commit [0-9a-f]{40}' | wc -l` ;
	chomp $number_of_commits ;
	
	if($number_of_commits)
		{
		#~ print "number of git revision $number_of_commits.\n" ;
		return("${version}.${number_of_commits}") ;
		}
	else
		{
		print "Couldn't get git revision, using version from '$file'!\n" ;
		return($version) ;
		}
	}
else
	{
	return($version) ;
	}
}

my $code = <<'EOC'

use strict ;
use warnings ;

sub GetVersionAndRevisionFrom
{
my ($file) = @_ ;

my $version_from = File::Spec->catfile( split '/', $file );
my $version      = Module::Build->version_from_file($version_from);

if($ENV{'Data_HexDump_Range_USE_GIT_VERSION_FOR_DIST'})
	{
	my $number_of_commits = `git log | grep -E 'commit [0-9a-f]{40}' | wc -l` ;
	chomp $number_of_commits ;
	
	if($number_of_commits)
		{
		#~ print "number of git revision $number_of_commits.\n" ;
		return("${version}.${number_of_commits}") ;
		}
	else
		{
		print "Couldn't get git revision, using version from '$file'!\n" ;
		return($version) ;
		}
	}
else
	{
	return($version) ;
	}
}

sub ACTION_author_test
{
my $self = shift;
local $self->{properties}{test_files} = 'xt/author/*.t' ;
$self->SUPER::ACTION_test();
}

sub ACTION_dist
{
my $self = shift;

if($ENV{'Data_HexDump_Range_USE_GIT_VERSION_FOR_DIST'})
	{
	my $have_git = $self->do_system('git --version');
	
	if($have_git)
		{
		print `git status`;
		
		if($self->do_system('git log  --decorate > git_Changes'))
			{
			use File::Copy;
			move('git_Changes', 'Changes') ;
			}
		else
			{
			print "Couldn't get git log, 'Changes' will not be generated from git log!\n" ;
			}
		}
	else
		{
		print "git not found, 'Changes' will not be generated from git log!\n" ;
		}
	}

$self->SUPER::ACTION_test() ;
#~ $self->ACTION_author_test() ;

$self->SUPER::ACTION_dist();
};

EOC
;

my $class = Module::Build->subclass(class => 'Data::HexDump::Range', code => $code) ;

my $build = $class->new
	(
	module_name => 'Data::HexDump::Range',
	
	dist_version => GetVersionAndRevisionFrom('lib/Data/HexDump/Range.pm'),
	
	license => 'perl',
	build_requires => 
		{
		'Text::Diff' => 0,
		'Test::Block' => 0,
		'Test::Exception' => 0,
		'Test::NoWarnings' => 0,
		'Test::Warn' => 0,
		},
	requires => 
		{
		'Readonly'         => 0,
		'Sub::Exporter'     => 0,
		'Getopt::Long' => 0,
		'List::Util' => 0,
		'List::MoreUtils' => 0,
		'Scalar::Util' => 0,
		'Data::TreeDumper' => 0,
		'Term::Bash::Completion::Generator' => 0,
		'Text::Colorizer' => 0,
		'Text::Pluralize' => 0,
		},
		
	pm_files     => \%all_modules,
	#~ autosplit    => \@split_modules,
	
	script_files => 'scripts/hdr',
	dist_author  => 'Nadim ibn hamouda el Khemir. <nkh@cpan.org>',
	dist_abstract => 'Hexadecimal Range Dumper with color, bitfields and skip ranges',
	);
	
$build->create_build_script;
  
