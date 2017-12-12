use 5.010001;
use ExtUtils::MakeMaker;

for my $mod ( qw( Module::Refresh Lexical::Persistence ) ) {
    if ( not defined ExtUtils::MakeMaker->_installed_file_for_module($mod) ) {
        warn "$mod not found, some features will be unavailable\n";
    }
}

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'App::PerlShell',
    VERSION_FROM      => 'lib/App/PerlShell.pm', # finds $VERSION
    ($ExtUtils::MakeMaker::VERSION >= 6.3002) ? ('LICENSE'  => 'perl', ) : (),
    EXE_FILES         => ['bin/plsh.pl'],
    PREREQ_PM         => {Term::ReadLine => 0}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/App/PerlShell.pm', # retrieve abstract from module
       AUTHOR         => 'Michael Vincent <vin at vinsworld dot com>') : ()),
);
