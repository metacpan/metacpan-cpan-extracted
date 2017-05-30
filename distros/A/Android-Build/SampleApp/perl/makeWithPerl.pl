#!/usr/bin/perl
#-------------------------------------------------------------------------------
# Command line build of an Android apk
# Philip R Brenan at gmail dot com, Appa Apps Ltd, 2017
#-------------------------------------------------------------------------------

use warnings FATAL => qw(all);
use strict;
use Android::Build;

my $a = &Android::Build::new();

$a->buildTools    = qq(/home/phil/Android/sdk/build-tools/25.0.2/);             # Android SDK Build tools folder
$a->icon          = qq(/home/phil/images/Jets/EEL.jpg);                         # Image that will be scaled to make an icon using Imagemagick - the English Electric Lightening
$a->keyAlias      = qq(xxx);                                                    # Alias of key to be used to sign this app
$a->keyStoreFile  = qq(/home/phil/keystore/release-key.keystore);               # Key store file
$a->keyStorePwd   = qq(xxx);                                                    # Password for key store file
$a->package       = qq(com.appaapps.genapp);                                    # Package name containing the activity for this app
$a->platform      = qq(/home/phil/Android/sdk/platforms/android-25/);           # Android SDK platform folder
$a->platformTools = qq(/home/phil/Android/sdk/platform-tools/);                 # Android SDK platform tools folder
$a->title         = qq(Generic App);                                            # Title of the app as seen under the icon

$a->run;
