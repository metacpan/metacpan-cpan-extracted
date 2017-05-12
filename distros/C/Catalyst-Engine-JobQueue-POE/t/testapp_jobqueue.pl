#!/usr/local/bin/perl -w

BEGIN { 
    $ENV{CATALYST_ENGINE} = 'JobQueue::POE';
    $ENV{CATALYST_SCRIPT_GEN} = 28;
}  

use strict;
use warnings;
use Getopt::Long;
use Pod::Usage;
use FindBin;
use lib "$FindBin::Bin/lib";
use lib "$FindBin::Bin/../lib";

$ENV{CATALYST_HOME} = "$FindBin::Bin";

my $debug             = 0;
my $fork              = 0;
my $help              = 0;
my $crontab           = "$FindBin::Bin/crontab";

my @argv = @ARGV;

GetOptions(
    'debug|d'       => \$debug,
    'fork'          => \$fork,
    'help|?'        => \$help,
    'crontab|c'     => \$crontab,
);

pod2usage(1) if $help;

if ( $debug ) {
    $ENV{CATALYST_DEBUG} = 1;
    $ENV{CATALYST_POE_DEBUG} = 1;
}

# This is require instead of use so that the above environment
# variables can be set at runtime.
require TestApp;

TestApp->run( {
    argv        => \@argv,
    'fork'      => $fork,
    crontab     => $crontab,
} );

1;

=head1 NAME

testapp_jobqueue.pl - Catalyst JobQueue

=head1 SYNOPSIS

testapp_jobqueue.pl [options]

 Options:
   -d -debug          force debug mode
   -f -fork           handle each request in a new process
                      (defaults to false)
   -c -crontab        name of the crontab file
   -? -help           display this help and exits

 See also:
   perldoc Catalyst::Manual
   perldoc Catalyst::Manual::Intro

=head1 DESCRIPTION

Run a Catalyst JobQueue for this application.

=head1 AUTHOR

Christian Gruen, C<kiki@bsdro.org>

=head1 COPYRIGHT

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
