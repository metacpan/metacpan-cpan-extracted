
use strict ;
use warnings ;

use Module::Build;

my %all_modules ;
my @split_modules ;

my @pm_files = qw(
lib/App/Plog.pm
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

if($ENV{'App_Plog_USE_GIT_VERSION_FOR_DIST'})
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

if($ENV{'App_Plog_USE_GIT_VERSION_FOR_DIST'})
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

if($ENV{'App_Plog_USE_GIT_VERSION_FOR_DIST'})
	{
	my $have_git = $self->do_system('git --version');
	
	if($have_git)
		{
		print `git status -a`;
		
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

my $class = Module::Build->subclass(class => 'App::Plog', code => $code) ;

my $build = $class->new
	(
	module_name => 'App::Plog',
	
	dist_version => GetVersionAndRevisionFrom('lib/App/Plog.pm'),
	
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
		'File::Copy::Recursive' => 0,
		'FileHandle' => 0,
		'File::HomeDir' => 0,
		'File::Path' => 0,
		'File::Slurp' => 0,
		'File::Temp' => 0,
		'IPC::Open2' => 0,
		'IPC::Open3' => 0,
		'Pod::Simple::HTML' => 0,
		'Symbol' => 0,
		'Tie::Hash::Indexed' => 0,
		'XML::Atom::SimpleFeed' => 0,
		'Getopt::Long' => 0,
		},
		
	pm_files     => \%all_modules,
	#~ autosplit    => \@split_modules,
	
	script_files => 'scripts/plog',
	dist_author  => 'Nadim ibn hamouda el Khemir. <nkh@cpan.org>',
	dist_abstract => 'A rudimentary blog',
	);
	
#-----------------------------------------------------------------------------------------------------------

use File::HomeDir ;
my $user_template = home() . '/.plog' ;

if(-e $user_template)
	{
	print "Found plog configuration in '$user_template'! You should diff your configuration "
		. "with the configuration that comes with this version of App::Plog.\n\n" ;
	}
else
	{
	print "Creating default configuration files in home/you/.plog.\n" ;
	
	use File::Copy::Recursive 'rcopy' ;
	rcopy('configuration', $user_template) or die "Can't copy the configuration to your home directory: $!" ;
	}

$build->create_build_script;

