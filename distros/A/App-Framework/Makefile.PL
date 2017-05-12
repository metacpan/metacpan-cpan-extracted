use strict;
use warnings;
use inc::Module::Install;
use File::Path ;
use Config;

my $DEBUG = $ENV{DEBUG} || 0 ;

my $name = 'App-Framework' ;

my $mod = $name ;
$mod =~ s%\-%::%g ;

my $modpath = $name ;
$modpath =~ s%\-%/%g ;

  
# Define metadata
name            $name;
abstract_from	"lib/$modpath.pm" ;
author_from		"lib/$modpath.pm" ;
version_from	"lib/$modpath.pm" ;
license_from	"lib/$modpath.pm" ;
perl_version	'5.8.4' ;
##all_from       "lib/$modpath.pm";
  
# Specific dependencies
requires       'Cwd'; 
requires       'File::Basename';
requires       'File::Path';
requires       'File::Temp';
requires       'File::Spec';
requires       'File::Find';
requires       'File::Copy';
requires       'File::DosGlob';
requires       'File::Which';
requires       'Pod::Usage'		=> 1.33 ;	# Need at least this version or -man won't work!
requires       'Date::Manip';
requires       'Getopt::Long';

#recommends     'DBI' ;

test_requires  'Test::More'  => '0.42';
test_requires  'Test::Pod'  => '1.22';
test_requires  'Test::Pod::Coverage'  => '1.08';
test_requires  'File::Which' ;

no_index       'directory'   => 'examples';


## Optional modules
my %optional = (

	1 => {
		'name'			=> 'Feature::Sql',
		'description'	=> 'MySQL support',
		'requires'		=> {
			'DBI'			=> 0,
			'DBD::mysql'	=> 0,
		},
	},
	2 => {
		'name'			=> 'Feature::Mail',
		'description'	=> 'Mail support',
		'requires'		=> {
			'Net::SMTP'		=> 0,
		},
	},
#	3 => {
#		'name'			=> 'Extension::Daemon',
#		'description'	=> 'Daemon script extension',
#		'requires'		=> {
#			'Net::Server::Daemonize'		=> 0,
#		},
#	},
#	4 => {
#		'name'			=> 'Core::POE',
#		'description'	=> 'POE script personality',
#		'requires'		=> {
#			'POE'		=> 0,
#		},
#	},
) ;

print<<MSG;
$mod provides a number of optional modules which require additional CPAN modules. Please select
from the following which $mod modules you would like to be fully installed and tested (any modules
you do not select will still be available but you will have to manually install any module dependencies).

The optional modules are:
MSG

for my $num (sort { $a <=> $b } keys %optional) 
{
	printf "    [%d] %s - %s\n", $num, $optional{$num}{'name'}, $optional{$num}{'description'} ;
}
my $c = prompt("\nEnter your choices, separated by spaces (0=none, a=all):", "a"); print "\n";


my %to_install ;
if ($c)
{
	if ($c =~ /a/i)
	{
		for my $num (keys %optional) 
		{
			$to_install{$num} = 1 ;
		}
	}
	else
	{
		for my $num (split /\s+/, $c) 
		{
			next unless exists($optional{$num}) ;
			$to_install{$num} = 1 ;
		}
	}
}

my $to_test_str = "" ;
foreach my $num (keys %to_install)
{
	## Add required modules
	foreach my $req (keys %{$optional{$num}{'requires'}})
	{
		my @args = ($req) ;
		push @args, $optional{$num}{'requires'}{$req} if $optional{$num}{'requires'}{$req} ;
		requires(@args) ;
	}

	## Add module		
	$to_test_str .= "$mod\:\:$optional{$num}{name} => 1,\n" ;
}

open my $fh, ">t/config.pm" ;
print $fh <<CONFIG;
package config;
our \%TO_TEST = (
$to_test_str
) ;

1;
CONFIG
close $fh ;



## create extra pod files
sub MY::postamble {

check_new_version() ;

my $rm_install = check_old_version() ;
if ($rm_install)
{
	$rm_install = 
"
install :: rm_oldinstall 

rm_oldinstall :: $rm_install
	\$(NOECHO) \$(TOUCH) rm_oldinstall
";
}
else
{
	$rm_install = "# null\n\n" ;
}

my $modpod = '
pure_all :: modpod

modpod: pm_to_blib $(TO_INST_PM)
	$(PERLRUN) -Mblib -MApp::Framework -e "modpod(debug => '.$DEBUG.')"
	$(NOECHO) $(TOUCH) modpod
';

"$rm_install\n\n$modpod\n";

}

## clean out old installation

WriteAll() ;


sub check_old_version
{
	my $remove = "" ;
	
	my $version ;
	eval {
		no strict 'refs';
		require "$modpath.pm" ;
				
		$version = ${"${mod}::VERSION"} ;
	} ;
	if ($version)
	{
		print "Found an existing installation: Version $version\n" ;
		$version =~ s/_//g ;
		
		## see if we need to clear out old
		if ($version < 0.90)
		{
			print "Need to clean existing installation\n" ;
			
			my @remove = (
				'Modules/*',
				'Modules', 
				'Base/Run.pm',
				'Base/Sql.pm',
				'Base/Object/Logged.pm',
				'Config.pm',
			) ;
	
			my @files ;
			my @dirs ;
			my $installsitelib = $Config{installsitelib} ;
			$installsitelib =~ s%\\%/%g ;
			foreach my $rm (@remove)
			{
				foreach my $f (glob("$installsitelib/$modpath/$rm"))
				{
					if (-f $f)
					{
						push @files, $f ; 
					}
					if (-d $f)
					{
						push @dirs, $f ; 
					}
				}
			}
			
			## remove files first
			foreach my $f (@files)
			{
				$remove .= "\n\t\$(PERLRUN) -e \"unlink '$f'\"" ;
			}
	
			## remove dirs
			foreach my $d (@dirs)
			{
				$remove .= "\n\t\$(PERLRUN) -MFile::Path -e \"rmtree(['$d'])\"" ;
			}
		}
		
	}
	

	return $remove ;
}


sub check_new_version
{
	my $version = ExtUtils::MM_Unix->parse_version("lib/$modpath.pm");

	print "Installing Version: $version\n" ;
	
	## Check for newer version
	eval {
		require LWP::UserAgent;
	} ;
	if (!$@)
	{
		print "Checking for later version...\n" ;
		
		## specify user name so that I can filter out my builds
		my $user = $ENV{USER} || $ENV{USERNAME} || 'nobody' ;
		
		# CPAN testers
		my $cpan = $ENV{'PERL5_CPAN_IS_RUNNING'}||0 ;

		## check for OS-specific versions
		my $os = $^O ;
		my $url = "http://quartz.homelinux.com/CPAN/index.php?ver=$version&mod=$name&user=$user&os=$os&cpan=$cpan" ;
		 
		my $ua = LWP::UserAgent->new;
		$ua->agent("CPAN-$name/$version") ;
		$ua->timeout(10);
		$ua->env_proxy;
		 
		my $response = $ua->get($url);
		if ($response->is_success) 
		{
			my $content = $response->content ;
			if ($content =~ m/Current version : ([\d\.]+)/m)
			{
				print "Latest CPAN version is $1\n" ;
			}
			if ($content =~ m/Newer version/m)
			{
				print "** NOTE: A newer version than this is available. Please downloaded latest version **\n" ;
			}
			else
			{
				print "Got latest version\n" ;
			}
		}
		else
		{
			print "Unable to connect, assuming latest\n" ;
			#print $response->status_line;
		}
	}
	
}
