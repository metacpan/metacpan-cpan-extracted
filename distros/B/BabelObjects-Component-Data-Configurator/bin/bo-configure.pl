#!/usr/bin/perl

use strict;
use BabelObjects::Util::Facility::XMLFacility;
use BabelObjects::Runner::Initializer;
use BabelObjects::Runner::RunData;
use BabelObjects::Runner::Dispatcher;
use BabelObjects::Component::Data::Configurator;
use vars qw($AUTOLOAD);

my $debug = "";

my $file      = $ARGV[0];

if ($file eq "") {
    print "Usage : ./bo-configure.pl file.xml\n";
    exit();
}

#
# We take information from the xml configuration file provided in parameter.
# We construct an array with services to configure
#

my $aLog = new BabelObjects::Util::Dvlpt::Log();
my $doc = initParameters();

my $xmlHelper = new BabelObjects::Util::Facility::XMLFacility;

my $CFG = ($xmlHelper->getElementsByPath($doc,"download/parameter/bo_cache_conf"))[0]->getFirstChild->getData();

# we get all the service elements contained just under services element
my @serviceNodes = $xmlHelper->getElementsByPath($doc,
                                                 "services/service",
                                                 "([^\/]+)\/([^\/]+)");


my %newfiles;

foreach (@serviceNodes) {

    my $name = $_->getFirstChild->getData();
    print "Service = $name\n";

    my @files = $xmlHelper->getElementsByPath($doc,
                                              "$name/file",
                                              "([^\/]+)\/([^\/]+)");

    foreach (@files) {
        my @default = $xmlHelper->getElementByTagName($_, "default");
        my @config = $xmlHelper->getElementByTagName($_, "conf");
        $newfiles{$default[0]->getFirstChild->getData} =
                                       $config[0]->getFirstChild->getData;
    }
}

foreach (keys %newfiles) {
    print "  ".$_,
          "\n    => ".$newfiles{$_}."\n";
}

print "\n-----\n";

foreach (@serviceNodes) {
    process($_->getFirstChild->getData());
}

sub initParameters {
    my %parameters;
 
    %parameters = ();
    $parameters{"cfg"} = $file;
    my $aInitializer = new BabelObjects::Runner::Initializer(\%parameters);
    return $aInitializer->getParameters();
} 
 
sub process {
    my $service = shift;
 
    my @files = `ls $CFG/$service/*.default`;

    my %args = ();
    #$args{"req"} = $doc;
    $args{"context"} = $service;
    
    my %runData = ();
    $runData{"req"} = \%args;
    $runData{"confParameters"} = $doc;

    my $aRunData = new BabelObjects::Runner::RunData(\%runData);

    %runData = ();
    $runData{"runData"} = $aRunData;

    my $aDispatcher = new BabelObjects::Runner::Dispatcher(\%runData);
 
    foreach (@files) {
        chop;
        my $newfile = $newfiles{$_};
        if ($newfile ne "") {
            print "$_ >>\n";
            print "    $newfile\n";
            if (! $debug) {
                #print "Real mode";
                $aDispatcher->parseFile("$_", $newfile);
            } else {
                print "Debug mode";
                $aDispatcher->parseFile("$_");
            }
        } else {
            print "$_ must be specified in $file to be configured\n";
        }
    }
}  
