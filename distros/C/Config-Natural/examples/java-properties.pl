#!/usr/bin/perl -w
# 
# This example shows that Config::Natural can also read some 
# other common configuration formats like Java ".properties" 
# files. 
# 
use strict;
use Config::Natural;
use File::Spec;

print STDERR <<'USAGE' and exit unless $ENV{'JAVA_HOME'};
Please set JAVA_HOME accordingly to your configuration.
USAGE

# I use this trick because on Mac OS X, there is no jre/ 
# sub-directory in the Java directory. 
my $JAVA_HOME = $ENV{'JAVA_HOME'};
$JAVA_HOME = File::Spec->catfile($JAVA_HOME, 'jre') 
    if -d File::Spec->catfile($JAVA_HOME, 'jre');

my $javacfg = new Config::Natural { 
        auto_create_surrounding_list => 0, 
        multiline_begin_symbol => '\\', 
        multiline_end_symbol   => '' 
    };

# This file is not present on all systems.
eval { $javacfg->read_source("$JAVA_HOME/lib/swing.properties") };
unless($@) {
    my @class = split /[.]/, $javacfg->param('swing.defaultlaf');
    my $theme = $class[-1];
    my $maker = $class[0] eq 'com' ? ucfirst $class[1] : ucfirst $class[0];
    print "Your Swing applications use the $theme theme, made by $maker.\n" unless $@;
}

# This file should be present on all systems. 
$javacfg->read_source("$JAVA_HOME/lib/logging.properties");
print "Your Java apps are using the following log handlers: ", $javacfg->param('handlers'), $/;
print "The default global logging level is ", $javacfg->param('.level'), $/;
