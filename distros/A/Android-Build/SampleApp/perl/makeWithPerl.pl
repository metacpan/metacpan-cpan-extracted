#!/usr/bin/perl
#-------------------------------------------------------------------------------
# Command line build of an Android apk
# Philip R Brenan at gmail dot com, Appa Apps Ltd, 2017
#-------------------------------------------------------------------------------

use warnings FATAL => qw(all);
use strict;
use Android::Build;
use Data::Dump qw(dump);
use Data::Table::Text qw(:all);
use Carp;

my $home = "/home/phil/vocabulary/supportingDocumentation";

my $a = &Android::Build::new();

$a->sdk          = qq(/home/phil/Android/sdk/);                                 # Android SDK on the local machine
$a->buildTools   = $a->sdk."build-tools/25.0.2/";                               # Build tools folder
$a->name         = qq(Genapp);                                                  # Name of the app, this value will be lower cased and appended to the domain name to form the package name
$a->title        = qq(Generic App);                                             # Title of the app as seen under the icon
$a->domain       = qq(com.appaapps);                                            # Domain name in reverse order
$a->icon         = "$home/images/Jets/EEL.jpg";                                 # English Electric Lightning: image that will be scaled to make an icon using Imagemagick
$a->keyAlias     = qq(xxx);                                                     # Alias of key to be used to sign this app
$a->keyStoreFile = "$home/keystore/release-key.keystore";                       # Key store file
$a->keyStorePwd  = qq(xxx);                                                     # Password for key store file

$a->build(qw(run));
