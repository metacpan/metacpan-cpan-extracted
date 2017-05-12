use strict;
use Module::Build;
use File::Spec;

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
if (Module::Build->prompt('Do you want to enable these tests?', 'y') =~ /^y/i)
{
   open my $enabled, '>', $enable_filename or die 'Failed to enable: '.$!;
   close $enabled;
}


Module::Build->new(
                   module_name => 'CAM::SOAPApp',
                   license => 'perl',
                   requires => {
                      'perl'                     => '5.6.0',
                      'CAM::App'                 => '0.08',
                      'SOAP::Lite'               => '0.55',
                   },
                   recommends => {
                      'LWP::UserAgent'           => '2.00',
                   },
                   build_requires => {
                      'Test::More'               => '0.01',
                      'IO::Socket'               => '1.00',
                      'HTTP::Daemon'             => '1.00',
                   },
                   )->create_build_script;
