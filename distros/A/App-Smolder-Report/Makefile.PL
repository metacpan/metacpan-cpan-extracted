use inc::Module::Install;

# Define metadata
name     'App-Smolder-Report';
all_from 'lib/App/Smolder/Report.pm';

# Make sure script is installed
install_script "smolder_report";

# Specific dependencies
requires 'LWP::UserAgent'  => 0;
requires 'Getopt::Long'    => 0;
requires 'Carp::Clan'      => 0;
requires 'Test::More'      => 0;
requires 'Test::Deep'      => 0;
requires 'Test::Exception' => 0;
requires 'File::Temp'      => 0;
requires 'Cwd'             => 0;

# Meta
repository 'http://github.com/melo/perl-app-smolder-report';

WriteAll;
