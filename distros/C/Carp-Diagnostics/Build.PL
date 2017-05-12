
use strict ;
use warnings ;

use Module::Build;

my %all_modules ;
my @split_modules ;

my @pm_files = qw(
lib/Carp//Diagnostics.pm
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

if($ENV{'Carp_Diagnostic_USE_GIT_VERSION_FOR_DIST'})
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

my $code = <<'EOC';
use strict ;
use warnings ;

sub GetVersionAndRevisionFrom
{
my ($file) = @_ ;

my $version_from = File::Spec->catfile( split '/', $file );
my $version      = Module::Build->version_from_file($version_from);

if($ENV{'Carp_Diagnostic_USE_GIT_VERSION_FOR_DIST'})
	{
	my $number_of_commits = `git log | grep -E 'commit [0-9a-f]{40}' | wc -l` ;
	chomp $number_of_commits ;
	
	if($number_of_commits)
		{
		#print "number of git revision: $number_of_commits.\n" ;
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

if($ENV{'Carp_Diagnostic_USE_GIT_VERSION_FOR_DIST'})
	{
	my $have_git = $self->do_system('git --version');
	
	if($have_git)
		{
		print `git status -a`;
		
		if($self->do_system('git log  > git_Changes'))
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

my $class = Module::Build->subclass(class => 'Carp::Diagnostics', code => $code) ;

my %other_dependencies ;

if($^O ne 'MSWin32')
	{
	$other_dependencies{'Term::Size'} = 0.2 ;
	}
else
	{
	$other_dependencies{'Win32::Console'} = 0
	}

my $build = $class->new
	(
	module_name => 'Carp::Diagnostics',
	
	dist_version => GetVersionAndRevisionFrom('lib/Carp/Diagnostics.pm'),
	
	license => 'perl',
	
	requires => 
		{
		'Readonly'         => 0,
		'Sub::Exporter'     => 0,
		'IO::String' => 0,
		'Pod::Text' => 0,
		 %other_dependencies,
		
		'Test::Block' => 0,
		'Test::Exception' => 0,
		'Test::NoWarnings' => 0,
		'Test::Warn' => 0,
		},
		
	pm_files     => \%all_modules,
	autosplit    => \@split_modules,
	
	#~ script_files => 'script/xxx.pl',
	dist_author  => 'Khemir Nadim ibn Hamouda. <nadim@khemir.net>',
	dist_abstract => 'Carp with a diagnostic message',
	);
	
$build->create_build_script;
  
