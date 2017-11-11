## -----------
## Makefile.PL
## -----------
## Perl Makefile generation for Cego DBD driver
##
## ( derived from the SQLite package )
##
## by Bjoern Lemke, 2007-2013
##

eval {
    require DBI;
    require DBI::DBD;
};

use ExtUtils::MakeMaker;
use Config;

# $CC = 'c++';

use strict;
use Getopt::Long();

use vars qw($opt);
$opt = { "help" => \&Usage, };


Getopt::Long::GetOptions(
    $opt,
    "help",
    "prefix=s",
    "verbose",
    ) || die Usage();

if (! exists $opt->{'prefix'}) 
{
  print "Missing prefix, use option --prefix\n"; 
  die Usage();
}

use vars qw($loadlibs);
$loadlibs= "-L" . $opt->{'prefix'} . " -llfc";
my $so = $Config{so};

WriteMakefile(
    'NAME'          => 'DBD::Cego',
    'VERSION_FROM'  => 'Cego.pm',
    'PREREQ_PM'     => {DBI => 1.03},
    'OBJECT'        => '$(O_FILES)',
    'INC'           => '-I$(DBI_INSTARCH_DIR) -I' . $opt->{'prefix'} . '/include -I' . $opt->{'prefix'} . '/include',
    'MYEXTLIB'    => $opt->{'prefix'} . "/lib/libcego.$so* " 
	      . $opt->{'prefix'} . "/lib/liblfcxml.$so* " 
	      . $opt->{'prefix'} . "/lib/liblfcbase.$so",
    "CC" => "clang++",
    "LD" => "clang++",
    "XSPROTOARG" => "-noprototypes",
    'OPTIMIZE'      => '-O3 -DNDEBUG=1',
    'XSOPT'             => '-C++',
    'TYPEMAPS'          => ['perlobject.map' ],
    'LICENSE'	=> 'gpl3',
    'clean'         => { FILES => 'config.h' },
);

sub Usage {
  print STDERR <<"USAGE";
Usage: perl $0 [options]

Possible options are:

  --prefix=<prefix path>       Use <prefix> for setting up the appropriate prefix path
                               to find cego libs and includes

USAGE
  exit 1;
}

package MY;
sub top_targets {
  my $class = shift;
  my $default = $class->SUPER::top_targets;
  $default =~ s/config :: Makefile/config :: Makefile config.h/;
  
  return $default . <<'EOT';
EOT
}

sub postamble { 
  DBI::DBD::dbd_postamble(@_);
}
sub libscan {
    my ($self, $path) = @_;
    ($path =~ m/\~$/) ? undef : $path;
}

