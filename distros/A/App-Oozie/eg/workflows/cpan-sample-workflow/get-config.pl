#!/usr/bin/env perl

# This program can be used to dynamically set parameters / conf values
# to become available to your Oozie workflow actions.
#
# Also see workflow.xml for the actual use cases for the configuration
# emitted from this program.
#

use strict;
use warnings;

use App::Oozie::Date;
use Carp qw( croak );
use Config::Properties;
use Getopt::Long qw( GetOptions );
use Log::Log4perl qw( :easy );

GetOptions(
    \my %OPT,
    qw(
        nosleep
    )
) or croak 'Failed to parse command line arguments!';

Log::Log4perl->init(\qq{
log4perl.rootLogger                = ALL, Screen
log4perl.appender.Screen           = Log::Log4perl::Appender::Screen
log4perl.appender.Screen.Threshold = DEBUG
log4perl.appender.Screen.layout    = Log::Log4perl::Layout::SimpleLayout
});

# ---------------------------------------------------------------------------- #

INFO 'Starting to collect information';

if ( $OPT{nosleep} ) {
    INFO "Skipping sleep ...";
}
else {
    #
    # A sleep might increase randomization of some settings, if lets say you
    # are collecting some database node addresses from a service which can
    # shuffle result sets based on the load it detects.
    #
    # This can especially be useful for jobs creating too many fork paths
    # and calling this program to collect configuration, which might lead to
    # a thundering herd situation.
    #
    my @sleep = map { $_ * 5 } 1..20;
    my $secs = $sleep[ rand @sleep ];

    INFO sprintf "Will sleep for %s seconds ...", $secs;

    sleep $secs;
}

# Start collecting configuration
my %conf;

#
# Add the databases you need to collect their configuration and
# make available to the Oozie actions.
#

$conf{db_user}          = 'foo';
$conf{db_password_file} = 'hdfs:///some/path/to/db.secret';
$conf{db_host}          = '127.0.0.1';
$conf{db_schema}        = 'test';

$conf{today} = App::Oozie::Date->new( timezone => 'UTC' )->today;

#
# Finally dump the data for Oozie consumption
#
my $properties = Config::Properties->new( order => 'alpha' );
$properties->setProperty( $_ => $conf{$_} ) for keys %conf;
$properties->store( \*STDOUT );
