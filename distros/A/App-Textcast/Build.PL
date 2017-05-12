
use strict ;
use warnings ;

use Module::Build;

my %all_modules ;
my @split_modules ;

my @pm_files = qw(
lib/App//Textcast.pm
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

if($ENV{'App_Textcast_USE_GIT_VERSION_FOR_DIST'})
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

if($ENV{'App_Textcast_USE_GIT_VERSION_FOR_DIST'})
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

if($ENV{'App_Textcast_USE_GIT_VERSION_FOR_DIST'})
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

my $class = Module::Build->subclass(class => 'App::Textcast', code => $code) ;

my @prerequisits ;
if($^O ne 'MSWin32')
	{
	push @prerequisits, 'Term::Size', 0.2 ;
	}
else
	{
	push @prerequisits, 'Win32::Console',  0 ;
	}

my $build = $class->new
	(
	module_name => 'App::Textcast',
	dist_version => GetVersionAndRevisionFrom('lib/App/Textcast.pm'),
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
		'Readonly' => 0,
		'Sub::Exporter' => 0,
		'Term::VT102' => 0,
		'IO::Handle' => 0,
		'POSIX' => 0,
		'IO::Pty' => 0,
		'File::Slurp' => 0,
		'Time::HiRes' => 0,
		'Getopt::Long' => 0,
		@prerequisits,
		},
		
	pm_files     => \%all_modules,
	autosplit    => \@split_modules,
	
	script_files => ['scripts/record_textcast', 'scripts/play_textcast'],
	dist_author  => 'Nadim ibn hamouda el Khemir. <nkh@cpan.org>',
	dist_abstract => 'Light weight text casting',
	);
	
$build->create_build_script;
  
