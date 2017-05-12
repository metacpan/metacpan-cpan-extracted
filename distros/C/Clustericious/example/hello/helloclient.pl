use strict;
use warnings;
use Clustericious::Log;
use Path::Class qw( file );
use Clustericious::HelloWorld::Client;
use Clustericious::Client::Command;
use Clustericious::Log::CommandLine (':all', ':loginit' => <<"EOT");
           log4perl.rootLogger = WARN, Screen
           log4perl.appender.Screen = Log::Log4perl::Appender::ScreenColoredLevels
           log4perl.appender.Screen.layout = Log::Log4perl::Layout::PatternLayout
           log4perl.appender.Screen.layout.ConversionPattern = [%-5p] %d %F{1} (%L) %m %n
EOT

# This example uses Clustericious::HelloWorld::Client which lives in the
# main distribution as lib/Clustericious/HelloWorld/Client.pm
# see also the server in hello.pl

$ENV{CLUSTERICIOUS_CONF_DIR} = file(__FILE__)->parent->absolute->stringify;

Clustericious::Client::Command->run(Clustericious::HelloWorld::Client->new, @ARGV);
