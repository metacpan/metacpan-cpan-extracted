# Makefile.PL -- Makefile for App::Music::PlayTab
# Author          : Johan Vromans
# Created On      : Mon Feb  8 11:46:56 1999
# Last Modified By: Johan Vromans
# Last Modified On: Tue Dec  5 13:30:45 2017
# Update Count    : 93
# Status          : Stable

# Ease the life of the CPAN testers.
exit 0 if $ENV{AUTOMATED_TESTING} && $] < 5.010000;

# EU::MM 6.5503 is the first version to understand *_REQUIRES.
use ExtUtils::MakeMaker 6.5503;

# Verify perl version.
require 5.010001;

# EU::MM 6.5503 is the first version to understand *_REQUIRES.
use ExtUtils::MakeMaker 6.5503;

my $master = 'lib/App/Music/PlayTab/Version.pm';
my $version = MM->parse_version($master);
$master =~ s;/Version;;;

my @scripts = qw(playtab);

WriteMakefile
  (
   NAME         => 'App::Music::PlayTab',
   AUTHOR	=> 'Johan Vromans (jvromans@squirrel.nl)',
   ABSTRACT	=> 'Print play tabs (griles, grids) of songs',
   VERSION      => $version,
   MIN_PERL_VERSION => 5.010001,
   PREREQ_PM	=> {
      Clone => 0,
      PDF::API2 => 2.030,
      App::Packager => 1.420,
     },
   EXE_FILES    => [ map { "script/$_" } @scripts ],
   PL_FILES	=> {
		    'script/pp.PL' => [ map { "script/$_" } @scripts ]
		   },
   CONFIGURE_REQUIRES => {
      "ExtUtils::MakeMaker" => 6.5503,
   },
   TEST_REQUIRES => {
      Test::More => 0,
   },

   META_MERGE => {
      license => "perl_5",
      resources => {
	  license    => "http://dev.perl.org/licenses/",
	  repository => "https://github.com/sciurius/playtab",
	  bugtracker => "https://github.com/sciurius/playtab/issues",
      },
      provides => {
	 playtab =>
	   { file => "script/playtab", version => $version },
	 App::Music::PlayTab =>
	   { file => $master, version => $version },
	},
      no_index => {
         directory => [
	    "lib/App/Music/PlayTab",
	   ],
	},
     },
  );
