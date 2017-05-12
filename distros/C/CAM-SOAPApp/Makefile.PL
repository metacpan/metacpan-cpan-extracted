use strict;
use ExtUtils::MakeMaker qw(WriteMakefile prompt);

## Get user's permission to run SOAP tests against a local server

# Get port and timeout numbers from the regression test
my ($PORT, $TIMEOUT);
open my $file, '<', File::Spec->catfile('t', 'server.t');
while (<$file>)
{
   m/\$PORT \s* = \s* (\d+)    /xms && ($PORT = $1);
   m/\$TIMEOUT \s* = \s* (\d+) /xms && ($TIMEOUT = $1);
}
close $file;

# Warn user
print <<"EOM";
Most of the tests require a live SOAP server.  We will start a
server on your computer listening on localhost port $PORT.
This server will be killed at the end of the tests, or
after $TIMEOUT seconds, whichever comes first.

EOM

# Ask for permission
my $enable_filename = File::Spec->catfile('t', 'ENABLED');
unlink $enable_filename;
if (prompt('Do you want to enable these tests?', 'y') =~ /^y/i)
{
   open my $enabled, '>', $enable_filename or die 'Failed to enable: '.$!;
   close $enabled;
}

WriteMakefile(
              'NAME'		=> 'CAM::SOAPApp',
              'VERSION_FROM'	=> 'lib/CAM/SOAPApp.pm',
              'PREREQ_PM'		=> {
                 'CAM::App'        => 0.08,
                 'SOAP::Lite'      => 0.55,
              },
              'PL_FILES'        => {},
              ($] >= 5.005 ?
               (ABSTRACT_FROM => 'lib/CAM/SOAPApp.pm',
                AUTHOR     => 'Clotho Advanced Media <cpan@clotho.com>') : ()),
              );
