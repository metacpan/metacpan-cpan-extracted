#!/usr/bin/perl -w

BEGIN { 
    $ENV{CATALYST_ENGINE} ||= 'HTTP::POE';
}  

use strict;
use Getopt::Long;
use Pod::Usage;
use FindBin;
use lib "$FindBin::Bin/../lib";

my $debug         = 0;
my $help          = 0;
my $host          = undef;
my $port          = 3000;

my @argv = @ARGV;

GetOptions(
    'debug|d'           => \$debug,
    'help|?'            => \$help,
    'host=s'            => \$host,
    'port=s'            => \$port,
);

pod2usage(1) if $help;

if ( $debug ) {
    $ENV{CATALYST_DEBUG} = 1;
}

# This is require instead of use so that the above environment
# variables can be set at runtime.
require TestApp;

TestApp->run( $port, $host, {
    argv          => \@argv,
} );

1;

=head1 NAME

testapp_server.pl - Catalyst Testserver

=head1 SYNOPSIS

testapp_server.pl [options]

 Options:
   -d -debug          force debug mode
   -f -fork           handle each request in a new process
                      (defaults to false)
   -? -help           display this help and exits
      -host           host (defaults to all)
   -p -port           port (defaults to 3000)
   -k -keepalive      enable keep-alive connections
   -r -restart        restart when files got modified
                      (defaults to false)
   -rd -restartdelay  delay between file checks
   -rr -restartregex  regex match files that trigger
                      a restart when modified
                      (defaults to '\.yml$|\.yaml$|\.pm$')

 See also:
   perldoc Catalyst::Manual
   perldoc Catalyst::Manual::Intro

=head1 DESCRIPTION

Run a Catalyst Testserver for this application.

=head1 AUTHOR

Sebastian Riedel, C<sri@oook.de>

=head1 COPYRIGHT

Copyright 2004 Sebastian Riedel. All rights reserved.

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
