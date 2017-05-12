#!/usr/bin/perl

use strict;
use BabelObjects::Util::Facility::XMLFacility;
use BabelObjects::Runner::Initializer;
use vars qw($AUTOLOAD);

my $file      = $ARGV[0];

if ($file eq "") {
    print "Usage : ./bo-upgrade.pl file.xml\n";
    exit();
}

#
# We take information from the xml configuration file provided in parameter.
# We construct an array with rpms to install
#

my $doc = initParameters();
my $xmlHelper = new BabelObjects::Util::Facility::XMLFacility;

my $CFG       = getConfParameter("bo_cache_conf");
my $HOST      = getConfParameter("host");
my $LOGIN     = getConfParameter("login");
my $PASSWD    = getConfParameter("passwd")|| "$LOGIN\@".`hostname | tr -d "\n"`;
my $CACHE_DIR = getConfParameter("cache_dir");
my $DEBUG     = getConfParameter("loglevel");

my @toInstall = loadAndStoreRpms();
installRpms(@toInstall);

sub getConfParameter {
    my $parameter = shift;
    print "Parameter = $parameter\n";
    my @elements = $xmlHelper->getElementsByPath(
                       $doc,
                       "download/parameter/".$parameter);
    return @elements[0]->getFirstChild->getData();
}


#
# Rpms Installation
#
sub loadAndStoreRpms {
    my @toInstall = ();

    # we get all the rpm elements contained just under rpms element
    my @rpmNodes = $xmlHelper->getElementsByPath($doc,
                                                 "rpms/rpm",
                                                 "([^\/]+)\/([^\/]+)");

    system("mkdir -p $CACHE_DIR/RPMS");
    system("mkdir -p $CACHE_DIR/RPMS/RedHat");

    foreach my $rpm (@rpmNodes) {

        my $dir = "";
        my $app = "";
	my $version = "";
	my $release = "";
        my $name = $rpm->getFirstChild->getData();
        print "Rpm = $name : ";

        $_ = $name;

        if ( m#/# ) {
            ($dir, $app, $version, $release) = /([^\/]*)\/(.*)-([^-]*)-([^-]+)\.(sparc|alpha|i686|i386|src).rpm/;
        } else {
            ($app, $version, $release) = /(.*)-([^-]*)-([^-]+)\.(sparc|alpha|i686|i386|src).rpm/;
        }

	if ( `rpm -q $app | tr -d "\n"` ne "$app-$version-$release" ) {
            # Le package n'est pas installé
            push(@toInstall, $name);
            print "  => A installer\n";
            if ( ! -e "$CACHE_DIR/RPMS/$name" ) {
                print "RPMS/$name doesn't exist : get it\n";
                my $ftp = "/usr/bin/ncftpget -u $LOGIN -p $PASSWD "
                          ." $HOST $CACHE_DIR/RPMS/$dir /dist/RPMS/$name";
                print "  => System : $ftp\n";
                system($ftp);
            }
            print "\n";
        } else {
            print "...Already installed\n";
        }
    }

    return @toInstall;
}

sub installRpms {
    my @toInstall = @_;

    # a little strange
    foreach (@toInstall) {
        if ($_) {
            my $cmd = "rpm -Uvh --force --nodeps $CACHE_DIR/RPMS/$_";
            print "System : $_ / $cmd\n";
            system($cmd);
        }
    }
}

sub initParameters {
    my %parameters;

    %parameters = ();
    $parameters{"cfg"} = $file;
    my $aInitializer = new BabelObjects::Runner::Initializer(\%parameters);
    return $aInitializer->getParameters();
}

