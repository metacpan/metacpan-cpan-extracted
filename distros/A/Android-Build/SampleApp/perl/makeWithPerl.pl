#!/usr/bin/perl -I/home/phil/z/perl/cpan/DataTableText/lib -I/home/phil/z/perl/cpan/AndroidBuild/lib
#-------------------------------------------------------------------------------
# Command line build of an Android apk
# Philip R Brenan at gmail dot com, Appa Apps Ltd, 2017
#-------------------------------------------------------------------------------

use warnings FATAL => qw(all);
use strict;
use Android::Build '20171001';

my $a = &Android::Build::new();

$a->buildTools    = qq(~/Android/sdk/build-tools/25.0.2/);                      # Android SDK Build tools folder
$a->icon          = qq(~/images/Jets/EEL.jpg);                                  # Image that will be scaled to make an icon using Imagemagick - the English Electric Lightening
$a->keyAlias      = qq(xxx);                                                    # Alias of key to be used to sign this app
$a->keyStoreFile  = qq(~/keystore/release-key.keystore);                        # Key store file
$a->keyStorePwd   = qq(xxx);                                                    # Password for key store file
$a->package       = qq(com.appaapps.genapp);                                    # Package name containing the activity for this app
$a->platform      = qq(~/Android/sdk/platforms/android-25/);                    # Android SDK platform folder
$a->platformTools = qq(~/Android/sdk/platform-tools/);                          # Android SDK platform tools folder
$a->src           = [q(~/AndroidBuild/SampleApp/src/Activity.java)];            # Source code for the app
$a->title         = qq(Generic App);                                            # Title of the app as seen under the icon

$a->run;
