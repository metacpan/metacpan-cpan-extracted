#!perl
use strict;
use warnings;
use Getopt::Long();
use Data::Dumper();

sub Usage {
    my $msg = shift;
    if ($msg) {
        print STDERR "$msg\n\n";
    }
    print STDERR <<"USAGE";
Usage: perl $0 <options>

Possible options are:
  --logDirectory=<directory>  Configures the log directory, where
                              XML-RPC requests and responses are being
                              logged.
  --testUrl=<url>             Configures the Bugzilla server to use for
                              integration tests.
  --testUser=<user>           Configures the Bugzilla user to use for
                              integration tests.
  --testPassword=<password>   Configures the Bugzilla password to use for
                              integration tests.
USAGE
    exit 1;
}

Usage() unless @ARGV;
my($testUrl, $testUser, $testPassword, $logDirectory);
Getopt::Long::GetOptions(
    'help' => \&Usage,
    'logDirectory=s' => \$logDirectory,
    'testUrl=s' => \$testUrl,
    'testUser=s' => \$testUser,
    'testPassword=s' => \$testPassword
    ) or Usage();

my $config = {
    logDirectory => $logDirectory,
    testUser => $testUser,
    testUrl => $testUrl,
    testPassword => $testPassword
};

my $configFile = 'config.pl';
open(my $fh, '>', $configFile)
    or die "Failed to create $configFile: $!";
(print $fh Data::Dumper->new([$config])->Indent(1)->Terse(1)->Dump())
    or die "Failed to write to $configFile: $!";
close($fh)
    or die "Failed to close $configFile: $!";

1
